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

*To be added.*

Example
-------

This example assumes you are already familiar with KIF-next and borrows from the example on that project. 

*To be added.*