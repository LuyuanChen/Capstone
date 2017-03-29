//
//  BCRBeaconService.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRBeaconService.h"
#import "TransferService.h"

@interface BCRBeaconService () <CLLocationManagerDelegate,CBPeripheralManagerDelegate>

// location properties
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *region;

// bluetooth properties
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;

@end

@implementation BCRBeaconService

+ (BCRBeaconService *)sharedService
{
    static id sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc]init];
    });
    return  sharedService;
}


- (void)startAdvertisingWithUUID: (NSUUID *)uuid
                           major: (CLBeaconMajorValue)major
                           minor: (CLBeaconMinorValue)minor
                      identifier: (NSString *)identifier
{
    self.region = [[CLBeaconRegion alloc]initWithProximityUUID:uuid major:major minor:minor identifier:identifier];
    
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];

    // broadcast the beacon
}

- (void)stopAdvertising;
{
    [self.peripheralManager stopAdvertising];
}

#pragma mark - Bluetooth call backs

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn)
    {
        NSLog(@"Peripheral manager can't work under state: [%ld]", (long)peripheral.state);
        return;
    }
    // TODO: fuck this shit
    NSMutableDictionary *peripheralData = [[NSMutableDictionary alloc] init];
    peripheralData = [self.region peripheralDataWithMeasuredPower:@-59];
    [self.peripheralManager startAdvertising:peripheralData];

    NSLog(@"Peripheral manager initialized");
    NSLog(@"Peripheral data: [%@]", peripheralData);
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Peripheral manager can't start advertising due to: [%@]", error.localizedDescription);
        return;
    }
    NSLog(@"Beacon advertising successfully started");
}

@end
