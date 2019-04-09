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
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, assign) AVCaptureFlashMode  flashMode;

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
    // Do any additional setup after loading the view, typically from a nib.
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setUpViews {
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureDevice * backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
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
            [self setUpLivePreview];
        }
    }
}
-(void)setUpLivePreview {
    
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    if (self.videoPreviewLayer) {
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        [self.view.layer addSublayer:self.videoPreviewLayer];
    }
    
    self.videoPreviewLayer.frame = _cameraView.frame;
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [weakSelf.session startRunning];
       
        dispatch_async(dispatch_get_main_queue(), ^{
           // weakSelf.videoPreviewLayer.frame = weakSelf.cameraView.bounds;
            [weakSelf setupUI];
        });
        //Step 13
    });
    
}

-(void)setupUI{
    _topHeaderView.backgroundColor = [UIColor blackColor];
    _bottomContainerView.backgroundColor = [UIColor blackColor];
    _btnCapture.clipsToBounds = YES;
    _btnCapture.layer.cornerRadius = _btnCapture.frame.size.height/2;
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


-(void)updateFlashModeState{
    if (![self currentDevice]) {
        return;
    }
    _btnFlashOn.selected = (self.flashMode == AVCaptureFlashModeOn);
    _btnFlashOff.selected = (self.flashMode == AVCaptureFlashModeOff);
    _btnFlashAuto.selected = (self.flashMode == AVCaptureFlashModeAuto);
    
    AVCaptureDevice *device = [self currentDevice];
    NSError *error = nil;
    BOOL success = [device lockForConfiguration:&error];
    if (success) {
        device.flashMode = self.flashMode;
    }
    [device unlockForConfiguration];
}

-(IBAction)flashModeSeleced:(id)sender {

    if (sender == self.btnFlashAuto) {
        _flashMode = AVCaptureFlashModeAuto;
    }
     else if (sender == self.btnFlashOn) {
        _flashMode = AVCaptureFlashModeOn;
     }
     else {
     _flashMode = AVCaptureFlashModeOff;
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
@end
