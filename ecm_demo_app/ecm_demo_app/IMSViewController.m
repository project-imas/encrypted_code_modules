//
//  IMSViewController.m
//  iMAS_app_integrity
//
//  Created by Gregg Ganley on 3/13/14.
//  Copyright (c) 2014 Gregg Ganley. All rights reserved.
//

#import "IMSViewController.h"
#import "AppIntegrity.h"
#include <asl.h>

@interface IMSViewController ()

@end

@implementation IMSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    
    [AppIntegrity do_app_integrity];
    
    [self.detailedStatusOut setText:@""];
    
    BOOL status = true;
    
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
        if ([[tmpDict objectForKey:@"Message"] rangeOfString:@"MISMATCH"].location != NSNotFound)
            status = false;
        
    }
    aslresponse_free(r);

    //** scroll textfield to bottom
    [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:@"\n"]];
    [self.detailedStatusOut setText:[_detailedStatusOut.text stringByAppendingString:@"\n"]];
    [self.detailedStatusOut scrollRangeToVisible:NSMakeRange([_detailedStatusOut.text length] - 1,0)];
    
    if (status)
        _statusOut.text = @"Success!";
    else
        _statusOut.text = @"Fail!";
    
}


@end
