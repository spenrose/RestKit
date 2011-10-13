//
//  RKAuthenticationExample.m
//  RKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2011 Two Toasters. All rights reserved.
//

#import "RKAuthenticationExample.h"
#import <RestKit/Support/RKAlert.h>

enum {
    RKAuthenticationExampleAuthNone = 0,
    RKAuthenticationExampleHTTPAuthRow,
    RKAuthenticationExampleHTTPAuthBasicRow,
    RKAuthenticationExampleOAuth1,
    RKAuthenticationExampleOAuth2
};

@interface RKAuthenticationExampleOAuthDialog : UIViewController <RKOAuth2ClientDelegate>

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) RKOAuth2Client *OAuthClient;
@end

@implementation RKAuthenticationExampleOAuthDialog

@synthesize webView;
@synthesize OAuthClient;

- (void)loadView {
    [super loadView];
    
    // Raise the logging during authentication
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/Network/Queue", RKLogLevelTrace);
    
    self.title = @"Login to Facebook";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Dismiss" 
                                                                               style:UIBarButtonItemStyleDone 
                                                                              target:self 
                                                                              action:@selector(cancel)] autorelease];
    
    webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    [webView release];
    
    OAuthClient = [[RKOAuth2Client alloc] initWithClientID:@"230395497014065" 
                                              clientSecret:@"1190baa4b907b1adc2c53e1d9cacbe9b" 
                                              authorizeURL:[NSURL URLWithString:@"https://www.facebook.com/dialog/oauth"] 
                                                  tokenURL:[NSURL URLWithString:@"https://graph.facebook.com/oauth/access_token"]];
    OAuthClient.redirectURL = [NSURL URLWithString:@"https://www.facebook.com/connect/login_success.html"];
    OAuthClient.delegate = self;
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    
    // Ask Facebook to draw mobile friendly
    NSDictionary *params = [NSDictionary dictionaryWithObject:@"touch" forKey:@"display"];
    [OAuthClient authorizeUsingWebView:webView additionalParameters:params];
}

- (void)cancel {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - RKOAuth2Client

- (void)OAuthClient:(RKOAuth2Client *)client didAcquireAccessToken:(NSString *)token {
    RKAlertWithTitle(@"Access Token Obtained", [NSString stringWithFormat:@"Obtained access token: %@", token]);
}

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithInvalidGrantError:(NSError *)error {
    
}

@end

@implementation RKAuthenticationExample

@synthesize pickerView;
@synthesize URLTextField;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize authenticationTypePickerView;
@synthesize OAuthLabel;
@synthesize consumerKeyOrAccessToken;
@synthesize consumerSecretOrRefreshToken;
@synthesize accessToken;
@synthesize accessTokenSecret;
@synthesize authenticateButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKClient *client = [RKClient clientWithBaseURL:gRKCatalogBaseURL];
        [RKClient setSharedClient:client];
        self.title = @"Authentication";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [pickerView selectRow:1 inComponent:0 animated:YES];
}

/**
 We are constructing our own RKRequest here rather than working with the client.
 It is important to remember that RKClient is really just a factory object for instances
 of RKRequest. At any time you can directly configure an RKRequest instead.
 */
- (void)sendRequest {
    NSURL *URL = [NSURL URLWithString:[URLTextField text]];
    RKRequest *request = [RKRequest requestWithURL:URL delegate:self];
    request.queue = [RKClient sharedClient].requestQueue;
    request.authenticationType = [pickerView selectedRowInComponent:0];
    
    if (request.authenticationType == RKRequestAuthenticationTypeHTTP || request.authenticationType == RKRequestAuthenticationTypeHTTPBasic) {
        request.username = [usernameTextField text];
        request.password = [passwordTextField text];
    } else if (request.authenticationType == RKRequestAuthenticationTypeOAuth1) {
        request.OAuth1AccessToken = [accessToken text];
        request.OAuth1AccessTokenSecret = [accessTokenSecret text];
        request.OAuth1ConsumerKey = [consumerKeyOrAccessToken text];
        request.OAuth1ConsumerSecret = [consumerSecretOrRefreshToken text];
    } else if (request.authenticationType == RKRequestAuthenticationTypeOAuth2) {
        request.OAuth2AccessToken = [consumerKeyOrAccessToken text];
        request.OAuth2RefreshToken = [consumerSecretOrRefreshToken text];
    }
    [request send];
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    RKLogError(@"Load of RKRequest %@ failed with error: %@", request, error);
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    RKLogCritical(@"Loading of RKRequest %@ completed with status code %d. Response body: %@", request, response.statusCode, [response bodyAsString]);
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case RKAuthenticationExampleAuthNone:
            return @"None";
            break;
            
        case RKAuthenticationExampleHTTPAuthRow:
            return @"HTTP Auth";
            break;
        
        case RKAuthenticationExampleHTTPAuthBasicRow:
            return @"HTTP Basic Auth";
            break;
        
        case RKAuthenticationExampleOAuth1:
            return @"OAuth 1.0";
            break;
        
        case RKAuthenticationExampleOAuth2:
            return @"OAuth 2.0";
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (row) {
        case RKAuthenticationExampleAuthNone:
            usernameTextField.hidden = YES;
            passwordTextField.hidden = YES;
            
            OAuthLabel.hidden = YES;
            consumerKeyOrAccessToken.hidden = YES;
            consumerSecretOrRefreshToken.hidden = YES;
            accessToken.hidden = YES;
            accessTokenSecret.hidden = YES;
            authenticateButton.hidden = YES;
            break;
            
        case RKAuthenticationExampleHTTPAuthRow:
        case RKAuthenticationExampleHTTPAuthBasicRow:
            usernameTextField.hidden = NO;
            passwordTextField.hidden = NO;
            
            OAuthLabel.hidden = YES;
            consumerKeyOrAccessToken.hidden = YES;
            consumerSecretOrRefreshToken.hidden = YES;
            accessToken.hidden = YES;
            accessTokenSecret.hidden = YES;
            authenticateButton.hidden = YES;
            break;
        
        case RKAuthenticationExampleOAuth1:
            usernameTextField.hidden = YES;
            passwordTextField.hidden = YES;
            
            OAuthLabel.hidden = NO;
            consumerKeyOrAccessToken.hidden = NO;
            consumerSecretOrRefreshToken.hidden = NO;
            accessToken.hidden = NO;
            accessTokenSecret.hidden = NO;
            
            consumerKeyOrAccessToken.placeholder = @"Consumer Key";
            consumerSecretOrRefreshToken.placeholder = @"Consumer Secret";
            authenticateButton.hidden = YES;
            break;
        
        case RKAuthenticationExampleOAuth2:
            usernameTextField.hidden = YES;
            passwordTextField.hidden = YES;
            
            OAuthLabel.hidden = NO;
            consumerKeyOrAccessToken.hidden = NO;
            consumerSecretOrRefreshToken.hidden = NO;
            accessToken.hidden = YES;
            accessTokenSecret.hidden = YES;
            
            consumerKeyOrAccessToken.placeholder = @"Access Token";
            consumerSecretOrRefreshToken.placeholder = @"Refresh Token";            
            authenticateButton.hidden = NO;
            break;
            
        default:
            break;
    }
}

- (IBAction)showAuthenticationWebView:(id)sender {
    RKAuthenticationExampleOAuthDialog *dialog = [[RKAuthenticationExampleOAuthDialog alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:dialog animated:YES];
//    [self presentModalViewController:dialog animated:YES];
}

@end
