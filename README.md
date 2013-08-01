AMYServer KIF-next Test Actors
=====================================

AMYServer, which stands for AMY Mocks Your Server, provides a mechanism for mocking your web servers within a KIF-next test case.

**How does it compare to something like Mocktail?** Mocktail is useful for taking the server out of the equation when doing development but has some limitations which may impact testing.

- Request bodies are completely ignored.
- Mocks are (mostly) limited to one response per URL, meaning if you have a single URL that may respond with totally different response bodies, you can't quickly switch between them while running test cases.
- There is no direct validation of expectations. If your test triggers a network call, you have to monitor the UI to see how it reacted.

AMYServer addresses these problems by creating KIF test actors to represent your servers.  With a little setup, your tests will develop into a logical story where you can really understand what your system is doing:

    [tester enterText:@"brian" intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:@"$ecret" intoViewWithAccessibilityLabel:@"Password"];
    
    [myServer waitForLoginWithUsername:@"brian" password:@"$ecret"
              andRespondWithSuccess:YES message:@"Welcome, Brian" token:@"12345"];
    
    [tester waitForViewWithAccessibilityLabel:@"Welcome, Brian"];

AMYServer also integrates with Mocktail to simplify the process of setting up new tests.  If you have existing tail files you can integrate them with just a few lines to code.

**Important Notes:** AMYServer does not run against the standard KIF build from Square but instead the KIF-next branch on [bnickel/KIF](https://github.com/bnickel/KIF).  I have not yet worked on this with a real system so the API is unstable and input is welcome.

See AMYServer in Action
-----------------------

AMYServer includes a few test cases to validate that it works.  Kick off the test to see AMYServer go through a few standard cases.

Installation
------------

AMYServer can be installed with a [CocoaPods](http://cocoapods.org).

    target 'Acceptance Tests' do
      pod 'AMYServer', '~> 0.0'
    end

Example 1: Using Mocktails
--------------------------

This example assumes you are already familiar with KIF-next and Mocktail.

The first step is to define your server with the API it will use:

**ExampleServer.h**

    #import "AMYServer.h"

    #define exampleServer KIFActorWithClass(ExampleServer) // (3)

    @interface ExampleServer : AMYServer // (1)

    - (void)waitForLoginAndRespondWithMessage:(NSString *)message
                                        token:(NSString *)token; // (2)

    @end

1. Create a new instance of `AMYServer` for your server.
2. Define methods that make sense in the context of your script with information you can validate or provide.
3. Define the actor shortcut you will use, similar to `tester`.

**ExampleServer.m**

    #import "ExampleServer.h"
    
    @implementation ExampleServer

	- (NSURL *)baseURL
	{
	    return [NSURL URLWithString:@"https://example.com/services/"]; // (1)
	}


    - (void)waitForLoginAndRespondWithMessage:(NSString *)message
                                        token:(NSString *)token
    {
        [self waitForRequestMatchingMocktail:@"successful-login"
              andRespondWithValues:@{@"token": token ?: @"", @"message": message ?: @""}]; // (2)
    }

    @end
    
1. Define the base URL that the server will respond to.
2. Select a mock to use for your response and values to use.

**successful-login.tail**

	POST
	login.json
	200
	application/json

	{
	    "success": true,
    	"message": "{{{message}}}",
    	"token": "{{{token}}}"
	}

Define your Mocktail and include it in your test target.

Once configured, you can write a test that uses it.

**LoginTests.m**

    #import <KIFTestCase.h>
    #import "ExampleServer.h"

    @interface AMYServerTests : KIFTestCase
    @end

    @implementation AMYServerTests

    - (void)beforeAll
    {
        [exampleServer start]; // (1)
    }

    - (void)afterAll
    {
        [exampleServer stop]; // (5)
    }

    - (void)testSuccessfulLogin
    {
        [tester tapViewWithAccessibilityLabel:@"Log In"]; // (2)
        [exampleServer waitForLoginAndRespondWithMessage:@"Welcome, Brian" token:@"12345"]; // (3)
        [tester waitForViewWithAccessibilityLabel:@"Welcome, Brian"]; // (4)
    }
    
    @end

1. Start mocking.
2. Trigger a request.
3. Wait for and respond to the request.
4. Monitor for the effects of the response.
5. Stop mocking.

Example 2: Advanced Mocktails
-----------------------------

AMYServer provides a few features that build upon Mocktail.

1. Request body validation as part of the test step.
2. Mustache templates for full customization.
3. Reponse headers with mustache replacement.

Using these, we can enhance the login test step to validate the username and password and inject a custom header in the response.

**ExampleServer.m**

    - (void)waitForLoginWithUsername:(NSString *)username
                            password:(NSString *)password
               andRespondWithMessage:(NSString *)message
                               token:(NSString *)token
    {
        [self waitForRequestMatchingMocktail:@"successful-login"
              withHTTPBodyMatchingBlock:^KIFTestStepResult(NSData *body, NSError *__autoreleasing *error) {
              
                  id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
                  KIFTestWaitCondition([json[@"username"] isEqualToString:username], error, @"Could not find username");
                  KIFTestWaitCondition([json[@"password"] isEqualToString:password], error, @"Could not find password");
                  return KIFTestStepResultSuccess;
              } 
              andRespondWithValues:@{@"token": token ?: @"", @"message": message ?: @""}];
    }

    @end
    
In this case, AMYServer will ignore requests that don't have the correct username and password and provide a meaningful error.

**successful-login.tail**

	POST
	login.json
	200
	application/json
	X-Application-Token: {{{token}}}
	
	{
	    "success": true,
    	"message": "{{{message}}}",
    	"token": "{{{token}}}"
	}

Here, AMYServer injects a custom header with the token.

Example 3: Default Mustache values
----------------------------------

Rather than providing every value every time you render a template, AMYServer lets your provide a JSON file with default values.  The name of this file is the same as the tail file with an additional extension `.defaults.json`.

**successful-login.tail.defaults.json**

    { "message": "Good morning, sir", "token": "1234" }


Example 4: Custom Behavior
--------------------------

AMYServer is not limited to just Mocktails.  It can be use for serving images, 1000 bytes at a time, with 5 seconds between bytes.

    - (void)waitForImageRequestAndRespondPainfully
    {
        AMYRequest *request = [self waitForRequestMatchingBlock:^KIFTestStepResult(NSURLRequest *request, NSError **error) {
            KIFTestWaitCondition([request.URL.lastPathComponent isEqualToString:@"image.do"], error, @"Could not find request for image.do");
            return KIFTestStepResultSuccess;
        }];
        
        [request respondWithSatusCode:200 headerFields:@{@"Content-Size": @"1000000"}];
        while (!done) {
	        [request sendData:moreData];
	        [self waitForTimeInterval:5];
	    }
        [request close];
    }
    
First we wait for a request matching whatever rule we want.  In this case, the last path component should be "image.do".  Then we send the response header and slowly build up the body before closing.  The important thing here is that we can run any sort of actions we want while the data is returned.