//
//  EV3WifiManager.m
//  Ev3WifiFit
//
//  Created by FloodSurge on 5/17/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import "EV3WifiManager.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"

#import "EV3DirectCommander.h"

#define UDP_PORT 3015



@interface EV3WifiManager ()
@property (nonatomic,strong,readwrite) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic,strong,readwrite) NSMutableDictionary *devices;
@property (nonatomic,strong) NSTimer *timer;
@end

@implementation EV3WifiManager

+ (EV3WifiManager *)sharedInstance
{
    static EV3WifiManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EV3WifiManager alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        // set up UDP socket
        
        dispatch_queue_t udpSocketQueue = dispatch_queue_create("com.manmanlai.updSocketQueue", DISPATCH_QUEUE_CONCURRENT);
        
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:udpSocketQueue];
        
        
        
        // init devices
        
        self.devices = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

#pragma mark - GCDAsyncUdpSocket

- (void)startUdpSocket
{
    NSError *error = nil;
    
    if (![self.udpSocket bindToPort:UDP_PORT error:&error])
    {
        NSLog(@"Error starting server (bind): %@", error);
        return;
    }
    if (![self.udpSocket beginReceiving:&error])
    {
        [self.udpSocket close];
        
        NSLog(@"Error starting server (recv): %@", error);
        return;
    }
    
    NSLog(@"Udp Echo server started on port %hu", [self.udpSocket localPort]);
}

- (void)stopUdpSocket
{
    [self.udpSocket close];
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
        NSString *serialNumber = [msg substringWithRange:NSMakeRange(14, 12)];
        
        NSString *host = [GCDAsyncUdpSocket hostFromAddress:address];
        
        EV3Device *device = [self.devices objectForKey:host];
        
        
        
        if (!device && host.length < 20) {
            
            EV3Device *aDevice = [[EV3Device alloc] initWithSerialNumber:serialNumber address:host tag:self.devices.count isConnected:NO];
            
            
            
            // set up TCP/IP socket
            dispatch_queue_t tcpSocketQueue = dispatch_queue_create("com.manmanlai.tcpSocketQueue", DISPATCH_QUEUE_CONCURRENT);
            GCDAsyncSocket *tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:tcpSocketQueue];
            
            aDevice.tcpSocket = tcpSocket;
            
            
            [self.devices setObject:aDevice forKey:aDevice.address];
            
            
            
            if ([self.delegate respondsToSelector:@selector(updateView)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate updateView];
                });
            }
        }
        
	}
	else
	{
        NSLog(@"Error converting received data into UTF-8 String");
	}
	
	[self.udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
}

#pragma mark - GCDAsyncSocket

- (void)connectTCPSocketWithDevice:(EV3Device *)device
{
    
    GCDAsyncSocket *tcpSocket = device.tcpSocket;
    // connnect
    NSError *error = nil;
    if (![tcpSocket connectToHost:device.address
                                onPort:5555
                                 error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        
    } else {
        NSLog(@"Connected");
        // write data
        NSLog(@"writing...");
        NSString *unlockMsg = [NSString stringWithFormat:@"GET /target?sn=%@ VMTP1.0 Protocol: EV3",device.serialNumber];
        NSData *unlockData = [unlockMsg dataUsingEncoding:NSUTF8StringEncoding];
        [tcpSocket writeData:unlockData withTimeout:-1 tag:MESSAGE_UNLOCK];
        
        //[self.tcpSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
        
        [tcpSocket readDataWithTimeout:-1 tag:MESSAGE_UNLOCK];
        
    }
    
    
}

- (void)disconnectTCPSocketWithDevice:(EV3Device *)device
{
    //[device.tcpSocket disconnect];
    [device stopScan];
    [device.tcpSocket disconnect];
    [self.devices removeObjectForKey:device.address];
    if ([self.delegate respondsToSelector:@selector(updateView)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate updateView];
        });
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    
    /*
     [sock performBlock:^{
     if ([sock enableBackgroundingOnSocket])
     NSLog(@"Enabled backgrounding on socket");
     else
     NSLog(@"Enabling backgrounding failed!");
     }];
     */
    
    
    // Configure SSL/TLS settings
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // If you simply want to ensure that the remote host's certificate is valid,
    // then you can use an empty dictionary.
    
    // If you know the name of the remote host, then you should specify the name here.
    //
    // NOTE:
    // You should understand the security implications if you do not specify the peer name.
    // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
    
    [settings setObject:@"Lego EV3"
                 forKey:(NSString *)kCFStreamSSLPeerName];
    
    // To connect to a test server, with a self-signed certificate, use settings similar to this:
    
    //	// Allow expired certificates
    //	[settings setObject:[NSNumber numberWithBool:YES]
    //				 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
    //
    //	// Allow self-signed certificates
    //	[settings setObject:[NSNumber numberWithBool:YES]
    //				 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    //
    //	// In fact, don't even validate the certificate chain
    //	[settings setObject:[NSNumber numberWithBool:NO]
    //				 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    //NSLog(@"Starting TLS with settings:\n%@", settings);
    
    //[sock startTLS:settings];
    
    // You can also pass nil to the startTLS method, which is the same as passing an empty dictionary.
    // Again, you should understand the security implications of doing so.
    // Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
    

	
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	//NSLog(@"socket:%p connectedAddress:%@ didReadData:withTag:%ld", sock,sock.connectedHost,tag);
	
	//NSLog(@"Received Data:\n%@", data);
    
    NSString *host = sock.connectedHost;
    EV3Device *device = [self.devices objectForKey:host];
    
    //[self.ev3WifiDataSource handleReceivedData:data withTag:tag fromDevice:device];
    [device handleReceivedData:data withTag:tag];
	
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"socketDidDisconnect:%p hash:%@ withError: %@", sock,[NSString stringWithFormat:@"%lul",(unsigned long)sock.hash], err);
    //[self.tcpSockets removeObjectForKey:sock.localHost];
    //[self.devices removeObjectForKey:sock.connectedHost];
    
    EV3Device *device = nil;
    for (EV3Device *aDevice in [self.devices allValues]) {
        if (aDevice.tcpSocket == sock) device = aDevice;
    }
    if (device) {
        device.isConnected = NO;
        [self.devices removeObjectForKey:device.address];
        if ([self.delegate respondsToSelector:@selector(updateView)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate updateView];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Caution!" message:@"EV3 is disconnected!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });

    }
}

/*
- (void)handleReceivedData:(NSData *)data withTag:(long)tag fromDevice:(EV3Device *)device
{
    NSLog(@"data is %@",data);
    
    switch (tag) {
        case MESSAGE_UNLOCK:
        {
            NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *response =[httpResponse substringToIndex:12];
            if ([response isEqualToString:@"Accept:EV340"]) {
                //device.isConnected = YES;
                if ([self.delegate respondsToSelector:@selector(ev3WifiConnectedWithDevice:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate ev3WifiConnectedWithDevice:device];
                        
                    });
                }
            }
            
            break;
        }
            
        case MESSAGE_SCAN_SENSOR_TYPE_AND_MODE:
        {
            Byte * bytes = (Byte *)data.bytes;
        
             for (int i = 0; i < data.length; i++) {
             NSLog(@"%d ",bytes[i]);
             }
 
            
            self.sensorPortA.type = bytes[5];
            self.sensorPortA.mode = bytes[6];
            self.sensorPortB.type = bytes[7];
            self.sensorPortB.mode = bytes[8];
            self.sensorPortC.type = bytes[9];
            self.sensorPortC.mode = bytes[10];
            self.sensorPortD.type = bytes[11];
            self.sensorPortD.mode = bytes[12];
            self.sensorPort1.type = bytes[13];
            self.sensorPort1.mode = bytes[14];
            self.sensorPort2.type = bytes[15];
            self.sensorPort2.mode = bytes[16];
            self.sensorPort3.type = bytes[17];
            self.sensorPort3.mode = bytes[18];
            self.sensorPort4.type = bytes[19];
            self.sensorPort4.mode = bytes[20];
            
            break;
        }
            
        case MESSAGE_SCAN_SENSOR_DATA:
        {
            Byte * bytes = (Byte *)data.bytes;
            
            
            ;
            [self.sensorPortA.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[5] | (bytes[6] << 8))]];
            [self.sensorPortB.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[7] | (bytes[8] << 8))]];
            [self.sensorPortC.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[9] | (bytes[10] << 8))]];
            [self.sensorPortD.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[11] | (bytes[12] << 8))]];
            [self.sensorPort1.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[13] | (bytes[14] << 8))]];
            [self.sensorPort2.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[15] | (bytes[16] << 8))]];
            [self.sensorPort3.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[17] | (bytes[18] << 8))]];
            [self.sensorPort4.dataArray addObject:[NSNumber numberWithShort:(short)(bytes[19] | (bytes[20] << 8))]];
            
            
            break;
        }
            
        case MESSAGE_GET_SENSOR_TYPE_AND_MODE:
        {
            
            break;
        }
            
        case MESSAGE_READ_DATA:
        {
            break;
        }
            
            
            
            
            
        default:
            break;
    }
    

}

*/

/*
#pragma mark - ev3 direct command methods

#pragma mark - Sensor Control Methods

- (void)scanEv3PortOfDevice:(EV3Device *)device
{
    if (device) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateSensorData) userInfo:device repeats:YES];
    }

    //[self scanSensorTypeAndModeOfDevice:device];
    
    //[self scanSensorDataOfDevice:device inTimeInterval:0.01];
}

- (void)stopScanPortOfDevice:(


- (void)scanSensorTypeAndModeOfDevice:(EV3Device *)device
{
    if (device) {
        NSData *data = [EV3DirectCommander scanSensorTypeAndMode];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_SCAN_SENSOR_TYPE_AND_MODE];
        [device.tcpSocket readDataWithTimeout:-1 tag:MESSAGE_SCAN_SENSOR_TYPE_AND_MODE];
    }
    
    
}

- (void)scanSensorDataOfDevice:(EV3Device *)device  inTimeInterval:(NSTimeInterval)timeInterval
{
    if (device) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(updateSensorData) userInfo:device repeats:YES];
    }
}


- (void)updateSensorData
{
    EV3Device *device = (EV3Device *)self.timer.userInfo;
    NSData *data = [EV3DirectCommander scanSensorData];
    
    [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_SCAN_SENSOR_DATA];
    [device.tcpSocket readDataWithTimeout:-1 tag:MESSAGE_SCAN_SENSOR_DATA];
}

- (void)readSensorTypeAndModeOfDevice:(EV3Device *)device inPort:(EV3InputPort)port
{
    if (device) {
        NSData *data = [EV3DirectCommander readSensorTypeAndModeAtPort:port];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_GET_SENSOR_TYPE_AND_MODE];
        [device.tcpSocket readDataWithTimeout:-1 tag:MESSAGE_GET_SENSOR_TYPE_AND_MODE];

    }
}

- (void)readSensorDataOfDevice:(EV3Device *)device Port:(EV3InputPort)port mode:(int)mode
{
    if (device) {
        NSData *data = [EV3DirectCommander readSensorDataAtPort:port mode:mode];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_READ_DATA];
        [device.tcpSocket readDataWithTimeout:-1 tag:MESSAGE_READ_DATA];
        
    }
}


#pragma mark - Motor Control Methods

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power
{
    if (device) {
        NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power time:(NSTimeInterval)time
{
    if (device) {
        NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
        [NSThread sleepForTimeInterval:time];
        data = [EV3DirectCommander turnMotorAtPort:port power:0];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees
{
    if (device) {
        NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power degrees:degrees];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)stopMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port
{
    if (device) {
        NSData *data = [EV3DirectCommander stopMotorAtPort:port];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

#pragma mark - Sound Control Methods

- (void)playToneOfDevice:(EV3Device *)device volume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration
{
    if (device) {
        NSData *data = [EV3DirectCommander playToneWithVolume:volume frequency:frequency duration:duration];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)playSoundOfDevice:(EV3Device *)device volume:(int)volume filename:(NSString *)filename repeat:(BOOL)repeat
{
    if (device) {
        NSData *data = [EV3DirectCommander playSoundWithVolume:volume filename:filename repeat:repeat];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)soundBrakeOfDevice:(EV3Device *)device
{
    if (device) {
        NSData *data = [EV3DirectCommander soundBrake];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

#pragma mark - Image Control Methods

- (void)drawImageOfDevice:(EV3Device *)device color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y filename:(NSString *)filename
{
    if (device) {
        NSData *data = [EV3DirectCommander drawImageWithColor:color x:x y:y fileName:filename];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)drawTextOfDevice:(EV3Device *)device text:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y
{
    if (device) {
        NSData *data = [EV3DirectCommander drawText:text color:color x:x y:y];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

- (void)drawFillWindowOfDevice:(EV3Device *)device color:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1
{
    if (device) {
        NSData *data = [EV3DirectCommander drawFillWindowWithColor:color y0:y0 y1:y1];
        [device.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    }
}

*/


@end
