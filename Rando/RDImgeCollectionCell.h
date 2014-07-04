//
//  RDImgeCollectionCell.h
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDImgeCollectionCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *imageView;

- (void)setMask;
- (void)clearMask;
- (void)showLikeMsg:(int)count;
@end
