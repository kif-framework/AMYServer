//
//  AMYServerTests.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIFTestStepValidation.h>
#import <KIFTestCase.h>
#import "ExampleServer.h"

@interface AMYServerTests : KIFTestCase
@end

@implementation AMYServerTests

- (void)beforeAll
{
    [exampleServer start];
    [tester enterText:@"brian" intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:@"$ecret" intoViewWithAccessibilityLabel:@"Password"];
}

- (void)afterAll
{
    [tester clearTextFromViewWithAccessibilityLabel:@"Username"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Password"];
    [exampleServer stop];
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Log In"];
}

- (void)afterEach
{
}

- (void)testSuccess
{
    [exampleServer waitForLoginWithUsername:@"brian" password:@"$ecret" andRespondWithSuccess:YES message:@"Welcome, Brian" token:@"12345"];
    
    [tester waitForViewWithAccessibilityLabel:@"Welcome, Brian"];
    [tester tapViewWithAccessibilityLabel:@"Close"];
}

- (void)testMissingMocktail
{
    KIFExpectFailure([exampleServer waitForRequestMatchingMocktail:@"logon" andRespondWithValues:@{}]);
}

- (void)testBasicMocktail
{
    [exampleServer waitForRequestMatchingMocktail:@"successful-login" andRespondWithValues:@{@"token": @"1234", @"message": @"Yo, Brian"}];
    
    [tester waitForViewWithAccessibilityLabel:@"Yo, Brian"];
    [tester tapViewWithAccessibilityLabel:@"Close"];
}

- (void)testMocktailWithBodyConditions
{
    [exampleServer waitForRequestMatchingMocktail:@"successful-login" withHTTPBodyMatchingBlock:^KIFTestStepResult(NSData *body, NSError *__autoreleasing *error) {
        id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
        KIFTestWaitCondition([json[@"username"] isEqualToString:@"brian"], error, @"Could not find username");
        return KIFTestStepResultSuccess;
    } andRespondWithValues:@{@"token": @"1234", @"message": @"'Sup, Brian"}];
    
    [tester waitForViewWithAccessibilityLabel:@"'Sup, Brian"];
    [tester tapViewWithAccessibilityLabel:@"Close"];
}


- (void)testMocktailWithFailingBodyConditions
{
    KIFExpectFailure([[exampleServer usingTimeout:0.5] waitForRequestMatchingMocktail:@"successful-login" withHTTPBodyMatchingBlock:^KIFTestStepResult(NSData *body, NSError *__autoreleasing *error) {
        id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
        KIFTestWaitCondition([json[@"username"] isEqualToString:@"joe"], error, @"Could not find username");
        return KIFTestStepResultSuccess;
    } andRespondWithValues:@{}]);
}


@end
