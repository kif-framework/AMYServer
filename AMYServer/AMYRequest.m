//
//  AMYRequest.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "AMYRequest.h"
#import "_AMYURLProtocol.h"

@implementation AMYRequest

- (instancetype)initWithProtocol:(_AMYURLProtocol *)protocol
{
    self = [super init];
    if (self) {
        _protocol = protocol;
    }
    return self;
}

- (NSURLRequest *)URLRequest
{
    return _protocol.request;
}

- (void)respondWithStatusCode:(NSInteger)statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields cacheStoragePolicy:(NSURLCacheStoragePolicy)cacheStoragePolicy
{
    if ([_protocol canRespond]) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.URLRequest.URL statusCode:statusCode HTTPVersion:HTTPVersion headerFields:headerFields];
        [_protocol.client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    }
}

- (void)respondWithStatusCode:(NSInteger)statusCode headerFields:(NSDictionary *)headerFields
{
    [self respondWithStatusCode:statusCode HTTPVersion:@"1.1" headerFields:headerFields cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
}

- (void)sendData:(NSData *)data
{
    if ([_protocol canRespond]) {
        [_protocol.client URLProtocol:_protocol didLoadData:data];
    }
}

- (void)close
{
    if ([_protocol canRespond]) {
        [_protocol.client URLProtocolDidFinishLoading:_protocol];
    }
}

@end
