//
//  BCRCapViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2017-03-28.
//  Copyright © 2017 Luyuan Chen. All rights reserved.
//

#import "BCRCapViewController.h"
#import "BCRCentralService.h"

@interface BCRCapViewController () <BCRCentralServiceDelegate>

@property (nonatomic, strong) BCRCentralService *service;

@end

@implementation BCRCapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)activateBLE:(UIButton *)sender {
//    do things here
    BCRCentralService *service = [BCRCentralService sharedService];
    service.delegate = self;
    service.logDelegate = self;
    [service BLEinit];
    
    
}

- (void) didGenerateLogMessage:(NSString *)message {
    NSLog(@"Message generated: [%@]", message);
}


@end
