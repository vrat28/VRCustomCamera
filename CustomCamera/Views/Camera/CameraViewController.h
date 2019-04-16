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
@property (nonatomic,copy) void (^completionHandler) (UIImage *);
@property (nonatomic,strong) NSString * leftPreviewButtonTitle;
@property (nonatomic,strong) NSString * rightPreviewButtonTitle;


+(instancetype)loadFromStoryBoard;
-(instancetype)initWithNib;

@end

