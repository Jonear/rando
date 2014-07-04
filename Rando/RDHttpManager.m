//
//  KHttpManager.m
//  TestSinaLogin
//
//  Created by kyle on 13-12-10.
//  Copyright (c) 2013年 kyle. All rights reserved.
//

#import "RDHttpManager.h"

@interface RDHttpManager() <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@end

@implementation RDHttpManager {
    NSMutableData *_responseData;
    NSURLConnection *_urlConnection;
    NSMutableURLRequest *_request;
    
    void (^_success)(id);
    void (^_failure)(NSError *);
}

- (id)init
{
    if (self = [super init]) {
        _responseData = [[NSMutableData alloc] init];
    }
    return self;
}

+ (RDHttpManager *) manager
{
    return [[RDHttpManager alloc] init];
}

- (NSMutableURLRequest *)GetRequest:(NSString *)URLString
                         parameters:(NSDictionary *)parameters
                            success:(void (^)(id))success
                            failure:(void (^)(NSError *))failure
{
    _success = [success copy];
    _failure = [failure copy];
    NSURL *url = [self generateURL:URLString params:parameters];
    _request = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    //content-length
    NSRange range = [[url absoluteString] rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        NSString *length = [NSString stringWithFormat:@"%ld", (long)([url absoluteString].length - range.location - 1)];
        [_request setValue:length forHTTPHeaderField:@"Content-Length"];
    }
    
    [_request setHTTPMethod:@"GET"];
    [_request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    return _request;
}

- (NSMutableURLRequest *)PostRequest:(NSString *)URLString
                          parameters:(NSDictionary *)parameters
                             success:(void (^)(id))success
                             failure:(void (^)(NSError *))failure
{
    _success = success;
    _failure = failure;
    NSURL *url = [NSURL URLWithString:URLString];
    _request = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    //content-length
    NSString *postContent = [self generateParams:parameters];
    NSData *postData = [postContent dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    [_request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [_request setHTTPBody:postData];
    [_request setHTTPMethod:@"POST"];
    [_request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    return _request;
}

- (NSMutableURLRequest *)PostImageRequest:(NSString *)URLString
                                  UIImage:(UIImage*)image
                               parameters:(NSDictionary *)parameters
                                  success:(void (^)(id))success
                                  failure:(void (^)(NSError *))failure
{
    _success = [success copy];
    _failure = [failure copy];
    //分界线的标识符
    NSString *TWITTERFON_FORM_BOUNDARY = @"AaB03x";
    //根据url初始化request
    _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:10];
    //分界线 --AaB03x
    NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
    //结束符 AaB03x--
    NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
    //得到图片的data
    NSData* data = UIImageJPEGRepresentation(image, 1);
    //http body的字符串
    NSMutableString *body=[[NSMutableString alloc]init];
    //参数的集合的所有key的集合
    NSArray *keys= [parameters allKeys];

    //遍历keys
    for(int i=0;i<[keys count];i++)
    {
        //得到当前key
        NSString *key=[keys objectAtIndex:i];
        //如果key不是pic，说明value是字符类型，比如name：Boris
        if(![key isEqualToString:@"pic"])
        {
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            //添加字段名称，换2行
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
            //添加字段的值
            [body appendFormat:@"%@\r\n",[parameters objectForKey:key]];
        }
    }

    ////添加分界线，换行
    [body appendFormat:@"%@\r\n",MPboundary];
    //声明pic字段，文件名为boris.png
    [body appendFormat:@"Content-Disposition: form-data; name=\"ImageField\"; filename=\"x1234.png\"\r\n"];
    //声明上传文件的格式
    [body appendFormat:@"Content-Type: image/jpeg\r\n\r\n"];

    //声明结束符：--AaB03x--
    NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
    //声明myRequestData，用来放入http body
    NSMutableData *myRequestData=[NSMutableData data];
    //将body字符串转化为UTF8格式的二进制
    [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    //将image的data加入
    [myRequestData appendData:data];
    //加入结束符--AaB03x--
    [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];

    //设置HTTPHeader中Content-Type的值
    NSString *content=[[NSString alloc] initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
    //设置HTTPHeader
    [_request setValue:content forHTTPHeaderField:@"Content-Type"];
    //设置Content-Length
    [_request setValue:[NSString stringWithFormat:@"%d", [myRequestData length]] forHTTPHeaderField:@"Content-Length"];
    //设置http body
    [_request setHTTPBody:myRequestData];
    //http method
    [_request setHTTPMethod:@"POST"];
    
    return _request;
}

- (void)start
{
    if (_request) {
        _urlConnection = [[NSURLConnection alloc]initWithRequest:_request delegate:self];
    }
    _request = nil;
}

- (void)syncStart
{
    if (_request) {
        NSError *error;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:_request returningResponse:nil error:&error];
        if (!error) {
            NSString *receiveStr = [[NSString alloc]initWithData:returnData encoding:NSUTF8StringEncoding];
            _success(receiveStr);
        } else {
            _failure(error);
        }
    }
    _request = nil;
}

- (NSString*)generateParams:(NSDictionary*)params
{
	if ([params count]) {
		NSMutableArray* pairs = [[NSMutableArray alloc] init];
		for (NSString* key in params.keyEnumerator) {
			NSString* value = [params objectForKey:key];
            //NSString* escapedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString* escapedValue = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                           NULL, /* allocator */
                                                                                                           (CFStringRef)value,
                                                                                                           NULL, /* charactersToLeaveUnescaped */
                                                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                           kCFStringEncodingUTF8));
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
		}
		
		NSString* query = [pairs componentsJoinedByString:@"&"];
        return query;
    }
    return nil;
}

- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params
{
	if ([params count]) {
		NSMutableArray* pairs = [[NSMutableArray alloc] init];
		for (NSString* key in params.keyEnumerator) {
			NSString* value = [params objectForKey:key];
            //NSString* escapedValue = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString* escapedValue = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                           NULL, /* allocator */
                                                                                                           (CFStringRef)value,
                                                                                                           NULL, /* charactersToLeaveUnescaped */
                                                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                           kCFStringEncodingUTF8));
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escapedValue]];
		}
		
        NSString* url;
		NSString* query = [pairs componentsJoinedByString:@"&"];
        if (baseURL.length) {
            url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
        } else {
            url = query;
        }
		
		return [NSURL URLWithString:url];
	} else {
		return [NSURL URLWithString:baseURL];
	}
}

#pragma mark ---- NSURLConnectionDataDelegate -----
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    //NSLog(@"%@",[res allHeaderFields]);
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *receiveStr = [[NSString alloc]initWithData:_responseData encoding:NSUTF8StringEncoding];
    _success(receiveStr);
}

#pragma mark ---- NSURLConnectionDelegate -----
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _failure(error);
}

@end
