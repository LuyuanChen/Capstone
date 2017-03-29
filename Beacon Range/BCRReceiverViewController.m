//
//  BCRReceiverViewController.m
//  Beacon Range
//
//  Created by Luyuan Chen on 2014-05-08.
//  Copyright (c) 2014 Luyuan Chen. All rights reserved.
//

#import "BCRReceiverViewController.h"
#import "BCRDefaults.h"
#import "BCRAppDelegate.h"
#import "TransferService.h"
#import "BCRCentralService.h"
@import CoreLocation;

@interface BCRReceiverViewController () <BCRCentralServiceDelegate, UITableViewDataSource, UITableViewDelegate>

// UI
@property (weak, nonatomic) IBOutlet UITextField *instructionTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UILabel *connectionStateLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISegmentedControl *lightControl;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;

@end

@implementation BCRReceiverViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [BCRCentralService sharedService].VCDelegate = self;
    [BCRCentralService sharedService].serviceUUID = [CBUUID UUIDWithString:TRANSFER_SERVICE_UUID];
    if (![BCRCentralService sharedService].isConnected)
    {
        [[BCRCentralService sharedService]BLEinit];
    }
    else
    {
        [self.spinner stopAnimating];
        self.connectionStateLabel.text = @"Connected";
        self.discoveredPeripherals = [BCRCentralService sharedService].discoveredPeripherals;
        [self.tableView reloadData];
    }
    
    // setting up the UI
    [self.spinner startAnimating];
    self.lightControl.selectedSegmentIndex = 1; // selecting Off by default
    
    // setting up the table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // stop monitoring
//    [[BCRCentralService sharedService] stopMonitoring];
}

- (IBAction)textFieldShouldReturn
{
    [self.instructionTextField resignFirstResponder];
}

- (IBAction)sendData
{
    NSData *dataToSend = [self.instructionTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
}

- (IBAction)lightSwitch:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1)
    {
        NSData *dataToSend = [@"F" dataUsingEncoding:NSUTF8StringEncoding];
        [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
        return;
    }
    else if (sender.selectedSegmentIndex == 0)
    {
        NSData *dataToSend = [@"O" dataUsingEncoding:NSUTF8StringEncoding];
        [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
        return;
    }
}

- (IBAction)slider:(UISlider *)sender
{
    self.sliderLabel.text = [NSString stringWithFormat:@"%f", sender.value];
}
#pragma mark - Call backs

- (void)didConnect
{
    self.connectionStateLabel.text = @"Connected";
    [self.spinner stopAnimating];
    self.lightControl.selectedSegmentIndex = 0;
    
    NSData *dataToSend = [@"O" dataUsingEncoding:NSUTF8StringEncoding];
    [[BCRCentralService sharedService] writeToPeripheral:dataToSend type:CBCharacteristicWriteWithoutResponse];
}

-(void)didDisconnect
{
    self.connectionStateLabel.text = @"Connecting...";
    [self.spinner startAnimating];
    [[BCRCentralService sharedService] BLEinit];    
}

- (void)discoveredPeripheral:(CBPeripheral *)peripheral didUpdateRSSI:(int)RSSI
{
    // TODO: Update RSSI
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // #warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // #warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.discoveredPeripherals count];
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeripheralCell" forIndexPath:indexPath];
 
     if (!cell)
     {
         cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:@"PeripheralCell"];
     }

     // extract the peripheral data
     CBPeripheral *peripheral = self.discoveredPeripherals[indexPath.row];
     
     cell.textLabel.text = peripheral.name;
     cell.detailTextLabel.text = [peripheral.RSSI stringValue];
 
     return cell;
 }


 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
     // Return NO if you do not want the specified item to be editable.
    return NO;
 }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)shouldUpdatePeripheralData:(NSArray *)discoveredPeripherals
{
    self.discoveredPeripherals = discoveredPeripherals;
    [self.tableView reloadData];
}


@end
