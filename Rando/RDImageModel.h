//
//  RDImageModel.h
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDImageModel : NSObject

@property (assign, nonatomic) int imageID;
@property (strong, nonatomic) NSString* imageUrl;
@property (assign, nonatomic) float lat;
@property (assign, nonatomic) float lot;
@property (strong, nonatomic) NSString* sign;
@property (assign, nonatomic) int likeNumber;
@property (assign, nonatomic) float radius;
@property (assign, nonatomic) BOOL isMyImage;
@property (assign, nonatomic) BOOL isLike;
@property (assign, nonatomic) BOOL isReport;
@property (assign, nonatomic) BOOL isOpen;
@property (assign, nonatomic) BOOL isUpdate;

@end
