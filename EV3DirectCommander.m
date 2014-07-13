//
//  EV3DirectCommander.m
//  EV3Wifi
//
//  Created by FloodSurge on 5/9/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import "EV3DirectCommander.h"

@interface EV3DirectCommander ()
{
    int cursor;
    Byte buffer[1008];
    
}
@end

@implementation EV3DirectCommander
#pragma mark - Basic Methods

- (id)initWithCommandType:(EV3CommandType)commandType
               globalSize:(UInt16)globalSize
                localSize:(int)localSize
{
    self = [super init];
    if (self) {
        
        // Set BTstack delegate to receive packet
        //[BTstackManager sharedInstance].delegate = self;
        
        
        // Command size,this gets filled later
        buffer[0] = 0xff;
        buffer[1] = 0xff;
        
        // Message count set default 0x00
        buffer[2] = 0x00;
        buffer[3] = 0x00;
        
        // Command type
        buffer[4] = commandType;
        
        
        buffer[5] = globalSize & 0xff;
        buffer[6] = (Byte)((localSize << 2) | ((globalSize >> 8) & 0x03));
        cursor = 7;
        
    }
    return self;
}

- (void)addOperationCode:(EV3OperationCode)operationCode
{
    if (operationCode > EV3OperationTest) {
        buffer[cursor] = (operationCode & 0xff00)>> 8;
        cursor++;
    }
    buffer[cursor] = operationCode & 0xff;
    cursor++;
}

- (void)addParameterWithInt8:(Byte)parameter
{
    buffer[cursor] = EV3ParameterSizeByte;
    cursor++;
    buffer[cursor] = parameter;
    cursor++;
    
}

- (void)addParameterWithInt16:(UInt16)parameter
{
    buffer[cursor] = EV3ParameterSizeInt16;
    cursor++;
    buffer[cursor] = (Byte)parameter;
    cursor++;
    buffer[cursor] = (Byte)((parameter & 0xff00) >> 8);
    cursor++;
}

- (void)addParameterWithInt32:(UInt32)parameter
{
    buffer[cursor] = EV3ParameterSizeInt32;
    cursor++;
    buffer[cursor] = (Byte)parameter;
    cursor++;
    buffer[cursor] = (Byte)((parameter & 0xff00) >> 8);
    cursor++;
    buffer[cursor] = (Byte)((parameter & 0xff0000) >> 16);
    cursor++;
    buffer[cursor] = (Byte)((parameter & 0xff000000) >> 24);
    cursor++;

}

- (void)addParameterWithString:(NSString *)string
{
    buffer[cursor] = EV3ParameterSizeString;
    cursor++;
    
    NSData *byteData = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte * bytes = (Byte *)byteData.bytes;
    
    NSLog(@"Bytes: ");
    for (int i = 0; i < byteData.length; i++) {
        buffer[cursor] = bytes[i];
        cursor++;
        NSLog(@"%d ",bytes[i]);
    }
    
    buffer[cursor] = 0x00;
    cursor++;
    
    
    
    
    
}


- (void)addRawParameterWithInt8:(Byte)parameter
{
    buffer[cursor] = parameter;
    cursor++;
}

- (void)addGlobalIndex:(Byte)index
{
    buffer[cursor] = 0xe1;
    cursor++;
    buffer[cursor] = index;
    cursor++;
}

- (void)addCommandSize
{
    Byte commandSize = cursor - 2;
    //NSLog(@"command size:%d",commandSize);
    
    buffer[0] = commandSize & 0xff;
    buffer[1] = (commandSize & 0xff00) >> 8;
}

- (NSData *)assembledCommandData
{
    [self addCommandSize];
    
    return [NSData dataWithBytes:buffer length:cursor];
    
}

- (void)addCommandReadSensorTypeAndModeAtPort:(EV3InputPort)port globalIndex:(Byte)index
{
    [self addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [self addParameterWithInt8:0x00];
    [self addParameterWithInt8:port];
    [self addGlobalIndex:index];
    [self addGlobalIndex:index + 1];
}

- (void)addCommandReadSensorDataAtPort:(EV3InputPort)port mode:(Byte)mode
       globalIndex:(Byte)index
{
    [self addOperationCode:EV3OperationInputDeviceReadyRaw];
    [self addParameterWithInt8:0x00];
    [self addParameterWithInt8:port];
    [self addParameterWithInt8:0x00];
    [self addParameterWithInt8:mode];
    [self addParameterWithInt8:0x01];
    [self addGlobalIndex:index];
}


#pragma mark - Direct Command

#pragma mark - Motor Control Method

+ (NSData *)turnMotorAtPort:(EV3OutputPort)port power:(int)power
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationOutputPower];
    [command addParameterWithInt8:0];
    [command addParameterWithInt8:port];
    if (abs(power) > 100) {
        [command addParameterWithInt8:100];
    } else {
        [command addParameterWithInt8:(Byte)power];
    }
    
    [command addOperationCode:EV3OperationOutputStart];
    [command addParameterWithInt8:0];
    [command addParameterWithInt8:port];
    
    
    return [command assembledCommandData];
}

+ (NSData *)turnMotorAtPort:(EV3OutputPort)port power:(int)power degrees:(UInt32)degrees
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationOutputStepPower];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:port];
    [command addParameterWithInt8:(Byte)power];
    [command addParameterWithInt32:0x00];
    [command addParameterWithInt32:degrees];
    [command addParameterWithInt32:0x00];
    [command addParameterWithInt8:0x01];
    

    return [command assembledCommandData];
}

+ (NSData *)stopMotorAtPort:(EV3OutputPort)port
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationOutputStop];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:port];
    [command addParameterWithInt8:0x01];
    
    return [command assembledCommandData];
}

+ (NSData *)clearAllCommands
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationInputDeviceClearAll];
    [command addParameterWithInt8:0x00];

    
    return [command assembledCommandData];
}

#pragma mark - Sound Control Methods

+ (NSData *)playToneWithVolume:(int)volume frequency:(UInt16)frequency duration:(UInt16)duration
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationSoundTone];
    [command addParameterWithInt8:(Byte)volume];
    [command addParameterWithInt16:frequency];
    [command addParameterWithInt16:duration];
    
    
    return [command assembledCommandData];
}

+ (NSData *)playSoundWithVolume:(int)volume filename:(NSString *)filename repeat:(BOOL)repeat
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationSoundPlay];
    [command addParameterWithInt8:(Byte)volume];
    [command addParameterWithString:filename];
    
    if (repeat) {
        
        [command addOperationCode:EV3OperationSoundRepeat];
        [command addParameterWithInt8:(Byte)volume];
        [command addParameterWithString:filename];
    }
    
    return [command assembledCommandData];

}

+ (NSData *)soundBrake
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationSoundBreak];
    
    return [command assembledCommandData];
}

#pragma mark - Image Control Methods

+ (NSData *)drawImageWithColor:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y fileName:(NSString *)fileName
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationUIDrawClean];
    [command addOperationCode:EV3OperationUIDrawUpdate];

    [command addOperationCode:EV3OperationUIDrawBmpFile];
    [command addParameterWithInt8:color];
    [command addParameterWithInt16:x];
    [command addParameterWithInt16:y];
    [command addParameterWithString:fileName];

    [command addOperationCode:EV3OperationUIDrawUpdate];

    
    return [command assembledCommandData];

}

+ (NSData *)drawText:(NSString *)text color:(EV3ScreenColor)color x:(UInt16)x y:(UInt16)y
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    
    [command addOperationCode:EV3OperationUIDrawClean];
    [command addOperationCode:EV3OperationUIDrawUpdate];
    
    [command addOperationCode:EV3OperationUIDrawText];
    [command addParameterWithInt8:color];
    [command addParameterWithInt16:x];
    [command addParameterWithInt16:y];
    [command addParameterWithString:text];
    
    [command addOperationCode:EV3OperationUIDrawUpdate];

    
    return [command assembledCommandData];

}

+ (NSData *)updateUI
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationUIDrawUpdate];
    
    return [command assembledCommandData];
}

+ (NSData *)clearUI
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    [command addOperationCode:EV3OperationUIDrawClean];
    
    return [command assembledCommandData];

}

+ (NSData *)drawFillWindowWithColor:(EV3ScreenColor)color y0:(UInt16)y0 y1:(UInt16)y1
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectNoReply globalSize:0 localSize:0];
    
    [command addOperationCode:EV3OperationUIDrawClean];
    [command addOperationCode:EV3OperationUIDrawUpdate];
    
    [command addOperationCode:EV3OperationUIDrawFillWindow];
    [command addParameterWithInt8:color];
    [command addParameterWithInt16:y0];
    [command addParameterWithInt16:y1];
    
    [command addOperationCode:EV3OperationUIDrawUpdate];
    
    return [command assembledCommandData];
}

#pragma mark - Sensor Control Methods

+ (NSData *)scanPorts
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectReply globalSize:32 localSize:0];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPort1 globalIndex:0];
    [command addCommandReadSensorDataAtPort:EV3InputPort1 mode:0 globalIndex:2];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPort2 globalIndex:4];
    [command addCommandReadSensorDataAtPort:EV3InputPort2 mode:0 globalIndex:6];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPort3 globalIndex:8];
    [command addCommandReadSensorDataAtPort:EV3InputPort3 mode:0 globalIndex:10];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPort4 globalIndex:12];
    [command addCommandReadSensorDataAtPort:EV3InputPort4 mode:0 globalIndex:14];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPortA globalIndex:16];
    [command addCommandReadSensorDataAtPort:EV3InputPortA mode:0 globalIndex:18];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPortB globalIndex:20];
    [command addCommandReadSensorDataAtPort:EV3InputPortB mode:0 globalIndex:22];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPortC globalIndex:24];
    [command addCommandReadSensorDataAtPort:EV3InputPortC mode:0 globalIndex:26];
    
    [command addCommandReadSensorTypeAndModeAtPort:EV3InputPortD globalIndex:28];
    [command addCommandReadSensorDataAtPort:EV3InputPortD mode:0 globalIndex:30];
    
    
    
    return [command assembledCommandData];

}



+ (NSData *)scanSensorTypeAndMode
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectReply globalSize:16 localSize:0];
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortA];
    [command addGlobalIndex:0];
    [command addGlobalIndex:1];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortB];
    [command addGlobalIndex:2];
    [command addGlobalIndex:3];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortC];
    [command addGlobalIndex:4];
    [command addGlobalIndex:5];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortD];
    [command addGlobalIndex:6];
    [command addGlobalIndex:7];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort1];
    [command addGlobalIndex:8];
    [command addGlobalIndex:9];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort2];
    [command addGlobalIndex:10];
    [command addGlobalIndex:11];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort3];
    [command addGlobalIndex:12];
    [command addGlobalIndex:13];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort4];
    [command addGlobalIndex:14];
    [command addGlobalIndex:15];
    
    return [command assembledCommandData];

    
}

+ (NSData *)scanSensorData
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectReply globalSize:16 localSize:0];
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortA];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:0];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortB];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:2];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortC];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:4];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPortD];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:6];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort1];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:8];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort2];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:10];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort3];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:12];
    
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:EV3InputPort4];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:0x01];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:14];
    
    return [command assembledCommandData];

}



+ (NSData *)readSensorTypeAndModeAtPort:(EV3InputPort)port
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectReply globalSize:2 localSize:0];
    
    [command addOperationCode:EV3OperationInputDeviceGetTypeMode];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:port];
    [command addGlobalIndex:0];
    [command addGlobalIndex:1];
    
    return [command assembledCommandData];

}

+ (NSData *)readSensorDataAtPort:(EV3InputPort)port mode:(int)mode
{
    EV3DirectCommander *command = [[EV3DirectCommander alloc] initWithCommandType:EV3CommandTypeDirectReply globalSize:2 localSize:0];
    [command addOperationCode:EV3OperationInputDeviceReadyRaw];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:port];
    [command addParameterWithInt8:0x00];
    [command addParameterWithInt8:(Byte)mode];
    [command addParameterWithInt8:0x01];
    [command addGlobalIndex:0];
    
    return [command assembledCommandData];
}

@end
