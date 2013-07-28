//
//  AMYServer.h
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF.h>
#import "AMYRequest.h"

@interface AMYServer : KIFTestActor

@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSArray *pendingURLRequests;

- (AMYRequest *)waitForRequestMatchingBlock:(KIFTestStepResult (^)(NSURLRequest *request, NSError **error))block;
- (void)waitForRequestMatchingMocktail:(NSString *)mocktail withHTTPBodyMatchingBlock:(KIFTestStepResult (^)(NSData *body, NSError **error))block andRespondWithValues:(NSDictionary *)values;
- (void)waitForRequestMatchingMocktail:(NSString *)mocktail andRespondWithValues:(NSDictionary *)values;

- (void)start;
- (void)stop;

@end
