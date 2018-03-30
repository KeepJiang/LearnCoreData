//
//  MultithreadingVC.m
//  LearnCoreData
//
//  Created by JZW on 2018/3/30.
//  Copyright © 2018年 Beijing yinzhibang Technology. All rights reserved.
//

#import "MultithreadingVC.h"
#import <CoreData/CoreData.h>
#import "Teacher+CoreDataClass.h"
#import "AppDelegate.h"
#define kEntityName @"Teacher"

@interface MultithreadingVC ()
/*! @brief 主队列管理对象上下文 */
@property(nonatomic, strong) NSManagedObjectContext *mainMOContext;
/*! @brief 子线程管理对象上下文 */
@property(nonatomic, strong) NSManagedObjectContext *privateMOContext;
/*! @brief UIApplication delegate  */
@property(nonatomic, weak) AppDelegate *appDelegate;
/*! @brief teacher数组 */
@property(nonatomic, strong) NSArray *teachers;
/*! @brief 子线程上下文保存监听者 */
@property(nonatomic, strong) id observer;
@end

@implementation MultithreadingVC
#pragma mark -getter & setter
- (AppDelegate *)appDelegate{
    if (nil == _appDelegate) {
        _appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    }
    return _appDelegate;
}

- (NSManagedObjectContext *)mainMOContext {
    if (!_mainMOContext) {
        NSLog(@"%s",__func__);
        //初始化托管对象上下文，指定初始化类型，设置存储对象解析器
        _mainMOContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainMOContext.persistentStoreCoordinator = self.appDelegate.psCoordinator;
    }
    return _mainMOContext;
}
#pragma mark -lifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -mark 数据库操作
- (IBAction)dataBaseOption:(UIButton *)button {
    //    NSLog(@"按钮点击");
    switch (button.tag) {
        case 0:
            [self testCoredataMultiThread1]; // coredata多线程(使用通知)
            break;
        case 1:
            [self testCoredataMultiThread2]; // coredata多线程（两层设计）
            break;
        case 2:
            [self testCoredataMultiThread3]; // coredata多线程（三层设计）
            break;
    }
}

#pragma mark -private functions
/**
 查询所有的老师
 @return 老师数组
 */
- (NSArray *)queryAllTeachers{
    NSLog(@"%s",__func__);
    //查询出数据库中所有的music记录
    //1、初始化抓去请求
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kEntityName];
    //2、设置抓取条件
    NSError *error;
    //3、利用context执行抓取
    NSArray *teachers = [self.mainMOContext executeFetchRequest:fetchRequest error:&error];
    
    [teachers enumerateObjectsUsingBlock:^(Teacher *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"Teacher: id = %d, name = %@", obj.teacherId, obj.teacherName);
    }];
    if (error) {
        NSLog(@"%s query error --%@",__func__,error);
    }
    return teachers;
}

/**
 获取当前数据库teacher表的最大ID
 @return 最大ID
 */
- (NSInteger)getMaxTeacherId{
    int maxId = 0;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kEntityName];
    NSSortDescriptor *sortIdDescriptor = [[NSSortDescriptor alloc] initWithKey:@"teacherId" ascending:YES];
    fetchRequest.sortDescriptors = @[sortIdDescriptor];
    NSArray *array = [self.mainMOContext executeFetchRequest:fetchRequest error:nil];
    
    maxId = [[array lastObject] teacherId] + 1;
    
    return maxId;
}

/**
 通知模式多线程
 */
- (void)testCoredataMultiThread1 {
    NSLog(@"%s",__func__);
    //1、新建一个托管对象上下文，用私有化并列队列模式初始化
    self.privateMOContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //2、设置跟主队列上下文使用同一个持久化存储解析器
    self.privateMOContext.persistentStoreCoordinator = self.mainMOContext.persistentStoreCoordinator;
    
    //3、设置监听通知
    NSLog(@"%@",[NSOperationQueue currentQueue]);
    self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                                      object:self.privateMOContext queue:[NSOperationQueue currentQueue]
                                                                  usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"usingBlock----%@",[NSThread currentThread]);
        if (note.object == self.privateMOContext) {
            //回到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"dispatch_async----%@",[NSThread currentThread]);
                [self.mainMOContext performBlock:^{
                    NSLog(@"self.mainMOContext performBlock----%@",[NSThread currentThread]);
                    [self.mainMOContext mergeChangesFromContextDidSaveNotification:note];
                    self.teachers = [self queryAllTeachers];
                }];
            });
            
        }
    }];
    //获取当前数据库中teacher表的最大ID
    NSInteger i = [self getMaxTeacherId];
    //进行数据库耗时操作
    for (int j = 0; j < 500; ++j) {
        Teacher* teacher = [NSEntityDescription insertNewObjectForEntityForName:kEntityName
                                                         inManagedObjectContext:self.privateMOContext];
        NSInteger teacherId = i + j;
        teacher.teacherId = teacherId;
        teacher.teacherName = [NSString stringWithFormat:@"老师%ld", teacherId];
    }
    
    [self.privateMOContext performBlock:^{
        NSLog(@"self.privateMOContext performBlock-----%@",[NSThread currentThread]);
        NSError *error;
        if (self.privateMOContext.hasChanges) {
            if([self.privateMOContext save:&error]){
                NSLog(@"操作成功");
            }else{
                NSLog(@"error:%@",error);
            }
        }
    }];
    
}

/**
 父子Context两层多线程
 */
- (void)testCoredataMultiThread2 {
    NSLog(@"%s",__func__);
    //1、新建一个托管对象上下文，用私有化并列队列模式初始化
    self.privateMOContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    self.privateMOContext.parentContext = self.mainMOContext;
    
    //获取当前数据库中teacher表的最大ID
    NSInteger i = [self getMaxTeacherId];
    //进行数据库耗时操作
    for (int j = 0; j < 500; ++j) {
        Teacher* teacher = [NSEntityDescription insertNewObjectForEntityForName:kEntityName
                                                         inManagedObjectContext:self.privateMOContext];
        NSInteger teacherId = i + j;
        teacher.teacherId = teacherId;
        teacher.teacherName = [NSString stringWithFormat:@"老师%ld", teacherId];
    }
    
    // 私有队列的MOC和主队列的MOC，在执行save操作时，都应该调用performBlock:方法，在自己的队列中执行save操作。
    // 私有队列的MOC执行完自己的save操作后，还调用了主队列MOC的save方法，来完成真正的持久化操作，否则不能持久化到本地
    [self.privateMOContext performBlock:^{
        NSLog(@"self.privateMOContext performBlock-----%@",[NSThread currentThread]);
        NSError *error;
        if (self.privateMOContext.hasChanges) {
            if([self.privateMOContext save:&error]){
                NSLog(@"操作成功");
            }else{
                NSLog(@"error:%@",error);
            }
            [self.mainMOContext performBlock:^{
                [self.mainMOContext save:nil];
                [self queryAllTeachers];
            }];
        }
    }];
    
}
/**
 父子Context三层多线程
 */
- (void)testCoredataMultiThread3 {
    NSLog(@"%s",__func__);
    //1、新建两个托管对象上下文，用私有化并列队列模式初始化
    NSManagedObjectContext *privateMOContext1 = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    NSManagedObjectContext *privateMOContext2 = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    NSManagedObjectContext *mainMOContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
    privateMOContext2.persistentStoreCoordinator = self.appDelegate.psCoordinator;
    privateMOContext1.parentContext = mainMOContext;
    mainMOContext.parentContext = privateMOContext2;
    
    //获取当前数据库中teacher表的最大ID
    NSInteger i = [self getMaxTeacherId];
    //进行数据库耗时操作
    for (int j = 0; j < 500; ++j) {
        Teacher* teacher = [NSEntityDescription insertNewObjectForEntityForName:kEntityName
                                                         inManagedObjectContext:privateMOContext2];
        NSInteger teacherId = i + j;
        teacher.teacherId = teacherId;
        teacher.teacherName = [NSString stringWithFormat:@"老师%ld", teacherId];
    }
    
    // 私有队列的MOC和主队列的MOC，在执行save操作时，都应该调用performBlock:方法，在自己的队列中执行save操作。
    // 私有队列的MOC执行完自己的save操作后，还调用了主队列MOC的save方法，将数据同步到主线程的context，然后主线程context调用save方法将数据同步到privateMOContext，来完成真正的持久化操作，否则不能持久化到本地
    [privateMOContext1 performBlock:^{
        NSLog(@"privateMOContext1 performBlock-----%@",[NSThread currentThread]);
        if (privateMOContext1.hasChanges) {
            [privateMOContext1 save:nil];
            [mainMOContext performBlock:^{
                NSLog(@"privateMOContext1 performBlock-----%@",[NSThread currentThread]);
                [mainMOContext save:nil];
                [privateMOContext2 performBlock:^{
                    NSLog(@"privateMOContext1 performBlock-----%@",[NSThread currentThread]);
                    [privateMOContext2 save:nil];
                }];
            }];
        }
    }];
    
    [self queryAllTeachers];
}
@end
