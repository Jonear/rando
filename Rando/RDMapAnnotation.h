//
//  RDMapAnnotation.h
//  Rando
//
//  Created by Jonear on 14-3-17.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAPkit/Mapkit.h>

@interface RDMapAnnotation : NSObject <MKAnnotation>

- (id) initWithLat:(float)lat lot:(float)lot;

@end
