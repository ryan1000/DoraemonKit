//
//  DoraemonSanboxDetailViewController.m
//  AFNetworking
//
//  Created by yixiang on 2018/6/20.
//

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DoraemonSanboxDetailViewController.h"
#import "DoraemonToastUtil.h"
#import "UIView+Doraemon.h"
#import "Doraemoni18NUtil.h"
#import <QuickLook/QuickLook.h>
#import "DoraemonDBManager.h"
#import "DoraemonDBTableViewController.h"

@interface DoraemonSanboxDetailViewController ()<QLPreviewControllerDelegate,QLPreviewControllerDataSource,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, copy) NSArray *tableNameArray;
@property (nonatomic, strong) UITableView *dbTableNameTableView;

@end

@implementation DoraemonSanboxDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = DoraemonLocalizedString(@"文件预览");
    
    if (self.filePath.length > 0) {
        NSString *path = self.filePath;
        if ([path hasSuffix:@".strings"] || [path hasSuffix:@".plist"]) {
            // 文本文件
            [self setContent:[[NSDictionary dictionaryWithContentsOfFile:path] description]];
        } else if([path hasSuffix:@".DB"] || [path hasSuffix:@".db"] || [path hasSuffix:@".sqlite"] || [path hasSuffix:@".SQLITE"]){
            // 数据库文件
            self.title = DoraemonLocalizedString(@"数据库预览");
            [self browseDBTable];
        } else {
            // 其他文件 尝试使用 QLPreviewController 进行打开
            QLPreviewController *previewController = [[QLPreviewController alloc]init];
            previewController.delegate = self;
            previewController.dataSource = self;
            [self presentViewController:previewController animated:YES completion:nil];
        }
    } else {
        [DoraemonToastUtil showToast:DoraemonLocalizedString(@"文件不存在") inView:self.view];
    }
}

- (void)setContent:(NSString *)text {
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.font = [UIFont systemFontOfSize:12.0f];
    _textView.textColor = [UIColor blackColor];
    _textView.textAlignment = NSTextAlignmentLeft;
    _textView.editable = NO;
    _textView.dataDetectorTypes = UIDataDetectorTypeLink;
    _textView.scrollEnabled = YES;
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.layer.borderColor = [UIColor grayColor].CGColor;
    _textView.layer.borderWidth = 2.0f;
    _textView.text = text;
    if (@available(iOS 13.0, *)) {
        _textView.textColor = [UIColor labelColor];
        _textView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        _textView.textColor = [UIColor blackColor];
        _textView.backgroundColor = [UIColor whiteColor];
    }
    [self.view addSubview:_textView];
}

//浏览数据库中所有数据表
- (void)browseDBTable{
    [DoraemonDBManager shareManager].dbPath = self.filePath;
    self.tableNameArray = [[DoraemonDBManager shareManager] tablesAtDB];
    self.dbTableNameTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.doraemon_width, self.view.doraemon_height) style:UITableViewStylePlain];
//    self.dbTableNameTableView.backgroundColor = [UIColor whiteColor];
    self.dbTableNameTableView.delegate = self;
    self.dbTableNameTableView.dataSource = self;
    [self.view addSubview:self.dbTableNameTableView];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableNameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"db_table_name";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }
    cell.textLabel.text = self.tableNameArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *tableName = [self.tableNameArray objectAtIndex:indexPath.row];
    [DoraemonDBManager shareManager].tableName = tableName;
    
    DoraemonDBTableViewController *vc = [[DoraemonDBTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - QLPreviewControllerDataSource, QLPreviewControllerDelegate
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}
- (id)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    return [NSURL fileURLWithPath:self.filePath];
}
- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
    [self leftNavBackClick:nil];
}

@end
