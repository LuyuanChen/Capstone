//
//  BCRDefaults.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRDefaults.h"

@interface BCRDefaults()
@property(nonatomic, copy, readwrite) NSUUID *defaultProximityUUID;
@property(nonatomic, copy, readwrite) NSNumber *defaultPower;
@end

@implementation BCRDefaults

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.defaultProximityUUID = [[NSUUID alloc]initWithUUIDString:@"184F757A-F6AA-4805-8343-9C67940D6C2B"];
        self.defaultPower = @-59;
    }
    return self;
}

+ (BCRDefaults *)sharedDefault
{
    static id sharedDefault;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDefault = [[self alloc]init];
    });
    return sharedDefault;
}

@end
