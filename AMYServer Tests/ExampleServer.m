//
//  ExampleServer.m
//  AMYServer
//
//  Created by Brian Nickel on 7/20/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "ExampleServer.h"

@implementation ExampleServer

- (NSURL *)baseURL
{
    return [NSURL URLWithString:@"https://example.com/services/"];
}

- (AMYRequest *)waitForServiceRequest:(NSString *)serviceRequest withJSONDataMatchingBlock:(KIFTestStepResult (^)(id json, NSError **error))block
{
    return [self waitForRequestMatchingBlock:^KIFTestStepResult(NSURLRequest *request, NSError **error) {
        
        KIFTestWaitCondition([request.URL.lastPathComponent isEqualToString:serviceRequest], error, @"Could not find request for %@", serviceRequest);
        
        id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:NULL];
        return block(json, error);
    }];
}

- (void)waitForLoginWithUsername:(NSString *)username password:(NSString *)password andRespondWithSuccess:(BOOL)success message:(NSString *)message token:(NSString *)token
{
    AMYRequest *request = [self waitForServiceRequest:@"login.json" withJSONDataMatchingBlock:^KIFTestStepResult(id json, NSError *__autoreleasing *error) {
        
        NSDictionary *dict = (NSDictionary *)json;
        KIFTestWaitCondition([username isEqualToString:dict[@"username"]], error, @"Waiting for username=%@ in %@", username, dict);
        KIFTestWaitCondition([password isEqualToString:dict[@"password"]], error, @"Waiting for password=%@ in %@", password, dict);
        return KIFTestStepResultSuccess;
    }];
    
    id response = @{@"success": @(success), @"message": message ?: @"", @"token" : token ?: @""};
    
    [request respondWithSatusCode:200 headerFields:nil];
    [request sendData:[NSJSONSerialization dataWithJSONObject:response options:0 error:NULL]];
    [request close];
}

@end
