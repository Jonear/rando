//
//  RDCameraViewController.h
//  Rando
//
//  Created by 余成海 on 14-3-12.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDCameraViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *SRadius;

- (IBAction)takePictureClick:(id)sender;
- (IBAction)radiusChanged:(id)sender;
- (IBAction)dimissController:(id)sender;
- (IBAction)switchCamera:(id)sender;

@end
