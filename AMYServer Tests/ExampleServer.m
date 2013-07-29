//
//  ExampleServer.m
//  AMYServer
//
//  Created by Brian Nickel on 7/20/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "ExampleServer.h"

static inline NSString *pendingRequests(ExampleServer *server) {
    NSMutableArray *serviceRequests = [NSMutableArray array];
    for (NSURLRequest *request in server.pendingURLRequests) {
        [serviceRequests addObject:request.URL.lastPathComponent];
    }
    return [serviceRequests componentsJoinedByString:@", "];
}

#define waitForValueAtKeyPath(value, keypath, obj, error) KIFTestWaitCondition([value isEqual:[obj valueForKeyPath:keypath]], error, @"Waiting for %@=%@ in %@", keypath, value, obj)

@implementation ExampleServer

- (NSURL *)baseURL
{
    return [NSURL URLWithString:@"https://example.com/services/"];
}

- (AMYRequest *)waitForServiceRequest:(NSString *)serviceRequest withJSONDataMatchingBlock:(KIFTestStepResult (^)(id json, NSError **error))block
{
    return [self waitForRequestMatchingBlock:^KIFTestStepResult(NSURLRequest *request, NSError **error) {
        
        KIFTestWaitCondition([request.URL.lastPathComponent isEqualToString:serviceRequest], error, @"Could not find request for %@. Found requests for %@.", serviceRequest, pendingRequests(self));
        
        id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:NULL];
        return block(json, error);
    }];
}

- (void)waitForLoginWithUsername:(NSString *)username password:(NSString *)password andRespondWithSuccess:(BOOL)success message:(NSString *)message token:(NSString *)token
{
    AMYRequest *request = [self waitForServiceRequest:@"login.json" withJSONDataMatchingBlock:^KIFTestStepResult(id json, NSError *__autoreleasing *error) {
        waitForValueAtKeyPath(username, @"username", json, error);
        waitForValueAtKeyPath(password, @"password", json, error);
        return KIFTestStepResultSuccess;
    }];
    
    id response = @{@"success": @(success), @"message": message ?: @"", @"token" : token ?: @""};
    
    [request respondWithSatusCode:200 headerFields:@{@"X-Application-Token": response[@"token"]}];
    [request sendData:[NSJSONSerialization dataWithJSONObject:response options:0 error:NULL]];
    [request close];
}

@end
