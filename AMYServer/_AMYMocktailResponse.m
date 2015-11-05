//
//  MocktailResponse.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <Foundation/Foundation.h>
#import "_AMYMocktailResponse.h"
#import <GRMustache/GRMustache.h>

NSString * const _AMYMocktailFileExtension = @"tail";

@interface _AMYMocktailResponse ()
@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) NSUInteger bodyOffset;
@property (nonatomic, strong) NSDictionary *defaultValues;
@end

@implementation _AMYMocktailResponse

+ (instancetype)responseFromTail:(NSString *)tail bundle:(NSBundle *)bundle error:(NSError **)error
{
    NSURL *mocktailURL = [(bundle ?: [NSBundle mainBundle]) URLForResource:tail withExtension:_AMYMocktailFileExtension];
    return [self responseFromFileAtURL:mocktailURL error:error];
}

+ (instancetype)responseFromFileAtURL:(NSURL *)url error:(NSError **)error;
{
    if (!url) {
        if (error) {
            *error = [NSError errorWithDomain:@"Mocktail" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Mocktail URL cannot be nil."}];
        }
        return nil;
    }

    NSStringEncoding originalEncoding;
    NSString *contentsOfFile = [NSString stringWithContentsOfURL:url usedEncoding:&originalEncoding error:error];
    if (!contentsOfFile) {
        return nil;
    }

    NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
    NSString *headerMatter = nil;
    [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
    NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
    if ([lines count] < 4) {
        if (error) {
            *error = [NSError errorWithDomain:@"Mocktail" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invalid amount of lines: %u", (unsigned)[lines count]]}];
        }
        return nil;
    }
    
    _AMYMocktailResponse *response = [[self alloc] init];
    response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    response.statusCode = [lines[2] integerValue];
    NSMutableDictionary *headers = @{@"Content-Type":lines[3]}.mutableCopy;
    
    // From line 5 to '\n\n', expect HTTP response headers.
    NSRegularExpression *headerPattern = [NSRegularExpression regularExpressionWithPattern:@"^([^:]+):\\s+(.*)" options:0 error:NULL];
    for (NSUInteger line = 4; line < lines.count; line ++) {
        NSString *headerLine = lines[line];
        NSTextCheckingResult *match = [headerPattern firstMatchInString:headerLine options:0 range:NSMakeRange(0, headerLine.length)];
        
        if (match) {
            NSString *key = [headerLine substringWithRange:[match rangeAtIndex:1]];
            NSString *value = [headerLine substringWithRange:[match rangeAtIndex:2]];
            headers[key] = value;
        } else {
            if (error) {
                *error = [NSError errorWithDomain:@"Mocktail" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invalid header line: %@", headerLine]}];
            }
            return nil;
        }
    }
    
    response.headers = headers.copy;
    response.fileURL = url;
    response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    return response;
}

- (BOOL)matchesURL:(NSURL *)URL method:(NSString *)method patternLength:(NSUInteger *)patternLength;
{
    NSString *absoluteURL = [URL absoluteString];

    if ([self.absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
        if ([self.methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
            if (patternLength) {
                *patternLength = self.absoluteURLRegex.pattern.length;
            }
            return YES;
        }
    }

    return NO;
}

- (NSDictionary *)defaultValuesWithError:(NSError **)error;
{
    if (self.defaultValues) {
        return self.defaultValues;
    }
        
    NSURL *defaultValuesURL = [self.fileURL URLByAppendingPathExtension:@"defaults.json"];
    NSData *JSONData = [NSData dataWithContentsOfURL:defaultValuesURL];
    
    if (!JSONData) {
        self.defaultValues = @{};
        return self.defaultValues;
    }
    
    self.defaultValues = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:error];
    return self.defaultValues;
}

NSDictionary *_mocktailMergedDictionary(NSDictionary *dest, NSDictionary *src)
{
    NSMutableDictionary *result = dest.mutableCopy;
    
    [src enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        id destObj = dest[key];
        
        if (!destObj) {
            result[key] = obj;
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            result[key] = _mocktailMergedDictionary(destObj, obj);
        } else if ([obj isKindOfClass:[NSArray class]] && [(NSArray *)obj count]) {
            NSMutableArray *items = @[].mutableCopy;
            for (NSDictionary *item in destObj) {
                [items addObject:_mocktailMergedDictionary(item, obj[0])];
            }
            result[key] = items;
        }
    }];
    
    return result.copy;
}


- (NSDictionary *)headersWithValues:(NSDictionary *)values error:(NSError **)error;
{
    NSDictionary *defaultValues = [self defaultValuesWithError:error];
    if (!defaultValues) {
        return nil;
    }
    values = _mocktailMergedDictionary(values ?: @{}, defaultValues);
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *transformedObj = [GRMustacheTemplate renderObject:values fromString:obj error:error];
        headers[key] = transformedObj ?: obj;
    }];
    return headers.copy;
}

- (NSData *)bodyWithValues:(NSDictionary *)values error:(NSError **)error;
{
    NSDictionary *defaultValues = [self defaultValuesWithError:error];
    if (!defaultValues) {
        return nil;
    }
    values = _mocktailMergedDictionary(values ?: @{}, defaultValues);
    
    NSData *body = [NSData dataWithContentsOfURL:self.fileURL];
    body = [body subdataWithRange:NSMakeRange(self.bodyOffset, body.length - self.bodyOffset)];

    // Replace placeholders with values. We transform the body data into a string for easier search and replace.
    if ([values count] > 0) {
        NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        NSString *renderedBodyString = [GRMustacheTemplate renderObject:values fromString:bodyString error:error];
        if (!renderedBodyString) {
            return nil;
        }
        body = [renderedBodyString dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([self.headers[@"Content-Type"] hasSuffix:@";base64"]) {
        NSString *type = self.headers[@"Content-Type"];
        NSString *newType = [type substringWithRange:NSMakeRange(0, type.length - 7)];
        self.headers = @{@"Content-Type":newType};
        body = [self dataByDecodingBase64Data:body];
    }
    return body;
}

- (NSData *)body;
{
    return [self bodyWithValues:nil error:NULL];
}

- (NSData *)dataByDecodingBase64Data:(NSData *)encodedData;
{
    if (!encodedData) {
        return nil;
    }
    if (!encodedData.length) {
        return [NSData data];
    }

    static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    static char *decodingTable = NULL;
    if (!decodingTable) {
        @synchronized([self class]) {
            if (!decodingTable) {
                decodingTable = malloc(256);
                if (!decodingTable) {
                    return nil;
                }

                memset(decodingTable, CHAR_MAX, 256);
                for (char i = 0; i < 64; i++) {
                    decodingTable[(short)encodingTable[i]] = i;
                }
            }
        }
    }

    const char *characters = [encodedData bytes];
    if (!characters) {
        return nil;
    }

    char *bytes = malloc(((encodedData.length + 3) / 4) * 3);
    if (!bytes) {
        return nil;
    }

    NSUInteger length = 0;
    NSUInteger characterIndex = 0;

    while (YES) {
        char buffer[4];
        short bufferLength;

        for (bufferLength = 0; bufferLength < 4 && characterIndex < encodedData.length; characterIndex++) {
            if (characters[characterIndex] == '\0') {
                break;
            }
            if (isblank(characters[characterIndex]) || characters[characterIndex] == '=' || characters[characterIndex] == '\n' || characters[characterIndex] == '\r') {
                continue;
            }

            // Illegal character!
            buffer[bufferLength] = decodingTable[(short)characters[characterIndex]];
            if (buffer[bufferLength++] == CHAR_MAX) {
                free(bytes);
                [[NSException exceptionWithName:@"InvalidBase64Characters" reason:@"Invalid characters in base64 string" userInfo:nil] raise];

                return nil;
            }
        }

        if (bufferLength == 0) {
            break;
        }
        if (bufferLength == 1) {
            // At least two characters are needed to produce one byte!
            free(bytes);
            [[NSException exceptionWithName:@"InvalidBase64Length" reason:@"Invalid base64 string length" userInfo:nil] raise];
            return nil;
        }

        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2) {
            bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
        }
        if (bufferLength > 3) {
            bytes[length++] = (buffer[2] << 6) | buffer[3];
        }
    }

    realloc(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

@end
