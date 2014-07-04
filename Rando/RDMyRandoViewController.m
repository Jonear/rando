//
//  RDMyRandoViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDMyRandoViewController.h"
#import "RDModelManager.h"
#import "RDImgeCollectionCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "RDImageModel.h"
#import "RDDetailImageViewController.h"

@interface RDMyRandoViewController ()

@end

@implementation RDMyRandoViewController
{
    UIImageView *_guideTopView;
    UIImageView *_guideBottomView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"我的图片";
        _myRandoImageArray = [[NSMutableArray alloc] init];
        [_myRandoImageArray setArray:[[RDModelManager shareManager] getAllImageWithMy:YES]];
        
        //上提示
        _guideTopView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 70, 320, 200)];
        [_guideTopView setImage:[UIImage imageNamed:@"guide_top2"]];
        [self.view addSubview:_guideTopView];
        [_guideTopView setHidden:YES];
        //下提示
        _guideBottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0, PHOTOHEIGHT - 200 - 70, 320, 200)];
        [_guideBottomView setImage:[UIImage imageNamed:@"guide_bottom"]];
        [self.view addSubview:_guideBottomView];
        [_guideBottomView setHidden:YES];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //设置布局
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(CAPTURE_SIZE/2, CAPTURE_SIZE/2)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    flowLayout.minimumLineSpacing = 10;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.footerReferenceSize = CGSizeMake(300, 30);
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView setCollectionViewLayout:flowLayout];
    [_collectionView registerClass:[RDImgeCollectionCell class] forCellWithReuseIdentifier:@"RDImgeCollectionCell"];
    [_collectionView setAllowsMultipleSelection:YES];
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    
    [self reloadTableContentView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadSuccess:) name:noti_UploadSuccess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveImageToDB) name:noti_APPEnterBackground object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchImagesCountSuccess:) name:noti_FetchImagesCountSuccess object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_collectionView reloadData];
    
    if (_myRandoImageArray.count>0) {
        [_guideTopView setHidden:YES];
        [_guideBottomView setHidden:YES];
    } else {
        [_guideTopView setHidden:NO];
        [_guideBottomView setHidden:NO];
    }
}

- (void)reloadTableContentView
{
//    //ios6适配
//    if (!is_ios7) return;
    
    UIEdgeInsets contentInset = _collectionView.contentInset;
    contentInset.top = 64;
    contentInset.bottom = 45;
    [_collectionView setContentInset:contentInset];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)uploadSuccess:(NSNotification *)notification
{
    RDImageModel *image = [notification.userInfo objectForKey:@"imageModel"];
    if (image) {
        [_myRandoImageArray insertObject:image atIndex:0];
        [_collectionView reloadData];
    }
}

- (void)fetchImagesCountSuccess:(NSNotification *)notification
{
    NSArray *ImageIDKeys = [notification.userInfo allKeys];
    
    for (NSString *key in ImageIDKeys) {
        NSNumber *count = [notification.userInfo objectForKey:key];
        for (RDImageModel *image in _myRandoImageArray) {
            if (image.imageID == [key intValue]) {
                if (image.likeNumber != [count intValue]) {
                    image.likeNumber = [count intValue];
                    image.isUpdate = YES;
                }
                break;
            }
        }
    }
    [_collectionView reloadData];
}

- (void)saveImageToDB
{
    for (RDImageModel *image in _myRandoImageArray) {
        if (image.isUpdate) {
            [[RDModelManager shareManager] updateImage:image];
            image.isUpdate = NO;
        }
    }
}

#pragma -mark CollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _myRandoImageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"RDImgeCollectionCell";
    
    RDImgeCollectionCell *cell = (RDImgeCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    RDImageModel *image = [_myRandoImageArray objectAtIndex:indexPath.row];
    [cell.imageView setImageWithURL:[NSURL URLWithString:image.imageUrl] placeholderImage:[UIImage imageNamed:@"defaultImage"]];
//    if (image.likeNumber < 100) {
        [cell showLikeMsg:image.likeNumber];
//    }
    
    return cell;
}

#pragma -mark CollectionView UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    RDImageModel *image = [_myRandoImageArray objectAtIndex:indexPath.row];
    RDDetailImageViewController *detailImageViewController = [[RDDetailImageViewController alloc] init];
    detailImageViewController.imageArray = _myRandoImageArray;
    detailImageViewController.thisImage = image;
    detailImageViewController.isMyImage = YES;
    [_navController pushViewController:detailImageViewController animated:YES];
}

@end
