//
//  AYCustomCameraController.m
//  AYCustomCamera
//
//  Created by Andy on 2017/5/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "AYCustomCameraController.h"
#import <AVFoundation/AVFoundation.h>

#define kShow_Alert(_msg_)  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:_msg_ preferredStyle:UIAlertControllerStyleAlert];\
[alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];\
[[[UIApplication sharedApplication].windows firstObject].rootViewController presentViewController:alertController animated:YES completion:nil];


#define kScreen_Width [UIScreen mainScreen].bounds.size.width
#define kSCreen_Height [UIScreen mainScreen].bounds.size.height


@interface AYCustomCameraController ()

@property (nonatomic , strong)AVCaptureSession *captureSession;//

@property (nonatomic , strong)AVCaptureDeviceInput *captureDeviceInput;//输入数据流

@property (nonatomic , strong)AVCaptureStillImageOutput *captureStillImageOutput;//照片输出流

@property (nonatomic , strong)AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//显示相机拍摄到画面

@property (nonatomic , strong)AVCaptureDevice *captureDevice;//输入设备

@property (nonatomic , assign)BOOL flashFlag; //闪光灯开关

@property (nonatomic , strong)UIButton *flashBtn;//用于是否显示

@end

@implementation AYCustomCameraController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self ay_setLayoutSubviews];
    
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        if ([self.captureSession canAddInput:[self ay_getBackCameraInput]]) {
            [self.captureSession addInput:[self ay_getBackCameraInput]];
        }
    }else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
        if ([self.captureSession canAddInput:[self ay_getFrontCameraInput]]) {
            [self.captureSession addInput:[self ay_getFrontCameraInput]];
        }
    }else{
        kShow_Alert(@"照相机不可用!");
    }
    
    if ([self.captureSession canAddOutput:self.captureStillImageOutput]) {
        [self.captureSession addOutput:self.captureStillImageOutput];
    }
    [self.view.layer insertSublayer:self.captureVideoPreviewLayer atIndex:0];
}

- (void)ay_setLayoutSubviews{
    
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreen_Width, 40)];
    topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:topView];
    
    _flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _flashBtn.frame = CGRectMake(5, 0, 40, 40);
    [_flashBtn setImage:[UIImage imageNamed:@"camera_flash_on"] forState:UIControlStateSelected];
    [_flashBtn setImage:[UIImage imageNamed:@"camera_flash_off"] forState:UIControlStateNormal];
    [_flashBtn addTarget:self action:@selector(ay_exchangeFlash:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:_flashBtn];
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraBtn.frame = CGRectMake(kScreen_Width - 45, 5, 40, 30);
    [cameraBtn setTitle:@"交换" forState: UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(ay_exchangeCareme:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:cameraBtn];
    
    
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kSCreen_Height - 50, kScreen_Width, 50)];
    bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self.view addSubview:bottomView];
    
    UIButton *takeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takeBtn.frame = CGRectMake(kScreen_Width / 2 - 25, 5, 50, 40);
    [takeBtn setImage:[UIImage imageNamed:@"camera_take"] forState:UIControlStateNormal];
    [takeBtn addTarget:self action:@selector(ay_takePicture:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:takeBtn];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(10, 10, 40, 30);
    [cancelBtn setTitle:@"取消" forState: UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(ay_cancelTakePicture:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:cancelBtn];
    
}


/**
 拍照
 */
- (void)ay_takePicture:(UIButton*)sender{
    self.view.userInteractionEnabled = NO;// 阻断按钮响应者链,否则会造成崩溃
    AVCaptureConnection *captureConnection = [self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (captureConnection) {
        [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
           
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
                        
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_delegate respondsToSelector:@selector(ay_getImage:)]) {
                    [_delegate ay_getImage:image];
                }
                [self dismissViewControllerAnimated:YES completion:^{
                    self.view.userInteractionEnabled = YES;
                }];
            });
        }];
    }else{
        kShow_Alert(@"拍照失败!")
    }
}


/**
 更换闪光模式

 @param sender 切换闪光按钮
 */
- (void)ay_exchangeFlash:(UIButton*)sender{
    _flashFlag = !_flashFlag;
    NSError *error;
    [self.captureDevice lockForConfiguration:&error];
    if (!error && [_captureDevice hasFlash]) {
        if (_flashFlag) {
            [self.captureDevice setFlashMode:AVCaptureFlashModeOn];
        }else{
            [self.captureDevice setFlashMode:AVCaptureFlashModeOff];
        }
        [self.captureDevice unlockForConfiguration];
        sender.selected = _flashFlag;
    }
}


/**
 取消拍照

 @param sender 取消按钮
 */
- (void)ay_cancelTakePicture:(UIButton*)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)ay_exchangeCareme:(UIButton*)sender{
    AVCaptureDeviceInput *deviceInput = _captureDeviceInput;
    AVCaptureDevice *device = _captureDevice;
    if (_captureDevice.position == AVCaptureDevicePositionBack) {
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            [self ay_getFrontCameraInput];
        }
    }else if(_captureDevice.position == AVCaptureDevicePositionFront){
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            [self ay_getBackCameraInput];
        }
    }
    if (deviceInput) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:deviceInput];
        if ([self.captureSession canAddInput:_captureDeviceInput]) {
            [self.captureSession addInput:_captureDeviceInput];
            if ([_captureDevice hasFlash]) {
                _flashBtn.hidden = NO;
            }else{
                _flashBtn.hidden = YES;
            }
        }else{
            [_captureSession addInput:deviceInput];
            _captureDeviceInput = deviceInput;
            _captureDevice = device;
        }
        [self.captureSession commitConfiguration];
    }
}


/**
 获取上下文
 */
- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}


/**
 获取输出流

 @return 输出流对象
 */
- (AVCaptureStillImageOutput *)captureStillImageOutput{
    if (!_captureStillImageOutput) {
        _captureStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        [_captureStillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    }
    return _captureStillImageOutput;
}


- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer{
    if (!_captureVideoPreviewLayer) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        _captureVideoPreviewLayer.frame = self.view.bounds;
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _captureVideoPreviewLayer;
}


- (AVCaptureDeviceInput*)ay_getBackCameraInput{
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self ay_getCameraWithPosition:AVCaptureDevicePositionBack] error:&error];
    if (error) {
        NSLog(@"%@",error);
    }else{
        _captureDeviceInput = deviceInput;
    }
    return deviceInput;
}

- (AVCaptureDeviceInput*)ay_getFrontCameraInput{
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self ay_getCameraWithPosition:AVCaptureDevicePositionFront] error:&error];
    if (error) {
        NSLog(@"%@",error);
    }else{
        _captureDeviceInput = deviceInput;
    }
    return deviceInput;
}


- (AVCaptureDevice*)ay_getCameraWithPosition:(AVCaptureDevicePosition)devicePosition{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == devicePosition) {
            NSError *error;
            [device lockForConfiguration:&error];
            if (!error && [device hasFlash]) {
                if (_flashFlag) {
                    [device setFlashMode:AVCaptureFlashModeOn];
                }else{
                    [device setFlashMode:AVCaptureFlashModeOff];
                }
                [device unlockForConfiguration];
            }
            _captureDevice = device;
            return device;
        }
    }
    return nil;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end