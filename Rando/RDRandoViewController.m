//
//  RDRandoViewController.m
//  Rando
//
//  Created by 余成海 on 14-3-15.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import "RDRandoViewController.h"
#import "RDImgeCollectionCell.h"
#import "RDModelManager.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "RDDetailImageViewController.h"
#import "RDTabBarViewController.h"

@interface RDRandoViewController ()

@end

@implementation RDRandoViewController
{
    UIImageView *_guideTopView;
    UIImageView *_guideBottomView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"漂流";
        
        _randoImageArray = [[NSMutableArray alloc] init];
        [_randoImageArray setArray:[[RDModelManager shareManager] getAllImageWithMy:NO]];
        
        //上提示
        _guideTopView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 70, 320, 200)];
        [_guideTopView setImage:[UIImage imageNamed:@"guide_top1"]];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchSuccess:) name:noti_FetchSuccess object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveImageToDB) name:noti_APPEnterBackground object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_collectionView reloadData];
    
    if (_randoImageArray.count>0) {
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

- (void)fetchSuccess:(NSNotification *)notification
{
    RDImageModel *image = [notification.userInfo objectForKey:@"imageModel"];
    if (image) {
        [_randoImageArray insertObject:image atIndex:0];
        [_collectionView reloadData];
        [_guideTopView setHidden:YES];
        [_guideBottomView setHidden:YES];
    }
}

- (void)saveImageToDB
{
    for (RDImageModel *image in _randoImageArray) {
        if (image.isUpdate) {
            [[RDModelManager shareManager] updateImage:image];
            image.isUpdate = NO;
        }
    }
}

#pragma -mark CollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _randoImageArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"RDImgeCollectionCell";
    
    RDImgeCollectionCell *cell = (RDImgeCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    RDImageModel *image = [_randoImageArray objectAtIndex:indexPath.row];
    
    [cell.imageView setImageWithURL:[NSURL URLWithString:image.imageUrl]
                   placeholderImage:[UIImage imageNamed:@"defaultImage"]
                            options:SDWebImageRetryFailed
                          completed:nil];
    
    if (!image.isOpen){
        [cell setMask];
    } else {
        [cell clearMask];
    }
    
    return cell;
}

#pragma -mark CollectionView UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    RDImageModel *image = [_randoImageArray objectAtIndex:indexPath.row];
    RDDetailImageViewController *detailImageViewController = [[RDDetailImageViewController alloc] init];
    detailImageViewController.imageArray = _randoImageArray;
    detailImageViewController.thisImage = image;
    detailImageViewController.isMyImage = NO;
    [_navController pushViewController:detailImageViewController animated:YES];
}

@end
