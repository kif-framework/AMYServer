//
//  _AMYURLProtocol.h
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KIFTestActor.h>

@class AMYRequest;

@interface _AMYURLProtocol : NSURLProtocol

@property (nonatomic, readonly) BOOL canRespond;
@property (nonatomic, readonly) BOOL cancelled;

+ (AMYRequest *)findAndRemoveRequestMatchingBaseURL:(NSURL *)baseURL block:(KIFTestStepResult (^)(NSURLRequest *URLRequest, NSError **error))block error:(NSError **)error;
+ (void)startMonitoringURL:(NSURL *)URL;
+ (void)stopMonitoringURL:(NSURL *)URL;
+ (NSArray *)pendingURLRequestsMatchingBaseURL:(NSURL *)baseURL;

@end
