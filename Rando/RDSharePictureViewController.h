//
//  RDSharePictureViewController.h
//  Rando
//
//  Created by 余成海 on 14-3-12.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDSharePictureViewController : UIViewController

- (void)setImage:(UIImage*)image;
- (IBAction)dimissController:(id)sender;
- (IBAction)shareImageClick:(id)sender;
- (IBAction)editSignClick:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *btnShare;
@property (weak, nonatomic) IBOutlet UIButton *btnEditSign;

@end
