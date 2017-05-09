//
//  AYCustomCameraController.h
//  AYCustomCamera
//
//  Created by Andy on 2017/5/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AYCustomCameraDelegate <NSObject>

- (void)ay_getImage:(UIImage*)image;

@end

@interface AYCustomCameraController : UIViewController

@property (nonatomic , weak)id<AYCustomCameraDelegate> delegate;

@end
