//
//  ViewController.m
//  CustomCamera
//
//  Created by Varun Rathi on 09/04/19.
//  Copyright © 2019 Varun Rathi. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(IBAction)btnShowClicked:(id)sender{
CameraViewController * vc = [[CameraViewController alloc]initWithNib];
    [self presentViewController:vc animated:NO completion:nil];
//[self.navigationController pushViewController:vc animated:NO];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
