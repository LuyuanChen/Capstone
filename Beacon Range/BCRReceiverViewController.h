//
//  BCRReceiverViewController.h
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreBluetooth;


@interface BCRReceiverViewController : UIViewController

@property (strong, nonatomic) NSArray *discoveredPeripherals;

@end
