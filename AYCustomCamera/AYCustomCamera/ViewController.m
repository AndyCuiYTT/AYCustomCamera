//
//  ViewController.m
//  AYCustomCamera
//
//  Created by Andy on 2017/5/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "ViewController.h"
#import "AYCustomCameraController.h"

@interface ViewController ()<AYCustomCameraDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *bgImgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    
    
    

}

- (IBAction)ay_takePicture:(UIButton *)sender {
    
    AYCustomCameraController *vc = [[AYCustomCameraController alloc] init];
    vc.delegate = self;
    
    [self presentViewController:vc animated:YES completion:nil];
    
    
}


- (void)ay_getImage:(UIImage *)image{
    self.bgImgView.image = image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
