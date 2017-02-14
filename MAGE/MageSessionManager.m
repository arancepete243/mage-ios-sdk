//
//  MageSessionManager.m
//  mage-ios-sdk
//

#import "MageSessionManager.h"
#import "UserUtility.h"
#import "NSString+Contains.h"
#import "MageServer.h"

NSString * const MAGETokenExpiredNotification = @"mil.nga.giat.mage.token.expired";

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }
    
    return request;
}

@interface MageSessionManager()

@property (nonatomic, strong)  NSString * token;

@end

@implementation MageSessionManager

static MageSessionManager *managerSingleton = nil;

+ (MageSessionManager *) manager {
    
    if (managerSingleton == nil) {
        managerSingleton = [[self alloc] init];
    }

    return managerSingleton;
}

- (id) init {
    if ((self = [super init])) {
        
        AFJSONResponseSerializer *responseJsonSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        responseJsonSerializer.removesKeysWithNullValues = YES;
        
        AFHTTPResponseSerializer *responseHttpSerializer = [AFHTTPResponseSerializer serializer];
        
        AFCompoundResponseSerializer *resposneCompoundSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[responseJsonSerializer, responseHttpSerializer]];
        
        [self setResponseSerializer:resposneCompoundSerializer];
        
        AFJSONRequestSerializer *requestJsonSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
        [requestJsonSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [self setRequestSerializer:requestJsonSerializer];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkRequestDidFinish:)
                                                     name:AFNetworkingTaskDidCompleteNotification
                                                   object:nil];
    }
    return self;
}

-(void) setToken: (NSString *) token{
    _token = token;
    [self setTokenInRequestSerializer:self.requestSerializer];
}

-(void) clearToken{
    [self setToken:nil];
}

-(void) setTokenInRequestSerializer: (AFHTTPRequestSerializer *) requestSerializer{
    [requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", _token] forHTTPHeaderField:@"Authorization"];
}

-(AFHTTPRequestSerializer *) httpRequestSerializer{
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [self setTokenInRequestSerializer:requestSerializer];
    return requestSerializer;
}

- (void)networkRequestDidFinish:(NSNotification *)notification {
    NSURLRequest *request = AFNetworkRequestFromNotification(notification);
    NSURLResponse *response = [notification.object response];
    
    if (!request && !response) {
        return;
    }
    
    NSUInteger responseStatusCode = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        responseStatusCode = (NSUInteger)[(NSHTTPURLResponse *)response statusCode];
        
        // token expired
        if (![[UserUtility singleton] isTokenExpired] && responseStatusCode == 401 && (![[request.URL path] safeContainsString:@"login"] && ![[request.URL path] safeContainsString:@"devices"]) ) {
            [[UserUtility singleton] expireToken];
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGETokenExpiredNotification object:response];
        }
    }
    return;
}
@end