//
//  EV3Device.m
//  EV3WifiController
//
//  Created by FloodSurge on 5/13/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import "EV3Device.h"
#import "GCDAsyncSocket.h"
#import "EV3MessageType.h"
#import "EV3DirectCommander.h"

NSString *const EV3DeviceConnectedNotification = @"EV3DeviceConnectedNotification";

@interface EV3Device ()
@property (nonatomic,strong,readwrite) NSString *serialNumber;
@property (nonatomic,strong,readwrite) NSString *address;
@property (nonatomic,readwrite) NSUInteger tag;
@property (nonatomic,assign) BOOL isScan;

@end

@implementation EV3Device


- (id)initWithSerialNumber:(NSString *)serialNumber address:(NSString *)address tag:(NSUInteger)tag isConnected:(BOOL)isConnected
{
    self = [super init];
    if (self) {
        self.serialNumber = serialNumber;
        self.address = address;
        self.tag = tag;
        self.isConnected = isConnected;
        self.sensorPort1 = [[EV3Sensor alloc] init];
        self.sensorPort2 = [[EV3Sensor alloc] init];
        self.sensorPort3 = [[EV3Sensor alloc] init];
        self.sensorPort4 = [[EV3Sensor alloc] init];
        self.sensorPortA = [[EV3Sensor alloc] init];
        self.sensorPortB = [[EV3Sensor alloc] init];
        self.sensorPortC = [[EV3Sensor alloc] init];
        self.sensorPortD = [[EV3Sensor alloc] init];
        self.isScan = FALSE;
    }
    return self;
}

- (void)handleReceivedData:(NSData *)data withTag:(long)tag
{
    NSLog(@"receive data!");
    
    switch (tag) {
        case MESSAGE_UNLOCK:
        {
            NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *response =[httpResponse substringToIndex:12];
            if ([response isEqualToString:@"Accept:EV340"]) {
                self.isConnected = YES;
                NSLog(@"ev3 connected");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scanPorts];
                    [[NSNotificationCenter defaultCenter] postNotificationName:EV3DeviceConnectedNotification object:self];
                });
            }
                break;
        }
            
        case MESSAGE_SCAN_PORTS:
        {
            if (self.isScan) {
                [self updatePorts];
            }
            Byte * bytes = (Byte *)data.bytes;
            
            int index = 5;
            
            self.sensorPort1.type = bytes[index++];
            self.sensorPort1.mode = bytes[index++];
            self.sensorPort1.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPort2.type = bytes[index++];
            self.sensorPort2.mode = bytes[index++];
            self.sensorPort2.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPort3.type = bytes[index++];
            self.sensorPort3.mode = bytes[index++];
            self.sensorPort3.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPort4.type = bytes[index++];
            self.sensorPort4.mode = bytes[index++];
            self.sensorPort4.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPortA.type = bytes[index++];
            self.sensorPortA.mode = bytes[index++];
            self.sensorPortA.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPortB.type = bytes[index++];
            self.sensorPortB.mode = bytes[index++];
            self.sensorPortB.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPortC.type = bytes[index++];
            self.sensorPortC.mode = bytes[index++];
            self.sensorPortC.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
            self.sensorPortD.type = bytes[index++];
            self.sensorPortD.mode = bytes[index++];
            self.sensorPortD.data = (short)(bytes[index++] | (bytes[index++] << 8));
            
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
            
            self.sensorPortA.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPortB.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPortC.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPortD.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPort1.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPort2.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPort3.data = (short)(bytes[5] | (bytes[6] << 8));
            self.sensorPort4.data = (short)(bytes[5] | (bytes[6] << 8));
            
            
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

#pragma mark - EV3 Direct Commands

- (void)clearCommands
{
    NSData *data = [EV3DirectCommander clearAllCommands];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_CLEAR];
}

- (void)scanPorts
{
    NSLog(@"scan!");
    self.isScan = YES;
    [self clearCommands];
    [self updatePorts];
}

- (void)stopScan
{
    NSLog(@"stop scan!");
    self.isScan = FALSE;
    [self clearCommands];
}

- (void)updatePorts
{
    //NSLog(@"send command");
    NSData *data = [EV3DirectCommander scanPorts];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_SCAN_PORTS];
    [self.tcpSocket readDataWithTimeout:-1 tag:MESSAGE_SCAN_PORTS];
}

#pragma mark - Motor Control Methods

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power
{
    NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power time:(NSTimeInterval)time
{
    NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    [NSThread sleepForTimeInterval:time];
    data = [EV3DirectCommander turnMotorAtPort:port power:0];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees
{

    NSData *data = [EV3DirectCommander turnMotorAtPort:port power:power degrees:degrees];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
    
}

- (void)stopMotorAtPort:(EV3OutputPort)port
{
    NSData *data = [EV3DirectCommander stopMotorAtPort:port];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];

}

#pragma mark - Sound Control Methods

- (void)playToneAtVolume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration
{
    NSData *data = [EV3DirectCommander playToneWithVolume:volume frequency:frequency duration:duration];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

- (void)playSoundAtVolume:(int)volume filename:(NSString *)filename repeat:(BOOL)repeat
{
    NSData *data = [EV3DirectCommander playSoundWithVolume:volume filename:filename repeat:repeat];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

- (void)playSoundBrake
{

    NSData *data = [EV3DirectCommander soundBrake];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

#pragma mark - Image Control Methods

- (void)drawImageAtColor:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y filename:(NSString *)filename
{

    NSData *data = [EV3DirectCommander drawImageWithColor:color x:x y:y fileName:filename];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}

- (void)drawText:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y
{
    NSData *data = [EV3DirectCommander drawText:text color:color x:x y:y];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];

}

- (void)drawFillWindowAtColor:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1
{
    NSData *data = [EV3DirectCommander drawFillWindowWithColor:color y0:y0 y1:y1];
    [self.tcpSocket writeData:data withTimeout:-1 tag:MESSAGE_NO_REPLY];
}


@end
