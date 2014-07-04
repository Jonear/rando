//
//  RDDetailImageViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDDetailImageViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "STScratchView.h"
#import "RDModelManager.h"
#import "MBProgressHUD.h"
#import "RDHttpManager.h"
#import "Mapkit/Mapkit.h"
#import "RDMapAnnotation.h"

@interface RDDetailImageViewController ()

@end

@implementation RDDetailImageViewController
{
    STScratchView *_scratchView;
    MKMapView *_mapView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_thisImage.sign.length > 0) {
        self.title = _thisImage.sign;
    } else {
        self.title = @"匿名图片";
    }
    if (!_thisImage.isOpen) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]  initWithTitle:@"自动刮开" style:UIBarButtonItemStyleDone target:self action:@selector(takeOpen)];
        
        UIView *maskView= [[UIView alloc] initWithFrame:CGRectMake(0, 0, CAPTURE_SIZE, CAPTURE_SIZE)];
        [maskView setBackgroundColor:[UIColor lightGrayColor]];
        _scratchView = [[STScratchView alloc] init];
        [_scratchView setContentMode:UIViewContentModeScaleAspectFit];
        [_scratchView setFrame:_imageView.frame];
        [_scratchView setBackgroundColor:[UIColor clearColor]];
        [_scratchView setSizeBrush:60.0];
        [_scratchView setHideView:maskView];
        [self.view addSubview:_scratchView];
    }
    if (_thisImage.isLike) {
        [_btnLike setTitle:@" 已赞" forState:UIControlStateNormal];
    }
    if (_thisImage.isReport) {
        [_btnReport setEnabled:NO];
        [_btnReport setTitle:@" 已举报" forState:UIControlStateNormal];
    }
    if (_isMyImage) {
        [_btnLike setTitle:[NSString stringWithFormat:@" %d",_thisImage.likeNumber] forState:UIControlStateNormal];
        [_btnReport setTitle:@"保存" forState:UIControlStateNormal];
        [[RDModelManager shareManager] fetchLikeCountServer:[NSString stringWithFormat:@"%d",_thisImage.imageID]
                                                    success:^(id countStr) {
                                                        if ([countStr isKindOfClass:[NSString class]]) {
                                                            int count = [countStr intValue];
                                                            [_btnLike setTitle:[NSString stringWithFormat:@" %d",count] forState:UIControlStateNormal];
                                                            if (count != _thisImage.likeNumber)
                                                            {
                                                                _thisImage.likeNumber = count;
                                                                _thisImage.isUpdate = YES;
                                                            }
                                                            
                                                        }
                                                    } failure:^(NSError* e){
             
                                                    }];
    }
    [self initMapView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImageView)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [_imageView addGestureRecognizer:tapGesture];
    _imageView.userInteractionEnabled = YES;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"图片加载中...";
    [_imageView setImageWithURL:[NSURL URLWithString:_thisImage.imageUrl]
               placeholderImage:[UIImage imageNamed:@"defaultImage"]
                        options:SDWebImageRetryFailed
                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                          if (error) {
                              hud.labelText = @"图片加载失败，请检查网络";
                              hud.detailsLabelText = @"";
                              hud.mode = MBProgressHUDModeText;
                              [hud hide:YES afterDelay:TIP_TIME];
                              [_scratchView removeFromSuperview];
                              self.navigationItem.rightBarButtonItem = nil;
                              [_imageView removeGestureRecognizer:tapGesture];
                          } else {
                              [hud hide:YES];
                          }
                      }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginOpenMask) name:noti_haveOpenMask object:nil];
}

- (void)initMapView
{
    CLLocationCoordinate2D center;
    center.latitude=_thisImage.lat;
    center.longitude=_thisImage.lot;
    
    RDMapAnnotation *annotation = [[RDMapAnnotation alloc] initWithLat:_thisImage.lat lot:_thisImage.lot];
    
    MKCoordinateSpan span;
    span.latitudeDelta=0.02;
    span.longitudeDelta=0.02;
    MKCoordinateRegion region={center,span};
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, CAPTURE_SIZE, CAPTURE_SIZE)];
    if (_thisImage.lat == 0) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CAPTURE_SIZE, CAPTURE_SIZE)];
        label.text = @"来自匿名的地址";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor redColor];
        label.backgroundColor = [UIColor grayColor];
        [label.layer setCornerRadius:_thisImage.radius];
        [_mapView addSubview:label];
    } else {
        [_mapView setRegion:region];
        [_mapView addAnnotation:annotation];
    }
    [_mapView.layer setMasksToBounds:YES];
    [_mapView.layer setCornerRadius:_thisImage.radius];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)takeOpen
{
    _thisImage.isOpen = YES;
    _thisImage.isUpdate = YES;
    [_scratchView removeFromSuperview];
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)beginOpenMask
{
    _thisImage.isOpen = YES;
    _thisImage.isUpdate = YES;
}

- (IBAction)deleteClick:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除图片"
                                                    message:@"确认是否删除该图片"
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles:@"删除",nil];
    [alert show];
}

- (IBAction)reportOrSaveClick:(id)sender {
    if (_isMyImage) {
        [self savePhoto:_imageView.image];
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"举报图片"
                                                        message:@"确认是否举报该图片"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"举报",nil];
        [alert show];

    }
}

- (IBAction)likeClick:(id)sender {
    
    if (_thisImage.isLike || _isMyImage) {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"发送赞...";
    
    [[RDModelManager shareManager] likeImageToServer:[NSString stringWithFormat:@"%d", _thisImage.imageID]
                                             success:^(id msg) {
                                                 [_btnLike setTitle:@" 已赞" forState:UIControlStateNormal];
                                                 _thisImage.isLike = YES;
                                                 _thisImage.isUpdate = YES;
                                                 [hud hide:YES];
                                             } failure:^(NSError *e) {
                                                 hud.labelText = @"赞失败，请检查网络";
                                                 hud.detailsLabelText = @"";
                                                 hud.mode = MBProgressHUDModeText;
                                                 [hud hide:YES afterDelay:TIP_TIME];
                                             }];
}

- (void)savePhoto:(UIImage *)image
{
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(id)context{
    
    NSString *text = nil;
    if (error) {
        text = @"请到设置-隐私-照片中打开权限";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存失败"
                                                        message:text
                                                       delegate:nil
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        text = @"已保存到相册";
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = text;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:TIP_TIME];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
        if ([alertView.title isEqualToString:@"删除图片"]) {
            [[RDModelManager shareManager] deleteImage:_thisImage];
            if (_imageArray) {
                [_imageArray removeObject:_thisImage];
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else if([alertView.title isEqualToString:@"举报图片"]){
            [self reportImage];
        }

    }
}

- (void)reportImage
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"举报中...";
    [[RDModelManager shareManager] sendMessageToServer:[NSString stringWithFormat:@"[举报]imageid:%d", _thisImage.imageID]
                                               success:^(id msg) {
                                                   [_btnReport setEnabled:NO];
                                                   [_btnReport setTitle:@"已举报" forState:UIControlStateNormal];
                                                   _thisImage.isReport = YES;
                                                   _thisImage.isUpdate = YES;
                                                   hud.labelText = @"举报成功";
                                                   hud.detailsLabelText = @"我们将尽快处理这张图片，保证漂流的健康与文明，感谢您的举报";
                                                   hud.mode = MBProgressHUDModeText;
                                                   [hud hide:YES afterDelay:TIP_TIME];
                                               } failure:^(NSError *e) {
                                                   hud.labelText = @"举报失败，请检查网络";
                                                   hud.detailsLabelText = @"";
                                                   hud.mode = MBProgressHUDModeText;
                                                   [hud hide:YES afterDelay:TIP_TIME];
                                               }];
}

- (void)selectImageView
{
    [self turn3DTransformWithImage:_imageView.layer duration:0.5];
}

- (void)addMap
{
    if (![_mapView superview]) {
        [_imageView addSubview:_mapView];
    } else {
        [_mapView removeFromSuperview];
    }

}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    CABasicAnimation *animation = (CABasicAnimation *)anim;
    if ([animation.keyPath isEqualToString:@"transform"] && flag){
        [self addMap];
        [self turn3DTransformWithMap:_imageView.layer duration:0.5];
    }
}

- (void)turn3DTransformWithImage:(CALayer*)layer duration:(float)duration
{
    CABasicAnimation *animation = [ CABasicAnimation
                                   animationWithKeyPath: @"transform" ];
    animation.toValue =[ NSValue valueWithCATransform3D: CATransform3DMakeRotation(M_PI/2.0, 0, 1, 0) ];
    animation.cumulative=YES;
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    animation.delegate = self;
    [animation setFillMode:kCAFillModeRemoved];
    [animation setRemovedOnCompletion:NO];
    [layer addAnimation: animation forKey: @"animation" ];
}

- (void)turn3DTransformWithMap:(CALayer*)layer duration:(float)duration
{
    CABasicAnimation *animation = [ CABasicAnimation
                                   animationWithKeyPath: @"transform" ];
    animation.fromValue =[ NSValue valueWithCATransform3D: CATransform3DMakeRotation(M_PI/2.0, 0, 1, 0) ];
    animation.toValue =[ NSValue valueWithCATransform3D: CATransform3DMakeRotation(0, 0, 1, 0) ];
    animation.cumulative=YES;
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
    animation.delegate = nil;
    [animation setFillMode:kCAFillModeRemoved];
    [animation setRemovedOnCompletion:NO];
    [layer addAnimation: animation forKey: @"animation" ];
}

@end
