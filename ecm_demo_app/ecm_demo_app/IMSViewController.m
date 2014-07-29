//
//  IMSViewController.m
//  iMAS_app_integrity
//
//  Created by Gregg Ganley on 3/13/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import "IMSViewController.h"
#import "AppIntegrity.h"

@interface IMSViewController ()

@end

@implementation IMSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performAppIntegrity:(id)sender {
    
    [AppIntegrity do_app_integrity];
    
    _detailedStatusOut.text = @"gregg";
    
}
@end
