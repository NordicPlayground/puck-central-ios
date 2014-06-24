//
//  NSPInitialViewController.m
//  iEvere
//
//  Created by Nordic Semiconductor on 24/06/14.
//  Copyright (c) 2014 Nordic Semiconductor. All rights reserved.
//

#import "NSPInitialViewController.h"

@interface NSPInitialViewController ()

@end

@implementation NSPInitialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"iEvere";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
