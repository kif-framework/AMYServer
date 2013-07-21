//
//  AMYServer.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "AMYServer.h"
#import "_AMYURLProtocol.h"
#import "AMYRequest.h"

@implementation AMYServer

- (NSURL *)baseURL
{
    NSAssert(NO, @"%s must be overridden by subclass %@", __PRETTY_FUNCTION__, NSStringFromClass([self class]));
    return nil;
}

- (NSArray *)pendingURLRequests
{
    return [_AMYURLProtocol pendingURLRequestsMatchingBaseURL:self.baseURL];
}

- (void)start
{
    [_AMYURLProtocol startMonitoringURL:self.baseURL];
}

- (void)stop
{
    [_AMYURLProtocol stopMonitoringURL:self.baseURL];
}

- (AMYRequest *)waitForRequestMatchingBlock:(KIFTestStepResult (^)(NSURLRequest *, NSError **))block
{
    __block AMYRequest *request = nil;
    [self runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        request = [_AMYURLProtocol findAndRemoveRequestMatchingBaseURL:self.baseURL block:block error:error];
        if (!request) {
            if (error && !*error) {
                KIFTestWaitCondition(request, error, @"Could not find request for %@ matching block.", self.baseURL);
            } else {
                return KIFTestStepResultWait;
            }
        }
        return KIFTestStepResultSuccess;
    }];
    return request;
}

@end
