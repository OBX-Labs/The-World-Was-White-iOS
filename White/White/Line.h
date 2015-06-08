//
//  Line.h
//  White
//
//  Created by Christian Gratton on 2013-03-19.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KineticObject.h"
#import "SoundManager.h"

@class Word;
@class OKSentenceObject;
@class OKTessFont;

@interface Line : KineticObject
{
    // Font
    OKTessFont *font;
    CGRect rBounds;
    
    // Words
    NSMutableArray *wordSource;
    NSMutableArray *source;
    NSMutableArray *words;
    
    // Background loaders    
    NSOperationQueue *queue;
    
    // Touches
    NSMutableDictionary *ctrlPts;
    
    // Properties
    int left, right;
    int highlight;
    
    float dragScroll;
    float xScroll;
    float axScroll;
    float vxScroll;
    
    float touchOffset;
    float offsetSpeed;
    
    //Sound variable
    int forwardSnd, backwardSnd;		//id of the sound samples
    NSString* forwardSndString;
    NSString* backwardSndString;
	int fadeInDuration, fadeOutDuration;	//fade durations (millis)
    int direction;
    SoundManager* soundManager;
    
    float dirLength;
    NSMutableArray* underline;  //will contains points for underline.
    
}

- (id) initWithFont:(OKTessFont*)aFont source:(NSArray*)aSource start:(int)aStart renderingBounds:(CGRect)aRenderingBounds soundManager:(SoundManager*)sndManager;
- (BOOL) revive:(int)highlightedWordIndex;
- (void) backgroundLoadWordAtIndex:(int)index;
//-(void) setAudio:(int)fwd bwd:(int)bwd;
-(void) setAudioString:(NSString*)fwd bwd:(NSString*)bwd;
-(void) setFadeDurations:(int)in out:(int) out;

#pragma mark - DRAW

- (void) draw;
- (void) drawFill;
- (void) drawOutline;
- (void) update:(long)dt;
//- (void) updateWithSoundManager:(SoundManager*)soundManager dt:(long)dt;
- (void) updateTouchOffset:(long)dt;

#pragma mark - TOUCHES

- (void) setCtrlPts:(KineticObject*)aCtrlPt forID:(int)aID;
- (void) removeCtrlPts:(int)aID;
- (BOOL) isTouched;
- (float) getVxScroll;

#pragma mark - BAHVIOURS

- (void) detach;
- (void) quickFadeOut;
- (void) removeLeft;
- (BOOL) addLeft;
- (void) removeRight;
- (BOOL) addRight;

- (BOOL) isFadedOut;
- (BOOL) isTouchingAt:(OKPoint)aPos;
- (int) highlightedWordIndex;
- (int) sourceIndexForWordIndex:(int)index;

@end
