//
//  ViewController.m
//  CustomCamera
//
//  Created by Varun Rathi on 09/04/19.
//  Copyright © 2019 Varun Rathi. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()<AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, assign) AVCaptureFlashMode  flashMode;
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (nonatomic, strong) NSOperationQueue * sessionQueue;

@end

@implementation CameraViewController

-(instancetype)initWithNib{
    if (self = [super initWithNibName:@"CameraViewController" bundle:nil]) {
    //init
    }
return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    [self setUpViews];
    
    self.sessionQueue = [NSOperationQueue new];
    UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
   // self.blurView = blurEffect;
    // Do any additional setup after loading the view, typically from a nib.
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}


-(AVCaptureDevice *)captureDeviceWithPosition:(AVCaptureDevicePosition)position {
return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
}

-(void)setUpViews {
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureDevice * backCamera = [self captureDeviceWithPosition:AVCaptureDevicePositionBack];
  //  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    if (!backCamera) {
        return;
    }
    
    NSError * error = nil;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    
    if (!error) {
    
        self.stillImageOutput = [AVCapturePhotoOutput new];
        self.stillImageOutput.highResolutionCaptureEnabled = YES;
        
        if ([self.session canAddInput:input] && [self.session canAddOutput:self.stillImageOutput]) {
            [self.session addInput:input];
            [self.session addOutput:self.stillImageOutput];
            [self setUpLiveCameraPreviewLayer];
        }
    
        // enable autofocus
        if ([backCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [backCamera lockForConfiguration:&error];
            backCamera.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [backCamera unlockForConfiguration];
        }
        
         AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings photoSettings];
            NSError *error = nil;
            BOOL success = [backCamera lockForConfiguration:&error];
            if (success) {
            
                if ([backCamera hasFlash]) {
                    photoSettings.flashMode = AVCaptureFlashModeAuto;
                }
                else {
                    photoSettings.flashMode = AVCaptureFlashModeOff;
                }
            }
            [backCamera unlockForConfiguration];
    }
}
-(void)setUpLivePreview {
    
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    if (self.videoPreviewLayer) {
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        [self.cameraView.layer addSublayer:self.videoPreviewLayer];
    }
    
   
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [weakSelf.session startRunning];
       
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.videoPreviewLayer.frame = weakSelf.cameraView.bounds;
            [weakSelf setupUI];
        });
        //Step 13
    });
    
}

-(void)setupUI{
    _topHeaderView.backgroundColor = [UIColor blackColor];
    _bottomContainerView.backgroundColor = [UIColor blackColor];
    _btnCapture.clipsToBounds = YES;
    _btnCapture.layer.cornerRadius = _btnCapture.frame.size.width/2;
}

-(IBAction)btnBackPressed:(id)sender {
  //  [self.navigationController popViewControllerAnimated:NO];
}

-(void)viewWillDisappear:(BOOL)animated {

[super viewWillDisappear:animated];

[self.navigationController setNavigationBarHidden:NO];
}

-(IBAction)btnDismiss:(id)sender{

[self dismissViewControllerAnimated:NO completion:nil];
}


-(IBAction)captureClicked:(id)sender{
    
    if (_stillImageOutput) {
        AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings new];
        photoSettings.autoStillImageStabilizationEnabled = true;
        photoSettings.highResolutionPhotoEnabled = true;
        photoSettings.flashMode = AVCaptureFlashModeAuto;
        [_stillImageOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
}

-(IBAction)switchClicked:(id)sender {
    
    
    __weak typeof( self) weakSelf = self;
    if (self.session == nil) return ;
    
    // Stop the session since we will animate switch transition
    [self.session stopRunning];
    
    NSBlockOperation * switchOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        AVCaptureDeviceInput * currentInput = [weakSelf.session.inputs firstObject];
        AVCaptureDevice * cameraToSwitch = nil;
        
        if (currentInput.device.position == AVCaptureDevicePositionBack) {
            cameraToSwitch = [weakSelf captureDeviceWithPosition:AVCaptureDevicePositionFront];
        } else {
            cameraToSwitch = [weakSelf captureDeviceWithPosition:AVCaptureDevicePositionBack];
        }
        
        // Switch the flash indicator
        dispatch_async(dispatch_get_main_queue(), ^{
           // weakSelf.btnFlash.hidden = (cameraToSwitch.isFlashAvailable == NO);
        });
        
        //Remove the previous camera
        
        [weakSelf.session removeInput:currentInput];
        
        NSError * error = nil;
        
        // Get the new input with the new camera device
        
        currentInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraToSwitch error:&error];
        if (!currentInput) return ;
        
        [weakSelf.session addInput:currentInput];
    }];
    
    switchOperation.completionBlock = ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!weakSelf.session) return ;
            
            [weakSelf.session startRunning];
            [weakSelf.blurView removeFromSuperview];
        });
        
    };
    
    switchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    
    //TODO Handle blur view
    
    [UIView transitionWithView:weakSelf.cameraView duration:0.3f options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent animations:nil completion:^(BOOL finished) {
       [weakSelf.sessionQueue addOperation:switchOperation];
    }];
    
}


-(IBAction)flashButtonClicked:(id)sender {
    [self animateFlashButtonOptions];
}

- (AVCaptureDevice *)currentDevice
{
    return [(AVCaptureDeviceInput *)self.session.inputs.firstObject device];
}

-(AVCaptureDevice *)getFrontCamera {
     NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

-(void)setFlashMode:(AVCaptureFlashMode)flashMode {
    _flashMode = flashMode;
    [self updateFlashButton];
     [self updateFlashModeState];

}

-(void)updateFlashButton {

NSString * imageName;
    switch (_flashMode) {
        case AVCaptureFlashModeAuto:
            imageName = Image_Flash_auto;
            break;
            
        case AVCaptureFlashModeOn:
            imageName = Image_Flash_on;
            break;
        default:
            imageName = Image_Flash_off;
            break;
    }
     [_btnFlash setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

-(void)updateFlashModeState{
    if (![self currentDevice]) {
        return;
    }
    _btnFlashOn.selected = (self.flashMode == AVCaptureFlashModeOn);
    _btnFlashOff.selected = (self.flashMode == AVCaptureFlashModeOff);
    _btnFlashAuto.selected = (self.flashMode == AVCaptureFlashModeAuto);
    
    AVCaptureDevice *device = [self currentDevice];
    AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings photoSettings];
    NSError *error = nil;
    
    if ([device hasFlash]) {
            BOOL success = [device lockForConfiguration:&error];
            if (success) {
                photoSettings.flashMode = self.flashMode;
            }
            [device unlockForConfiguration];
        }
}

-(IBAction)flashModeSeleced:(id)sender {

    if (sender == self.btnFlashAuto) {
        self.flashMode = AVCaptureFlashModeAuto;
    }
     else if (sender == self.btnFlashOn) {
        self.flashMode = AVCaptureFlashModeOn;
     }
     else {
        self.flashMode = AVCaptureFlashModeOff;
     }
     [self updateFlashModeState];
     [self animateFlashButtonOptions];
}




-(void)animateFlashButtonOptions
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3f animations:^{
        
       if (weakSelf.flashContainerView.alpha == 0.0f) {
           weakSelf.flashContainerView.alpha = 1.0f;
       } else {
            weakSelf.flashContainerView.alpha = 0.0f;
       }
      //  self.cameraButton.alpha = self.cameraButton.alpha == 1.0f ? 0.0f : 1.0f;
    }];
}


-(void)enableCameraModule{

    if (_session ) return;
    
    NSBlockOperation * operation = [self captureOperation];
    self.btnFlash.hidden = YES;
    

}


-(NSBlockOperation *)captureOperation {
return [NSBlockOperation new];
}


#pragma mark - Photo Capture delegates

-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {

    if (error) {

        NSLog(@"Error in capturing Image");
        return;
    }
    
    if (photoSampleBuffer) {
      NSData * imageData =  [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
      
      if (imageData) {
        UIImage * capturedImage = [[UIImage alloc]initWithData:imageData scale:1.0];
        if (capturedImage) {
            UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil);
        }
      }
    
    } else {
    // Error
    
    }

}
-(void)viewDidLayoutSubviews {

    [super viewDidLayoutSubviews];
    _videoPreviewLayer.frame = _cameraView.bounds;
    [self.view layoutIfNeeded];
    
    
}
@end
