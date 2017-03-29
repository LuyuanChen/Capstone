//
//  BCRPeripheralService.h
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-15.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BCRPeripheralServiceDelegate <NSObject>
@optional
- (void)didWriteData: (NSData *)data;

@end

@interface BCRPeripheralService : NSObject

@property (nonatomic, retain) id <BCRPeripheralServiceDelegate> delegate;

+ (BCRPeripheralService *)sharedService;
- (void)startBLEPeripheralService;
- (void)stopBLEPeripheralService;

@end
