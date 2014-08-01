//
//  APViewController.m
//  APComplexPassEncryt
//
//  Created by ct on 4/4/13.
//  Copyright (c) 2013 Mitre. All rights reserved.
//

#import "APViewController.h"
#import "iMASMainViewController.h"

@interface APViewController ()

//** key to retain these objects (pass and questions) b/c ARC will deallocate when view this view controller is backgrounded
@property (nonatomic, retain) APPass    *pass;
@property (nonatomic, retain) APPass    *question;

@property (nonatomic) NSInteger  numberOfQuestion;
@property (nonatomic) PASS_CTL   passControl;


@property (nonatomic,strong) IBOutlet UIButton *askForPassword;
@property (nonatomic,strong) IBOutlet UIImage  *background;
@property (nonatomic,strong) IBOutlet UIButton *logoutButton;
@property (nonatomic,strong) IBOutlet UIButton *resetButton;

//@property (weak, nonatomic) IBOutlet UIButton *clearAllButton;
@property (nonatomic,strong) IBOutlet UIButton *forgotButton;

@end


@implementation APViewController

//** private instance vars
//** obfuscated password reset var
bool class_vector = FALSE;
//** obfuscated logout var
bool obj_var = FALSE;

-(id)initWithParameter: (int8_t)thaThing {
    self = [super init];
    if (self) {
        if (thaThing == 1)
            class_vector = TRUE;
        else
            obj_var = TRUE;
    }
    return self;
}


- (void)     viewDidLoad                {
    
    [super viewDidLoad];
    
    [self.askForPassword  addTarget:self
                             action:@selector(askForPasscode:)
                   forControlEvents:UIControlEventTouchUpInside];
    
    // ---------------------------------------------------------------
    // AppPassword API - passcode
    // ---------------------------------------------------------------
    self.pass                = [APPass passComplex];
    self.pass.delegate       = self;
    self.pass.background     = self.background;
    self.pass.syntax         = @"^.*(?=.*[a-zA-Z])(?=.*[0-9])(?=.{6,}).*$";
    self.pass.syntaxLabel    = @"length:6 - 1 digit, 1 capital";
    self.pass.resetEnabled   = FALSE; //** TRUE - ask user for questions and password resets after 3 failures
                                      //** FALSE - exit(0) after 3 failures
    // ---------------------------------------------------------------
    // AppPassword API - security questions
    // ---------------------------------------------------------------
    self.numberOfQuestion    = 2;
    self.question            = [APPass passQuestions:self.numberOfQuestion];
    self.question.delegate   = self;
    self.question.background = self.background;
    

    //** uncomment to clear password for testing purposes
    //[self clearPassword:0];

    if (class_vector) {
        //** reset passcode after login
        class_vector = FALSE;
        [self askForQuestions];
    }
    else if (obj_var) {
        //** logout
        obj_var = FALSE;
        [self passLogout:0];
    }
    else {
        //** uncomment to automatically launch the passcode dialog
        [self askForPasscode:self];
    }
    
}


- (IBAction)  askForPasscode:(id)sender {
    
    if ( [self checkForIMSCrytoPass] ) {
        //** standard user login
        self.pass.verify         = @"verify";
        self.passControl         = PASS_VERIFY;
        
    } else {
        //** first time login: create password and questions
        self.pass.verify         = nil;
        self.passControl         = PASS_CREATE;
        
    }
    // ---------------------------------------------------------------
    // setting the parent will cause the passView to be displayed
    // ---------------------------------------------------------------
    self.pass.parentView     = self.view;
}


//- (IBAction) askForQuestions:(id)sender {
- (void) askForQuestions {
    
    self.question.verifyQuestions  = IMSCryptoManagerSecurityQuestions();
    self.passControl         = (nil == self.pass.verify) ? PASS_CREATE_Q: PASS_VERIFY_Q;
    // ---------------------------------------------------------------
    // setting the parent will cause the passView to be displayed
    // ---------------------------------------------------------------
    
    self.question.parentView = self.view;
}


//*******************
//** DEBUG purposes - remove from production code

# if 1
- (IBAction) clearPassword:(id)sender {
    //** remove password and questions and answers
    
    IMSCryptoManagerPurge();
    
    NSArray *accounts = [IMSKeychain accounts];
    
    [accounts enumerateObjectsUsingBlock:
     
     ^(NSDictionary *account, NSUInteger idx, BOOL *stop) {
         
         NSString *serviceName = account[(__bridge NSString *)kSecAttrService];
         NSString *accountName = account[(__bridge NSString *)kSecAttrAccount];
         
         [IMSKeychain deletePasswordForService:serviceName account:accountName];
     }];
    
    [IMSKeychain synchronize];
    
    self.pass.clear     = @"clear";
    self.question.clear = @"clear";
    
    [[[UIAlertView alloc]
      initWithTitle:@"Welcome"
      message:@"Passwords and Q&A cleared!"
      delegate:nil
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil]
     show];

}
#endif


//------------------------------------------------------------------------------
// APPassProtocol - required
//------------------------------------------------------------------------------
-(void) APPassComplete:(UIViewController*) viewController
            withPhrase:(NSString*)         phrase {


    if ( nil != phrase ) {
        
        switch (self.passControl) {
                
            case PASS_CREATE:
                //** first time login
                [self processCreate:viewController
                                       withPhrase:phrase];
                break;
                
            case PASS_RESET:
                [self  processReset:viewController
                                       withPhrase:phrase];
                //** succesful reset; so pop-up alert box
                break;
                
            case PASS_VERIFY:
                //** standard login
                [self processVerify:viewController
                                       withPhrase:phrase];
                break;
                
            default: break;
        }
    }
}


//------------------------------------------------------------------------------
// First Time Login: The passcode has been entered now present the questions
//------------------------------------------------------------------------------
- (void) processCreate:(UIViewController*) viewController
            withPhrase:(NSString*) phrase {

    NSLog(@"here in processCreate");
    
    //** hold on to the phrase for finialize method
    //** only called during the initial creation of the passcode, otherwise the temporary variable is never used.
    IMSCryptoManagerStoreTP(phrase);
    
    // ask to create questions
    [self askForQuestions];

}


//------------------------------------------------------------------------------
// Update the stored passcode with a new one
//------------------------------------------------------------------------------
- (void)  processReset:(UIViewController*) viewController
            withPhrase:(NSString*) phrase {
   
    IMSCryptoManagerUpdatePasscode(phrase);
    
    //** call delegate return
    [self.delegate validUserAccess:self];
}


//------------------------------------------------------------------------------
//  Callback from APassword on successful login
//------------------------------------------------------------------------------
- (void) processVerify:(UIViewController*) viewController
            withPhrase:(NSString*) phrase {
    
    //NSLog(@"here in processVerify USER Logged");
    
    //** USER logged in
    //** call delegate return
    [self.delegate validUserAccess:self];
}

//------------------------------------------------------------------------------
// APPassProtocol - required if implementing secureFoundation
//------------------------------------------------------------------------------
-(BOOL) verifyPhraseWithSecureFoundation:(NSString*) phrase {
    
    BOOL ret = NO;
    
    ret = IMSCryptoManagerUnlockWithPasscode(phrase);
    
    return ret;
}


//------------------------------------------------------------------------------
// Required if implementing secureFoundation
//------------------------------------------------------------------------------
-(NSString*) checkForIMSCrytoPass {
    
    NSString* key = nil;
    
    if (IMSCryptoManagerHasPasscode()) key = @"verify";
    
    return key;
}


-(void) resetPassAP {
    
    [self askForQuestions];
}

-(void) forgotPassAP {
    //** called from delegate APpassword
    
    [self askForQuestions];
}

//------------------------------------------------------------------------------
// APQuestionProtocol - required
//------------------------------------------------------------------------------
-(void) APPassComplete:(UIViewController *) viewController
         withQuestions:(NSArray *)          questions
            andAnswers:(NSArray *)          answers {
    
    if ( nil != questions && nil != answers ) {
        
        switch (self.passControl) {
                
            case PASS_CREATE_Q:
                //** first time login - questions create
                [self processCreateQuestion:questions
                                withAnswers:answers];
                               
                //** USER logged in
                //** delegate return
                [self.delegate validUserAccess:self];
                break;
                
            case PASS_RESET_Q:  [self processResetQuestion:questions
                                               withAnswers:answers];
                break;
                
            default: break;
        }
    }
}

-(void) processCreateQuestion:questions withAnswers:answers {
    
    IMSCryptoManagerStoreTSQA(questions,answers);
    IMSCryptoManagerFinalize();
    
    //** 
}

-(void)  processResetQuestion:questions withAnswers:answers {
    
    IMSCryptoManagerUpdateSecurityQuestionsAndAnswers(questions, answers);
}


-(BOOL) APPassQuestion:(UIViewController *) viewController
         verifyAnswers:(NSArray *)          answers {
    
    if (IMSCryptoManagerUnlockWithAnswersForSecurityQuestions(answers) == FALSE) {
        //** wrong answers to questions
        //** display a dialog and then quit app
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Answers do not match Questions, exiting" message:nil delegate:self
                              cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert setTag:0];
        [alert show];
        
        return FALSE;
    }
    else {
        //** App Password will prompt for new passcode
        //** display a dialog and then quit app
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Reset success, enter new passcode" message:nil delegate:self
                              cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert setTag:1];
        [alert show];
        
        return TRUE;
    }
}

//------------------------------------------------------------------------------
// user forgot the passcode and is answering security questions in order to
// reset it
//------------------------------------------------------------------------------
-(void) APPassQuestionVerified:(UIViewController *) viewController
                   verifyState:(BOOL)               verify {
    
    if ( verify ) {
        
        self.passControl     = PASS_RESET;
        self.pass.verify     = nil;
        self.pass.parentView = self.view;
        
    } else {
        
        exit(0);
    }
}


- (IBAction)passcodeReset:(id)sender {
    
    //** check and confirm passcode was entered by user already
    if (IMSCryptoManagerHasPasscode()) {
        self.passControl     = PASS_RESET;
        self.pass.verify     = nil;
        self.pass.parentView = self.view;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex]) return;

    //** question reset - failed Q&A
    if (alertView.tag == 0)
    {
        //** user entered bad answers to questions
        exit(0);
    }
    
    //** question reset - good Q&A, just return when OK is pressed
    if (alertView.tag == 1)
    {
        return;
    }

    //** logout
    if (alertView.tag == 2)
    {
       NSLog(@"User Logged out");
       IMSCryptoManagerPurge();
       exit(0);
    }
    
    
    if (alertView.tag == 2 || alertView.tag == 3) {
        //** user logged out or cleared all passwords and questions
        ; 
    }

    //** clear all
    if (alertView.tag == 3)
    {
        NSLog(@"User CLEARED ALL!");
        [self clearPassword:nil];
    }

}

//** use this IBaction when there is an actual view associated with this controller
#if 1
- (IBAction)passLogout:(id)sender {
    
       
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Logout, are you sure?" message:nil delegate:self
                          cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert setTag:2];
    [alert show];
    
}
#endif


@end

