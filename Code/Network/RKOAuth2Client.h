//
//  RKOAuth2Client.h
//  RestKit
//
//  Created by Rodrigo Garcia on 7/20/11.
//  Copyright 2011 RestKit. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "RKClient.h"
#import "RKRequest.h"

/**
 Defines error codes for OAuth client errors
 */
typedef enum RKOAuth2ClientErrors {
    RKOAuth2ClientErrorInvalidGrant              = 3001,     // An invalid authorization code was encountered
    RKOAuth2ClientErrorUnauthorizedClient        = 3002,     // The client is not authorized to perform the action
    RKOAuth2ClientErrorInvalidClient             = 3003,     // 
    RKOAuth2ClientErrorInvalidRequest            = 3004,     // 
    RKOAuth2ClientErrorUnsupportedGrantType      = 3005,     // 
    RKOAuth2ClientErrorInvalidScope              = 3006,     // 
    RKOAuth2ClientErrorRequestError              = 3007      // 
} RKOAuth2ClientErrorCode;

@protocol RKOAuth2ClientDelegate;

/**
 An OAuth client implementation used for OAuth 2 authorization code flow.
 */
@interface RKOAuth2Client : NSObject <RKRequestDelegate> {
	NSString *_clientID;
    NSString *_clientSecret;
	NSString *_authorizationCode;
    NSURL *_authorizationURL;
    NSURL *_callbackURL;
    NSString *_accessToken;
    id<RKOAuth2ClientDelegate> _delegate;
}

/// @name OAuth Client Authentication

/**
 The authorization code issued by the authorization server
 */
@property(nonatomic, retain) NSString *authorizationCode;

/**
 A unique string issued by the authorization server for uniquely 
 identifying the client
 */
@property(nonatomic, retain) NSString *clientID;

/**
 A secret access token for authenticating the client
 */
@property(nonatomic, retain) NSString *clientSecret;

/// @name OAuth Endpoints

// The end-user URL endpoint for authorization???
@property (nonatomic, retain) NSURL *authorizeURL;
@property (nonatomic, retain) NSURL *tokenURL;

// Redirection URL (Web Server Flow)
@property (nonatomic, retain) NSURL *redirectURL;

/**
 Returns the access token retrieved
 */
// TODO: We may want to turn this into an object...
@property (nonatomic, readonly) NSString *accessToken;

// Client Delegate
@property (nonatomic, assign) id<RKOAuth2ClientDelegate> delegate;

+ (RKOAuth2Client *)clientWithClientID:(NSString *)clientID                         
                          clientSecret:(NSString *)clientSecret 
                          authorizeURL:(NSURL *)authorizeURL
                              tokenURL:(NSURL *)tokenURL;

- (id)initWithClientID:(NSString *)clientID
          clientSecret:(NSString *)clientSecret 
          authorizeURL:(NSURL *)authorizeURL
              tokenURL:(NSURL *)tokenURL;

// Actions
- (void)validateAuthorizationCode;

// Get NSURL for external login (Web Server Flow)
// Get NSURLRequest for web login (Web Server Flow)
// authorizeUsingWebView (Web Server Flow)
// authenticateWithUsername:password: (Credentials Flow)
//
// TODO:
// - refreshAccessToken:

@end

/**
 Lifecycle events for RKClientOAuth
 */
@protocol RKOAuth2ClientDelegate <NSObject>
@required

/**
 * Sent when a new access token has being acquired
 */
- (void)OAuthClient:(RKOAuth2Client *)client didAcquireAccessToken:(NSString *)token;

/**
 * Sent when an access token request has failed due an invalid authorization code
 */
- (void)OAuthClient:(RKOAuth2Client *)client didFailWithInvalidGrantError:(NSError *)error;

@optional

/**
 @name OAuth2 Authorization Code Flow Exceptions
 */

/**
 Sent to the delegate when the OAuth client encounters any error
 */
- (void)OAuthClient:(RKOAuth2Client *)client didFailWithError:(NSError *)error;

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithUnauthorizedClientError:(NSError *)error;

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithInvalidClientError:(NSError *)error;

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithInvalidRequestError:(NSError *)error;

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithUnsupportedGrantTypeError:(NSError *)error;

- (void)OAuthClient:(RKOAuth2Client *)client didFailWithInvalidScopeError:(NSError *)error;

/** 
 Sent to the delegate when an authorization code flow request failed loading due to an error
 */
- (void)OAuthClient:(RKOAuth2Client *)client didFailLoadingRequest:(RKRequest *)request withError:(NSError *)error;

@end

@interface RKOAuth2Client (UIWebViewIntegration) <UIWebViewDelegate>
- (void)authorizeUsingWebView:(UIWebView *)webView;
- (void)authorizeUsingWebView:(UIWebView *)webView additionalParameters:(NSDictionary *)additionalParameters;
- (void)extractAccessCodeFromCallbackURL:(NSURL *)url;
@end
