//
//  RDSharePictureViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-12.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDSharePictureViewController.h"
#import "UIImage+Resize.h"
#import "MBProgressHUD/MBProgressHUD.h"
#import "RDLocationManager.h"
#import "RDModelManager.h"

@interface RDSharePictureViewController ()

@end

@implementation RDSharePictureViewController
{
    UIImageView *_imageView;
    RDLocationManager *_locationManager;
    UITextField *_textField;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake((PHOTOWIDTH - CAPTURE_SIZE)/2, 50, CAPTURE_SIZE, CAPTURE_SIZE)];
        [self.view addSubview:_imageView];
        _locationManager = [RDLocationManager shareManager];
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(60, -30, 200, 30)];
        [_textField setBorderStyle:UITextBorderStyleRoundedRect];
        [_textField setBackgroundColor:[UIColor whiteColor]];
        [_textField setPlaceholder:@"图片名字（6个词内）"];
        _textField.returnKeyType = UIReturnKeySend;
        [_textField addTarget:self action:@selector(shareImageClick:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [self.view addSubview:_textField];
        [self.view bringSubviewToFront:_btnShare];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

- (void)setImage:(UIImage*)image
{
    [_imageView setImage:image];
}

- (IBAction)dimissController:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)shareImageClick:(id)sender {
    
    [self hideTextFiledView];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"图片发送中";
    
    if (_textField.text.length >6) {
        hud.labelText = @"标题不能超过6个字";
        hud.detailsLabelText = @"";
        hud.mode = MBProgressHUDModeText;
        hud.yOffset -= 40;
        [hud hide:YES afterDelay:TIP_TIME];
        return;
    }
    
    UIImage *newImage = [_imageView.image imageByScalingAndCroppingForSize:CGSizeMake(CAPTURE_SIZE, CAPTURE_SIZE)];

    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:UDCameraRadius];
    if (!radius) {
        radius = [NSNumber numberWithInt:CAPTURE_SIZE/2];
    }
    
    [[RDModelManager shareManager] uploadImageToServer:newImage
                                                 title:_textField.text
                                                   lat:_locationManager.lat
                                                   lot:_locationManager.lot
                                                radius:[radius floatValue]
                                               success:^(id msg) {
                                                   [hud hide:YES];
                                               } failure:^(NSError *e) {
                                                   hud.labelText = @"上传失败，请检查网络";
                                                   hud.detailsLabelText = @"";
                                                   hud.mode = MBProgressHUDModeText;
                                                   [hud hide:YES afterDelay:TIP_TIME];
                                               }];

}

- (IBAction)editSignClick:(id)sender {

    [_textField becomeFirstResponder];
    [_btnEditSign setHidden:YES];
    
    [UIView animateWithDuration:0.5 animations:^{
        [_textField setFrame:CGRectMake(_textField.frame.origin.x, 105, _textField.frame.size.width, _textField.frame.size.height)];
        [_btnShare setFrame:CGRectMake(_btnShare.frame.origin.x, 200, _btnShare.frame.size.width, _btnShare.frame.size.height)];
    }];

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self hideTextFiledView];
}

- (void)hideTextFiledView
{
    if (_textField.frame.origin.x>0) {
        [_textField resignFirstResponder];
        [_btnEditSign setHidden:NO];
        
        [UIView animateWithDuration:0.5 animations:^{
            [_textField setFrame:CGRectMake(_textField.frame.origin.x, -30, _textField.frame.size.width, _textField.frame.size.height)];
            [_btnShare setFrame:CGRectMake(_btnShare.frame.origin.x, 390, _btnShare.frame.size.width, _btnShare.frame.size.height)];
        }];
    }
}

@end
