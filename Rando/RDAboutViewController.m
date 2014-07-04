//
//  RDAboutViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-21.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDAboutViewController.h"
#import "RDFeedbackViewController.h"

@interface RDAboutViewController ()

@end

@implementation RDAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"关于";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* commonCellIdentify = @"aboutCommonCellIdentify";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:commonCellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:commonCellIdentify];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"评分";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"意见反馈";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

#pragma mark -UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 180;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 180)];
    
    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(105, 20, 110, 110)];
    [icon setImage:[UIImage imageNamed:@"icon"]];
    icon.layer.masksToBounds = YES;
    icon.layer.cornerRadius = 6.0;
    [view addSubview:icon];
    
    UILabel *version = [[UILabel alloc] initWithFrame:CGRectMake(105, 140, 110, 30)];
    [version setTextAlignment:NSTextAlignmentCenter];
    NSString *kVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    [version setText:[NSString stringWithFormat:@"漂流 v%@", kVersion]];
    [view addSubview:version];
    
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/id667263240"];
        [[UIApplication sharedApplication]openURL:url];
    } else if (indexPath.row == 1) {
        RDFeedbackViewController *feedbackViewController = [[RDFeedbackViewController alloc] init];
        [self.navigationController pushViewController:feedbackViewController animated:YES];
    }
}

@end
