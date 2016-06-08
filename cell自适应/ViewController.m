//
//  ViewController.m
//  cell自适应
//
//  Created by 刘浩浩 on 16/6/8.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

#import "ViewController.h"
#import "AFNetwork3.0/AFNetworking/AFNetworking.h"
#import "UIImageView+WebCache.h"
#import "DataModel.h"

#define PICURL @"http://pic.108tian.com/pic/"
#define VIEWWIDTH self.view.frame.size.width
#define VIEWHEIGHT self.view.frame.size.height

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView *_tableView;
    NSMutableArray *_daraArray;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _daraArray=[[NSMutableArray alloc]init];
    [self loadData];
}
/*
 *下载数据
 *使用AFNetWorking3.0
 */
-(void)loadData
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];//请求
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];//响应
    // 设置超时时间
    manager.requestSerializer.timeoutInterval = 8.f;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/json",@"text/html",@"text/plain",@"application/json",nil];
    
    [manager POST:@"https://api.108tian.com/mobile/v3/SceneDetail?id=528b91c9baf6773975578c5c" parameters:nil progress:^(NSProgress *progress)
     {
         
     } success:^(NSURLSessionDataTask *_Nullable task,id _Nonnull responseObject)
     {
         NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
         NSLog(@"%@",dic);
         NSDictionary *data=[dic objectForKey:@"data"];
         NSDictionary *details=[data objectForKey:@"details"];
         NSArray *paragraph=[details objectForKey:@"paragraph"];
         for (NSDictionary *subDic in paragraph) {
             NSArray *body=[subDic objectForKey:@"body"];
             for (NSDictionary *bodySubDic in body) {
                 DataModel *dataModel=[[DataModel alloc]init];
                 if ([bodySubDic objectForKey:@"text"]!=nil) {
                     dataModel.text=[bodySubDic objectForKey:@"text"];
                 }
                 else
                 {
                     dataModel.url=[[bodySubDic objectForKey:@"img"] objectForKey:@"url"];
                 }
                 [_daraArray addObject:dataModel];
                 
             }
         }
         [self initTableView];
         
         
     }failure:^(NSURLSessionDataTask*_Nullable task,NSError *error)
     {
         NSLog(@"%@",error);
     }];

}
/*
 *
 *UITableView初始化
 *
 */
-(void)initTableView
{
    _tableView=[[UITableView alloc]initWithFrame:CGRectMake(0, 0, VIEWWIDTH, VIEWHEIGHT) style:UITableViewStylePlain];
    _tableView.delegate=self;
    _tableView.dataSource=self;
    [self.view addSubview:_tableView];
    [_tableView reloadData];
}
#pragma mark - UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _daraArray.count ;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DataModel *dataModel=[_daraArray objectAtIndex:indexPath.row];
    if (dataModel.text!=nil) {
        NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:13]};
        CGSize size = [dataModel.text boundingRectWithSize:CGSizeMake(VIEWWIDTH-20, 0) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
        return size.height+10;
    }
    else
    {
        
        CGSize size=[[self class]getImageSizeWithURL:[NSString stringWithFormat:@"%@%@",PICURL,dataModel.url]];
        if (size.width>(VIEWWIDTH-20)) {
            return size.height/(size.width/(VIEWWIDTH-20))+10;
        }
        else
        {
            return size.height*((VIEWWIDTH-20)/size.width)+10;
        }
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentify=@"cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    DataModel *dataModel=[_daraArray objectAtIndex:indexPath.row];
    if (dataModel.text!=nil) {
        NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:13]};
        CGSize size = [dataModel.text boundingRectWithSize:CGSizeMake(VIEWWIDTH-10, 0) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
        UILabel *contentLabel=[[UILabel alloc]initWithFrame:CGRectMake(10, 10, VIEWWIDTH-20, size.height)];
        contentLabel.text=dataModel.text;
        contentLabel.numberOfLines=0;
        contentLabel.textColor=[UIColor blackColor];
        contentLabel.font=[UIFont systemFontOfSize:13];
        [cell.contentView addSubview:contentLabel];
    }
    else
    {
        UIImageView *imageView=[[UIImageView alloc]init];
        [imageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",PICURL,dataModel.url]]];
        CGSize size=[[self class]getImageSizeWithURL:[NSString stringWithFormat:@"%@%@",PICURL,dataModel.url]];
        if (size.width>(VIEWWIDTH-20)) {
            imageView.frame=CGRectMake(10, 10, VIEWWIDTH-20, size.height/(size.width/(VIEWWIDTH-20)));
        }
        else
        {
            imageView.frame=CGRectMake(10, 10, VIEWWIDTH-20, size.height*((VIEWWIDTH-20)/size.width));
        }
        [cell.contentView addSubview:imageView];
    }
    return cell;
}
#pragma mark - 根据图片url获取图片尺寸
+(CGSize)getImageSizeWithURL:(id)imageURL
{
    NSURL* URL = nil;
    if([imageURL isKindOfClass:[NSURL class]]){
        URL = imageURL;
    }
    if([imageURL isKindOfClass:[NSString class]]){
        URL = [NSURL URLWithString:imageURL];
    }
    if(URL == nil)
        return CGSizeZero;                  // url不正确返回CGSizeZero
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    NSString* pathExtendsion = [URL.pathExtension lowercaseString];
    
    CGSize size = CGSizeZero;
    if([pathExtendsion isEqualToString:@"png"]){
        size =  [self getPNGImageSizeWithRequest:request];
    }
    else if([pathExtendsion isEqual:@"gif"])
    {
        size =  [self getGIFImageSizeWithRequest:request];
    }
    else{
        size = [self getJPGImageSizeWithRequest:request];
    }
    if(CGSizeEqualToSize(CGSizeZero, size))                    // 如果获取文件头信息失败,发送异步请求请求原图
    {
        NSData* data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:URL] returningResponse:nil error:nil];
        UIImage* image = [UIImage imageWithData:data];
        if(image)
        {
            size = image.size;
        }
    }
    return size;
}
//  获取PNG图片的大小
+(CGSize)getPNGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=16-23" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 8)
    {
        int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        [data getBytes:&w3 range:NSMakeRange(2, 1)];
        [data getBytes:&w4 range:NSMakeRange(3, 1)];
        int w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4;
        int h1 = 0, h2 = 0, h3 = 0, h4 = 0;
        [data getBytes:&h1 range:NSMakeRange(4, 1)];
        [data getBytes:&h2 range:NSMakeRange(5, 1)];
        [data getBytes:&h3 range:NSMakeRange(6, 1)];
        [data getBytes:&h4 range:NSMakeRange(7, 1)];
        int h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4;
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}
//  获取gif图片的大小
+(CGSize)getGIFImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=6-9" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 4)
    {
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        short w = w1 + (w2 << 8);
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(2, 1)];
        [data getBytes:&h2 range:NSMakeRange(3, 1)];
        short h = h1 + (h2 << 8);
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}
//  获取jpg图片的大小
+(CGSize)getJPGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=0-209" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if ([data length] <= 0x58) {
        return CGSizeZero;
    }
    
    if ([data length] < 210) {// 肯定只有一个DQT字段
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
        [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
        short w = (w1 << 8) + w2;
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
        [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
        short h = (h1 << 8) + h2;
        return CGSizeMake(w, h);
    } else {
        short word = 0x0;
        [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
        if (word == 0xdb) {
            [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
            if (word == 0xdb) {// 两个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0xa5, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0xa6, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0xa3, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0xa4, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            } else {// 一个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            }
        } else {
            return CGSizeZero;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
