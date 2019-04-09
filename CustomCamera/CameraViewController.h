//
//  ViewController.h
//  CustomCamera
//
//  Created by Varun Rathi on 09/04/19.
//  Copyright © 2019 Varun Rathi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraViewController : UIViewController

@property (nonatomic,weak) IBOutlet UIView * topHeaderView;
@property (nonatomic, weak) IBOutlet UIView * bottomContainerView;
@property (nonatomic, weak) IBOutlet UIView * cameraView;
@property (nonatomic, weak) IBOutlet UIView * containerView;
@property (nonatomic, weak) IBOutlet UIButton * btnFlash;
@property (nonatomic, weak) IBOutlet UIButton * btnCapture;
@property (nonatomic, weak) IBOutlet UIButton * btnSwitch;
@property (nonatomic, weak) IBOutlet UIButton * btnCancel;

+(instancetype)loadFromStoryBoard;
-(instancetype)initWithNib;

@end

