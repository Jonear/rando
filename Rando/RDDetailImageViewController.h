//
//  RDDetailImageViewController.h
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDImageModel.h"

@interface RDDetailImageViewController : UIViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSMutableArray *imageArray;
@property (strong, nonatomic) RDImageModel *thisImage;
@property (assign, nonatomic) BOOL isMyImage;

@property (weak, nonatomic) IBOutlet UIButton *btnLike;
@property (weak, nonatomic) IBOutlet UIButton *btnReport;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;

- (IBAction)deleteClick:(id)sender;
- (IBAction)reportOrSaveClick:(id)sender;
- (IBAction)likeClick:(id)sender;

@end
