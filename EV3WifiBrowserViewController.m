//
//  WifiBrowserViewController.m
//  EV3WifiController
//
//  Created by FloodSurge on 5/10/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import "EV3WifiBrowserViewController.h"
#import "EV3WifiManager.h"

@interface EV3WifiBrowserViewController ()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,EV3WifiManagerDelegate>
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIBarButtonItem *doneButton;
@property (nonatomic,strong) EV3WifiManager *ev3WifiManager;
 
@end

@implementation EV3WifiBrowserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self viewConfiguration];
    
    
    // init ev3WifiManager
    self.ev3WifiManager = [EV3WifiManager sharedInstance];
    self.ev3WifiManager.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ev3DeviceConnected:) name:EV3DeviceConnectedNotification object:nil];
    
    [self.ev3WifiManager startUdpSocket];
    

}

- (void)viewConfiguration
{
    // basic configuration
    self.view.backgroundColor = [UIColor whiteColor];
    
    // add table view
    CGRect viewFrame = self.view.frame;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, viewFrame.size.width, viewFrame.size.height - 64) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    // add navigation bar
    
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, 64)];
    [self.view addSubview:navigationBar];
    
    // add bar button items
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    // initially set done button disabled
    self.doneButton.enabled = NO;
    
    UINavigationItem *item = [[UINavigationItem alloc] init];
    item.leftBarButtonItem = cancelButton;
    item.rightBarButtonItem = self.doneButton;
    [navigationBar pushNavigationItem:item animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


- (void)cancel:(UIBarButtonItem *)item
{
    [self dismissViewControllerAnimated:YES completion:nil];
    // STOP udp echo server
    
    //[self.udpSocket close];
    [self.ev3WifiManager stopUdpSocket];
    
    NSLog(@"Stopped Udp Echo server");
}

- (void)done:(UIBarButtonItem *)item
{
    [self dismissViewControllerAnimated:YES completion:nil];
    // STOP udp echo server
    
    //[self.udpSocket close];
    [self.ev3WifiManager stopUdpSocket];

    
    NSLog(@"Stopped Udp Echo server");
}

#pragma mark - Table View Delegate

- (void)update
{
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"EV3 Lists:";

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [self.ev3WifiManager.devices count];
    return count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }


    if (indexPath.row < [self.ev3WifiManager.devices count]) {
        EV3Device *device = [[self.ev3WifiManager.devices allValues] objectAtIndex:indexPath.row];
        cell.textLabel.text = device.address;
        
        cell.accessoryView = nil;
        if (device.isConnected) cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.textLabel.text = @"Searching...";
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.hidesWhenStopped = YES;
        cell.accessoryView = indicator;
        [indicator startAnimating];
        
        
    }
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // select unconnected devices
    if (self.ev3WifiManager.devices.count) {
        EV3Device *device = [[self.ev3WifiManager.devices allValues] objectAtIndex:indexPath.row];
        NSLog(@"device ip:%@",device.address);
        [self update];
        
        if (!device.isConnected) {
            // connect device
            [self.ev3WifiManager connectTCPSocketWithDevice:device];
        } else {
            // ask to disconnect
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Do you want to disconnect?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            alertView.tag = device.tag;
            [alertView show];
            
        }
        
    }
    [self update];
    
    
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        EV3Device *device = nil;
        for (EV3Device *aDevice in [self.ev3WifiManager.devices allValues]) {
            if (aDevice.tag == alertView.tag) device = aDevice;
        }
        [self.ev3WifiManager disconnectTCPSocketWithDevice:device];
    }
}

#pragma mark - ev3 wifi manager delegate

- (void)updateView
{
    [self update];
}

#pragma mark - ev3 device connected notification

- (void)ev3DeviceConnected:(NSNotification *)notification
{
    //NSLog(@"ev3 connected tag:%lu",(unsigned long)device.tag);
    EV3Device *device = (EV3Device *)notification.object;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:device.tag inSection:0]];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self update];
    self.doneButton.enabled = YES;
}


@end
