//
//  BCRViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "BCRViewController.h"
#import "BCRAppDelegate.h"

@interface BCRViewController ()

@end

@implementation BCRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"Current: Base, root: %@", ((BCRAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController.presentingViewController);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
