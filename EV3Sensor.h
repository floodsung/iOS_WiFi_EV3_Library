//
//  EV3Sensor.h
//  Ev3WifiFit
//
//  Created by FloodSurge on 6/1/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EV3CommandDefinitions.h"

@interface EV3Sensor : NSObject

@property (nonatomic,assign) EV3SensorType type;
@property (nonatomic,strong) NSString *typeString;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,assign) int mode;
@property (nonatomic,assign) short data;

- (void)refreshTypeStringWithType:(EV3SensorType)type;

@end
