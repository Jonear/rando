//
//  RDLocationManager.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDLocationManager.h"

@implementation RDLocationManager
{
    CLLocationManager *_manager;
    CLLocationCoordinate2D _coordinate;
    
    void (^_success)(float,float);
    void (^_failure)();
}

+ (id)shareManager
{
    static id instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        _lat = 0.;
        _lot = 0.;
        if([CLLocationManager locationServicesEnabled]){
            //定位功能开启的情况下进行定位
            _manager = [[CLLocationManager alloc] init];
            _manager.distanceFilter = kCLDistanceFilterNone;
            _manager.desiredAccuracy = kCLLocationAccuracyBest;
            _manager.delegate = self;
            _isFinishGetLocation = NO;
            [_manager startUpdatingLocation];
        }
    }
    return self;
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
    if (!_isFinishGetLocation) {
        
        //获得当前位置
        _coordinate = newLocation.coordinate;
        _lat = _coordinate.latitude;
        _lot = _coordinate.longitude;
        
        //已经成功获得位置
        _isFinishGetLocation = YES;
        [manager stopUpdatingLocation];
        
        if (_success) {
            _success(_lat,_lot);
            _success = nil;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [manager stopUpdatingLocation];
    if (_failure) {
        _failure();
        _failure = nil;
    }
}

- (void)updateLocation
{
    _isFinishGetLocation = NO;
    [_manager startUpdatingLocation];
}

- (BOOL)updateLocationWithSuccess:(void (^)(float,float))success
                          failure:(void (^)())failure
{
    _isFinishGetLocation = NO;
    [_manager startUpdatingLocation];
    
    if (_success && _failure) {
        return NO;
    } else {
        _success = success;
        _failure = failure;
    }
    return YES;
}

@end
