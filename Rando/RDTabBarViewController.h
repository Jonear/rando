//
//  RDMainViewController.h
//  Rando
//
//  Created by Jonear on 14-3-8.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDTabBarViewController : UIViewController <UIScrollViewDelegate>
{
    NSMutableArray *_viewControllers;
}

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *selectView;
@property (assign, nonatomic) int fetchNum;
@property (assign, nonatomic) int indexSelectView;
@property (weak, nonatomic) IBOutlet UIView *tabButtonView;
@property (weak, nonatomic) IBOutlet UIButton *btnRandoImage;
@property (weak, nonatomic) IBOutlet UIButton *btnMyRando;

- (void)selectViewController:(int)index animated:(BOOL)animated;
- (void)setViewControllers:(UIViewController*)firstObj, ... NS_REQUIRES_NIL_TERMINATION;

- (IBAction)cameraClick:(id)sender;
- (IBAction)randoViewClick:(id)sender;
- (IBAction)myRandoViewClick:(id)sender;

@end
