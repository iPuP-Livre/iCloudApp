//
//  ListTableViewController.h
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListTableViewController : UITableViewController
{
    NSMutableArray *_arrayOfPseudos;
}
@property (nonatomic, strong) NSManagedObjectContext *moc;
@end
