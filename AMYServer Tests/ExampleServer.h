//
//  ExampleServer.h
//  AMYServer
//
//  Created by Brian Nickel on 7/20/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "AMYServer.h"

#define exampleServer KIFActorWithClass(ExampleServer)

@interface ExampleServer : AMYServer

- (void)waitForLoginWithUsername:(NSString *)username password:(NSString *)password andRespondWithSuccess:(BOOL)success message:(NSString *)message token:(NSString *)token;

@end
