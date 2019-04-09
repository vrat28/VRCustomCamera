//
//  ViewController.m
//  CustomCamera
//
//  Created by Varun Rathi on 09/04/19.
//  Copyright © 2019 Varun Rathi. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()


@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

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
    
    if (_stillImageOutput.connections) {
}

}

-(IBAction)switchClicked:(id)sender {

}

@end
