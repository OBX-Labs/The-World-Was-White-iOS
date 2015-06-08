//
//  White.h
//  White
//
//  Created by Christian Gratton on 2013-03-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKGeometry.h"
#import "SoundManager.h"

@class OKTessFont;
@class OKTextObject;
@class OKSentenceObject;
@class OKCharObject;

@class OKTessData;
@class OKCharDef;
@class Line;

@class PerlinTexture;
@class Snow;

@interface White : NSObject
{
    // Screen bounds
    CGRect sBounds;
    
    // Touches
    NSMutableDictionary *ctrlPts;
    
    // Properties
    OKTessFont *font;
    
    OKTextObject *text;
    float bgOpacity;
    OKPoint bgCenter;
    NSMutableArray *bgWords;
    
    NSMutableArray *scrollTextLines;
    NSMutableArray *cScrollTextLines;
    NSMutableArray *removableScrollTextLines;
    int scrollTextWords;
    int nextWordLine1;
    int nextWordLine2;
    
    NSMutableArray *words;
        
    // Animation time tracking
    NSDate *lUpdate;
    NSDate *now;
    long DT;
    int frameCount;
    
    // Blood
    PerlinTexture *blood;   //blood layer
    Snow *snowTexture;      //noisy snow layer that covers the blood
    float activity;         //level of interaction activity
    float BLOOD_START;      //multiplier to define when blood starts (0 = starts right away, 1= starts when activity is at maximum)
    
    //audio
    SoundManager *soundManager;
    
}

- (id) initWithFont:(OKTessFont*)tFont text:(OKTextObject*)textObj andBounds:(CGRect)bounds;
- (void) buildOutlinedWords:(OKSentenceObject*)aSentenceObj;
- (int) scrollTextWordsCount:(OKTextObject*)textObj;
- (NSArray*) buildWords:(OKTextObject*)textObj;
- (Line*) createLine:(int)start;

#pragma mark - DRAW

- (void) draw;
- (void) update:(long)dt;
- (void) updateBgText:(long)dt;
- (void) updateText:(long)dt;
- (void) drawText;
- (void) drawBlood;

#pragma mark - Touches

- (void) setCtrlPts:(int)aID atPosition:(CGPoint)aPosition;
- (void) removeCtrlPts:(int)aID atPosition:(CGPoint)aPosition;

- (void) touchesBegan:(int)aID atPosition:(CGPoint)aPosition;
- (void) touchesMoved:(int)aID atPosition:(CGPoint)aPosition;
- (void) touchesEnded:(int)aID atPosition:(CGPoint)aPosition;
- (void) touchesCancelled:(int)aID atPosition:(CGPoint)aPosition;

@end
