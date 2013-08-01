//
//  MocktailResponse.h
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const _AMYMocktailFileExtension;

@interface _AMYMocktailResponse : NSObject

+ (instancetype)responseFromTail:(NSString *)tail bundle:(NSBundle *)bundle error:(NSError **)error;
+ (instancetype)responseFromFileAtURL:(NSURL *)url error:(NSError **)error;

- (BOOL)matchesURL:(NSURL *)URL method:(NSString *)method patternLength:(NSUInteger *)patternLength;

@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSData *body;

- (NSData *)bodyWithValues:(NSDictionary *)values error:(NSError **)error;
- (NSDictionary *)headersWithValues:(NSDictionary *)values error:(NSError **)error;

@end
