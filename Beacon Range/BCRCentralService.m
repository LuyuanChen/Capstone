//
//  BCRCentralService.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRCentralService.h"
#import "BCRDefaults.h"
#import "BCRAppDelegate.h"
#import "TransferService.h"
@import CoreLocation;
@import PassKit;



@interface BCRCentralService () <CLLocationManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;
@property (strong, nonatomic) CLBeaconRegion *region;

// Manager
@property (strong, nonatomic) NSDictionary *peripheralData;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CBCentralManager *centralManager;

// Peripherals
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) CBCharacteristic *transferCharacteristic;
@property (strong, nonatomic) CBCharacteristic *notifyCharacteristic;
@property (strong, nonatomic, readwrite) NSArray *discoveredPeripherals;


@property (nonatomic, readwrite, getter = isConnected) BOOL connected;


// Bluetooth UUIDs

@end


@implementation BCRCentralService

// redefine the init

#pragma mark - Class methods
+ (BCRCentralService *)sharedService
{
    static id sharedService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc]init];
    });
    return sharedService;
}

- (void)startMonitoring
{
//    NSUUID *uuid = [[NSUUID alloc]initWithUUIDString:@"184F757A-F6AA-4805-8343-9C67940D6C2B"];
//    self.region = [[CLBeaconRegion alloc]initWithProximityUUID:uuid major:1 minor:1 identifier:@"test"];
//    self.region.notifyOnEntry = YES;
//    self.region.notifyOnExit = YES;
//    self.region.notifyEntryStateOnDisplay = YES;
//    self.locationManager = [[CLLocationManager alloc]init];
//    [self.locationManager startMonitoringForRegion:self.region];
//    self.locationManager.delegate = self;
//    
//    NSLog(@"Monitoring started");
}

- (void)stopMonitoring
{
    [self.locationManager stopMonitoringForRegion:self.region];
    NSLog(@"Monitoring stopped");

}

- (void)BLEinit
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:queue options:@{ CBCentralManagerOptionRestoreIdentifierKey: @"BeaconRangeCentralServiceRestoreIdentifier"}];
}

- (void)BLEstopScan
{
    [self.centralManager stopScan];
}

- (void)writeAttempt
{
    NSLog(@"Writing data to peripheral");
    [_logDelegate didGenerateLogMessage:@"Writing data to peripheral"];
    
    // setting up the data to write
    NSData *dataToWrite = [@"String字符串" dataUsingEncoding:NSUTF8StringEncoding];
    
    // write the data
    [self.discoveredPeripheral writeValue:dataToWrite forCharacteristic:self.transferCharacteristic type:CBCharacteristicWriteWithResponse];
    
    // check if write is succ
    [self.discoveredPeripheral readValueForCharacteristic:self.transferCharacteristic];
}

- (void)writeToPeripheral:(NSData *)dataToWrite type:(CBCharacteristicWriteType)type
{
    [self.discoveredPeripheral writeValue:dataToWrite forCharacteristic:self.transferCharacteristic type:type];
    
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Sending data" message:[[NSString alloc]initWithData:dataToWrite encoding:NSUTF8StringEncoding] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        // [alert show];
//    });
}

- (void)read
{
    [self.discoveredPeripheral readValueForCharacteristic:self.notifyCharacteristic];
}

- (void)disconnect
{
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    if ([self.VCDelegate respondsToSelector:@selector(didDisconnect)])
    {
        [self.VCDelegate didDisconnect];
    }
}

#pragma mark - Central maneger
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // if the central is not in mood...
    if (central.state < CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Device not ready for connection");
        NSLog(@"Device state: [%ld]", (long)central.state);
        [_logDelegate didGenerateLogMessage:@"Device not ready for connection"];
        [self BLEinit];
        return;
    }
    NSLog(@"Device ready to scan");
    [self scan];
}

- (void)scan
{
    NSLog(@"Scanning w/ UUID [%@]", self.infoUUID);
    [self.centralManager scanForPeripheralsWithServices:@[self.infoUUID] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    NSLog(@"Scan started");
    [_logDelegate didGenerateLogMessage:@"Scan Started"];

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is in reasonable range
    if (RSSI.integerValue > -15 || RSSI.integerValue < -75)
    {
        return;
    }
    
    NSString *log = [NSString stringWithFormat:@"Discovered %@ at %@",peripheral.name, RSSI];
    NSLog(@"Discovered %@ at %@\n", peripheral.name, RSSI);
    [_logDelegate didGenerateLogMessage:log];
    
    // Ok, it's in range - have we already seen it?
    if (!(self.discoveredPeripheral == peripheral))
    {
        self.discoveredPeripheral = peripheral;
    }
    
    // And connect
    log = [NSString stringWithFormat:@"Connecting to peripheral %@\n", peripheral];
    NSLog(@"Connecting to peripheral %@\n", peripheral);
    [_logDelegate didGenerateLogMessage:log];
    
    // add it to the discovered peripheral
    if (!self.discoveredPeripherals)
    {
        self.discoveredPeripherals = [[NSArray alloc] initWithObjects:peripheral, nil];
    }
    else
    {
        // need to check duplication
        for (int i = 0; i < [self.discoveredPeripherals count]; i++)
        {
            CBPeripheral *curr = self.discoveredPeripherals[i];
            if ([peripheral.name isEqualToString:curr.name])
            {
                break;
            }
            
            if (i == self.discoveredPeripherals.count)
            {
                // the last object
                CBPeripheral *curr = self.discoveredPeripherals[i];
                if (![peripheral.name isEqualToString:curr.name])
                {
                    // not exist in the list
                    NSMutableArray *array = [self.discoveredPeripherals mutableCopy];
                    [array addObject:peripheral];
                    self.discoveredPeripherals = array;
                }
            }
        }

    }
    
    // send the data to peripheral on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.VCDelegate respondsToSelector:@selector(shouldUpdatePeripheralData:)])
        {
            [self.VCDelegate shouldUpdatePeripheralData:self.discoveredPeripherals];
        }
    });
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // if connection failed
    NSString *log = [NSString stringWithFormat:@"Failed connection to the peripheral: %@, with error: %@\n", peripheral.name, [error localizedDescription]];
    NSLog(@"Failed connection to the peripheral: %@, with error: %@\n", peripheral.name, [error localizedDescription]);
    [_logDelegate didGenerateLogMessage:log];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // sussessfully connected, now start to search the services
    // stop the scan
    [self.centralManager stopScan];
    NSLog(@"Scan stopped\n");
    NSLog(@"Connected\n");
    peripheral.delegate = self;
    // search for the services
    [peripheral discoverServices:@[self.serviceUUID]];
    NSLog(@"Start to discover service\n\n");
    
    // log to delegate
    [_logDelegate didGenerateLogMessage:@"Connected to peripheral"];
    [_logDelegate didGenerateLogMessage:@"Start to discover service"];
    
    self.connected = YES;
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error)
    {
        // check for error
        NSLog(@"Error: [%@] happened while attempting to connect to peripheral: [%@]", error.localizedDescription, peripheral.description);
        NSString *log = [NSString stringWithFormat:@"Error: [%@] happened while attempting to connect to peripheral: [%@]", error.localizedDescription, peripheral.description];
        [_logDelegate didGenerateLogMessage:log];
        
        // if failed, we start again!
        // setting the central manager to nil first because it will be initialized 
        self.centralManager = nil;
        [self BLEinit];
        return;
    }
    
    NSLog(@"Did disconnect");
    [_logDelegate didGenerateLogMessage:@"Did disconnect"];
    
    self.connected = NO;
    
    //[self scan];
}

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    
    // if there are peripherals...
    if (peripherals)
    {
        // check if there is actually one that we want by looping throuth it
        for (CBPeripheral *peripheral in peripherals)
        {
            // TODO: Here to modify the peripheral name
            if ([peripheral.name isEqualToString:@"Ahhhhh"])
            {
                [central connectPeripheral:peripheral options:nil];
                // srore a local copy
                self.centralManager = central;
            }
        }
    }
}

#pragma mark - Peripheral call backs

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // see if error
    if (error)
    {
        NSLog(@"Failed to discover service due to error: %@\n", [error localizedDescription]);
        NSString *log = [NSString stringWithFormat:@"Failed to discover service due to error: %@\n", [error localizedDescription]];
        [_logDelegate didGenerateLogMessage:log];
        
        return;
    }
    
    // if no error, continue to discover charateristics
    
    for (CBService *service in peripheral.services)
    {
        peripheral.delegate = self;
        NSArray *characteristicArray = nil;//[[NSArray alloc]initWithObjects:self.writeCharacteristicUUID, self.notifyCharacteristicUUID, nil];
        [peripheral discoverCharacteristics:characteristicArray forService:service];
        NSLog(@"Discovered service: %@\n", service.UUID);
        NSString *log = [NSString stringWithFormat:@"Discovered service: %@\n", service.UUID];
        [_logDelegate didGenerateLogMessage:log];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // if error occurred
    if (error)
    {
        NSLog(@"Failed to discover service due to error: %@", [error localizedDescription]);
        NSString *log = [NSString stringWithFormat:@"Failed to discover service due to error: %@", [error localizedDescription]];
        [_logDelegate didGenerateLogMessage:log];
        
        return;
    }
    
    NSLog(@"The characteristics are: [%@]", service.characteristics);
    NSString *log = [NSString stringWithFormat:@"The characteristic: %@", service.characteristics];
    [_logDelegate didGenerateLogMessage:log];

    // then we suscribe to the services
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        // check the property of the characteristic
        if (characteristic.properties == CBCharacteristicPropertyWriteWithoutResponse)
        {
            // store the characteristic in transfer
            self.transferCharacteristic = characteristic;
        }
        else if (characteristic.properties == CBCharacteristicPropertyNotify)
        {
            self.notifyCharacteristic = characteristic;
            
            // if the characteristic is notifying, we need to subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            NSLog(@"Did subscribe to characteristic: %@", characteristic.UUID);
            
        }
    }
    // store a local copy of the variable
    self.discoveredPeripheral = peripheral;
    
    // let delegate know
    if ([_logDelegate respondsToSelector:@selector(centralManager:readyToSendToPeripheral:)])
    {
        [_logDelegate centralManager:self.centralManager readyToSendToPeripheral:peripheral];
    }
    if ([self.delegate respondsToSelector:@selector(centralManager:readyToSendToPeripheral:)])
    {
        [self.delegate centralManager:self.centralManager readyToSendToPeripheral:peripheral];
    }
    if ([self.delegate respondsToSelector:@selector(doit)])
    {
        [self.delegate doit];
    }
    
    // tell VC to update UI, main queue dispatching needed
    dispatch_async(dispatch_get_main_queue(), ^{
        // let VC delegate knoe
        if ([self.VCDelegate respondsToSelector:@selector(didConnect)])
        {
            [self.VCDelegate didConnect];
        }
        
    });
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSLog(@"Characteristic: %@", characteristic.UUID);
    NSString *log = [NSString stringWithFormat:@"Characteristic: %@", characteristic.UUID];
    [_logDelegate didGenerateLogMessage:log];
    
    NSLog(@"Characteristic value changed, to: %@", stringFromData);
    log = [NSString stringWithFormat:@"Characteristic value changed, to: %@", stringFromData];
    [_logDelegate didGenerateLogMessage:log];
    
    if ([self.logDelegate respondsToSelector:@selector(didUpdateValueForCharacteristic:)])
    {
        [self.logDelegate didUpdateValueForCharacteristic:stringFromData];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // the central is currently suscribed to the service
    NSLog(@"Central did suscribe the service");
    
    // Also
    NSLog(@"Notification state updated.");
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing to characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Write sussessful");
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(discoveredPeripheral:didUpdateRSSI:)])
    {
        [self.delegate discoveredPeripheral:peripheral didUpdateRSSI:[peripheral.RSSI intValue]];
        return;
    }
    NSLog(@"RSSI changing: %d", [peripheral.RSSI intValue]);
    
    // change the data in self.discoveredPeripherals
    NSMutableArray *peripherals = [self.discoveredPeripherals mutableCopy];
    
    for (int i = 0; i <= [peripherals count]; i++)
    {
        if ([((CBPeripheral *)peripherals[i]) isEqual:peripheral])
        {
            peripherals[i] = peripheral;
        }
    }
    
    self.discoveredPeripherals = peripherals;
    
    // send the data to peripheral on main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.VCDelegate respondsToSelector:@selector(shouldUpdatePeripheralData:)])
        {
            [self.VCDelegate shouldUpdatePeripheralData:self.discoveredPeripherals];
        }
    });
}


@end
