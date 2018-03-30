//
//  ViewController.m
//  LearnCoreData
//
//  Created by JiangZongwu on 2017/12/13.
//  Copyright © 2017年 Beijing yinzhibang Technology. All rights reserved.
//

#import "ViewController.h"
#import <CoreData/CoreData.h>
#import "Student+CoreDataProperties.h"
#import "LCTableViewController.h"
#import "Grade+CoreDataProperties.h"
#define kHomePath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
#define pageNum 5
/**
 数据库操作类型
 - kCoreDataInsert: 插入
 - kCoreDataDelete: 删除
 - kCoreDataUpdate: 修改
 - kCoreDataQuery:  查询
 */

/**
 数据库操作类型
 - kCoreDataInsert: 插入
 - kCoreDataDelete: 删除
 - kCoreDataUpdate: 修改
 - kCoreDataQuery:  查询
 - kCoreDataBatchUpdate: 批量更新
 - kCoreDataAsynchronousFetching: 异步抓取
 - kCoreDataBatchDelete: 批量删除
 */
typedef NS_OPTIONS(NSInteger, coreDataOption){
    kCoreDataInsert = 0,
    kCoreDataDelete,
    kCoreDataUpdate,
    kCoreDataQuery,
    kCoreDataBatchUpdate,
    kCoreDataAsynchronousFetching,
    kCoreDataBatchDelete,
};

@interface ViewController ()
/*! @brief 数据库模型文件map，映射实体类和数据库表的关系 */
@property(nonatomic, strong) NSManagedObjectModel *managedObjectModel;
/*! @brief 持久化存储协调器，用来处理磁盘持久化数据和实体类对象的相互转化 */
@property(nonatomic, strong) NSPersistentStoreCoordinator *psCoordinator;
/*! @brief 持久化实体类对象管理上下文 */
@property(nonatomic, strong) NSManagedObjectContext *managedOC;
/*! @brief 分页下标 */
@property(nonatomic, assign) NSInteger pageOffset;
@end

@implementation ViewController
#pragma mark - lazyload
- (NSManagedObjectModel *)managedObjectModel{
    if (nil == _managedObjectModel) {
        /**
         *从包的根目录获取到模型文件的url，然后通过模型文件初始化managedObjectModel
         *模型文件的后缀名和在工程中看到的不一样，工程中为@“xcdatamodeld”，真实为@“momd”
         *模型文件本质上是一个苹果自定义的xml文件
         */
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"LearnCoreData"
                                             withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)psCoordinator{
    if (nil == _psCoordinator) {
        //1.使用数据模型初始化
        _psCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        //2.配置底层文件名和保存路径
//        NSString *homePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSURL *pathURL = [NSURL fileURLWithPath:[kHomePath stringByAppendingPathComponent:@"learnCoreData.sql"]];
        //3.配置持久化数据存储类型和路径
        [_psCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                     configuration:nil
                                               URL:pathURL
                                           options:nil
                                             error:nil];
    }
    return _psCoordinator;
}

- (NSManagedObjectContext *)managedOC{
    if (nil == _managedOC) {
        //初始化ManagedObjectContext并选择类型
        _managedOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedOC.persistentStoreCoordinator = self.psCoordinator;
    }
    return _managedOC;
}

#pragma mark - lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"沙盒路径：%@", kHomePath);
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -response & Button functions
- (IBAction)buttonOnClicked:(UIButton *)sender {
    switch (sender.tag) {
        case kCoreDataInsert:
            [self coreDataInsert];
            break;
        case kCoreDataDelete:
            [self coreDataDelete];
            break;
        case kCoreDataUpdate:
            [self coreDataUpdate];
            break;
        case kCoreDataQuery:
            [self coreDataQuery];
            break;
        case kCoreDataBatchUpdate:
            [self batchUpdate];
            break;
        case kCoreDataAsynchronousFetching:
            [self asynchronousFetching];
            break;
        case kCoreDataBatchDelete:
            [self batchDelete];
            break;
        default:
            break;
    }
}
- (IBAction)gotoFRC:(UIButton *)sender {
    LCTableViewController *frcTableVC = [[LCTableViewController alloc] init];
    [self.navigationController pushViewController:frcTableVC animated:YES];
}
#pragma mark -private functions

/**
 使用CoreData进行数据库插入
 */
- (void)coreDataInsert{
    Grade *grade1 = [NSEntityDescription insertNewObjectForEntityForName:@"Grade" inManagedObjectContext:self.managedOC];
    grade1.gradeId = 1;
    grade1.gradeName = @"1班";
    
    Grade *grade2 = [NSEntityDescription insertNewObjectForEntityForName:@"Grade" inManagedObjectContext:self.managedOC];
    grade2.gradeId = 2;
    grade2.gradeName = @"2班";
    for (int i = 0; i < 1000; i++) {
        //+insertNewObjectForEntityForName:inManagedObjectContext:
        //工厂方法，根据给定的 Entity 描述，利用反射生成相应的 NSManagedObject 对象，并插入到 ManagedObjectContext 中
        Student *student = [NSEntityDescription insertNewObjectForEntityForName:@"Student"
                                                         inManagedObjectContext:self.managedOC];
        student.studentId = i;
        student.studentName = [NSString stringWithFormat:@"student%d", i];
        student.studentSex = i % 2;
        if (i < 25) {
            student.grade = grade1;
        }else{
            student.grade = grade2;
        }
        NSError *error;
        //调用MOC的save方法将内存中托管对象变化同步到底层数据库中
        if ([self.managedOC hasChanges]) {
            [self.managedOC save:&error];
            if (error) {
                [self logError:error];
            }
        }
    }
    
}
/**
 使用CoreData进行数据库删除
 */
- (void)coreDataDelete{
    //1.调用NSFetchRequest的方法指定要查询的类，同样使用了反射机制
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
    //2.设置谓词，定义查询条件，这里自定id为『1』的Student
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"studentId = %d", 1];
    //2.1 将通过谓词自定的查询条件赋给查询请求
    fetchRequest.predicate = predicate;
    //3.使用MOC查询到要删除的MO
    NSError *error;
    NSArray *delStudents = [self.managedOC executeFetchRequest:fetchRequest error:&error];
    [self logError:error];
    //4.调用MOC的删除方法进行删除
    for (Student *student in delStudents) {
        [self.managedOC deleteObject:student];
    }
    //5.调用MOC的save方法将内存中托管对象变化同步到底层数据库中
    if ([self.managedOC hasChanges]) {
        [self.managedOC save:&error];
        [self logError:error];
    }
}
/**
 使用CoreData进行数据库更新
 */
- (void)coreDataUpdate{
    //1.调用NSFetchRequest的方法指定要查询的类，同样使用了反射机制
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
    //2.设置谓词，定义查询条件，这里自定id为『1』的Student
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"studentId = %d", 1];
    //2.1 将通过谓词自定的查询条件赋给查询请求
    fetchRequest.predicate = predicate;
    //3.使用MOC查询到要更新的MO
    NSError *error;
    NSArray *upDateStudents = [self.managedOC executeFetchRequest:fetchRequest error:&error];
    [self logError:error];
    //4.直接对MO进行更新
    for (Student *student in upDateStudents) {
        student.studentName = @"student Special";
    }
    //5.调用MOC的save方法将内存中托管对象变化同步到底层数据库中
    if ([self.managedOC hasChanges]) {
        [self.managedOC save:&error];
        [self logError:error];
    }
}
/**
 使用CoreData进行数据库查询
 */
- (void)coreDataQuery{

//    [self queryMatch];
    [self queryAll];
}
/**
 查询全部
 */
- (void)queryAll{
    NSFetchRequest *fetchRequest = [Student fetchRequest];
    NSError *error;
    NSArray *students = [self.managedOC executeFetchRequest:fetchRequest error:&error];
    [self logError:error];
    [self logQueryResults:students];
}
/**
 模糊和多条件查询
 */
- (void)queryMatch{
    //模糊查询
    NSFetchRequest *fetchRequest = [Student fetchRequest];
    //使用通配符做匹配
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"studentName LIKE %@ AND studentSex = %d", @"student*", 0];
    fetchRequest.predicate = predicate;
    NSError *error;
    NSArray *students = [self.managedOC executeFetchRequest:fetchRequest error:&error];
    [self logError:error];
    [self logQueryResults:students];
}
/**
 查询排序和分页
 */
- (void)querySort{
    //1.利用字符串反射，指定要查询的托管对象
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
    //2.指定分页的开始下标
    fetchRequest.fetchOffset = (self.pageOffset++) * pageNum;
    //3.指定每页大小
    fetchRequest.fetchLimit = pageNum;
    //4.使用NSSortDescriptor对象设置排序的字段和升降序
    //id降序
    NSSortDescriptor *sortIdDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"studentId" ascending:NO];
    //性别升序
    NSSortDescriptor *sortSexDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"studentSex" ascending:YES];
    fetchRequest.sortDescriptors = @[sortIdDescriptor, sortSexDescriptor];
    //5.调用MOC执行查询
    NSError *error;
    NSArray *students = [self.managedOC executeFetchRequest:fetchRequest error:&error];
    //6.打印查询结果
    [self logError:error];
    [self logQueryResults:students];
}

/**
 批量更新
 */
- (void)batchUpdate{
    //1.使用批量更新request，指定要批量更新的MO，即数据库表
    NSBatchUpdateRequest *batchUpdateRequest = [NSBatchUpdateRequest batchUpdateRequestWithEntityName:@"Student"];
    //2.初始化查询条件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"studentSex = %d", 1];
    batchUpdateRequest.predicate = predicate;
    //3.通过配置propertiesToUpdate批量修改的属性和和要修改的值，为一个dictionary
    batchUpdateRequest.propertiesToUpdate = @{@"studentName" : @"student", @"studentSex" : @(0)};
    batchUpdateRequest.resultType = NSUpdatedObjectIDsResultType;
    //3.1可以设置批量更新放回的结果集类型,设置后返回结果会存到NSBatchUpdateResult的result属性中
    /**
     *NSStatusOnlyResultType          :默认值，只返回批量更新的结果 YES：成功 / NO : 失败
     *NSUpdatedObjectIDsResultType    :返回批量更新后的MO id数组
     *NSUpdatedObjectsCountResultType :返回批量更新后的数量
     */
    //4.调用MOC执行批量更新操作
    NSError *error;
    //4.1获取批量更新的结果
    NSBatchUpdateResult *batchUpdateResult = [self.managedOC executeRequest:batchUpdateRequest error:&error];
    if (error) {
        [self logError:error];
    }else{
        NSLog(@"批量更新成功");
        //4.2获取到批量更新的id数组
        id managedObjectIds = batchUpdateResult.result;
        //4.3遍历id数组
        for (id managedObjectId in managedObjectIds) {
            //4.4通过id获取到托管对象
            NSManagedObject *managedObject = [self.managedOC objectWithID:managedObjectId];
            if (managedObject) {
                __weak typeof(self) weakSelf = self;
                [self.managedOC performBlock:^{
                    //4.5合并数据更新到托管对象
                    [weakSelf.managedOC refreshObject:managedObject mergeChanges:YES];
                }];
            }
        }
         [self queryAll];
    }
}

/**
 异步查询
 */
- (void)asynchronousFetching{
    //1.通过NSFetchRequest指定要查询的托管对象
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
    //2.使用NSFetchRequest初始化NSAsynchronousFetchRequest，指定批量查询的数据，并设置查询完成的回调
    NSAsynchronousFetchRequest *asynchronousFetchRequest = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest completionBlock:^(NSAsynchronousFetchResult * _Nonnull asynchronousFetchResult) {
        if (asynchronousFetchResult.finalResult) {
            NSLog(@"批量查询结果:%@", asynchronousFetchResult.finalResult);
            NSArray *students = asynchronousFetchResult.finalResult;
            NSLog(@"Students: %@", students);
        }
        
    }];
    //3.调用MOC执行异步查询
    NSError *error;
    NSAsynchronousFetchResult *asynchronousFetchResult = [self.managedOC executeRequest:asynchronousFetchRequest error:&error];
    //4.调用普通查询
    [self queryAll];
    //5.调用模糊查询
    [self queryMatch];
    //6.根据打印发现，虽然异步查询在前，但是后最后执行，不会阻塞当前的MOC
    NSLog(@"result；%@", asynchronousFetchResult.finalResult);
}

/**
 批量删除
 */
- (void)batchDelete{
    //1.指定查询的类
    NSFetchRequest *fetchRequest = [Student fetchRequest];
    //2.初始化批量删除request，并通过fetchRequest设置要删除的数据
    NSBatchDeleteRequest *batchDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
    //3.指定批量删除的操作结果
    batchDeleteRequest.resultType = NSStatusOnlyResultType;
    NSError *error;
    NSBatchDeleteResult *batchDeleteResult = [self.managedOC executeRequest:batchDeleteRequest error:&error];
    if ([batchDeleteResult.result boolValue]) {
        NSLog(@"批量删除成功");
    }
}


/**
 打印查询结果
 @param students students
 */
- (void)logQueryResults:(NSArray *)students{
    [students enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Student *student = (Student *)obj;
        NSLog(@"Student:<id: %d, name : %@, sex : %@, grade: %@>",
              student.studentId,
              student.studentName,
              student.studentSex == 0 ? @"男" : @"女",
              student.grade.gradeName);
    }];
}
#pragma mark -logs
/**
 打印错误信息
 @param error error
 */
- (void)logError:(NSError *)error {
    if (error) {
        NSLog(@"error:%@", error.localizedDescription);
    }
}
@end
