//
//  Pseudo.h
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Pseudo : NSManagedObject

@property (nonatomic, retain) NSString * nom;
@property (nonatomic, retain) NSNumber * age;

@end
