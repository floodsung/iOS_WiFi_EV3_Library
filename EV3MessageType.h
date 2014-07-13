//
//  EV3MessageType.h
//  Ev3WifiFit
//
//  Created by FloodSurge on 5/19/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//
//  Description: this head file is to define the message type to send to ev3 from ios

//  描述：本头文件用来定义各种从ios向ev3发送的信息的类型

#ifndef Ev3WifiFit_EV3MessageType_h
#define Ev3WifiFit_EV3MessageType_h

#define MESSAGE_UNLOCK 1  // 发送ev3解锁信息
#define MESSAGE_NO_REPLY 11
#define MESSAGE_GET_SENSOR_TYPE_AND_MODE 12
#define MESSAGE_READ_DATA 13
#define MESSAGE_SCAN_PORTS 14
#define MESSAGE_SCAN_SENSOR_TYPE_AND_MODE 15
#define MESSAGE_SCAN_SENSOR_DATA 16
#define MESSAGE_CLEAR 17


#define MESSAGE_UNDEFINE 0

#endif
