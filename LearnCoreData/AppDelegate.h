//
//  AppDelegate.h
//  LearnCoreData
//
//  Created by JiangZongwu on 2017/12/13.
//  Copyright © 2017年 Beijing yinzhibang Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
/*! @brief 数据库模型文件map，映射实体类和数据库表的关系 */
@property(readonly, strong) NSManagedObjectModel *managedObjectModel;
/*! @brief 持久化存储协调器，用来处理磁盘持久化数据和实体类对象的相互转化 */
@property(readonly, strong) NSPersistentStoreCoordinator *psCoordinator;
/*! @brief 持久化实体类对象管理上下文 */
@property(readonly, strong) NSManagedObjectContext *managedOC;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

