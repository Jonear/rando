//
//  RDModelManager.h
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDImageModel.h"

@interface RDModelManager : NSObject

+ (id)shareManager;

//DB
- (BOOL)insertImage:(RDImageModel*)image;            //插入图片到数据库
- (BOOL)updateImage:(RDImageModel*)image;            //更新图片
- (BOOL)deleteImage:(RDImageModel*)image;            //删除图片
- (NSArray*)getAllImageWithMy:(BOOL)isMyImage;       //获取图片

//HTTP 都是异步的方法

//网络获取一张图
- (void)fetchImageFromServer:(void (^)(id))success
                            failure:(void (^)(NSError *))failure;
//上传一张图片
- (void)uploadImageToServer:(UIImage *)image
                      title:(NSString *)sign
                        lat:(float)lat
                        lot:(float)lot
                     radius:(float)radius
                    success:(void (^)(id))success
                    failure:(void (^)(NSError *))failure;
//赞一张图片
- (void)likeImageToServer:(NSString*)imageID
                  success:(void (^)(id))success
                  failure:(void (^)(NSError *))failure;

//获得一张图片的被赞次数
- (void)fetchLikeCountServer:(NSString*)imageID
                     success:(void (^)(id))success
                     failure:(void (^)(NSError *))failure;

//获得我的多张图片的被赞次数
- (void)fetchMyImagesCountServer:(void (^)(id))success
                         failure:(void (^)(NSError *))failure;

//获得我的多张图片的被赞次数
- (void)sendMessageToServer:(NSString*)content
                    success:(void (^)(id))success
                    failure:(void (^)(NSError *))failure;

@end
