//
//  AMYMocktailResponseTests.m
//  AMYServer
//
//  Created by Brian Nickel on 8/01/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIFTestStepValidation.h>
#import <KIFTestCase.h>
#import "_AMYMocktailResponse.h"
#import <NSBundle-KIFAdditions.h>

@interface AMYMocktailResponseTests : XCTestCase
@end

@implementation AMYMocktailResponseTests

- (void)testDefaults
{
    _AMYMocktailResponse *response = [_AMYMocktailResponse responseFromTail:@"xml" bundle:[NSBundle KIFTestBundle] error:NULL];
    NSString *body = [[NSString alloc] initWithData:[response bodyWithValues:@{} error:NULL] encoding:NSUTF8StringEncoding];
    XCTAssertTrue([body rangeOfString:@"<items description=\"abc\">"].location != NSNotFound, @"Should have found default.");
    XCTAssertTrue([body rangeOfString:@"<item key=\"k\">v</item>"].location != NSNotFound, @"Should have found default.");
}

- (void)testThatSettingOneValueDoesNotWipeOutAnother
{
    _AMYMocktailResponse *response = [_AMYMocktailResponse responseFromTail:@"xml" bundle:[NSBundle KIFTestBundle] error:NULL];
    NSString *body = [[NSString alloc] initWithData:[response bodyWithValues:@{@"a":@{@"q":@"r"}} error:NULL] encoding:NSUTF8StringEncoding];
    NSLog(@"Body: %@", body);
    XCTAssertTrue([body rangeOfString:@"<items description=\"abc\">"].location != NSNotFound, @"Should have found default.");
    XCTAssertTrue([body rangeOfString:@"<item key=\"k\">v</item>"].location != NSNotFound, @"Should have found default.");
}

- (void)testThatNewValuesOverrideOldOnes
{
    _AMYMocktailResponse *response = [_AMYMocktailResponse responseFromTail:@"xml" bundle:[NSBundle KIFTestBundle] error:NULL];
    NSString *body = [[NSString alloc] initWithData:[response bodyWithValues:@{@"a":@{@"b":@{@"c":@"d"}}} error:NULL] encoding:NSUTF8StringEncoding];
    XCTAssertTrue([body rangeOfString:@"<items description=\"d\">"].location != NSNotFound, @"Should have overridden default for child.");
}

- (void)testThatItemsInAnArrayTreatTheFirstItemAsATemplate
{
    _AMYMocktailResponse *response = [_AMYMocktailResponse responseFromTail:@"xml" bundle:[NSBundle KIFTestBundle] error:NULL];
    NSString *body = [[NSString alloc] initWithData:[response bodyWithValues:@{@"items":@[@{@"key": @"key"}, @{@"value":@"value"}, @{}]} error:NULL] encoding:NSUTF8StringEncoding];
    NSLog(@"Body: %@", body);
    XCTAssertTrue([body rangeOfString:@"<item key=\"key\">v</item>"].location != NSNotFound, @"Should have found 'key' in position 1.");
    XCTAssertTrue([body rangeOfString:@"<item key=\"k\">value</item>"].location != NSNotFound, @"Should have found 'value' in position 2.");
    XCTAssertTrue([body rangeOfString:@"<item key=\"k\">v</item>"].location != NSNotFound, @"Should have found default in position 3.");
}


@end
