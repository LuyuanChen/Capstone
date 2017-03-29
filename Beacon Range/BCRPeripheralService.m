//
//  BCRPeripheralService.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRPeripheralService.h"
#import "TransferService.h"
#import "BCRAppDelegate.h"
@import CoreBluetooth;

@interface BCRPeripheralService () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBCharacteristic *transferCharacteristic;
@property (strong, nonatomic) CBService *transferService;

@end

@implementation BCRPeripheralService

+ (BCRPeripheralService *)sharedService
{
    static id sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc]init];
    });
    return sharedService;
}

- (void)startBLEPeripheralService
{
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

- (void)stopBLEPeripheralService
{
    [self.peripheralManager stopAdvertising];
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state < CBPeripheralManagerStatePoweredOn)
    {
        NSLog(@"Peripheral manager can't work, in state [%ld]", (long)peripheral.state);
        return;
    }
    
    // set up the characteristic here
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                                properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
                                                                                     value:nil
                                                                               permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    // set up the service
    CBMutableService *service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    
    service.characteristics = @[characteristic];
    [self.peripheralManager addService:service];
    
    NSMutableDictionary *peripheralData = [[NSMutableDictionary alloc]initWithDictionary:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]}];
    [self.peripheralManager startAdvertising:peripheralData];

}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error starting the service: [%@]", error.localizedDescription);
        return;
    }
    NSLog(@"Service successfully started");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // when central subscribe to the characteristic, make local copy of service and char
    NSLog(@"Central did subscribe to characteristic: [%@]", characteristic.UUID);
    self.transferCharacteristic = characteristic;
    self.transferService = characteristic.service;
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    // check if central requests to write to the transfer characteristic
    if ([request.characteristic.UUID isEqual:self.transferCharacteristic.UUID])
    {
        if (request.offset > self.transferCharacteristic.value.length)
        {
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorInvalidOffset];
        }
        
        request.value = [self.transferCharacteristic.value subdataWithRange:NSMakeRange(request.offset, self.transferCharacteristic.value.length - request.offset)];
        // respond
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    CBATTRequest *request = [requests objectAtIndex:0];
    
    // check if the request is of the transfer service
    if ([self.transferCharacteristic.UUID isEqual:request.characteristic.UUID])
    {
        [self.transferCharacteristic setValue:request.value forKeyPath:@"value"];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        [_delegate didWriteData:request.value];
    }
}

@end