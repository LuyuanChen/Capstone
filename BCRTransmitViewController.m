//
//  BCRTransmitViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRTransmitViewController.h"
#import "BCRBeaconService.h"
#import "BCRPeripheralService.h"
#import "TransferService.h"
#import "BCRAppDelegate.h"

@interface BCRTransmitViewController () <BCRPeripheralServiceDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *beaconSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *BLESwitch;

@end

@implementation BCRTransmitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [BCRPeripheralService sharedService].delegate = self;
    
    NSLog(@"Current: BCRTransmitter, root: %@", ((BCRAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController.childViewControllers);
    
    // disable the monitoring function 
    [((BCRAppDelegate *)[UIApplication sharedApplication].delegate) stopMonitor];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // stop all transmitting service
    [[BCRBeaconService sharedService]stopAdvertising];
    [[BCRPeripheralService sharedService]stopBLEPeripheralService];
}


// UI interactions
- (IBAction)beaconControl:(UISwitch *)sender
{
    if (sender.on == YES)
    {
        [[BCRBeaconService sharedService]startAdvertisingWithUUID:[[NSUUID alloc]initWithUUIDString:BEACON_UUID]
                                                            major:1
                                                            minor:1
                                                       identifier:@"com.test"];
        return;
    }
    [[BCRBeaconService sharedService]stopAdvertising];
}

- (IBAction)BLEControl:(UISwitch *)sender
{
    if (sender.on == YES)
    {
        [[BCRPeripheralService sharedService]startBLEPeripheralService];
        return;
    }
    [[BCRPeripheralService sharedService]stopBLEPeripheralService];
}

// Call back of peripheral service
- (void)didWriteData:(NSData *)data
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Data Received" message:[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

@end
