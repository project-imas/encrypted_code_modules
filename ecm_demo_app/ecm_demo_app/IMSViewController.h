//
//  IMSViewController.h
//  iMAS_app_integrity
//
//  Created by Gregg Ganley on 3/13/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMSViewController : UIViewController

- (IBAction)performAppIntegrity:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *detailedStatusOut;
@property (weak, nonatomic) IBOutlet UILabel *statusOut;
@end
