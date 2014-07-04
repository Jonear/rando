//
//  RDImgeCollectionCell.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDImgeCollectionCell.h"

@implementation RDImgeCollectionCell
{
    UILabel *_label;
    UIImageView *_likeIcon;
    UILabel *_lblikenum;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CAPTURE_SIZE/2, CAPTURE_SIZE/2)];
        _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CAPTURE_SIZE/2, CAPTURE_SIZE/2)];
        _lblikenum = [[UILabel alloc] initWithFrame:CGRectMake(CAPTURE_SIZE/2-20, CAPTURE_SIZE/2-20, 20, 15)];
        _lblikenum.textColor = [UIColor whiteColor];
        [_lblikenum setShadowColor:[UIColor darkGrayColor]];
        [_lblikenum setShadowOffset:CGSizeMake(1., 1.)];
        [_lblikenum setHidden:YES];
        _likeIcon = [[UIImageView alloc] initWithFrame:CGRectMake(CAPTURE_SIZE/2-40, CAPTURE_SIZE/2-23, 20, 20)];
        [_likeIcon setImage:[UIImage imageNamed:@"like"]];
        [_likeIcon setHidden:YES];
        [self addSubview:_imageView];
        [self addSubview:_lblikenum];
        [self addSubview:_likeIcon];
    }
    return self;
}

- (void)setMask
{
    _label.text = @"点击可以刮开";
    _label.backgroundColor = [UIColor lightGrayColor];
    _label.textColor = [UIColor whiteColor];
    _label.font = [UIFont systemFontOfSize:17];
    _label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_label];
}

- (void)clearMask
{
    [_label removeFromSuperview];
}

- (void)showLikeMsg:(int)count
{
    [_lblikenum setText:[NSString stringWithFormat:@"%d", count]];
    [_lblikenum setHidden:NO];
    [_likeIcon setHidden:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
