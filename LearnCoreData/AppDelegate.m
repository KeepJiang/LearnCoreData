//
//  AppDelegate.m
//  LearnCoreData
//
//  Created by JiangZongwu on 2017/12/13.
//  Copyright © 2017年 Beijing yinzhibang Technology. All rights reserved.
//

#import "AppDelegate.h"
#define kHomePath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"LearnCoreData"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

#pragma mark -getter & setter
@synthesize managedObjectModel = _managedObjectModel;
@synthesize psCoordinator = _psCoordinator;
@synthesize managedOC = _managedOC;
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
        //3.配置自带迁移选项
        NSDictionary *options =
        @{
          NSMigratePersistentStoresAutomaticallyOption :@YES,
          NSInferMappingModelAutomaticallyOption:@YES
          };
        //4.配置持久化数据存储类型和路径
        [_psCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                     configuration:nil
                                               URL:pathURL
                                           options:options
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
@end
