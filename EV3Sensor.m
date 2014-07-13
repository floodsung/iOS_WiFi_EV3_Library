//
//  EV3Sensor.m
//  Ev3WifiFit
//
//  Created by FloodSurge on 6/1/14.
//  Copyright (c) 2014 FloodSurge. All rights reserved.
//

#import "EV3Sensor.h"

@implementation EV3Sensor

@synthesize type = _type;

- (id)init
{
    self = [super init];
    if (self) {
        
        self.type = EV3SensorTypeUnknown;
        self.typeString = @"Unknown";
        self.mode = 0;
        self.data = 0;
    }
    return self;
}

- (void)setType:(EV3SensorType)type
{
    if (_type != type) {
        _type = type;
        [self refreshTypeStringWithType:type];
    }
}


- (void)refreshTypeStringWithType:(EV3SensorType)type
{
    switch (type) {
        case EV3SensorTypeEmpty:
            self.typeString = @"Empty";
            self.image = [UIImage imageNamed:@"Empty"];
            break;
        case EV3SensorTypeWrongPort:
            self.typeString = @"WrongPort";
            break;
        case EV3SensorTypeUltrasonicSensor:
            self.typeString = @"Ultrasonic Sensor";
            self.image = [UIImage imageNamed:@"UltrasonicSensor"];

            break;
        case EV3SensorTypeUnknown:
            self.typeString = @"Unknown";
            self.image = [UIImage imageNamed:@"Unknown"];

            break;
        case EV3SensorTypeColorSensor:
            self.typeString = @"Color Sensor";
            self.image = [UIImage imageNamed:@"ColorSensor"];

            break;
        case EV3SensorTypeGyroscopeSensor:
            self.typeString = @"Gyroscope Sensor";
            self.image = [UIImage imageNamed:@"GyroSensor"];

            break;
        case EV3SensorTypeInfraredSensor:
            self.typeString = @"Infrared Sensor";
            self.image = [UIImage imageNamed:@"InfraredSensor"];

            break;
        case EV3SensorTypeInitializing:
            self.typeString = @"Init";
            self.image = [UIImage imageNamed:@"Init"];

            break;
        case EV3SensorTypeLargeMotor:
            self.typeString = @"Large Motor";
            self.image = [UIImage imageNamed:@"LargeMotor"];

            break;
        case EV3SensorTypeMediumMotor:
            self.typeString = @"Medium Motor";
            self.image = [UIImage imageNamed:@"MediumMotor"];

            break;
        case EV3SensorTypeTouchSensor:
            self.typeString = @"Touch Sensor";
            self.image = [UIImage imageNamed:@"TouchSensor"];

            break;
            
        default:
            break;
    }
}

@end
