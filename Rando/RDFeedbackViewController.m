//
//  RDFeedbackViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-21.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDFeedbackViewController.h"
#import "MBProgressHUD.h"
#import "RDModelManager.h"

@interface RDFeedbackViewController ()

@end

@implementation RDFeedbackViewController
{
    BOOL _isSending;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"意见反馈";
        _isSending = NO;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStyleDone target:self action:@selector(sendFeedback)];
    [_textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sendFeedback
{
    if (_textView.text.length > 150 || _textView.text.length < 3) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"意见请再3-150个字内";
        hud.detailsLabelText = @"";
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:TIP_TIME];
    } else if (!_isSending){
        _isSending = YES;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.detailsLabelText = @"意见发送中...";
        [[RDModelManager shareManager] sendMessageToServer:[NSString stringWithFormat:@"[意见]%@", _textView.text]
                                                   success:^(id msg) {
                                                       hud.labelText = @"发送成功";
                                                       hud.detailsLabelText = @"感谢您宝贵的意见，我们将积极改进";
                                                       hud.mode = MBProgressHUDModeText;
                                                       [hud hide:YES afterDelay:TIP_TIME];
                                                       [self performSelector:@selector(quitViewController) withObject:nil afterDelay:TIP_TIME];
                                                   } failure:^(NSError *e) {
                                                       hud.labelText = @"发送成功，请检查网络";
                                                       hud.detailsLabelText = @"";
                                                       hud.mode = MBProgressHUDModeText;
                                                       [hud hide:YES afterDelay:TIP_TIME];
                                                   }];
    }
}

- (void)quitViewController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
