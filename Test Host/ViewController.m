//
//  ViewController.m
//  Test Host
//
//  Created by Brian Nickel on 7/16/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logIn {
    
    if (self.userNameField.isFirstResponder) {
        [self.userNameField resignFirstResponder];
    }
    
    if (self.passwordField.isFirstResponder) {
        [self.passwordField resignFirstResponder];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com/services/login.json"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"username": self.userNameField.text, @"password": self.passwordField.text} options:0 error:NULL];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        
        [[[UIAlertView alloc] initWithTitle:result[@"message"] message:nil delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    }];
}

@end
