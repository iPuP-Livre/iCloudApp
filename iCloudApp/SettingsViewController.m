//
//  ViewController.m
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import "SettingsViewController.h"
#import "iCloudManager.h"

@interface SettingsViewController ()

@end

#define kSwitch @"switchValue"
#define kSlider @"sliderValue"
#define kTextField @"textFieldValue"

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // On récupère les données depuis la sauvegarde locale
    _switch.on = [[[NSUserDefaults standardUserDefaults] objectForKey:kSwitch] boolValue];
    _slider.value = [[[NSUserDefaults standardUserDefaults] objectForKey:kSlider] floatValue];
    _textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:kTextField];
    
    // On s'abonne aux notifications de iCloud Manager
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudManagerUpdateKeyStore:) name:iCloudManagerNeedToUpdateSettingsNotification object:nil];
    
    // On initialise notre iCloud Manager afin qu'il synchronise les données
    [iCloudManager shared];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];  
    
    // On sauve les données en local mais aussi en ligne si le compte iCloud est activé
    [[iCloudManager shared] setObject:[NSNumber numberWithBool:_switch.isOn] forKey:kSwitch];
    [[iCloudManager shared] setObject:[NSNumber numberWithFloat:_slider.value] forKey:kSlider];
    [[iCloudManager shared] setObject:_textField.text forKey:kTextField];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    // On rétracte le champ de texte
    [textField resignFirstResponder];
    return YES;
}

- (void) iCloudManagerUpdateKeyStore:(NSNotification*)notification
{
    // On récupère la clé de l'objet qui a changé
    NSString *key = [notification object];
    // On récupère localement la valeur de l'objet qui a changé
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    // On met à jour les données, avec un effet animé pour montrer la synchronisation
    if ([key isEqualToString:kSwitch]) {
        [_switch setOn:[object boolValue] animated:YES];
    }
    else if ([key isEqualToString:kSlider]) {
        [_slider setValue:[object floatValue] animated:YES];
    }
    else {
        [_textField setText:object];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:iCloudManagerNeedToUpdateSettingsNotification object:nil];
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

- (IBAction)switchChanged:(id)sender {
}

- (IBAction)sliderChanged:(id)sender {
}
@end
