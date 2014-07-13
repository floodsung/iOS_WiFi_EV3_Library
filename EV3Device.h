//
//  EV3Device.h
//  EV3WifiFit
//
//  Created by FloodSurge on 5/13/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//
//  Descriptions: this class is used to store ev3 device informations.

#import <Foundation/Foundation.h>
#import "EV3Sensor.h"

@class GCDAsyncSocket;

UIKIT_EXTERN NSString *const EV3DeviceConnectedNotification;

@interface EV3Device : NSObject

@property (nonatomic,strong) GCDAsyncSocket *tcpSocket;

@property (nonatomic,strong,readonly) NSString *serialNumber;
@property (nonatomic,strong,readonly) NSString *address;
@property (nonatomic,readonly) NSUInteger tag;
@property (nonatomic,assign) BOOL isConnected;

@property (nonatomic,strong) EV3Sensor *sensorPortA;
@property (nonatomic,strong) EV3Sensor *sensorPortB;
@property (nonatomic,strong) EV3Sensor *sensorPortC;
@property (nonatomic,strong) EV3Sensor *sensorPortD;
@property (nonatomic,strong) EV3Sensor *sensorPort1;
@property (nonatomic,strong) EV3Sensor *sensorPort2;
@property (nonatomic,strong) EV3Sensor *sensorPort3;
@property (nonatomic,strong) EV3Sensor *sensorPort4;


- (id)initWithSerialNumber:(NSString *)serialNumber address:(NSString *)address tag:(NSUInteger)tag isConnected:(BOOL)isConnected;

- (void)handleReceivedData:(NSData *)data withTag:(long)tag;

#pragma mark - EV3 Direct Command

// Scan or stop scan each port sensor condition and data on the ev3 brick

- (void)scanPorts;

- (void)stopScan;

- (void)clearCommands;

#pragma mark - Motor Control Methods

// turn motor power at specified port and power

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power;

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power time:(NSTimeInterval)time;

- (void)turnMotorAtPort:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees;

- (void)stopMotorAtPort:(EV3OutputPort)port;

#pragma mark -  Sound Control Methods

- (void)playToneAtVolume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration;

- (void)playSoundAtVolume:(int)volume filename:(NSString *)filename repeat:(BOOL)repeat;

- (void)playSoundBrake;

#pragma mark - Image Control Methods

- (void)drawImageAtColor:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y filename:(NSString *)filename;

- (void)drawText:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y;

- (void)drawFillWindowAtColor:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1;



@end

