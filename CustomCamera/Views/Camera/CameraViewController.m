//
//  ViewController.m
//  CustomCamera
//
//  Created by Varun Rathi on 09/04/19.
//  Copyright © 2019 Varun Rathi. All rights reserved.
//

#import "CameraViewController.h"
#import <Photos/Photos.h>

#define Image_Flash_auto    @"flash_auto"
#define Image_Flash_off    @"flash_off"
#define Image_Flash_on    @"flash_on"


@interface CameraViewController ()<AVCapturePhotoCaptureDelegate>{
    UIImage * capturedCachedImage;
    UIImageView * previewImageView;
}


@property (nonatomic,weak) IBOutlet UIView * topHeaderView;
@property (nonatomic, weak) IBOutlet UIView * bottomContainerView;
@property (nonatomic, weak) IBOutlet UIView * cameraView;
@property (nonatomic, weak) IBOutlet UIView * containerView;
@property (nonatomic, weak) IBOutlet UIButton * btnFlash;
@property (nonatomic, weak) IBOutlet UIButton * btnCapture;
@property (nonatomic, weak) IBOutlet UIButton * btnSwitch;
@property (nonatomic, weak) IBOutlet UIButton * btnCancel;

@property (nonatomic,weak) IBOutlet UIView * flashContainerView;
@property (nonatomic,weak)  IBOutlet UIButton * btnFlashAuto;
@property (nonatomic,weak)  IBOutlet UIButton * btnFlashOn;
@property (nonatomic,weak)  IBOutlet UIButton * btnFlashOff;

@property (nonatomic,weak) IBOutlet NSLayoutConstraint * bottomContainerHeight;
@property (nonatomic,weak) IBOutlet NSLayoutConstraint * topContainerSpacing;
@property (nonatomic,weak) IBOutlet  UIView * bottomCaptureContainerView;
@property (nonatomic,weak) IBOutlet  UIView * bottomPreviewContainerView;

@property (nonatomic,weak) IBOutlet UIButton * previewLeftBtn;
@property (nonatomic,weak) IBOutlet UIButton * previewRightBtn;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, assign) AVCaptureFlashMode  flashMode;
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (nonatomic, strong) NSOperationQueue * sessionQueue;

@end

@implementation CameraViewController

#pragma mark - View Life cycle & utility

-(instancetype)initWithNib{
    if (self = [super initWithNibName:@"CameraViewController" bundle:nil]) {
    //init
    }
return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addBlurViewTo:_cameraView];
    self.sessionQueue = [NSOperationQueue new];
    [self requestPhtoLibraryPermissions];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
     [self setNeedsStatusBarAppearanceUpdate];
  //

}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}


-(BOOL)prefersStatusBarHidden {
    return YES;
}
-(void)requestPhtoLibraryPermissions {
    
    __weak typeof(self) weakSelf = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            [self enableCamera];
            break;
        case AVAuthorizationStatusNotDetermined:
            
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if (granted) {
                [weakSelf enableCamera];
                }
                
            }];
        }
            
            break;
        default:
            break;
    }
}

#pragma mark - Camera methods and Utility


// Returns camera device - Front/ Back
-(AVCaptureDevice *)captureDeviceWithPosition:(AVCaptureDevicePosition)position {
return [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
}


// Method for setting up VideoPreview Layer

-(void)enableCamera {
    self.session = [AVCaptureSession new];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    
    AVCaptureDevice * backCamera = [self captureDeviceWithPosition:AVCaptureDevicePositionBack];
    
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
            
            // Now inputs and output streams are plugged in
            // Start the video connection layer
            [self setUpLiveCameraPreviewLayer];
        }
        
        // enable autofocus
        if ([backCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [backCamera lockForConfiguration:&error];
            backCamera.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            [backCamera unlockForConfiguration];
        }
        
        if ([backCamera hasFlash]) {
            self.flashMode = AVCaptureFlashModeAuto;
        }
        
        // Update the default flash button state( For the first time)
        [self enableDefaultFlashStateFor:backCamera];
        [self animateFlashButtonOptions];
        
    }
}

// Attach the video preview layer

-(void)setUpLiveCameraPreviewLayer {
    
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    if (self.videoPreviewLayer) {
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.cameraView.layer addSublayer:weakSelf.videoPreviewLayer];
        });
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [weakSelf.session startRunning];
       
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.videoPreviewLayer.frame = weakSelf.cameraView.bounds;
            [weakSelf setupUI];
        });
    });
    
}

#pragma mark - UI Setup methods

-(void)setupUI{
    [_blurView removeFromSuperview];
    _topHeaderView.backgroundColor = [UIColor blackColor];
    _bottomContainerView.backgroundColor = [UIColor blackColor];
    _bottomCaptureContainerView.backgroundColor = [UIColor clearColor];
    _bottomPreviewContainerView.backgroundColor = [UIColor darkTextColor];
    _btnCapture.clipsToBounds = YES;
    
    if (_leftPreviewButtonTitle.length) {
        [_previewLeftBtn setTitle:_leftPreviewButtonTitle forState:UIControlStateNormal];
    } else {
        [_previewLeftBtn setTitle:@"Retake" forState:UIControlStateNormal];
    }
    
    if (_rightPreviewButtonTitle.length) {
        [_previewRightBtn setTitle:_rightPreviewButtonTitle forState:UIControlStateNormal];
    } else {
        [_previewRightBtn setTitle:@"Use Photo" forState:UIControlStateNormal];
    }
}


-(void)togglePreviewMode:(BOOL)showPreview{

    _topHeaderView.hidden = showPreview;
    _bottomPreviewContainerView.hidden = !showPreview;
    _bottomCaptureContainerView.hidden = showPreview;
    
    if (showPreview) {
        [self.session stopRunning];
        _bottomContainerHeight.constant = 80;
        _topContainerSpacing.constant = 40.0;
    }
    else {
        _topContainerSpacing.constant = 0.0;
        [self.session startRunning];
        _bottomContainerHeight.constant = 120;
    }
    [self.view layoutIfNeeded];
    [self.cameraView layoutIfNeeded];
}

-(void)addBlurViewTo:(UIView *)parentView{
    
    if (_blurView == nil) {
        UIBlurEffect * blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.blurView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
    }
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [parentView addSubview:_blurView];
    [self pinView:_blurView with:parentView];
}



-(void)pinView:(UIView *)view with:(UIView *)superview {

    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint * down = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];

    NSArray * constraints = @[top,left,right,down];
    [NSLayoutConstraint activateConstraints:constraints];
    [superview addConstraints:constraints];

}

#pragma mark - Flash Handling

-(void)enableDefaultFlashStateFor:(AVCaptureDevice *)device{
    __weak typeof(self) weakSelf = self;
    AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings photoSettings];
    NSError *error = nil;
    BOOL success = [device lockForConfiguration:&error];
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([device hasFlash]) {
                if ([weakSelf.stillImageOutput.supportedFlashModes containsObject:@(self.flashMode)]) {
                        photoSettings.flashMode = weakSelf.flashMode;
                }
                weakSelf.topHeaderView.hidden = NO;
            }
            else {
               // photoSettings.flashMode = AVCaptureFlashModeOff;
                weakSelf.topHeaderView.hidden = YES;
            }
        });
    }
    [device unlockForConfiguration];
}

-(void)setFlashMode:(AVCaptureFlashMode)flashMode {
    _flashMode = flashMode;
    [self updateFlashButton];
     [self updateFlashModeState];

}

// Flash button state
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

// Flash mode view
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


// Hide/Unhide switching for flash mode view

-(void)animateFlashButtonOptions
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3f animations:^{
        
       if (weakSelf.flashContainerView.alpha == 0.0f) {
           weakSelf.flashContainerView.alpha = 1.0f;
       } else {
            weakSelf.flashContainerView.alpha = 0.0f;
       }
    }];
}


- (AVCaptureDevice *)currentDevice
{
    return [(AVCaptureDeviceInput *)self.session.inputs.firstObject device];
}


#pragma mark - Actions

-(IBAction)btnDismiss:(id)sender{
[self.navigationController setNavigationBarHidden:NO];
[self.navigationController popViewControllerAnimated:NO];
//[self dismissViewControllerAnimated:NO completion:nil];
}

-(IBAction)captureClicked:(id)sender{
    
    if (_stillImageOutput) {
        AVCapturePhotoSettings * photoSettings = [AVCapturePhotoSettings photoSettings];
         photoSettings.autoStillImageStabilizationEnabled = YES;
        photoSettings.highResolutionPhotoEnabled = YES;
        
        if ([[self currentDevice] hasFlash]) {
            photoSettings.flashMode = self.flashMode;
        }
        [_stillImageOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
}

-(IBAction)switchClicked:(id)sender {
    
    __weak typeof( self) weakSelf = self;
    if (self.session == nil) return ;
    
     [self addBlurViewTo:self.cameraView];
    
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
        
        // Switch Flash state
        [self enableDefaultFlashStateFor:cameraToSwitch];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateFlashButton];
        });
       
        
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
            weakSelf.btnSwitch.selected = !weakSelf.btnSwitch.selected;
            if (!weakSelf.session) return ;
            [weakSelf.session startRunning];
            [weakSelf.blurView removeFromSuperview];
        });
        
    };
    
    switchOperation.queuePriority = NSOperationQueuePriorityVeryHigh;
    
   // Flip animation
    [UIView transitionWithView:weakSelf.cameraView duration:0.3f options:UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionAllowAnimatedContent animations:nil completion:^(BOOL finished) {
       [weakSelf.sessionQueue addOperation:switchOperation];
    }];
    
}


-(IBAction)flashButtonClicked:(id)sender {
    [self animateFlashButtonOptions];
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
     //[self updateFlashModeState];
     [self animateFlashButtonOptions];
}


-(IBAction)btnUsePhotoClicked:(id)sender {
    if (_completionHandler != NULL && capturedCachedImage) {
        _completionHandler(capturedCachedImage);
        
        if (capturedCachedImage) {
            [self writeToPhotoLibraryWith:capturedCachedImage];
        }
        
    }
}

-(IBAction)btnRetakeClicked:(id)sender{

    if (previewImageView) {
    [previewImageView removeFromSuperview];
    }
    [self togglePreviewMode:NO];
}

#pragma mark - Photo Capture delegates

//-(void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
//
//    // Stop the connection
//    [self.session stopRunning];
//    // Animate capture flicker with Shutter sound
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        weakSelf.cameraView.layer.opacity = 0.0;
//        [UIView animateWithDuration:0.3 animations:^{
//           weakSelf.cameraView.layer.opacity = 1.0;
//        }];
//    });
//}


-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error  API_AVAILABLE(ios(11.0)){

    [self.session startRunning];

    if (error) {
        //[self.session startRunning];
        return;
        
    }
     if (photo) {
        NSData * imageData = [photo fileDataRepresentation];
        [self handleCapturedImageWith:imageData];
      }
}

-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {


    [self.session startRunning];

    if (error) {

        NSLog(@"Error in capturing Image");
        return;
    }

    // Use the buffer to get nsdata and then to an Image

    if (photoSampleBuffer) {
        NSData * imageData =  [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        [self handleCapturedImageWith:imageData];
        
    } else {
    // Error

    }

}

-(void)handleCapturedImageWith:(NSData *)imageData {
    if (nil == imageData) return;
    UIImage * capturedImage = [[UIImage alloc]initWithData:imageData scale:1.0];
    if (capturedImage) {
        capturedCachedImage = capturedImage;
    
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            previewImageView = [[UIImageView alloc]initWithImage:capturedImage];
            previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
            previewImageView.contentMode = UIViewContentModeScaleAspectFit;
            [weakSelf.cameraView addSubview:previewImageView];
            [weakSelf pinView:previewImageView with:weakSelf.cameraView];
            [weakSelf.cameraView layoutIfNeeded];
            [weakSelf togglePreviewMode:YES];
        });
    
    }
}

 // For storing on to the photo library
-(void)writeToPhotoLibraryWith:(UIImage *)image {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized){
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}



@end
