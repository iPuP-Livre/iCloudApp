//
//  iCloudManager.m
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import "iCloudManager.h"

@implementation iCloudManager
@synthesize iCloudURL = _iCloudURL;

- (id) init
{
    self = [super init];
    if (self)
    {        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudSettingsDidChanged:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
        
        // Synchronisation des données
        [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    }
    return self;
}

- (void) dealloc
{
    // Désabonnement aux notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
}

- (void) iCloudSettingsDidChanged:(NSNotification*)notification
{
    // On récupère depuis la notification les clés dont les objets ont été modifiés
    NSDictionary* userInfo = [notification userInfo];
    NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    NSInteger reason = -1;
    
    // Si il n'y pas de raisons de changements, pas la peine de continuer
    if (!reasonForChange)
        return;
    
    // On met à jour seulement si les changements proviennent du serveur
    reason = [reasonForChange integerValue];
    
    if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
        (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
        // Si quelque chose est changé, on récupère ces changements, et on met à jour les données localement.

        NSArray* changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        // Attention : la boucle suivante considère que l'on utilise les mêmes clés pour les préférences locales et celles en ligne !
        for (NSString* key in changedKeys) {
            id value = [store objectForKey:key];
            [userDefaults setObject:value forKey:key];
            NSLog(@"clé %@ - valeur %@", key, value);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:iCloudManagerNeedToUpdateSettingsNotification
                                                                object:key];
        }
    }
}

- (void) setObject:(id)object forKey:(NSString *)key
{
    if (object) {
        // Sauvegarde locale
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
        // Sauvegarde dans le nuage
        if ([iCloudManager isiCloudAvailabled]) 
        {
            [[NSUbiquitousKeyValueStore defaultStore] setObject:object forKey:key];
            // Synchronisation : elle pourra ne pas être immédiate, le système choisit lui même quand synchroniser
            [[NSUbiquitousKeyValueStore defaultStore] synchronize];
        }
    }
}

+ (BOOL) isiCloudAvailabled 
{
    [iCloudManager shared].iCloudURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSLog(@"iCloud URL %@",  [iCloudManager shared].iCloudURL);
    if ([iCloudManager shared].iCloudURL) {
        return YES;
    }
    else
        return NO;
}

#pragma mark - singleton
+ (iCloudManager*) shared
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

@end

NSString * iCloudManagerNeedToUpdateSettingsNotification = @"iCloudManagerNeedToUpdateSettingsNotification";
NSString * iCloudManagerNeedToUpdateListNotification = @"iCloudManagerNeedToUpdateListNotification";
