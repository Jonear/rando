//
//  RDCameraViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-12.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDCameraViewController.h"
#import "SCCaptureSessionManager.h"
#import "RDSharePictureViewController.h"


@interface RDCameraViewController ()

@end

@implementation RDCameraViewController
{
    SCCaptureSessionManager *_captureManager;
    BOOL isFrontCamera;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _captureManager = [[SCCaptureSessionManager alloc] init];
        isFrontCamera = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect previewRect = CGRectMake((PHOTOWIDTH - CAPTURE_SIZE)/2, 50, CAPTURE_SIZE, CAPTURE_SIZE);
    [_captureManager configureWithParentLayer:self.view previewRect:previewRect];
    [_captureManager.session startRunning];
    
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:UDCameraRadius];
    if (!radius) {
        radius = [NSNumber numberWithInt:CAPTURE_SIZE/2];
    }
    _SRadius.maximumValue = CAPTURE_SIZE/2;
    _SRadius.value = [radius intValue];
    _SRadius.minimumValue = 0;
    [_captureManager setLayerRadius:_SRadius.value];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadSuccess) name:noti_UploadSuccess object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takePictureClick:(id)sender {
    [_captureManager takePicture:^(UIImage *stillImage) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_SRadius.value] forKey:UDCameraRadius];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        RDSharePictureViewController *sharePictureViewController = [[RDSharePictureViewController alloc] init];
        [sharePictureViewController setImage:stillImage];
        [self presentViewController:sharePictureViewController animated:NO completion:nil];
    }];
}

- (IBAction)radiusChanged:(id)sender {
    [_captureManager setLayerRadius:_SRadius.value];
}

- (IBAction)dimissController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchCamera:(id)sender {
    isFrontCamera = !isFrontCamera;
    [_captureManager switchCamera:isFrontCamera];
}

- (void)uploadSuccess
{
    [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
