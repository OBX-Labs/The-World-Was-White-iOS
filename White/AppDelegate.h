//
//  AppDelegate.h
//  White
//
//  Created by Christian Gratton on 2013-03-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OKPoEMM;
@class EAGLView;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) OKPoEMM *poemm;
@property (nonatomic, strong) EAGLView *eaglView;

- (void) setDefaultValues;
- (void) loadOKPoEMMInFrame:(CGRect)frame;
- (void) display:(NSNotification*)notification;

@end
