//
//  ListTableViewController.m
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import "ListTableViewController.h"
#import "AppDelegate.h"
#import "Pseudo.h"
#import "iCloudManager.h"

@implementation ListTableViewController
@synthesize moc = _moc;

- (NSArray*)sortDescriptorsForPseudo
{
    return [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"nom" ascending:YES]];
}

- (void) getAllPseudos
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Pseudo" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:[self sortDescriptorsForPseudo]];
    NSError *error = nil;
    NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects != nil) {
        [_arrayOfPseudos addObjectsFromArray:fetchedObjects];
    } 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Récupération du Managed object context
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.moc = appDelegate.managedObjectContext;
    
    _arrayOfPseudos = [[NSMutableArray alloc] init];
    
    // Récupération des pseudos
    [self getAllPseudos];
    
    // Création du bouton d'ajout d'un nouveau pseudo
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPseudo)];
    self.navigationItem.rightBarButtonItem = add;
}

- (void) addPseudo
{
    Pseudo *pseudo = (Pseudo *)[NSEntityDescription insertNewObjectForEntityForName:@"Pseudo" inManagedObjectContext:self.moc];
    
    pseudo.nom = [NSString stringWithFormat:@"Pseudo %d", [_arrayOfPseudos count]+1];
    pseudo.age = [NSNumber numberWithInt:arc4random()%70];
    
    [_arrayOfPseudos addObject:pseudo];
    
    // Tri du tableau
    [_arrayOfPseudos sortUsingDescriptors:[self sortDescriptorsForPseudo]];
    
    // Petite astuce pour retrouver l'index de l'objet dans le tableau trié
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_arrayOfPseudos indexOfObject:pseudo] inSection:0]; 
    
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
    
    // Sauvegarde
    [self.moc save:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // On s'abonne aux notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateList:) name:iCloudManagerNeedToUpdateListNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // On se désabonne
    [[NSNotificationCenter defaultCenter] removeObserver:self name:iCloudManagerNeedToUpdateListNotification object:nil];
}

- (void) updateList:(NSNotification*)notif
{
    // On récupère le userInfo de la notification. Si il existe, alors c'est un dictionnaire contenant les objets modifiés.
    // S'il n'existe pas, c'est que nous venons de synchroniser pour la première fois la base, il faut donc simplement faire une requète.
    
    NSDictionary *dicModif = [notif userInfo];
    
    NSLog(@"Mise à jour de la liste %@", dicModif);
    
    if ([dicModif isKindOfClass:[NSDictionary class]]) {
        NSSet *added = [dicModif objectForKey:NSInsertedObjectsKey];
        NSSet *deleted = [dicModif objectForKey:NSDeletedObjectsKey];
        NSSet *updated = [dicModif objectForKey:NSUpdatedObjectsKey];
        
        for (NSManagedObjectID *articleID in added)
        {
            Pseudo *pseudoAdded = (Pseudo*)[self.moc objectWithID:articleID];
            if(!pseudoAdded.isFault)
            {
                NSLog(@"Le pseudo %@ vient d'être ajouté", pseudoAdded);
                // On ajoute le pseudo au tableau
                [_arrayOfPseudos addObject:pseudoAdded];
            }
        }
        for (NSManagedObjectID *articleID in deleted)
        {
            Pseudo *pseudoDeleted = (Pseudo*)[self.moc objectWithID:articleID];
            if(!pseudoDeleted.isFault)
            {
                NSLog(@"Le pseudo %@ vient d'être supprimé", pseudoDeleted);
                // On supprime le pseudo
                [_arrayOfPseudos removeObject:pseudoDeleted];
            }
        }
        
        for (NSManagedObjectID *articleID in updated)
        {
            Pseudo *pseudoUpdated = (Pseudo*)[self.moc objectWithID:articleID];
            if(!pseudoUpdated.isFault)
            {
                NSLog(@"Le pseudo %@ vient d'être mis à jour", pseudoUpdated);
            }
        }
        
        // On recharge les données
        [self.tableView reloadData];
        // Notez que l'on pourrait recharger les données avec des animations
    }
    else
    {
        [self getAllPseudos];
        [self.tableView reloadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _arrayOfPseudos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }    
    
    Pseudo *pseudo = [_arrayOfPseudos objectAtIndex:indexPath.row];
    cell.textLabel.text = pseudo.nom;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d ans", [pseudo.age intValue]];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
