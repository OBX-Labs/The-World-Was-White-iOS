//
//  ESRenderer.h
//  White
//
//  Created by Christian Gratton on 12-06-18.
//  Copyright (c) 2012 Christian Gratton. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@class White;

@protocol ESRenderer <NSObject>

- (id) initWithMultisampling:(BOOL)aMultiSampling andNumberOfSamples:(int)requestedSamples;
- (void) reset;
- (void) render;
- (void) setFrame:(CGRect)aFrame;
- (void) renderWhite:(White*)white;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;

-(UIImage *) glToUIImage;
@end
