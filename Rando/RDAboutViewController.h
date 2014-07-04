//
//  RDAboutViewController.h
//  Rando
//
//  Created by 余成海 on 14-3-21.
//  Copyright (c) 2014年 Jonear. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDAboutViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
