//
//  RDLocationManager.h
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreLocation/CLLocationManagerDelegate.h"

@interface RDLocationManager : NSObject <CLLocationManagerDelegate>

+ (id)shareManager;

- (void)updateLocation;
- (BOOL)updateLocationWithSuccess:(void (^)(float,float))success
                          failure:(void (^)())failure;

@property (assign, nonatomic) float lat;
@property (assign, nonatomic) float lot;
@property (assign, nonatomic) BOOL isFinishGetLocation;

@end
