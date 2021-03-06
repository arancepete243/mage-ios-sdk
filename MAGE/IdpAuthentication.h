//
//  GoogleAuthentication.h
//  mage-ios-sdk
//
//  Created by William Newman on 11/5/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Authentication.h"

typedef NS_ENUM(NSInteger, OAuthRequestType) {
    SIGNIN,
    SIGNUP
};

@interface IdpAuthentication : NSObject<Authentication>
@end
