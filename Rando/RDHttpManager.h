//
//  KHttpManager.h
//  TestSinaLogin
//
//  Created by kyle on 13-12-10.
//  Copyright (c) 2013年 kyle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDHttpManager : NSObject

+ (RDHttpManager *)manager;

- (NSMutableURLRequest *)GetRequest:(NSString *)URLString
                         parameters:(NSDictionary *)parameters
                            success:(void (^)(id))success
                            failure:(void (^)(NSError *))failure;

- (NSMutableURLRequest *)PostRequest:(NSString *)URLString
                          parameters:(NSDictionary *)parameters
                            success:(void (^)(id))success
                            failure:(void (^)(NSError *))failure;

- (NSMutableURLRequest *)PostImageRequest:(NSString *)URLString
                                  UIImage:(UIImage*)image
                               parameters:(NSDictionary *)parameters
                                  success:(void (^)(id))success
                                  failure:(void (^)(NSError *))failure;
//异步请求
- (void)start;
//同步请求
- (void)syncStart;

@end
