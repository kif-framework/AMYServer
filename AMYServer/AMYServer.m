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
#import <MocktailResponse.h>
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
    NSURL *mocktailURL = [[[[NSBundle KIFTestBundle] resourceURL] URLByAppendingPathComponent:mocktail] URLByAppendingPathExtension:MocktailFileExtension];
    MocktailResponse *response = [MocktailResponse responseFromFileAtURL:mocktailURL];
    
    if (!response) {
        [self failWithError:[NSError KIFErrorWithCode:KIFTestStepResultFailure localizedDescriptionWithFormat:@"Failed to find valid mocktail named %@ at path %@", mocktail, mocktailURL.absoluteString] stopTest:YES];
    }
    
    AMYRequest *request = [self waitForRequestMatchingBlock:^KIFTestStepResult(NSURLRequest *request, NSError *__autoreleasing *error) {
        
        KIFTestWaitCondition([response matchesURL:request.URL method:request.HTTPMethod patternLength:NULL], error, @"Could not find request matching mocktail.");
        
        if (block) {
            return block(request.HTTPBody, error);
        }
        
        return KIFTestStepResultSuccess;
    }];
    
    [request respondWithSatusCode:response.statusCode headerFields:response.headers];
    [request sendData:[response bodyWithValues:values]];
    [request close];
}

@end
