//
//  BCRAppDelegate.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "BCRAppDelegate.h"
#import "BCRDefaults.h"
#import "TransferService.h"
#import "BCRReceiverViewController.h"
#import "BCRCentralService.h"
#import "BCRTransmitViewController.h"

@interface BCRAppDelegate () <BCRCentralServiceDelegate, CLLocationManagerDelegate>//, CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (nonatomic,getter = isComingIn) BOOL comingIn;

@end

@implementation BCRAppDelegate
{
    CLLocationManager *_locationManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // handle the localnotification
    UILocalNotification *localNotif = [launchOptions objectForKeyedSubscript:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif)
    {
        [[self.window.rootViewController.childViewControllers objectAtIndex:0] performSegueWithIdentifier:@"Receiver" sender:self];
        [[BCRCentralService sharedService] BLEinit];
    }
    
    [self startMonitor];
    
    NSLog(@"AppDelegate monitoring started");
    
    
    // Configure the central service
    [BCRCentralService sharedService].delegate = self;
    
    
//    NSLog(@"Application didFinishLaunchingWithOption: Try BLE connect");
//    [[BCRCentralService sharedService] BLEinit];
    
    
    
    
    // handles the wake up when the bluetooth backgrounding
    NSArray *centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
    if (centralManagerIdentifiers)
    {
        // init the BLE service using the same restoration identifier
        // [[BCRCentralService sharedService]BLEinit];
    }

    return YES;
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    [[BCRCentralService sharedService] disconnect];
}

- (void)startMonitor
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc]initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:BEACON_UUID] major:1 minor:1 identifier:@"com.test"];
    region.notifyEntryStateOnDisplay = YES;
    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    
    [_locationManager startMonitoringForRegion:region];
}

- (void)stopMonitor
{
    if (_locationManager)
    {
        [_locationManager stopMonitoringForRegion:[[CLBeaconRegion alloc]initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:BEACON_UUID] major:1 minor:1 identifier:@"com.test"]];
        return;
    }
}




#pragma mark - delegate
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        NSLog(@"Name of region: %@", region.identifier);
        // store the region class
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        
        if ([beaconRegion.proximityUUID isEqual:[BCRDefaults sharedDefault].defaultProximityUUID])
        {
            UILocalNotification *notification = [[UILocalNotification alloc]init];
            notification.alertBody = @"Welcome home! Swipe me to turn on the lights";
            
            [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
        }
        
        NSLog(@"Sending from the AppDelegate");
        
        // when beacon received, we start the bluetooth
        [BCRCentralService sharedService].serviceUUID = [CBUUID UUIDWithString:TRANSFER_SERVICE_UUID];
        // info service for BLE
        [BCRCentralService sharedService].infoUUID = [CBUUID UUIDWithString:INFO_UUID];
        [BCRCentralService sharedService].writeCharacteristicUUID = [CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID];
        [BCRCentralService sharedService].notifyCharacteristicUUID = [CBUUID UUIDWithString:TRANSFER_NOTIFY_CHARACTERISTC_UUID];
        [[BCRCentralService sharedService] BLEinit];
        self.comingIn = YES;
    }
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    BCRDefaults *defaultSettings = [[BCRDefaults alloc]init];
    
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        // store the region class
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        
        if ([beaconRegion.proximityUUID isEqual:defaultSettings.defaultProximityUUID])
        {
            UILocalNotification *notification = [[UILocalNotification alloc]init];
            notification.alertBody = @"You entered the evil zone!";
            
            [[UIApplication sharedApplication]presentLocalNotificationNow:notification];
            
            // at the entering of the region, start BLE service
            // [[BCRCentralService sharedService] BLEinit];
            self.comingIn = YES;
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]])
    {
        NSLog(@"Exited the region");
        [[BCRCentralService sharedService] disconnect];
    }
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    // the location manager failed
    if (error)
    {
        NSLog(@"The location manager failed to monitor region: [%@], for the error [%@]", region.identifier, [error localizedDescription]);
    }
}

- (void)centralManager:(CBCentralManager *)central readyToSendToPeripheral:(CBPeripheral *)peripheral
{
    if (self.isComingIn)
    {
        NSLog(@"Writing ON to peripheral");
        NSData *dataToWrite = [@"O" dataUsingEncoding:NSUTF8StringEncoding];
        [[BCRCentralService sharedService] writeToPeripheral:dataToWrite type:CBCharacteristicWriteWithoutResponse];
    }
}

- (void)doit
{
    NSLog(@"Did it");
}

// handles notification

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // if we are already in one of recerver and transmitter
    NSArray *vcs = self.window.rootViewController.childViewControllers;
    if ([vcs count] == 2)
    {
        // if we are in transmitter
        if ([[vcs objectAtIndex:1] isKindOfClass:[BCRTransmitViewController class]])
        {
            // need to pop the current vc and segue to the receiver
            [[vcs objectAtIndex:1]dismissViewControllerAnimated:YES completion:nil];
            vcs = self.window.rootViewController.childViewControllers;
            // the 0th content should perform segue
            [[vcs objectAtIndex:0]performSegueWithIdentifier:@"Receiver" sender:self];
            return;
        }
    }
    else if ([vcs count] == 1)
    {
        [[self.window.rootViewController.childViewControllers objectAtIndex:0] performSegueWithIdentifier:@"Receiver" sender:self];
        //[[BCRCentralService sharedService] BLEinit];
    }
}
@end
