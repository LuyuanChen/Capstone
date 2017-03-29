//
//  BCRBeaconService.h
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
@import CoreBluetooth;


@interface BCRBeaconService : NSObject
// Properties


// Methods
+ (BCRBeaconService *)sharedService;
- (void)startAdvertisingWithUUID: (NSUUID *)uuid
                           major: (CLBeaconMajorValue)major
                           minor: (CLBeaconMinorValue)minor
                      identifier: (NSString *)identifier;

/**
 * regions = nil, stop all regions
 */
- (void)stopAdvertising;

@end
