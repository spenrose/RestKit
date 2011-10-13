//
//  RKAuthenticationExample.h
//  RKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKCatalog.h"

@interface RKAuthenticationExample : UIViewController <RKRequestDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) IBOutlet UIPickerView *pickerView;
@property (nonatomic, retain) IBOutlet UITextField  *URLTextField;
@property (nonatomic, retain) IBOutlet UITextField  *usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField  *passwordTextField;
@property (nonatomic, retain) IBOutlet UIPickerView *authenticationTypePickerView;

// OAuth Outlets
@property (nonatomic, retain) IBOutlet UIButton     *authenticateButton;
@property (nonatomic, retain) IBOutlet UILabel      *OAuthLabel;
@property (nonatomic, retain) IBOutlet UITextField  *consumerKeyOrAccessToken;
@property (nonatomic, retain) IBOutlet UITextField  *consumerSecretOrRefreshToken;
@property (nonatomic, retain) IBOutlet UITextField  *accessToken;
@property (nonatomic, retain) IBOutlet UITextField  *accessTokenSecret;

- (IBAction)sendRequest;
- (IBAction)showAuthenticationWebView:(id)sender;

@end
