//
//  RDModelManager.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDModelManager.h"
#import "FMDatabase.h"
#import "RDHttpManager.h"
#import "SDWebImage/SDImageCache.h"

@implementation RDModelManager
{
    FMDatabase *db;
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
        [self initDatabase];
    }
    return self;
}

//初始化数据库
- (void)initDatabase
{
    if (db) {
        [db close];
    }
    //get database path
    NSString *dbFile = PATH_OF_DOCUMENT;
    dbFile = [dbFile stringByAppendingString:@"/Rando_v1"];
    
    //create/open database
    db = [FMDatabase databaseWithPath:dbFile];
    if (!db) {
        debugLog(@"FMDatabase databaseWithPath failed.");
        abort();
    }
    
    if (![db open]) {
        debugLog(@"FMDatabase open failed.");
        abort();
    }
    
    //create Image table
    NSString * sql = @"CREATE TABLE IF NOT EXISTS 'Image' ('id' INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL, 'ImageID' INTEGER, 'imageUrl' VARCHAR(200), 'lat' DOUBLE, 'lot' DOUBLE, 'sign' VARCHAR(100), 'linkNumber' INTEGER, 'radius' DOUBLE, 'isMyImage' INTEGER, 'isLike' INTEGER, 'isReport' INTEGER, 'isOpen' INTEGER)";
    if (![db executeUpdate:sql]) {
        debugLog(@"create Image table failed. error=%@", [db lastError]);
    } else {
        debugLog(@"create Image table successfully.");
    }
    
}

- (BOOL)insertImage:(RDImageModel*)image
{
    if ([self isHaveImage:image.imageID]) {
        [self deleteImage:image];
    }
    
    NSString *sql = @"INSERT INTO Image (ImageID, imageUrl, lat, lot, sign, linkNumber, radius, isMyImage, isLike, isReport, isOpen) values (?,?,?,?,?,?,?,?,?,?,?)";
    BOOL res = [db executeUpdate:sql,
                [[NSNumber alloc] initWithInt:image.imageID],
                image.imageUrl,
                [[NSNumber alloc] initWithFloat:image.lat],
                [[NSNumber alloc] initWithFloat:image.lot],
                image.sign,
                [[NSNumber alloc] initWithInt:image.likeNumber],
                [[NSNumber alloc] initWithFloat:image.radius],
                [[NSNumber alloc] initWithBool:image.isMyImage],
                [[NSNumber alloc] initWithBool:image.isLike],
                [[NSNumber alloc] initWithBool:image.isReport],
                [[NSNumber alloc] initWithBool:image.isOpen]
                ];
    
    if (!res) {
        debugLog(@"addImage failed.error=%@", [db lastError]);
        return NO;
    } else {
        debugLog(@"addImage successfully.");
        return YES;
    }
}

- (BOOL)updateImage:(RDImageModel*)image
{
    NSString *sql = @"UPDATE Image SET linkNumber = ?, isMyImage = ?, isLike = ?, isReport = ?, isOpen = ? WHERE ImageID = ?";
    BOOL res = [db executeUpdate:sql,
                [[NSNumber alloc] initWithInt:image.likeNumber],
                [[NSNumber alloc] initWithBool:image.isMyImage],
                [[NSNumber alloc] initWithBool:image.isLike],
                [[NSNumber alloc] initWithBool:image.isReport],
                [[NSNumber alloc] initWithBool:image.isOpen],
                [[NSNumber alloc] initWithInt:image.imageID]
                ];
    
    if (!res) {
        debugLog(@"Update Image failed.error=%@", [db lastError]);
        return NO;
    } else {
        debugLog(@"Update Image successfully.");
        return YES;
    }
}

- (NSArray*)getAllImageWithMy:(BOOL)isMyImage
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *sql = @"SELECT * FROM Image WHERE isMyImage = 0 ORDER BY id DESC";
    if (isMyImage) {
        sql = @"SELECT * FROM Image WHERE isMyImage = 1  ORDER BY id DESC";
    }
    
    FMResultSet * rs = [db executeQuery:sql];
    while ([rs next]) {
        RDImageModel *image = [[RDImageModel alloc] init];
        image.imageID = [rs intForColumn:@"ImageID"];
        image.imageUrl = [rs stringForColumn:@"imageUrl"];
        image.lat = [rs doubleForColumn:@"lat"];
        image.lot = [rs doubleForColumn:@"lot"];
        image.sign = [rs stringForColumn:@"sign"];
        image.likeNumber = [rs intForColumn:@"linkNumber"];
        image.radius = [rs doubleForColumn:@"radius"];
        image.isMyImage = [rs boolForColumn:@"isMyImage"];
        image.isLike = [rs boolForColumn:@"isLike"];
        image.isReport = [rs boolForColumn:@"isReport"];
        image.isOpen = [rs boolForColumn:@"isOpen"];
        
        [array addObject:image];
    }
    
    if ([array count] == 0) {
        return nil;
    }
    
    return array;
}

- (BOOL)deleteImage:(RDImageModel*)image
{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Image WHERE ImageID = ?"];
    return [db executeUpdate:sql,[[NSNumber alloc] initWithInt:image.imageID]];
}

- (BOOL)isHaveImage:(int)imageID
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM Image WHERE ImageID = ?"];
    FMResultSet *rs  = [db executeQuery:sql,[[NSNumber alloc] initWithInt:imageID]];
    if ([rs next]) {
        [rs close];
        return YES;
    }
    [rs close];
    return NO;
}


#pragma mark -HTTP POST

- (void)fetchImageFromServer:(void (^)(id))success
                     failure:(void (^)(NSError *))failure;
{
    RDHttpManager *httpManager = [RDHttpManager manager];
    NSDictionary *params = @{@"uuid":[[UIDevice currentDevice] identifierForVendor].UUIDString};
    
    [httpManager PostRequest:FetchImageUrl
                  parameters:params
                     success:^(id msg) {
                         debugLog(@"fetch image success:%@", msg);
                         if ([self fetchImageSuccess:msg]) {
                             success(msg);
                         } else {
                             failure(nil);
                         }
                     } failure:^(NSError *error) {
                         debugLog(@"error:%@", error.description);
                         failure(error);
                     }];
    
    [httpManager start];
}

- (void)uploadImageToServer:(UIImage *)image
                      title:(NSString *)sign
                        lat:(float)lat
                        lot:(float)lot
                     radius:(float)radius
                    success:(void (^)(id))success
                    failure:(void (^)(NSError *))failure
{
    RDHttpManager *httpManager = [RDHttpManager manager];
    
    NSDictionary *params = @{@"uuid":[[UIDevice currentDevice] identifierForVendor].UUIDString,
                             @"lat":[NSString stringWithFormat:@"%f", lat],
                             @"lot":[NSString stringWithFormat:@"%f", lot],
                             @"radius":[NSString stringWithFormat:@"%f", radius],
                             @"sign":sign};
    
    [httpManager PostImageRequest:UploadImageUrl
                          UIImage:image
                       parameters:params
                          success:^(id msg) {
                              debugLog(@"upload image success:%@", msg);
                              if ([self insertImageToDB:msg image:image lat:lat lot:lot sign:sign radius:radius]) {
                                  success(msg);
                              } else {
                                  failure(nil);
                              }
                              
                          } failure:^(NSError *error) {
                              failure(error);
                          }];
    
    [httpManager start];
}

- (void)likeImageToServer:(NSString*)imageID
                  success:(void (^)(id))success
                  failure:(void (^)(NSError *))failure
{
    RDHttpManager *httpManager = [RDHttpManager manager];
    
    NSDictionary *params = @{@"imageID":imageID};
    
    [httpManager PostRequest:LikeImageUrl
                  parameters:params
                     success:^(id msg) {
                         debugLog(@"send like success:%@", msg);
                         success(msg);
                         
                     } failure:^(NSError *error) {
                         debugLog(@"error:%@", error.description);
                         failure(error);
                     }];
    
    [httpManager start];
}

- (void)fetchLikeCountServer:(NSString*)imageID
                     success:(void (^)(id))success
                     failure:(void (^)(NSError *))failure
{
    RDHttpManager *httpManager = [RDHttpManager manager];
    
    NSDictionary *params = @{@"imageID":imageID};
    
    [httpManager PostRequest:FetchLikeCountUrl
                  parameters:params
                     success:^(id msg) {
                         debugLog(@"get like success:%@", msg);
                         success(msg);
                         
                     } failure:^(NSError *error) {
                         debugLog(@"error:%@", error.description);
                         failure(error);
                     }];
    
    [httpManager start];
}

- (void)fetchMyImagesCountServer:(void (^)(id))success
                         failure:(void (^)(NSError *))failure
{
    NSArray *myImageArray = [self getAllImageWithMy:YES];
    if (myImageArray.count==0) {
        success(nil);
        return;
    }
    RDHttpManager *httpManager = [RDHttpManager manager];
    
    NSString *imageIDs = @"";
    int i=0;
    for (RDImageModel *image in myImageArray) {
        if (++i == myImageArray.count) {
            imageIDs = [imageIDs stringByAppendingString:[NSString stringWithFormat:@"%d",image.imageID]];
        } else {
            imageIDs = [imageIDs stringByAppendingString:[NSString stringWithFormat:@"%d,",image.imageID]];
        }
    }
    
    NSDictionary *params = @{@"imageIDs":imageIDs};
    
    [httpManager PostRequest:FetchMyImagesLikeUrl
                  parameters:params
                     success:^(id msg) {
                         debugLog(@"get like success:%@", msg);
                         if ([self fetchImagesCountSuccess:msg]) {
                             success(msg);
                         } else {
                             failure(nil);
                         }
                     } failure:^(NSError *error) {
                         debugLog(@"error:%@", error.description);
                         failure(error);
                     }];
    
    [httpManager start];
}

- (void)sendMessageToServer:(NSString*)content
                    success:(void (^)(id))success
                    failure:(void (^)(NSError *))failure
{
    RDHttpManager *httpManager = [RDHttpManager manager];
    NSDictionary *params = @{@"message":content};
    
    [httpManager PostRequest:SendMessageUrl
                  parameters:params
                     success:^(id msg) {
                         debugLog(@"send message success:%@", msg);
                         success(msg);
                     } failure:^(NSError *error) {
                         debugLog(@"error:%@", error.description);
                         failure(error);
                     }];
    
    [httpManager start];
}

- (BOOL)fetchImageSuccess:(NSString*)imageJson
{
    NSDictionary *json;
    NSError *error;
    if ([imageJson isKindOfClass:[NSString class]]) {
        NSData *data = [imageJson dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!jsonArray) {
            return NO;
        }
        json = [jsonArray objectAtIndex:0];
        
        RDImageModel *image = [[RDImageModel alloc] init];
        image.imageID = [[json objectForKey:@"id"] intValue];
        image.imageUrl = [json objectForKey:@"ImageUrl"];
        image.lat = [[json objectForKey:@"lat"] floatValue];
        image.lot = [[json objectForKey:@"lot"] floatValue];
        image.sign = [json objectForKey:@"sign"];
        image.likeNumber = [[json objectForKey:@"like"] intValue];
        image.radius = [[json objectForKey:@"radius"] floatValue];
        image.isMyImage = NO;
        image.isLike = NO;
        image.isReport = NO;
        image.isOpen = NO;
        image.isUpdate = NO;
        
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:image, @"imageModel", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:noti_FetchSuccess object:nil userInfo:dic];
        
        return [self insertImage:image];
        
    } else {
        return NO;
    }
    
    return NO;
}

- (BOOL)insertImageToDB:(NSString*)backMSG image:(UIImage*)imagesrc lat:(float)lat lot:(float)lot sign:(NSString*)sign radius:(float)radius
{
    NSRange range = [backMSG rangeOfString:@"|"];
    if (range.location != NSNotFound) {
        NSString *idstr = [backMSG substringToIndex:range.location];
        NSString *imageurl = [backMSG substringFromIndex:range.location+1];
        
        RDImageModel *image = [[RDImageModel alloc] init];
        image.imageID = [idstr intValue];
        image.imageUrl = imageurl;
        image.lat = lat;
        image.lot = lot;
        image.sign = sign;
        image.likeNumber = 0;
        image.radius = radius;
        image.isMyImage = YES;
        image.isLike = NO;
        image.isReport = NO;
        image.isOpen = YES;
        image.isUpdate = NO;
        
        
        //保存缓存
        [[SDImageCache sharedImageCache] storeImage:imagesrc forKey:imageurl toDisk:YES];
        //发出通知
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:image, @"imageModel", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:noti_UploadSuccess object:nil userInfo:dic];
        //保存到数据库
        return [self insertImage:image];
    }
    
    return NO;
}

- (BOOL)fetchImagesCountSuccess:(NSString*)imageJson
{
    NSDictionary *json;
    NSError *error;
    if ([imageJson isKindOfClass:[NSString class]]) {
        NSData *data = [imageJson dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (!jsonArray) {
            return NO;
        }
        json = [jsonArray objectAtIndex:0];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:noti_FetchImagesCountSuccess object:nil userInfo:json];
        return YES;
    }
    return NO;
}

@end
