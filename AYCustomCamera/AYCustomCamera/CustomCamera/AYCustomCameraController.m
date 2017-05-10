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


@interface AYCustomCameraController ()<UIGestureRecognizerDelegate>

@property (nonatomic , strong)AVCaptureSession *captureSession;//

@property (nonatomic , strong)AVCaptureDeviceInput *captureDeviceInput;//输入数据流

@property (nonatomic , strong)AVCaptureStillImageOutput *captureStillImageOutput;//照片输出流

@property (nonatomic , strong)AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//显示相机拍摄到画面

@property (nonatomic , assign)BOOL flashFlag; //闪光灯开关

@property (nonatomic , strong)UIButton *flashBtn;//用于是否显示

@property (nonatomic , assign)CGFloat effectiveScale;

@property (nonatomic , assign)CGFloat beginGestureScale;

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
        AVCaptureDeviceInput *deviceInput = [self ay_getBackCameraInput];
        if ([self.captureSession canAddInput:deviceInput]) {
            _captureDeviceInput = deviceInput;
            [self.captureSession addInput:deviceInput];
        }
    }else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]){
        AVCaptureDeviceInput *deviceInput = [self ay_getBackCameraInput];
        if ([self.captureSession canAddInput:deviceInput]) {
            _captureDeviceInput = deviceInput;
            [self.captureSession addInput:deviceInput];
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
    
    self.effectiveScale = 1.0f;
    UIPinchGestureRecognizer *pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pin.delegate = self;
    [self.view addGestureRecognizer:pin];
    
    
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
    [captureConnection setVideoScaleAndCropFactor:self.effectiveScale];
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
    [self.captureDeviceInput.device lockForConfiguration:&error];
    if (!error && [_captureDeviceInput.device hasFlash]) {
        if (_flashFlag) {
            [self.captureDeviceInput.device setFlashMode:AVCaptureFlashModeOn];
        }else{
            [self.captureDeviceInput.device setFlashMode:AVCaptureFlashModeOff];
        }
        [self.captureDeviceInput.device unlockForConfiguration];
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
    AVCaptureDeviceInput *deviceInput;
    if (_captureDeviceInput.device.position == AVCaptureDevicePositionBack) {
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            deviceInput = [self ay_getFrontCameraInput];
        }else{
            kShow_Alert(@"前置摄像头不可用");
        }
    }else if(_captureDeviceInput.device.position == AVCaptureDevicePositionFront){
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            deviceInput = [self ay_getBackCameraInput];
        }else{
            kShow_Alert(@"后置摄像头不可用");
        }
    }
    if (deviceInput) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:_captureDeviceInput];
        if ([self.captureSession canAddInput:deviceInput]) {
            [self.captureSession addInput:deviceInput];
            _captureDeviceInput = deviceInput;
            if ([_captureDeviceInput.device hasFlash]) {
                _flashBtn.hidden = NO;
            }else{
                _flashBtn.hidden = YES;
            }
        }else{
            if ([_captureSession canAddInput:_captureDeviceInput]) {
                [_captureSession addInput:_captureDeviceInput];
            }
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
    }
    return deviceInput;
}

- (AVCaptureDeviceInput*)ay_getFrontCameraInput{
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self ay_getCameraWithPosition:AVCaptureDevicePositionFront] error:&error];
    if (error) {
        NSLog(@"%@",error);
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
            return device;
        }
    }
    return nil;
}


//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.captureVideoPreviewLayer convertPoint:location fromLayer:self.captureVideoPreviewLayer.superlayer];
        if ( ! [self.captureVideoPreviewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        
        CGFloat maxScaleAndCropFactor = [[self.captureStillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.captureVideoPreviewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
