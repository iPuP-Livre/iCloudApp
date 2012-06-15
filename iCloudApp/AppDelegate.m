//
//  AppDelegate.m
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import "AppDelegate.h"
#import "ListTableViewController.h"
#import "SettingsViewController.h"
#import "iCloudManager.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    self.tabBarController = [[UITabBarController alloc] init];
    
    UITabBarItem *itemList = [[UITabBarItem alloc] initWithTitle:@"List" image:nil tag:0];
    ListTableViewController *list = [[ListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navList = [[UINavigationController alloc] initWithRootViewController:list];
    navList.tabBarItem = itemList;
    
    UITabBarItem *itemSettings = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:1];
    SettingsViewController *settings = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    UINavigationController *navSettings = [[UINavigationController alloc] initWithRootViewController:settings];
    navSettings.tabBarItem = itemSettings;
    
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navList, navSettings, nil];
    
    self.window.rootViewController = self.tabBarController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc performBlockAndWait:^{
            [moc setPersistentStoreCoordinator: coordinator];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(mergeChangesFrom_iCloud:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
        }];
        __managedObjectContext = moc;
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"iCloudApp" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}


- (BOOL) isExistingDirectory:(NSString *)directory 
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:directory];
    BOOL isDir;
    
    return [fileManager fileExistsAtPath:documentsDir isDirectory:&isDir] && isDir;
}
// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"iCloudApp.sqlite"];
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSPersistentStoreCoordinator* psc = __persistentStoreCoordinator;
    
    // Le traitement qui suit est fait de manière asynchrone, car lors de la première synchronisation, il est possible qu'iCloud mette très longtemps à télécharger les données.
    dispatch_async(dispatch_queue_create("CoreDataiCloudQueue", NULL), ^{
        NSDictionary* options = nil;
        
        if ([iCloudManager isiCloudAvailabled]) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
            NSString* coreDataCloudContent = [[cloudURL path] stringByAppendingPathComponent:@"CoreDataiCloud"];
            cloudURL = [NSURL fileURLWithPath:coreDataCloudContent];
            
            //  C'est ici où l'on active iCloud dans CoreData
            options = [NSDictionary dictionaryWithObjectsAndKeys:@"fr.ipup.iCloudApp.database.1", NSPersistentStoreUbiquitousContentNameKey, cloudURL, NSPersistentStoreUbiquitousContentURLKey, [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,nil];
        }
        else
            options = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                       [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        NSError *error = nil;
        
        [psc lock];
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            NSLog(@"Oups, grosse erreur %@, %@", error, [error userInfo]);
            //abort();
        } 
        
        [psc unlock];
        
        // On envoit une notification demandant au contrôleur de mettre à jour son affichage
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"asynchronously added persistent store!");
            [[NSNotificationCenter defaultCenter] postNotificationName:iCloudManagerNeedToUpdateListNotification object:self userInfo:nil];
        });
    });

    
    return __persistentStoreCoordinator;
}

// Cette notification est susceptible d'être postée depuis un processus secondaire. Il faut donc replacer les appels sur le processus principal
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
	NSManagedObjectContext* moc = [self managedObjectContext];
    
    [moc performBlock:^{
        [self mergeiCloudChanges:notification forContext:moc];
    }];
}

// Cette méthode prend la notification NSPersistentStoreDidImportUbiquitousContentChangesNotification et passe son userInfo dans la nouvelle
// notification envoyée
- (void)mergeiCloudChanges:(NSNotification*)note forContext:(NSManagedObjectContext*)moc {
    // On rassemble les données
    [moc mergeChangesFromContextDidSaveNotification:note]; 
    
    // On poste une nouvelle notification pour mettre à jour les données
    NSNotification* refreshNotification = [NSNotification notificationWithName:iCloudManagerNeedToUpdateListNotification object:self  userInfo:[note userInfo]];
    [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
