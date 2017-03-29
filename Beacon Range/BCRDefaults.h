//
//  BCRDefaults.h
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCRDefaults : NSObject

@property(nonatomic, copy, readonly) NSUUID *defaultProximityUUID;
@property(nonatomic, copy, readonly) NSNumber *defaultPower;

+ (BCRDefaults *)sharedDefault;

@end
