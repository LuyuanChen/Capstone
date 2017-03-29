//
//  BCRTransmitterViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRTransmitterViewController.h"
#import "BCRDefaults.h"
#import "TransferService.h"
@import CoreBluetooth;
@import CoreLocation;

@interface BCRTransmitterViewController () <CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) NSMutableDictionary *peripheralData;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;


@property (weak, nonatomic) IBOutlet UILabel *serviceLabel;

// peripheral delegate
@property (strong, nonatomic) CBCharacteristic *transferCharisteristic;

@end

@implementation BCRTransmitterViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up the default uuid, power things here
    self.beaconRegion = [[CLBeaconRegion alloc]initWithProximityUUID:[[NSUUID alloc]initWithUUIDString:BEACON_UUID] major:1 minor:1 identifier:@"test"];
    
    self.peripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
    
    // dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil options:nil];
    
    NSLog(@"Beacon Peripheral data: %@", self.peripheralData);
    
    // [self.peripheralData addEntriesFromDictionary:@{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]}];
    
    // self.peripheralData = [@{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]} mutableCopy];
    
    [self.peripheralData setObject:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] forKey:CBAdvertisementDataServiceUUIDsKey];
    
    NSLog(@"Peripheral data COMBINED: %@", self.peripheralData);

    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.peripheralManager stopAdvertising];
    NSLog(@"Advertising stopped");
}

- (IBAction)fire:(id)sender
{
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn)
    {
        [self.peripheralManager startAdvertising:self.peripheralData];

        NSLog(@"Service enabled");
        self.serviceLabel.text = @"Enabled";
        
        NSLog(@"The peripheral date is: %@", self.peripheralData);
    }
    else
    {
        NSLog(@"The serveice is not available");
        NSLog(@"Peripheral manager state: %d", self.peripheralManager.state);
    }
}


#pragma mark - Call back
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // ensure it's in the correct state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn)
    {
        return;
    }
    
    // we set the characteristics here
    
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                                properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead
                                                                                    value:nil
                                                                               permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable
                                               ];
    // set up the transfer service
    CBMutableService *service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    
    service.characteristics = @[characteristic];
    [self.peripheralManager addService:service];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    self.transferCharisteristic = characteristic;
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"Error when advertising: [%@]", error.localizedDescription);
    }
    NSLog(@"Advertising sussessfully started");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    if ([request.characteristic.UUID isEqual:self.transferCharisteristic.UUID])
    {
        if (request.offset > self.transferCharisteristic.value.length)
        {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
        }
        request.value = [self.transferCharisteristic.value subdataWithRange:NSMakeRange(request.offset, self.transferCharisteristic.value.length - request.offset)];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    CBATTRequest *request = [requests objectAtIndex:0];
    if ([request.characteristic.UUID isEqual:self.transferCharisteristic.UUID])
    {
        [self.transferCharisteristic setValue:request.value forKey:@"value"];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        self.serviceLabel.text = [[NSString alloc]initWithData:request.value encoding:NSUTF8StringEncoding];
    }
}
@end
