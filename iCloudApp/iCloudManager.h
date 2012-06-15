//
//  iCloudManager.h
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iCloudManager : NSObject
@property (nonatomic, strong) NSURL *iCloudURL;

+ (iCloudManager*) shared;
+ (BOOL) isiCloudAvailabled;

- (void) setObject:(id)object forKey:(NSString *)key;

@end

extern NSString * iCloudManagerNeedToUpdateSettingsNotification;
extern NSString * iCloudManagerNeedToUpdateListNotification;