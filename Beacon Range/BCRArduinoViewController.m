//
//  BCRArduinoViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-21.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRArduinoViewController.h"
#import "BCRCentralService.h"
#import "TransferService.h"
#import "BCRColorPicker.h"
#import <CoreGraphics/CoreGraphics.h>
#import "ISColorWheel.h"
#import "MBProgressHUD.h"

#define RED 1
#define GREEN 3
#define BLUE 5

@import CoreBluetooth;

@interface BCRArduinoViewController() <BCRCentralServiceDelegate, UITextFieldDelegate, ISColorWheelDelegate>
// class variable

// UI
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UITextField *dataField;
@property (weak, nonatomic) IBOutlet UISwitch *lightSwitch;
@property (weak, nonatomic) IBOutlet UIView *colorWheelView;
@property (weak, nonatomic) IBOutlet BCRColorPicker *pickerView;
@property (strong, nonatomic) ISColorWheel *colorWheel;

// UILabel
@property (weak, nonatomic) IBOutlet UILabel *redValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueValueLabel;

// property
@property (nonatomic) CGFloat redValue;
@property (nonatomic) CGFloat greenValue;
@property (nonatomic) CGFloat blueValue;

@end

@implementation BCRArduinoViewController

#pragma mark - Life cycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    // modify the viewcontroller
    
    [BCRCentralService sharedService].logDelegate = self;
    self.dataField.delegate = self;
    
    // set up the BLE
    [BCRCentralService sharedService].serviceUUID = [CBUUID UUIDWithString:TRANSFER_SERVICE_UUID];
    [BCRCentralService sharedService].writeCharacteristicUUID = [CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID];
    self.lightSwitch.enabled = NO;
    self.lightSwitch.on = NO;
    self.lightSwitch.onTintColor = [UIColor purpleColor];
    
    // configure the color wheel
    self.colorWheelView.backgroundColor = [UIColor whiteColor];
    
    CGSize size = self.colorWheelView.bounds.size;
    
    CGSize wheelSize = CGSizeMake(size.width * .9, size.width * .9);
    
    self.colorWheel = [[ISColorWheel alloc] initWithFrame:CGRectMake(size.width / 2 - wheelSize.width / 2,
                                                                 size.height * .1,
                                                                 wheelSize.width,
                                                                 wheelSize.height)];
    self.colorWheel.delegate = self;
    self.colorWheel.continuous = true;
    [self.colorWheelView addSubview:_colorWheel];
    
    
    // configure the gesture recognizer
    
    // set up the picker view
    self.pickerView.center = self.colorWheelView.center;
    [self.colorWheel addSubview:self.pickerView];
}

#pragma mark - ColorWheel
- (void)colorWheelDidChangeColor:(ISColorWheel *)colorWheel
{
    self.pickerView.color = self.colorWheel.currentColor;
    // setting up the rgb
    CGFloat red, blue, green;
    [self.colorWheel.currentColor getRed:&red green:&green blue:&blue alpha:NULL];
    self.redValue = red * 255;
    self.blueValue = blue * 255;
    self.greenValue = green * 255;
    
    // setting up labels
    self.redValueLabel.text = [NSString stringWithFormat:@"R: %.0f", red * 255];
    self.greenValueLabel.text = [NSString stringWithFormat:@"G: %.0f", green * 255];
    self.blueValueLabel.text = [NSString stringWithFormat:@"B: %.0f",  blue * 255];
    
    // send data to BLE device
    [self sendRGBdata];
}


- (IBAction)handleTap:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self.colorWheelView];

    self.pickerView.center = point;
    self.pickerView.hidden = NO;
}


- (IBAction)scanControl:(UIButton *)sender
{
    // start the scan if the title is "start scan"
    if ([sender.titleLabel.text isEqualToString:@"Start Scan"])
    {
        [[BCRCentralService sharedService] BLEinit];
        [self.scanButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        
    }
    else if ([sender.titleLabel.text isEqualToString:@"Disconnect"])
    {
        [[BCRCentralService sharedService] disconnect];
        [[BCRCentralService sharedService] BLEstopScan];
        [self.scanButton setTitle:@"Start Scan" forState:UIControlStateNormal];
        self.lightSwitch.on = NO;
        self.lightSwitch.enabled = NO;
    }
}

#pragma mark - Call back
-(void)didGenerateLogMessage:(NSString *)message
{
}

-(void)didUpdateValueForCharacteristic:(NSString *)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.animationType = MBProgressHUDAnimationZoomIn;
        hud.labelText = value;
        hud.minShowTime = 1;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

#pragma mark - UI

- (IBAction)backgroundTouch
{
    [self.dataField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self performSelector:@selector(sendData)];
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (range.location > 7)
    {
        return NO;
    }
    return YES;
}

- (void)centralManager:(CBCentralManager *)central readyToSendToPeripheral:(CBPeripheral *)peripheral
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.animationType = MBProgressHUDAnimationZoomIn;
        hud.labelText = @"Ready";
        hud.minShowTime = 0.5;
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
}

#pragma mark - action
- (IBAction)sendData
{
//    NSData *dataToSend = [self.dataField.text dataUsingEncoding:NSUTF8StringEncoding];
//    NSData *dataToSend = [@"R" dataUsingEncoding:NSUTF8StringEncoding];
//    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
//    
//    dataToSend = [@"4" dataUsingEncoding:NSUTF8StringEncoding];
//    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)read
{
    [[BCRCentralService sharedService] read];
}

- (IBAction)lightSwitch:(UISwitch *)sender
{
    if (sender.on == YES)
    {
        NSData *dataToSend = [@"O" dataUsingEncoding:NSUTF8StringEncoding];
        [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
        return;
    }
    NSData *dataToSend = [@"23" dataUsingEncoding:NSUTF8StringEncoding];
    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - Class method
- (void)sendRGBdata
{
    // the value goes to 123 or 0x7B
    // 0 as brightest, so 255 -> 0, 0 -> 123
    
    // Scale the RGB value so it's 0 -> 123

    float scale;
    scale = 123.0 / 255.0;
    
    float redScaled = self.redValue * scale;
    float greenScaled = self.greenValue * scale;
    float blueScaled = self.blueValue * scale;

    redScaled = 123 - redScaled;
    blueScaled = 123 - blueScaled;
    greenScaled = 123 - greenScaled;
    
    int red = (int)redScaled;
    int blue = (int)blueScaled;
    int green = (int)greenScaled;
    
    
    // wraps the data into an array
    UInt8 buf[7] = {0x01, 0x00, 0x03, 0x00, 0x05, 0x00, 0x00};
    
    buf[RED] = red;
    buf[GREEN] = green;
    buf[BLUE] =  blue;
    
    
    NSLog(@"Data sent: R:[%d]G:[%d]B:[%d]", red , green, blue);
    
    NSData *dataToSend = [[NSData alloc]initWithBytes:buf length:7];
    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
}

@end
