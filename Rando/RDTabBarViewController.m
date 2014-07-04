//
//  RDMainViewController.m
//  Rando
//
//  Created by Jonear on 14-3-8.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDTabBarViewController.h"
#import "RDCameraViewController.h"
#import "MBProgressHUD.h"
#import "RDModelManager.h"
#import "RDAboutViewController.h"

@interface RDTabBarViewController ()

@end

@implementation RDTabBarViewController
{
    UIBarButtonItem *_rightBarButtonItem1;
    UIBarButtonItem *_rightBarButtonItem2;
    UIView          *_titleView;
    UILabel         *_titleLabel;
    UILabel         *_starLabel;
    BOOL             _isFetching;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.automaticallyAdjustsScrollViewInsets = NO;
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, PHOTOWIDTH, PHOTOHEIGHT)];
        _scrollView.delegate = self;
        _viewControllers = [[NSMutableArray alloc] init];
        [self.view insertSubview:_scrollView atIndex:0];
        _selectView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 160, 40)];
        [_selectView setBackgroundColor:[UIColor darkGrayColor]];
        [_tabButtonView insertSubview:_selectView atIndex:0];
        _isFetching = NO;
        NSNumber *fetchNumber = [[NSUserDefaults standardUserDefaults] objectForKey:UDFetchNumber];
        if (fetchNumber) {
            _fetchNum = [fetchNumber intValue];
        } else {
            _fetchNum = 1;
        }
        _indexSelectView = -1;
        //系统时间对比
        [self comeEveryDay];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _rightBarButtonItem1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"download"] style:UIBarButtonItemStyleDone target:self action:@selector(fetchImage)];
    _rightBarButtonItem2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload"] style:UIBarButtonItemStyleDone target:self action:@selector(fetchLikeCount)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"about"] style:UIBarButtonItemStyleBordered target:self action:@selector(aboutClick)];
    
    _titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    
    _starLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 45, 120, 14)];
    _starLabel.backgroundColor = [UIColor clearColor];
    _starLabel.textAlignment = NSTextAlignmentCenter;
    _starLabel.font = [UIFont systemFontOfSize:14];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 20, 120, 30)];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    _titleLabel.text = @"漂流";

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveInfo) name:noti_APPEnterBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(comeEveryDay) name:noti_APPEnterForeground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareImageSuccess) name:noti_UploadSuccess object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (UIViewController* controller in _viewControllers) {
        [controller viewWillAppear:animated];
    }
    
    if (_indexSelectView == -1) {
        [self didSelectView:0];
        [self.navigationController.view addSubview:_starLabel];
        [self.navigationController.view addSubview:_titleLabel];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_indexSelectView == 0) {
        [_starLabel setHidden:NO];
        [_titleLabel setHidden:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_starLabel setHidden:YES];
    [_titleLabel setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)comeEveryDay
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:(@"yyyy-MM-dd")];
    NSString *today = [formatter stringFromDate:[NSDate new]];
    
    NSString *lastday = [[NSUserDefaults standardUserDefaults] objectForKey:UDLastDay];
    if (lastday && [lastday isEqualToString:today]) {
        
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:today forKey:UDLastDay];
        [[NSUserDefaults standardUserDefaults] synchronize];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"每日登录"
                                                        message:@"欢迎今日首次登陆，奖励★+1"
                                                       delegate:nil
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:nil];
        [alert show];
        _fetchNum = _fetchNum + 1;
        [self showStar];
    }
}

- (void)setViewControllers:(UIViewController*)firstObj, ...
{
    va_list args;
    va_start(args, firstObj); // scan for arguments after firstObject.
    
    // get rest of the objects until nil is found
    [_viewControllers removeAllObjects];
    for (UIViewController *controller = firstObj; controller != nil; controller = va_arg(args,UIViewController*)) {
        [_viewControllers addObject:controller];
        int newx = (_viewControllers.count - 1) * PHOTOWIDTH + controller.view.frame.origin.x;
        [controller.view setFrame:CGRectMake(newx, controller.view.frame.origin.y, PHOTOWIDTH, PHOTOHEIGHT)];
        [_scrollView addSubview:controller.view];
    }
    
    va_end(args);
    
    if (_scrollView && _viewControllers.count>0) {
        [_scrollView setContentSize:CGSizeMake(PHOTOWIDTH*_viewControllers.count, PHOTOHEIGHT)];
        [_scrollView setPagingEnabled:YES];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
    }
}

- (void)selectViewController:(int)index animated:(BOOL)animated
{
    if (index <= _viewControllers.count) {
        [_scrollView scrollRectToVisible:CGRectMake(PHOTOWIDTH*index, 0, PHOTOWIDTH, PHOTOHEIGHT) animated:animated];
    }
}

- (IBAction)cameraClick:(id)sender {
    RDCameraViewController *viewController = [[RDCameraViewController alloc] init];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)randoViewClick:(id)sender {
    [self selectViewController:0 animated:YES];
    [self didSelectView:0];
}

- (IBAction)myRandoViewClick:(id)sender {
    [self selectViewController:1 animated:YES];
    [self didSelectView:1];
}

- (void)didSelectView:(int)index
{
    UIViewController *controller = [_viewControllers objectAtIndex:index];
    self.title = controller.title;
    
    _indexSelectView = index;
    if (index == 0) {
        self.navigationItem.rightBarButtonItem = _rightBarButtonItem1;
        self.navigationItem.titleView = _titleView;
        [_starLabel setHidden:NO];
        [_titleLabel setHidden:NO];
        [_btnRandoImage setTintColor:[UIColor whiteColor]];
        [_btnMyRando setTintColor:[UIColor lightGrayColor]];

        [UIView animateWithDuration:0.4 animations:^{
            [_selectView setFrame:CGRectMake(0, _selectView.frame.origin.y, _selectView.frame.size.width, _selectView.frame.size.height)];
        }];
        [self showStar];
    } else if(index == 1) {
        self.navigationItem.rightBarButtonItem = _rightBarButtonItem2;
        self.navigationItem.titleView = nil;
        [_starLabel setHidden:YES];
        [_titleLabel setHidden:YES];
        [_btnMyRando setTintColor:[UIColor whiteColor]];
        [_btnRandoImage setTintColor:[UIColor lightGrayColor]];
        [UIView animateWithDuration:0.4 animations:^{
            [_selectView setFrame:CGRectMake(160, _selectView.frame.origin.y, _selectView.frame.size.width, _selectView.frame.size.height)];
        }];
    }

}

- (void)showStar
{
    if (_indexSelectView == 0) {
        NSString *starstr = @"";
        int i;
        _fetchNum = (_fetchNum>5) ? 5 : _fetchNum;
        for (i=0; i<_fetchNum; i++) {
            starstr = [starstr stringByAppendingString:@"★"];
        }
        for (i=0; i<5-_fetchNum; i++) {
            starstr = [starstr stringByAppendingString:@"☆"];
        }
        _starLabel.text = starstr;
    }
}

- (void)fetchImage
{
    if (_isFetching) {
        return;
    }
    if (_fetchNum<=0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"星星已经用完"
                                                        message:@"发张照片试试吧，或者选择明天再来"
                                                       delegate:nil
                                              cancelButtonTitle:@"知道了"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    _isFetching = YES;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"获取图片中";

    [[RDModelManager shareManager] fetchImageFromServer:^(id msg) {
        _fetchNum = _fetchNum - 1;
        [self showStar];
        [hud hide:YES];
        
        _isFetching = NO;
    } failure:^(NSError *error) {
        hud.labelText = @"获取失败，请检查网络";
        hud.detailsLabelText = @"";
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:TIP_TIME];
        
        _isFetching = NO;
    }];
}

- (void)fetchLikeCount
{
    if (_isFetching) {
        return;
    }
    
    _isFetching = YES;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.detailsLabelText = @"更新图片信息";
    
    [[RDModelManager shareManager] fetchMyImagesCountServer:^(id msg) {
        [hud hide:YES];
        _isFetching = NO;
    } failure:^(NSError *error) {
        hud.labelText = @"获取失败，请检查网络";
        hud.detailsLabelText = @"";
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:TIP_TIME];
        
        _isFetching = NO;
    }];
}

- (void)saveInfo
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_fetchNum] forKey:UDFetchNumber];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)shareImageSuccess
{
    _fetchNum = _fetchNum + 1;
    _fetchNum = (_fetchNum>5) ? 5 : _fetchNum;
    [self showStar];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"图片发送成功 ★+1";
    hud.detailsLabelText = @"";
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:TIP_TIME];
}

- (void)aboutClick
{
    RDAboutViewController *aboutViewController = [[RDAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutViewController animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self didSelectView:targetContentOffset->x/PHOTOWIDTH];
}

@end
