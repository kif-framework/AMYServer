//
//  _AMYURLProtocol.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "_AMYURLProtocol.h"
#import "AMYRequest.h"

#define AMYAssertMainThread() NSAssert([NSThread isMainThread], @"%s must be called from the main thread!", __PRETTY_FUNCTION__)

@implementation _AMYURLProtocol

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client
{
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self class] addRequestForProtocol:self];
        });
    }
    return self;
}

- (void)startLoading
{
    _canRespond = YES;
}

- (void)stopLoading
{
    _canRespond = NO;
    _cancelled = YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b;
{
    return NO;
}

+ (NSCountedSet *)URLs {
    static NSCountedSet *URLs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLs = [[NSCountedSet alloc] init];
    });
    return URLs;
}

+ (NSMutableArray *)pendingRequests
{
    static NSMutableArray *pendingRequests;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pendingRequests = [[NSMutableArray alloc] init];
    });
    return pendingRequests;
}

+ (void)addRequestForProtocol:(_AMYURLProtocol *)protocol
{
    AMYAssertMainThread();
    [[self pendingRequests] addObject:[[AMYRequest alloc] initWithProtocol:protocol]];
}

+ (AMYRequest *)findAndRemoveRequestMatchingBaseURL:(NSURL *)baseURL block:(KIFTestStepResult (^)(NSURLRequest *URLRequest, NSError **error))block error:(NSError **)error
{
    AMYAssertMainThread();
    for (AMYRequest *request in [self pendingRequests]) {
        if ([baseURL isEqual:[self baseURLForRequest:request.URLRequest]] && [request.protocol canRespond] && block(request.URLRequest, error) == KIFTestStepResultSuccess) {
            AMYRequest *strongRequest = request;
            [[self pendingRequests] removeObject:request];
            return strongRequest;
        }
    }
    
    return nil;
}

+ (void)startMonitoringURL:(NSURL *)URL
{
    AMYAssertMainThread();
    if (![self URLs].count) {
        [self registerClass:self];
    }
    
    [[self URLs] addObject:URL];
}

+ (void)stopMonitoringURL:(NSURL *)URL
{
    AMYAssertMainThread();
    [[self URLs] removeObject:URL];
    
    if (![self URLs].count) {
        [self unregisterClass:self];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return [self baseURLForRequest:request] != nil;
}

+ (NSURL *)baseURLForRequest:(NSURLRequest *)request
{
    for (NSURL *URL in [self URLs]) {
        NSString *baseURLString = URL.absoluteString;
        NSString *requestURLString = request.URL.absoluteString;
        if ([requestURLString rangeOfString:baseURLString].location == 0) {
            return URL;
        }
    }
    
    return nil;
}

@end
