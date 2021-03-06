//
//  ListViewController.m
//  mvmap-iphone
//
//  Created by XHB on 13-9-7.
//  Copyright (c) 2013年 XHB. All rights reserved.
//

#import "ListViewController.h"
#import "HttpClient.h"
#import "ListTableViewCell.h"
#import "ArticleTitleModel.h"
#import "UIImageView+AFNetworking.h"
#import "IIViewDeckController.h"
#import "ContentViewController.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"


@interface ListViewController ()

@property (strong, nonatomic) EGORefreshTableHeaderView *refreshHeaderView;

@property (assign, nonatomic) NSInteger catId;
@property (strong, nonatomic) NSArray *dataArray;

@property (assign, nonatomic) BOOL reloading;

@end

@implementation ListViewController

- (void)dealloc{
    
    [self.dataArray release];
    [self.refreshHeaderView release];
    
    [super dealloc];
}


- (void)viewDidLoad{
    [super viewDidLoad];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont fontWithName:@"FZLanTingHei-DB-GBK" size:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"极客地图";
    self.navigationItem.titleView = titleLabel;
    [titleLabel release];

    UIImage *image = [UIImage imageNamed:@"top_bar_navigation_btn.png"];
    UIButton *forLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    forLeftButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [forLeftButton setBackgroundImage:image forState:UIControlStateNormal];
    [forLeftButton addTarget:self action:@selector(forLeftClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *forLeftButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forLeftButton];
    self.navigationItem.leftBarButtonItem = forLeftButtonItem;
    [forLeftButtonItem release];
    
    
    EGORefreshTableHeaderView *refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
    refreshHeaderView.delegate = self;
    [self.tableView addSubview:refreshHeaderView];
    self.refreshHeaderView = refreshHeaderView;
    [refreshHeaderView release];
    
    [refreshHeaderView refreshLastUpdatedDate];
    
}

- (void)forLeftClick:(id)sender{
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (void)openCategory:(NSInteger)catId{
    if(catId == self.catId){
        return;
    }
    
    self.catId = catId;
    [self loadItemData];
    
}


- (void)loadItemData{
    NSString *url = nil;
    
    if(self.catId > 0){
        url = [NSLocalizedString(@"url.item.byCatId", nil) stringByAppendingString:[NSString stringWithFormat:@"%i",_catId]];
    }else{
        url = NSLocalizedString(@"url.item.top", nil);
    }
    
    NSString *data = [[HttpClient sharedInstance] getUrl:url];
    NSArray *array = [data objectFromJSONString];
    
    NSMutableArray *dataArray = [NSMutableArray arrayWithCapacity:[array count]];
    for(NSDictionary *dict in array){
        
        ArticleTitleModel *model = [[ArticleTitleModel alloc] init];
        model.aid = [[dict objectForKey:@"id"] integerValue];
        model.catId = [[dict objectForKey:@"cat_id"] integerValue];
        model.title = [dict objectForKey:@"title"];
        model.feedName = [dict objectForKey:@"feed_name"];
        model.img = [dict objectForKey:@"img"];;
        [dataArray addObject:model];
        [model release];
    }
    
    self.dataArray = dataArray;
    [self.tableView reloadData];
    
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.dataArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    ListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    
    ArticleTitleModel *model = [self.dataArray objectAtIndex:indexPath.row];
    [cell.imgView setImageWithURL:[NSURL URLWithString:model.img]];
    cell.titleLabel.text = model.title;
    
    return cell;
}


#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [ListTableViewCell getHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ArticleTitleModel *model = [self.dataArray objectAtIndex:indexPath.row];
    if(model){
        
        ContentViewController *contentViewController = [[ContentViewController alloc] init];
        contentViewController.aid = model.aid;
        [self.navigationController pushViewController:contentViewController animated:YES];
        [contentViewController release];
        
    }
}


#pragma mark UIScrollViewDelegate Methods
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

#pragma mark - EGORefreshTableHeaderDelegate
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    self.reloading = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(loadItemData)];
        self.reloading = NO;
        [_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        
    });

}


- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
    return self.reloading;
}


- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
    return [NSDate date];
}


@end
