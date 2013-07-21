//
//  AMYServerTests.m
//  AMYServer
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIFTestCase.h>
#import "ExampleServer.h"


@interface AMYServerTests : KIFTestCase
@end

@implementation AMYServerTests

- (void)beforeAll
{
    [exampleServer start];
}

- (void)afterAll
{
    [exampleServer stop];
}

- (void)afterEach
{
    [tester clearTextFromViewWithAccessibilityLabel:@"Username"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Password"];
}

- (void)testSuccess
{
    [tester enterText:@"brian" intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:@"$ecret" intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Log In"];
    
    [exampleServer waitForLoginWithUsername:@"brian" password:@"$ecret" andRespondWithSuccess:YES message:@"Welcome, Brian" token:@"12345"];
    
    [tester waitForViewWithAccessibilityLabel:@"Welcome, Brian"];
    [tester tapViewWithAccessibilityLabel:@"Close"];
}

@end
