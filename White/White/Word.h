//
//  Word.h
//  White
//
//  Created by Christian Gratton on 2013-03-19.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KineticObject.h"

@class Line;
@class OKTessFont;

@class OKWordObject;
@class OKCharObject;

typedef enum
{
    FADE_IN,
    FADE_OUT,
    STABLE
} FadeState;

@interface Word : KineticObject
{
    // Font
    OKTessFont *font;
    
    // Glyphs
    NSMutableArray *glyphs;
    
    // Properties
    float opacity; // opacity
    float fadeInSpeed, fadeOutSpeed; // fading speeds
    FadeState fadeState; // fading state (in, out, stable)
    float fadeTo; // opacity to fade to
    
    OKPoint velocity; // velocity
    float drag; // drag
    
    CGRect bounds;
    
    // Size
    CGSize size;
    
    // Value
    NSString *value;
}

- (id) initWithWord:(OKWordObject*)aWordObj font:(OKTessFont*)aFont renderingBounds:(CGRect)aRenderingBounds;
- (void) build:(OKWordObject*)aWordObj renderingBounds:(CGRect)aRenderingBounds;

#pragma mark - DRAW

- (void) draw; // Draws fill and outline
- (void) drawFill; // Draws fill
- (void) drawOutline; // Draws outline
- (void) drawDebugBounds;
- (void) update:(long)dt;
- (void) updateGlyphs:(long)dt;

#pragma mark - SETTERS

- (void) setPosition:(OKPoint)aPosition;
- (void) setOpacity:(float)aOpacity;
- (void) fadeTo:(float)aOpacity speed:(float)aSpeed;
- (void) fadeIn:(float)aOpacity;
- (void) fadeOut:(float)aOpacity;
- (void) fadeIn:(float)aOpacity speed:(float)aSpeed;
- (void) fadeOut:(float)aOpacity speed:(float)aSpeed;
- (void) setFadeInSpeed:(float)aFadeInSpeed fadeOutSpeed:(float)aFadeOutSpeed;

#pragma mark - GETTERS

- (CGRect) getAbsoluteBounds;
- (CGSize) getSize;
- (BOOL) isInside:(OKPoint)pt;
- (BOOL) isInsideLarger:(OKPoint)pt px:(int)px;
- (OKPoint) center;
- (BOOL) isFadingIn;
- (BOOL) isFadingOut;
- (BOOL) isFadedOut;
- (float) opacity;

- (NSString*) description;
- (NSString*) value;

@end
