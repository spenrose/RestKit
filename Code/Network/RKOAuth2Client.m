//
//  RKOAuth2Client.m
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

#import "RKOAuth2Client.h"
#import "../Support/Errors.h"
#import "../Support/NSURL+RestKit.h"
#import "../Support/NSDictionary+RKAdditions.h"
#import "../Support/RKLog.h"

@implementation RKOAuth2Client

@synthesize clientID = _clientID;
@synthesize clientSecret = _clientSecret;
@synthesize authorizationCode = _authorizationCode;
@synthesize authorizeURL = _authorizeURL;
@synthesize tokenURL = _tokenURL;
@synthesize redirectURL = _redirectURL;
@synthesize delegate = _delegate;
@synthesize accessToken = _accessToken;

+ (RKOAuth2Client *)clientWithClientID:(NSString *)clientID                         
                          clientSecret:(NSString *)clientSecret 
                          authorizeURL:(NSURL *)authorizeURL
                              tokenURL:(NSURL *)tokenURL {
    return [[[self alloc] initWithClientID:clientID clientSecret:clientSecret authorizeURL:authorizeURL tokenURL:tokenURL] autorelease];
}

- (id)initWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret authorizeURL:(NSURL *)authorizeURL tokenURL:(NSURL *)tokenURL {
    self = [self init];
    if (self) {
        self.clientID = clientID;
        self.clientSecret = clientSecret;
        self.authorizeURL = authorizeURL;
        self.tokenURL = tokenURL;
    }
    
    return self;
}

- (void)dealloc {
    [_clientID release];
    [_clientSecret release];
    [_accessToken release];
    [_authorizeURL release];
    [_tokenURL release];
    [_redirectURL release];
    
    [super dealloc];
}

- (NSURLRequest *)userAuthorizationRequestWithParameters:(NSDictionary *)additionalParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:self.clientID forKey:@"client_id"];
    [parameters setValue:@"code" forKey:@"response_type"];
    // TODO: Should we let you set the response_type?
    // TODO: response_type == code
    [parameters setValue:[self.redirectURL absoluteString] forKey:@"redirect_uri"];
    // @"token", @"response_type",
    if (additionalParameters) {
        [parameters addEntriesFromDictionary:additionalParameters];
    }
    
    // TODO: should have a URLByAppendingQueryParameters: and [NSURL|RKURL URLWithString: queryParameters:];
    NSURL *URL = [NSURL URLWithString:[[self.authorizeURL absoluteString] stringByAppendingFormat:@"?%@", [parameters stringWithURLEncodedComponents]]];
    NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:URL];
    [authRequest setHTTPMethod:@"GET"];
    
    return [[authRequest copy] autorelease];
}

- (void)validateAuthorizationWithAccessCode:(NSString *)accessCode {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.clientID, @"client_id", 
                                self.clientSecret, @"client_secret",                                 
                                self.redirectURL, @"redirect_uri", 
                                accessCode, @"code",                                 
                                @"authorization_code", @"grant_type", nil];
    RKRequest *request = [[RKRequest alloc] initWithURL:self.tokenURL];
    request.delegate = self;
    request.params = parameters;
    request.method = RKRequestMethodPOST;
    [request send];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    NSError *error = nil;
    NSString *errorResponse = nil;
    
    // If the response is plain text, 
    NSDictionary *authorizationData = nil;
    if ([response isText]) {
        authorizationData = [NSDictionary dictionaryWithURLEncodedString:[response bodyAsString]];
    } else {
        authorizationData = (NSDictionary *) [response parsedBody:&error];
    }
         
   if (!authorizationData && error) {
        RKLogWarning(@"Unable to parse OAuth2 authorization response: %@", response);
        return;
    }
    
    if ([authorizationData isKindOfClass:[NSDictionary class]]) {
        
        //Check the if an access token comes in the response
        // TODO: Turn the accessToken into an object...
        // TODO: Should be able to get the refresh token here also...
        _accessToken = [[authorizationData objectForKey:@"access_token"] copy];
        errorResponse = [authorizationData objectForKey:@"error"];
        
        if (_accessToken) {
            // W00T We got an accessToken            
            [self.delegate OAuthClient:self didAcquireAccessToken:_accessToken];
            
            return;
        } else if (errorResponse) {
            // Heads-up! There is an error in the response
            // The possible errors are defined in the OAuth2 Protocol
            
            RKOAuth2ClientErrorCode errorCode;
            NSString *errorDescription = [authorizationData objectForKey:@"error_description"];
            
            if ([errorResponse isEqualToString:@"invalid_grant"]) {
                errorCode = RKOAuth2ClientErrorInvalidGrant;
            }
            else if([errorResponse isEqualToString:@"unauthorized_client"]) {
                errorCode = RKOAuth2ClientErrorUnauthorizedClient;
            }
            else if([errorResponse isEqualToString:@"invalid_client"]) {
                errorCode = RKOAuth2ClientErrorInvalidClient;
            }
            else if([errorResponse isEqualToString:@"invalid_request"]) {
                errorCode = RKOAuth2ClientErrorInvalidRequest;
            }
            else if([errorResponse isEqualToString:@"unsupported_grant_type"]) {
                errorCode = RKOAuth2ClientErrorUnsupportedGrantType;
            }
            else if([errorResponse isEqualToString:@"invalid_scope"]) {
                errorCode = RKOAuth2ClientErrorInvalidScope;
            }
            
            NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorDescription, NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:RKRestKitErrorDomain code:errorCode userInfo:userInfo];
            
            
            // Inform the delegate of what happened
            if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
                [self.delegate OAuthClient:self didFailWithError:error];
            }
            
            // Invalid grant
            if (errorCode == RKOAuth2ClientErrorInvalidGrant && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidGrantError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidGrantError:error];
            }
            
            // Unauthorized client
            if (errorCode == RKOAuth2ClientErrorUnauthorizedClient && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithUnauthorizedClientError:)]) {
                [self.delegate OAuthClient:self didFailWithUnauthorizedClientError:error];
            }
            
            // Invalid client
            if (errorCode == RKOAuth2ClientErrorInvalidClient && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidClientError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidClientError:error];
            }
            
            // Invalid request
            if (errorCode == RKOAuth2ClientErrorInvalidRequest && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidRequestError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidRequestError:error];
            }
            
            // Unsupported grant type
            if (errorCode == RKOAuth2ClientErrorUnsupportedGrantType && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithUnsupportedGrantTypeError:)]) {
                [self.delegate OAuthClient:self didFailWithUnsupportedGrantTypeError:error];
            }
            
            // Invalid scope
            if (errorCode == RKOAuth2ClientErrorInvalidScope && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidScopeError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidScopeError:error];
            }
        }
    } else if (error) {
        if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
            [self.delegate OAuthClient:self didFailWithError:error];
        }
    } else {
        // TODO: Logging...
    }
    
    [request release];
}


- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              error, NSUnderlyingErrorKey, nil];
    NSError *clientError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKOAuth2ClientErrorRequestError userInfo:userInfo];
    if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailLoadingRequest:withError:)]) {
        [self.delegate OAuthClient:self didFailLoadingRequest:request withError:clientError];
    }
    
    if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
        [self.delegate OAuthClient:self didFailWithError:clientError];
    }
    
    [request release];
}

@end

// Portions of this code adapted from LROAuth2
//  Created by Luke Redpath on 14/05/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
@implementation RKOAuth2Client (UIWebViewIntegration)

- (void)authorizeUsingWebView:(UIWebView *)webView {
    [self authorizeUsingWebView:webView additionalParameters:nil];
}

- (void)authorizeUsingWebView:(UIWebView *)webView additionalParameters:(NSDictionary *)additionalParameters {
    [webView setDelegate:self];
    [webView loadRequest:[self userAuthorizationRequestWithParameters:additionalParameters]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {  
    if ([[request.URL absoluteString] hasPrefix:[self.redirectURL absoluteString]]) {
        [self extractAccessCodeFromCallbackURL:request.URL];
        
        return NO;
    }
    
    return YES;
}

/**
 * custom URL schemes will typically cause a failure so we should handle those here
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
    
    if ([failingURLString hasPrefix:[self.redirectURL absoluteString]]) {
        [webView stopLoading];
        [self extractAccessCodeFromCallbackURL:[NSURL URLWithString:failingURLString]];
    }
}

- (void)extractAccessCodeFromCallbackURL:(NSURL *)callbackURL {
    NSString *accessCode = [[callbackURL queryDictionary] valueForKey:@"code"];
    
    // TODO: Add to delegate?
    if ([self.delegate respondsToSelector:@selector(oauthClientDidReceiveAccessCode:)]) {
        [self.delegate oauthClientDidReceiveAccessCode:self];
    }
    [self validateAuthorizationWithAccessCode:accessCode];
}

@end
