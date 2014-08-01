//
//  iMASMainViewController.m
//  APSampleApp
//
//  Created by Ganley, Gregg on 8/22/13.
//  Copyright (c) 2013 MITRE Corp. All rights reserved.
//

#import "iMASMainViewController.h"
#import "APViewController.h"

@interface iMASMainViewController ()

@end

@implementation iMASMainViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
    
}


-(void)viewDidAppear:(BOOL)animated{
    [self becomeFirstResponder];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Flipside View


- (void)flipsideViewControllerDidFinish:(iMASFlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

//**
//**
//** RESET logic
//**

- (IBAction)resetPasscode:(id)sender {

    //** pop-up APview controller for questions
    APViewController *apc = [[APViewController alloc] initWithParameter:RESET_PASSCODE];
    apc.delegate = (id)self;
    [self presentViewController:apc animated:YES completion:nil];
}

- (void)validUserAccess:(APViewController *)controller {
    NSLog(@"MainView - validUserAccess - Delegate");
    //** callback for RESET
    [self dismissViewControllerAnimated:YES completion:nil];

}

//**
//** logout

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
        return;
    
    NSLog(@"User Logged out");
    IMSCryptoManagerPurge();
    exit(0);
}

- (IBAction)logout:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Logout, are you sure?" message:nil delegate:self
                          cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

@end
