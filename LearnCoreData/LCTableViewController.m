//
//  LCTableViewController.m
//  LearnCoreData
//
//  Created by JZW on 2018/3/26.
//  Copyright © 2018年 Beijing yinzhibang Technology. All rights reserved.
//

#import "LCTableViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Student+CoreDataProperties.h"
@interface LCTableViewController () <NSFetchedResultsControllerDelegate>
/*! @brief FRC */
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
/*! @brief UIApplication delegate  */
@property(nonatomic, weak) AppDelegate *appDelegate;
@end

NSString * const kFRCTableViewCell = @"frcCell";
@implementation LCTableViewController
#pragma mark -Getter & Setter
- (AppDelegate *)appDelegate{
    if (nil == _appDelegate) {
        _appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return _appDelegate;
}
- (NSFetchedResultsController *)fetchedResultsController{
    if (nil == _fetchedResultsController) {
        //1.使用fetchRequest指定要查询的数据表
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
        fetchRequest.fetchLimit = 50;
        fetchRequest.fetchOffset = 0;
        //2.使用NSSortDescriptor指定查询后的排序条件
        NSSortDescriptor *sortDescroptorName = [NSSortDescriptor sortDescriptorWithKey:@"grade.gradeName"
                                                                         ascending:YES];
        NSSortDescriptor *sortDescroptorId = [NSSortDescriptor sortDescriptorWithKey:@"studentId"
                                                                             ascending:YES];
        fetchRequest.sortDescriptors = @[sortDescroptorName, sortDescroptorId];
        //3.使用fetchRequest初始化NSFetchedResultsController
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.appDelegate.managedOC
                                                                          sectionNameKeyPath:@"grade.gradeName"
                                                                                   cacheName:nil];
    }
    return _fetchedResultsController;
}
#pragma mark -lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"测试FRC";
    //导航栏增加编辑和增加按钮
    UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonOnClick:)];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonOnClick:)];
    UIBarButtonItem *updateBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"更新" style:UIBarButtonItemStylePlain target:self action:@selector(updateButtonOnClick:)];
    self.navigationItem.rightBarButtonItems = @[addBarButtonItem, editBarButtonItem, updateBarButtonItem];
    //注册cell
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kFRCTableViewCell];
    //设置代理并执行FRC抓取
    self.fetchedResultsController.delegate = self;
    [self executeFRCFetch];
    
}
- (void)dealloc{
    self.fetchedResultsController = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    //FRC中封装好了section数组和section标题
    return self.fetchedResultsController.sections[section].indexTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //FRC中封装好了section数组，返回数组长度
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //FRC中封装好了section数组，直接获取相应section的row数量
    return [self.fetchedResultsController.sections objectAtIndex:section].numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //FRC中封装好了直接通过indexPath获取相应的对象
    Student *student = [self.fetchedResultsController objectAtIndexPath:indexPath];
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier];
    }
    // Configure the cell...
    cell.textLabel.text = student.studentName;
//    cell.detailTextLabel.text = student.studentSex == 0 ? @"男" : @"女";

    return cell;
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //用户删除cell时，通过indexPath获取到对应的托管对象，将数据同步到底层
        Student *student = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.appDelegate.managedOC deleteObject:student];
        NSError *error;
        if (![self.appDelegate.managedOC save:&error]) {
            NSLog(@"删除失败: %@", error);
        }
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    //移动cell时，将拖动的cell对应的托管对象数据进行相应修改
    Student *fromStudent = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    Student *toStudent = [self.fetchedResultsController objectAtIndexPath:toIndexPath];
    fromStudent.studentId = toStudent.studentId;
    fromStudent.grade = toStudent.grade;
    NSError *error;
    if (![self.appDelegate.managedOC save:&error]) {
        NSLog(@"移动失败: %@", error);
    }
}

/**下面拖动后修改被改变的数据库表记录的方法，无法解决跨section拖动的问题
 int fromIndex = (int)fromIndexPath.row;
 int toIndex = (int)(!toIndexPath.row ? 0 : toIndexPath.row);
 Student *student = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
 student.studentId = toIndexPath.row;
 NSLog(@"fromIndex:%d, toIndex:%ld", fromIndex, toIndexPath.row);
 if (fromIndex > toIndex) {
 for (int i = toIndex; i < fromIndex; i++) {
 Student *studentM = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
 studentM.studentId = i + 1;
 NSError *error;
 if (![self.appDelegate.managedOC save:&error]) {
 NSLog(@"移动失败: %@", error);
 }
 }
 }else{
 for (int i = fromIndex; i > toIndex; i--) {
 Student *studentM = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
 studentM.studentId = i - 1;
 NSError *error;
 if (![self.appDelegate.managedOC save:&error]) {
 NSLog(@"移动失败: %@", error);
 }
 }
 }
 */

#pragma mark -NSFetchedResultsControllerDelegate
/**
 MOC托管对象将要发生变化
 @param controller FRC
 */
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView beginUpdates];
}
/**
 MOC托管对象将要修改完成
 @param controller FRC
 */
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}
/**
 根据FRC的section返回tableview的分组标题
 @param controller FRC
 @param sectionName 标题值
 @return 修改后的标题值
 */
- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName{
    return [NSString stringWithFormat:@"班级:%@", sectionName];
}
/**
 MOC托管对象修改
 @param controller FRC
 @param anObject 改变的托管对象
 @param indexPath 改变的索引
 @param type 变化类型
 @param newIndexPath 改变后的索引
 */
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(nullable NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath *)newIndexPath{
    switch (type) {
        //插入变化
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView reloadData];
            break;
        //删除变化
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        //移动变化
        case NSFetchedResultsChangeMove:

            break;
        //更新变化
        case NSFetchedResultsChangeUpdate:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            Student *student = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cell.textLabel.text = student.studentName;
            cell.detailTextLabel.text = student.studentSex == 0 ? @"男" : @"女";
            break;
        }
    }
}
/**
 FRC section变化
 @param controller FRC
 @param sectionInfo section信息
 @param sectionIndex section 索引
 @param type 变化类型
 */
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type{
    switch (type) {
        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            
            break;
        case NSFetchedResultsChangeUpdate:
            
            break;
    }
}

#pragma mark -private functions
- (void)editButtonOnClick:(UIBarButtonItem *)barButtonItem{
    [self.tableView setEditing:!self.tableView.editing];
}

/**
 数据库增操作
 @param barButtonItem barButtonItem
 */
- (void)addButtonOnClick:(UIBarButtonItem *)barButtonItem{
    Student *student =  [self.fetchedResultsController.fetchedObjects lastObject];
    Student *insertStudent = [NSEntityDescription insertNewObjectForEntityForName:@"Student"
                                                           inManagedObjectContext:self.appDelegate.managedOC];
    int studentId = student.studentId + 1;
    insertStudent.studentId = studentId;
    insertStudent.studentName = [NSString stringWithFormat:@"student%d", studentId];
//    insertStudent.grade = student.grade;
    insertStudent.studentSex = studentId % 2;
    NSError *error;
    if (![self.appDelegate.managedOC save:&error]) {
        NSLog(@"新增失败: %@", error);
    }
}
/**
 数据库更新操作
 @param barButtonItem barButtonItem
 */
- (void)updateButtonOnClick:(UIBarButtonItem *)barButtonItem{
    Student *student =  [self.fetchedResultsController.fetchedObjects firstObject];
    student.studentName = @"test";
    NSError *error;
    if (![self.appDelegate.managedOC save:&error]) {
        NSLog(@"新增失败: %@", error);
    }
}

/**
 使用FRC执行查询
 */
- (void)executeFRCFetch{
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"查询失败：%@", error);
    }else{
        NSLog(@"查询成功");
    }
}
@end
