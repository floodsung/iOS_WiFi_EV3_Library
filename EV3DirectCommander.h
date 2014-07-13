//
//  EV3DirectCommander.h
//  EV3Wifi
//
//  Created by FloodSurge on 5/9/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EV3CommandDefinitions.h"
@interface EV3DirectCommander : NSObject

#pragma mark - Motor Control Methods

+ (NSData *)turnMotorAtPort:(EV3OutputPort)port power:(int)power;

+ (NSData *)turnMotorAtPort:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees;

+ (NSData *)stopMotorAtPort:(EV3OutputPort)port;

#pragma mark - General Control Methods

+ (NSData *)clearAllCommands;

#pragma mark - Sound Control Methods

+ (NSData *)playToneWithVolume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration;

+ (NSData *)playSoundWithVolume:(int)volume filename:(NSString *)fileName repeat:(BOOL)repeat;

+ (NSData *)soundBrake;

#pragma mark - Image Control Methods

+ (NSData *)drawImageWithColor:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y fileName:(NSString *)fileName;

+ (NSData *)drawText:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y;

+ (NSData *)drawFillWindowWithColor:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1;

#pragma mark - Sensor Control Methods

+ (NSData *)scanPorts;

+ (NSData *)scanSensorTypeAndMode;

+ (NSData *)scanSensorData;

+ (NSData *)readSensorTypeAndModeAtPort:(EV3InputPort)port;

+ (NSData *)readSensorDataAtPort:(EV3InputPort)port mode:(int)mode;


@end
