//
//  STScratchView.m
//  STScratchView
//
//  Created by Sebastien Thiebaud on 12/17/12.
//  Copyright (c) 2012 Sebastien Thiebaud. All rights reserved.
//

#import "STScratchView.h"

@implementation STScratchView
{
    BOOL _isOpen;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:NO];
        
        _sizeBrush = 10.0;
        _isOpen = NO;
    }
    return self;
}

#pragma mark -
#pragma mark CoreGraphics methods

// Will be called every touch and at the first init
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    UIImage *imageToDraw = [UIImage imageWithCGImage:scratchImage];
    [imageToDraw drawInRect:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
}

// Method to change the view which will be scratched
- (void)setHideView:(UIView *)hideView
{
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
	int bitmapByteCount;
	int bitmapBytesPerRow;

    float scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(hideView.bounds.size, NO, 0);
    [hideView.layer renderInContext:UIGraphicsGetCurrentContext()];
    hideView.layer.contentsScale = scale;
    hideImage = UIGraphicsGetImageFromCurrentImageContext().CGImage;
    UIGraphicsEndImageContext();
    
    size_t imageWidth = CGImageGetWidth(hideImage);
    size_t imageHeight = CGImageGetHeight(hideImage);
        
	bitmapBytesPerRow = (imageWidth * 4);
	bitmapByteCount = (bitmapBytesPerRow * imageHeight);
    
    CFMutableDataRef pixels = CFDataCreateMutable(NULL, imageWidth * imageHeight);
    contextMask = CGBitmapContextCreate(CFDataGetMutableBytePtr(pixels), imageWidth, imageHeight , 8, imageWidth, colorspace, kCGImageAlphaNone);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(pixels);
    
    CGContextSetFillColorWithColor(contextMask, [UIColor blackColor].CGColor);
    CGContextFillRect(contextMask, self.frame);
    
    CGContextSetStrokeColorWithColor(contextMask, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(contextMask, _sizeBrush);
    CGContextSetLineCap(contextMask, kCGLineCapRound);
    
    CGImageRef mask = CGImageMaskCreate(imageWidth, imageHeight, 8, 8, imageWidth, dataProvider, nil, NO);
    scratchImage = CGImageCreateWithMask(hideImage, mask);
    
    CGImageRelease(mask);
    CGColorSpaceRelease(colorspace);
}

- (void)scratchTheViewFrom:(CGPoint)startPoint to:(CGPoint)endPoint
{
    float scale = [UIScreen mainScreen].scale;

    CGContextMoveToPoint(contextMask, startPoint.x * scale, (self.frame.size.height - startPoint.y) * scale);
	CGContextAddLineToPoint(contextMask, endPoint.x * scale, (self.frame.size.height - endPoint.y) * scale);
	CGContextStrokePath(contextMask);
	[self setNeedsDisplay];
    
}

#pragma mark -
#pragma mark Touch event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];
    currentTouchLocation = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];
   
    if (!CGPointEqualToPoint(previousTouchLocation, CGPointZero))
    {
        currentTouchLocation = [touch locationInView:self];
    }
    
    previousTouchLocation = [touch previousLocationInView:self];
   
    [self scratchTheViewFrom:previousTouchLocation to:currentTouchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [[event touchesForView:self] anyObject];

    if (!CGPointEqualToPoint(previousTouchLocation, CGPointZero))
    {
        previousTouchLocation = [touch previousLocationInView:self];
        [self scratchTheViewFrom:previousTouchLocation to:currentTouchLocation];
    }
    
    if (!_isOpen) {
        //发出通知，表示已经有刮动
        [[NSNotificationCenter defaultCenter] postNotificationName:noti_haveOpenMask object:nil];
        _isOpen = YES;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

- (void)initScratch
{
    currentTouchLocation = CGPointZero;
    previousTouchLocation = CGPointZero;
}

@end
