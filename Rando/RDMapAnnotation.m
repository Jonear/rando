//
//  RDMapAnnotation.m
//  Rando
//
//  Created by Jonear on 14-3-17.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDMapAnnotation.h"

@implementation RDMapAnnotation
{
    float _lat;
    float _lot;
}

- (id) initWithLat:(float)lat lot:(float)lot
{
    self = [super init];
    if (self) {
        _lat = lat;
        _lot = lot;
    }
    return self;
}

-(CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D center;
    center.latitude=_lat;
    center.longitude=_lot;
    return center;
}


@end
