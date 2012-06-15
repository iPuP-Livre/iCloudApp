//
//  ViewController.h
//  iCloudApp
//
//  Created by Marian Paul on 09/04/12.
//  Copyright (c) 2012 iPuP SARL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UISwitch *_switch;
    IBOutlet UISlider *_slider;
    IBOutlet UITextField *_textField;
}

@end
