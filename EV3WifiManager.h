//
//  EV3WifiManager.h
//  Ev3WifiFit
//
//  Created by FloodSurge on 5/17/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//
//  Descriptions: This class is used to control the connection between iOS and ev3 using wifi. After connected,you can use API to send direct command to every ev3!
//  描述：这个类用来控制ios和ev3的wifi连接。连接之后，可以使用类中的API来向每个ev3发送direct command（直接命令）

#import <Foundation/Foundation.h>
#import "EV3CommandDefinitions.h"
#import "EV3MessageType.h"
#import "EV3Device.h"

@class GCDAsyncSocket;
@class GCDAsyncUdpSocket;

@protocol EV3WifiManagerDelegate <NSObject>

@optional
- (void)updateView;


@end

@interface EV3WifiManager : NSObject
@property (nonatomic,strong,readonly) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic,strong,readonly) NSMutableDictionary *devices;
@property (nonatomic,weak) id<EV3WifiManagerDelegate> delegate;

// Create or get the only ev3WifiManager instance to operate!
// 创建或者获取EV3WifiManager的唯一实例来进行操作
+ (EV3WifiManager *)sharedInstance;

#pragma mark - Search and Connection Methods

// Start udp socket searching to find every wifi-on ev3 nearby
// 启动UDP socket来搜索每一个连接到同一wifi下的ev3
- (void)startUdpSocket;

// Stop udp socket
// 停止UDP socket
- (void)stopUdpSocket;

// Connect or disconnect ev3 to ios. After connected,you can send direct command!
// 连接或者断开ev3到iOS。连接之后，就可以发送直接命令了。
- (void)connectTCPSocketWithDevice:(EV3Device *)device;
- (void)disconnectTCPSocketWithDevice:(EV3Device *)device;


/*
#pragma mark - Direct Command Methods


#pragma mark - Sensor Control Methods

// Scan 8 port of ev3 brick, scan every sensor connected and read the sensor data at a preset time interval.
- (void)scanEv3PortOfDevice:(EV3Device *)device;

// 读取每个端口连接的传感器的类型和工作模式
- (void)readSensorTypeAndModeOfDevice:(EV3Device *)device inPort:(EV3InputPort)port;

- (void)readSensorDataOfDevice:(EV3Device *)device Port:(EV3InputPort)port mode:(int)mode;


#pragma mark - Motor Control Methods

// turn motor power at specified port and power

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power;

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power time:(NSTimeInterval)time;

- (void)turnMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees;

- (void)stopMotorOfDevice:(EV3Device *)device port:(EV3OutputPort)port;

#pragma mark -  Sound Control Methods

- (void)playToneOfDevice:(EV3Device *)device volume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration;

- (void)playSoundOfDevice:(EV3Device *)device volume:(int)volume filename:(NSString *)filename repeat:(BOOL)repeat;

- (void)soundBrakeOfDevice:(EV3Device *)device;

#pragma mark - Image Control Methods

- (void)drawImageOfDevice:(EV3Device *)device color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y filename:(NSString *)filename;

- (void)drawTextOfDevice:(EV3Device *)device text:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y;

- (void)drawFillWindowOfDevice:(EV3Device *)device color:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1;

*/

@end


