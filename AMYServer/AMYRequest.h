//
//  AMYRequest.h
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class _AMYURLProtocol;

@interface AMYRequest : NSObject

- (instancetype)initWithProtocol:(_AMYURLProtocol *)protocol;

@property (nonatomic, readonly) NSURLRequest *URLRequest;
@property (nonatomic, readonly) _AMYURLProtocol *protocol;

- (void)respondWithSatusCode:(NSInteger) statusCode HTTPVersion:(NSString *)HTTPVersion headerFields:(NSDictionary *)headerFields cacheStoragePolicy:(NSURLCacheStoragePolicy)cacheStoragePolicy;
- (void)respondWithSatusCode:(NSInteger) statusCode headerFields:(NSDictionary *)headerFields;

- (void)sendData:(NSData *)data;

- (void)close;

@end
