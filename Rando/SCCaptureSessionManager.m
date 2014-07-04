//
//  SCCaptureSessionManager.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

@interface SCCaptureSessionManager ()


@property (nonatomic, strong) UIView *preview;
//@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SCCaptureSessionManager


#pragma mark -
#pragma mark configure
- (id)init {
    self = [super init];
    if (self != nil) {
        _scaleNum = 1.f;
        _preScaleNum = 1.f;
    }
    return self;
}

- (void)dealloc {
    [_session stopRunning];
    self.previewLayer = nil;
    self.session = nil;
    self.stillImageOutput = nil;
//    self.stillImage = nil;
}

- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect {
    
    self.preview = parent;
    
    //1、队列
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithRect:preivewRect];
    
    //4、input
    [self addVideoInputFrontCamera:NO];
    
    //5、output
    [self addStillImageOutput];
    
//    //6、preview imageview
//    [self addPreviewImageView];
    
//    //6、default flash mode
//    [self switchFlashMode:nil];
    
//    //7、default focus mode
//    [self setDefaultFocusMode];
}

/**
 *  创建一个队列，防止阻塞主线程
 */
- (void)createQueue {
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
}

/**
 *  session
 */
- (void)addSession {
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    //设置质量
//  _session.sessionPreset = AVCaptureSessionPresetPhoto;
}

/**
 *  相机的实时预览页面
 *
 *  @param previewRect 预览页面的frame
 */
- (void)addVideoPreviewLayerWithRect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = previewRect;
    _previewLayer = preview;
    [_preview.layer addSublayer:_previewLayer];
}

/**
 *  设置相框
 *
 *  @param radius 相框弧度
 */
- (void)setLayerRadius:(int)radius;
{
    _previewLayer.masksToBounds = YES;
    _previewLayer.cornerRadius = radius;

    _radius = radius;
}

/**
 *  添加输入设备
 *
 *  @param front 前或后摄像头
 */
- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        debugLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                debugLog(@"Device position : back");
                backCamera = device;
                
            }  else {
                debugLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                [_session addInput:frontFacingCameraDeviceInput];
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                debugLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                [_session addInput:backFacingCameraDeviceInput];
                self.inputDevice = backFacingCameraDeviceInput;
            } else {
                debugLog(@"Couldn't add back facing video input");
            }
        }
    }
}

/**
 *  添加输出设备
 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];//输出jpeg
    tmpOutput.outputSettings = outputSettings;
    
//    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    [_session addOutput:tmpOutput];
    
    self.stillImageOutput = tmpOutput;
}

#pragma mark - actions
/**
 *  拍照
 */
- (void)takePicture:(DidCapturePhotoBlock)block {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
//	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//    [videoConnection setVideoOrientation:avcaptureOrientation];
    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
	debugLog(@"about to request a capture from: %@", _stillImageOutput);
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments) {
            debugLog(@"attachements: %@", exifAttachments);
        } else {
            debugLog(@"no attachments");
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        debugLog(@"originImage:%@", [NSValue valueWithCGSize:image.size]);
        
        CGFloat squareLength = CAPTURE_SIZE;
        CGFloat headHeight = _previewLayer.bounds.size.height - squareLength;//_previewLayer的frame是(0, 44, 320, 320 + 44)
        CGSize size = CGSizeMake(squareLength * 2, squareLength * 2);
        
        UIImage *scaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:size interpolationQuality:kCGInterpolationHigh];
        debugLog(@"scaledImage:%@", [NSValue valueWithCGSize:scaledImage.size]);
        
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2 + headHeight, size.width, size.height);
        debugLog(@"cropFrame:%@", [NSValue valueWithCGRect:cropFrame]);
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        debugLog(@"croppedImage:%@", [NSValue valueWithCGSize:croppedImage.size]);
        
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation != UIDeviceOrientationPortrait) {
            
            CGFloat degree = 0;
            if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                degree = 180;// M_PI;
            } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                degree = -90;// -M_PI_2;
            } else if (orientation == UIDeviceOrientationLandscapeRight) {
                degree = 90;// M_PI_2;
            }
            croppedImage = [croppedImage rotatedByDegrees:degree];
        }
        
        croppedImage = [croppedImage cutImageWithRadius:_radius];
        //block、delegate、notification 3选1，传值
        if (block) {
            block(croppedImage);
        } else if ([_delegate respondsToSelector:@selector(didCapturePhoto:)]) {
            [_delegate didCapturePhoto:croppedImage];
        } else {
            //[[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
        }
    }];
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

/**
 *  切换前后摄像头
 *
 *  @param isFrontCamera YES:前摄像头  NO:后摄像头
 */
- (void)switchCamera:(BOOL)isFrontCamera {
    
    //旋转图层
    [self turn3DTransform:isFrontCamera];
    
    if (!_inputDevice) {
        return;
    }
    [_session beginConfiguration];
    
    [_session removeInput:_inputDevice];
    
    [self addVideoInputFrontCamera:isFrontCamera];
    
    [self performSelector:@selector(switchCameraDelay) withObject:nil afterDelay:0.2];
}

- (void)switchCameraDelay
{
    
    [_session commitConfiguration];
    _previewLayer.cornerRadius = _radius;
}

- (void)turn3DTransform:(BOOL)isFrontCamera
{
    //主layer的3D变换
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0/700;
    
    //在X轴上做一个20度的小旋转 在那个轴上面旋转就是对应的坐标值为1，当前为X轴旋转
    transform = CATransform3DRotate(transform, M_PI/9, 0, 0, 0);
    //设置CAlayer的sublayerTransform
    _previewLayer.sublayerTransform = transform;
    _previewLayer.cornerRadius = 0;
    [_previewLayer setBackgroundColor:[UIColor blackColor].CGColor];
    //添加Layer
//    [self.view.layer addSublayer:self.mainLayer];
    
    //动画
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.rotation.y"];
    
    animation.removedOnCompletion = NO;
    if (isFrontCamera) {
        animation.fillMode = kCAFillModeForwards;
    } else {
        animation.fillMode = kCAFillModeBackwards;
    }

    //从0到360度
    
    animation.toValue = [NSNumber numberWithFloat:M_PI];
    
    //间隔3秒
    
    animation.duration = 1.0;
    
    //无限循环
    
    animation.repeatCount = 1;//HUGE_VALF;
    
    //开始动画
    [_previewLayer addAnimation:animation forKey:@"rotation"];
}

/**
 *  拉近拉远镜头
 *
 *  @param scale 拉伸倍数
 */
- (void)pinchCameraViewWithScalNum:(CGFloat)scale {
    _scaleNum = scale;
    if (_scaleNum < MIN_PINCH_SCALE_NUM) {
        _scaleNum = MIN_PINCH_SCALE_NUM;
    } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
        _scaleNum = MAX_PINCH_SCALE_NUM;
    }
    [self doPinch];
    _preScaleNum = scale;
}

- (void)pinchCameraView:(UIPinchGestureRecognizer *)gesture {
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [gesture numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [gesture locationOfTouch:i inView:_preview];
		CGPoint convertedLocation = [_previewLayer convertPoint:location fromLayer:_previewLayer.superlayer];
		if ( ! [_previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		_scaleNum = _preScaleNum * gesture.scale;
        
        if (_scaleNum < MIN_PINCH_SCALE_NUM) {
            _scaleNum = MIN_PINCH_SCALE_NUM;
        } else if (_scaleNum > MAX_PINCH_SCALE_NUM) {
            _scaleNum = MAX_PINCH_SCALE_NUM;
        }
        
        [self doPinch];
	}
    
    if ([gesture state] == UIGestureRecognizerStateEnded ||
        [gesture state] == UIGestureRecognizerStateCancelled ||
        [gesture state] == UIGestureRecognizerStateFailed) {
        _preScaleNum = _scaleNum;
        debugLog(@"final scale: %f", _scaleNum);
    }
}

- (void)doPinch {
//    AVCaptureStillImageOutput* output = (AVCaptureStillImageOutput*)[_session.outputs objectAtIndex:0];
//    AVCaptureConnection *videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;//videoScaleAndCropFactor这个属性取值范围是1.0-videoMaxScaleAndCropFactor。iOS5+才可以用
    if (_scaleNum > maxScale) {
        _scaleNum = maxScale;
    }
    
//    videoConnection.videoScaleAndCropFactor = _scaleNum;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    [_previewLayer setAffineTransform:CGAffineTransformMakeScale(_scaleNum, _scaleNum)];
    [CATransaction commit];
}

/**
 *  切换闪光灯模式
 *  （切换顺序：最开始是auto，然后是off，最后是on，一直循环）
 *  @param sender: 闪光灯按钮
 */
- (void)switchFlashMode:(UIButton*)sender {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (!captureDeviceClass) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有拍照功能" delegate:nil cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
//        if (!sender) {//设置默认的闪光灯模式
//            device.flashMode = AVCaptureFlashModeAuto;
//        } else {
            if (device.flashMode == AVCaptureFlashModeOff) {
                device.flashMode = AVCaptureFlashModeOn;
                imgStr = @"flashing_on.png";
                
            } else if (device.flashMode == AVCaptureFlashModeOn) {
                device.flashMode = AVCaptureFlashModeAuto;
                imgStr = @"flashing_auto.png";
                
            } else if (device.flashMode == AVCaptureFlashModeAuto) {
                device.flashMode = AVCaptureFlashModeOff;
                imgStr = @"flashing_off.png";
                
            }
//        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"您的设备没有闪光灯功能" delegate:nil cancelButtonTitle:@"噢T_T" otherButtonTitles: nil];
        [alert show];
    }
    [device unlockForConfiguration];
}

/**
 *  点击后对焦
 *
 *  @param devicePoint 点击的point
 */
- (void)focusInPoint:(CGPoint)devicePoint {
//    if (CGRectContainsPoint(_previewLayer.bounds, devicePoint) == NO) {
//        return;
//    }
    
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
	dispatch_async(_sessionQueue, ^{
		AVCaptureDevice *device = [_inputDevice device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			debugLog(@"%@", error);
		}
	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

/**
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = _previewLayer.bounds.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    
    if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            if([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

#pragma mark ---------------private--------------
- (AVCaptureConnection*)findVideoConnection {
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in _stillImageOutput.connections) {
		for (AVCaptureInputPort *port in connection.inputPorts) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    return videoConnection;
}



@end
