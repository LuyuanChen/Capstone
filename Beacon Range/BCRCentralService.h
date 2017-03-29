//
//  BCRCentralService.h
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreBluetooth;

// define delegate method
@protocol BCRCentralServiceDelegate <NSObject>
@optional

// delegate
- (void)centralManager: (CBCentralManager *)central readyToSendToPeripheral: (CBPeripheral *)peripheral;
- (void)didGenerateLogMessage: (NSString *)message;
- (void)doit;
- (void)discoveredPeripheral: (CBPeripheral *)peripheral didUpdateRSSI: (int)RSSI;
- (void)didConnect;
- (void)didDisconnect;
- (void)shouldUpdatePeripheralData: (NSArray *)discoveredPeripherals;
- (void)didUpdateValueForCharacteristic: (NSString *)value;

@end

@interface BCRCentralService : NSObject <CBCentralManagerDelegate>

@property (nonatomic, strong) id <BCRCentralServiceDelegate> delegate;
@property (nonatomic, strong) id <BCRCentralServiceDelegate> logDelegate;
@property (nonatomic, strong) id <BCRCentralServiceDelegate> VCDelegate;

// Bluetooth UUIDs
@property (nonatomic, strong) CBUUID *infoUUID;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *notifyCharacteristicUUID;
@property (nonatomic, strong) CBUUID *writeCharacteristicUUID;
@property (nonatomic, strong) CBUUID *reserved;

// Peripherals
@property (strong, nonatomic, readonly) NSArray *discoveredPeripherals;
@property (nonatomic, readonly, getter = isConnected) BOOL connected;


/**
 *  This singleton design provide the instance of the BCRCentralService object
 *
 *  @return BCRCentralService object
 */
+ (BCRCentralService *)sharedService;

- (void)stopMonitoring;
- (void)startMonitoring;
- (void)BLEinit;
- (void)BLEstopScan;
- (void)writeAttempt;
/**
 *  Write to the only peripheral the central connected to
 *
 *  @param dataToWrite Data to send to the peripheral
 *  @param type        CBCharacteristicWriteType (with/without respond)
 */
- (void)writeToPeripheral:(NSData *)dataToWrite type:(CBCharacteristicWriteType)type;
- (void)disconnect;
- (void)read;

@end
