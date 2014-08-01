//
//  IMSViewController.m
//  iMAS_app_integrity
//
//  Created by Gregg Ganley on 3/13/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import "IMSViewController.h"
#import "AppIntegrity.h"
#import "IMSKeychain.h"
#include <asl.h>

@interface IMSViewController ()

@end

@implementation IMSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Don't show the unlock prompt if we have one stored
    NSString* unlockVal = [IMSKeychain securePasswordForService:@"ustorage" account:@"uaccount"];
    if(unlockVal) {
        self.unlockText.hidden = YES;
        self.unlockLabel.hidden = YES;
    }
	// Do any additional setup after loading the view, typically from a nib.
    
    //UIImageView *imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(40, 200, 280, 192)];
    UIImage *image = [UIImage imageNamed:@"Icon-72"];
    //imageHolder.image = image;
    // optional:
    // [imageHolder sizeToFit];
    //[self.icon setImage:image];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)performAppIntegrity:(id)sender {
    // Grab the dylib unlock value from the keychain or textbox
    BOOL hadValue = YES;
    NSString* unlockVal = [IMSKeychain securePasswordForService:@"ustorage" account:@"uaccount"];
    if(!unlockVal) {
        unlockVal = [[self unlockText] text];
        hadValue = NO;
    }
    
    NSLog(@"unlockVal: %@", unlockVal);
    
    // Clear the GUI
    [self.detailedStatusOut setText:@""];
    [self.unlockText setText:@""];
    self.unlockText.hidden = YES;
    self.unlockLabel.hidden = YES;
    [self.detailedStatusOut setText:@""];

    [self.view endEditing:YES];
    
    int success = [AppIntegrity do_app_integrity:unlockVal];
    
    // Only store value if it's not there and the dylib worked
    if(!hadValue && success == 0) {
        [IMSKeychain setSecurePassword:unlockVal forService:@"ustorage" account:@"uaccount"];
    }
    
//    BOOL status = true;
    
    //** READ APPLE System Logs facility (ASL)
    //** display contents in UI
    aslmsg q, m;
    int i;
    const char *key, *val;
    
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_SENDER, "imas_ecm_demo_app", ASL_QUERY_OP_EQUAL);
    
    aslresponse r = asl_search(NULL, q);
    while (NULL != (m = aslresponse_next(r)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(m, key);
            
            NSString *string = val?[NSString stringWithUTF8String:val]:@"";
            [tmpDict setObject:string forKey:keyString];
        }
        
        //NSLog(@"LLL %@", tmpDict);
        //NSLog(@"msg %@", [tmpDict objectForKey:@"Message"]);
        [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:[tmpDict objectForKey:@"Message"]]];
        [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:@"\n"]];
        
        //** hacky... search for string " match", if found mark as SUCCESS else fail
//        if ([[tmpDict objectForKey:@"Message"] rangeOfString:@"MISMATCH"].location != NSNotFound)
//            status = false;
        
        // gave do_app_integrity success/fail return value instead.
        
    }
    aslresponse_free(r);

    //** scroll textfield to bottom
    [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:@"\n"]];
    [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:@"\n"]];
    [self.detailedStatusOut scrollRangeToVisible:NSMakeRange([_detailedStatusOut.text length] - 1,0)];

    _statusOut.text = (success == 0)?@"Success!":@"Fail!";
}


@end
