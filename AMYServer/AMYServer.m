//
//  AMYServer.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "AMYServer.h"
#import "_AMYURLProtocol.h"
#import "_AMYMocktailResponse.h"
#import "AMYRequest.h"
#import <NSBundle-KIFAdditions.h>
#import <NSError-KIFAdditions.h>

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

- (void)waitForRequestMatchingMocktail:(NSString *)mocktail andRespondWithValues:(NSDictionary *)values
{
    [self waitForRequestMatchingMocktail:mocktail withHTTPBodyMatchingBlock:nil andRespondWithValues:values];
}

- (void)waitForRequestMatchingMocktail:(NSString *)mocktail withHTTPBodyMatchingBlock:(KIFTestStepResult (^)(NSData *, NSError *__autoreleasing *))block andRespondWithValues:(NSDictionary *)values
{
    NSError *error = nil;
    _AMYMocktailResponse *response = [_AMYMocktailResponse responseFromTail:mocktail bundle:[NSBundle KIFTestBundle] error:&error];
    
    if (error) {
        [self failWithError:[NSError KIFErrorWithUnderlyingError:error format:@"Failed to load mocktail: %@", error.localizedDescription] stopTest:YES];
    }
    
    AMYRequest *request = [self waitForRequestMatchingBlock:^KIFTestStepResult(NSURLRequest *request, NSError *__autoreleasing *error) {
        
        KIFTestWaitCondition([response matchesURL:request.URL method:request.HTTPMethod patternLength:NULL], error, @"Could not find request matching mocktail.");
        
        if (block) {
            return block(request.HTTPBody, error);
        }
        
        return KIFTestStepResultSuccess;
    }];
    
    NSDictionary *headers = [response headersWithValues:values error:&error];
    if (error) {
        [self failWithError:[NSError KIFErrorWithUnderlyingError:error format:@"Failed to generate headers: %@", error.localizedDescription] stopTest:YES];
    }
    
    NSData *body = [response bodyWithValues:values error:&error];
    if (error) {
        [self failWithError:[NSError KIFErrorWithUnderlyingError:error format:@"Failed to generate body: %@", error.localizedDescription] stopTest:YES];
    }
    
    [request respondWithStatusCode:response.statusCode headerFields:headers];
    [request sendData:body];
    [request close];
}

@end
