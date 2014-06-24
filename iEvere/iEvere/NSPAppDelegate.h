//
//  NSPAppDelegate.h
//  iEvere
//
//  Created by Nordic Semiconductor on 24/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

@import UIKit;

@interface NSPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
