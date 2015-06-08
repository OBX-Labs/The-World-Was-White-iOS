//
//  Line.m
//  White
//
//  Created by Christian Gratton on 2013-03-19.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "Line.h"
#import "OKPoEMMProperties.h"

#import "OKSentenceObject.h"
#import "OKWordObject.h"
#import "OKTessFont.h"
#import "Word.h"
#import "OKNoise.h"

static float SPACE_WIDTH;
static int MAX_SIDE_WORD;// iPad 5 iPhone 5
static float FADE_IN_OPACITY;// iPad 1.0f iPhone 1.0f
static float FADE_OUT_OPACITY;// iPad 0.0f iPhone 0.0f
static float FADE_OUT_SPEED;// iPad 0.05f iPhone 0.05f
static float FADE_IN_SPEED_HIGHLIGHT;// iPad 0.5f iPhone 0.1f
static float FADE_OUT_SPEED_HIGHLIGHT;// iPad 0.001f iPhone 0.001f
static float FADE_SPEED_SCROLL;// iPad 0.75f iPhone 0.75f
static float SCROLL_DRAG;// iPad 0.95f iPhone 0.95f
static float SCROLL_SPEED;// iPad 12.5f iPhone 12.5f
static float MAX_DISTANCE_MULTIPLIER;// iPad 35.0f iPhone 35.0f
static float MAX_DISTANCE_PADDING;// iPad 150.0f iPhone 70.0f
static int MAX_SIDE_PRELOAD_WORDS;// iPad 10 iPhone 10
static float FADE_OUT_SPEED_HIGHLIGHT_MAX;// iPad 0.1f iPhone 0.1f
static float TOUCH_OFFSET;// iPad 15.0 iPhone 15.0
static float OFFSET_SPEED_SCALAR; // iPad 0.065 iPhone 0.065
static float MAX_UNDERLINE_HEIGHT;
static float MAX_UNDERLINE_POINTS;

//direction for sound
static int UNKNOWN = 0;
static int BACKWARD = 1;
static int FORWARD = 2;

@implementation Line

- (id) initWithFont:(OKTessFont*)aFont source:(NSArray*)aSource start:(int)aStart renderingBounds:(CGRect)aRenderingBounds soundManager:(SoundManager *)sndManager
{
    self = [super init];
    if(self)
    {
        // Properties
        SPACE_WIDTH = [aFont getWidthForString:@" "];
        MAX_SIDE_WORD = [[OKPoEMMProperties objectForKey:MaximumSideWords] intValue];
        FADE_IN_OPACITY = [[OKPoEMMProperties objectForKey:FadeInOpacity] floatValue];
        FADE_OUT_OPACITY = [[OKPoEMMProperties objectForKey:FadeOutOpacity] floatValue];
        FADE_OUT_SPEED = [[OKPoEMMProperties objectForKey:FadeOutSpeed] floatValue];
        FADE_IN_SPEED_HIGHLIGHT = [[OKPoEMMProperties objectForKey:FadeInSpeedHighlight] floatValue];
        FADE_OUT_SPEED_HIGHLIGHT = [[OKPoEMMProperties objectForKey:FadeOutSpeedHighlight] floatValue];
        FADE_SPEED_SCROLL = [[OKPoEMMProperties objectForKey:FadeSpeedScroll] floatValue];
        SCROLL_DRAG = [[OKPoEMMProperties objectForKey:ScrollDrag] floatValue];
        SCROLL_SPEED = [[OKPoEMMProperties objectForKey:ScrollSpeed] floatValue];
        MAX_DISTANCE_MULTIPLIER = [[OKPoEMMProperties objectForKey:MaximumDistanceMultiplier] floatValue];
        MAX_DISTANCE_PADDING = [[OKPoEMMProperties objectForKey:MaximumDistancePadding] floatValue];
        MAX_SIDE_PRELOAD_WORDS = [[OKPoEMMProperties objectForKey:MaximumSidePreloadWords] intValue];
        FADE_OUT_SPEED_HIGHLIGHT_MAX = [[OKPoEMMProperties objectForKey:MaximumFadeOutSpeedHighlight] floatValue];
        TOUCH_OFFSET = [[OKPoEMMProperties objectForKey:TouchOffset] floatValue];
        OFFSET_SPEED_SCALAR = [[OKPoEMMProperties objectForKey:OffsetSpeedScalar] floatValue];
        MAX_UNDERLINE_HEIGHT = 10;
        MAX_UNDERLINE_POINTS = 80;
        
        // Catches if there's an error
        // We want to preload more words than side words
        if(MAX_SIDE_PRELOAD_WORDS <= MAX_SIDE_WORD) MAX_SIDE_PRELOAD_WORDS += ((MAX_SIDE_WORD - MAX_SIDE_PRELOAD_WORDS) + 1);
                
        // Preload Queues (we do not want concurrent operations, as we want them completed in order received)        
        queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:1];
        [queue setName:@"LoadQueue"];
        
        // Font
        font = aFont;
        rBounds = aRenderingBounds;
        
        // Words (obj of Word type)
        source = [[NSMutableArray alloc] initWithCapacity:[aSource count]];
        
        // Fill the array with null objects
        for(int i = 0; i < [aSource count]; i++)
        {
            [source insertObject:[NSNull null] atIndex:i];
        }
        
        // (Drawing words)
        words = [[NSMutableArray alloc] init];
        // (Word source (source of source which contains type OKWordObject)
        wordSource = [[NSMutableArray alloc] initWithArray:aSource];
                
        // Preload a few words of each side
        int maxLeftObjects = ((aStart - MAX_SIDE_PRELOAD_WORDS) > 0 ? MAX_SIDE_PRELOAD_WORDS : (aStart - MAX_SIDE_PRELOAD_WORDS) + MAX_SIDE_PRELOAD_WORDS);
        int maxRightObjects = ((aStart + MAX_SIDE_PRELOAD_WORDS) < [aSource count] ? MAX_SIDE_PRELOAD_WORDS : ([aSource count] - (aStart + MAX_SIDE_PRELOAD_WORDS)) + MAX_SIDE_PRELOAD_WORDS);
        
        // We have a bit more to add on the right
        if(maxLeftObjects < MAX_SIDE_PRELOAD_WORDS && maxRightObjects == MAX_SIDE_PRELOAD_WORDS)
        {
            int leftDifference = MAX_SIDE_PRELOAD_WORDS - maxLeftObjects;                        
            maxRightObjects += (maxRightObjects + leftDifference < [aSource count] ? leftDifference : [aSource count] - maxRightObjects);
        }
        else if(maxRightObjects < MAX_SIDE_PRELOAD_WORDS && maxLeftObjects == MAX_SIDE_PRELOAD_WORDS) // We have a bit more to add on the left
        {
            int rightDifference = MAX_SIDE_PRELOAD_WORDS - maxRightObjects;
            maxLeftObjects += (aStart - (maxLeftObjects + rightDifference) >= 0 ? rightDifference : (aStart - (maxLeftObjects + rightDifference)) + (maxLeftObjects + rightDifference));
        }
        
        int sIndex = aStart - maxLeftObjects;
        int eIndex = aStart + maxRightObjects;
        
        for(int i = sIndex; i < eIndex; i++)
        {
            Word *word = [[Word alloc] initWithWord:[aSource objectAtIndex:i] font:aFont renderingBounds:aRenderingBounds];
            [word setOpacity:0.0f];
            [source replaceObjectAtIndex:i withObject:word];
            [word release];
        }
        
        // Touches
        ctrlPts = [[NSMutableDictionary alloc] init];
        
        // Properties
        left = right = aStart;
        highlight = 0;
                
        // Start word
        Word *word = [source objectAtIndex:aStart];
        [word setPosition:OKPointMake(0.0f, 0.0f, 0.0f)];
        
        // Fill up the line
        [words addObject:word];
        
        // To the left
        for(int i = 0; i < MAX_SIDE_WORD; i++)
        {
            if(![self addLeft]) break;
        }
        
        // To the right
        for(int i = 0; i < MAX_SIDE_WORD; i++)
        {
            if(![self addRight]) break;
        }
        
        // Scroll attributes
        dragScroll = 1.0f;
        xScroll = 0.0f;
        vxScroll = 0.0f;
        
        touchOffset = TOUCH_OFFSET;
        
        //set fading attributes
        direction=UNKNOWN;
        fadeInDuration = 2000;
		fadeOutDuration = 500;
        
        //set soundManager
        soundManager = sndManager;
        
        //underline lenght
        dirLength=0;
        underline = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL) revive:(int)highlightedWordIndex
{
    id obj = [words objectAtIndex:highlightedWordIndex];
    
    // Make sure we have an word object (id instead of word to grab anytype of object)
    if(!obj) return NO;
    
    int index = [source indexOfObject:obj];
    
    // Make sure we get an index in bounds of array
    if(index < 0 || index > [source count] - 1) return NO;
    
    // All is good, revive line
    left = right = index;
    highlight = 0;
    
    // Start word
    Word *word = [source objectAtIndex:index];
    [word setPosition:OKPointMake(0.0f, 0.0f, 0.0f)];
    
    [words removeAllObjects];

    // Fill up the line
    [words addObject:word];
    
    // To the left
    for(int i = 0; i < MAX_SIDE_WORD; i++)
    {
        if(![self addLeft]) break;
    }
    
    // To the right
    for(int i = 0; i < MAX_SIDE_WORD; i++)
    {
        if(![self addRight]) break;
    }
    
    // Scroll attributes
    dragScroll = 1.0f;
    xScroll = 0.0f;
    vxScroll = 0.0f;
        
    touchOffset = 0.0f;
    offsetSpeed = (TOUCH_OFFSET - touchOffset) * OFFSET_SPEED_SCALAR;
    
    return YES;
}

- (void) backgroundLoadWordAtIndex:(int)index
{
    if(index < 0 || index > ([wordSource count] - 1)) return;
    
    id obj = [source objectAtIndex:index];
    
    if(obj != [NSNull null]) return;
    
    //There is bug with the queue, when a line is revive, the queue operations is slow/freeze
    //I decide to not use it, and to load the words in source directly.
    /*
    [queue addOperationWithBlock:^{
        
        Word *word = [[Word alloc] initWithWord:[wordSource objectAtIndex:index] font:font renderingBounds:rBounds];
        [word setOpacity:0.0];
        
        // Replace object in array on main thread
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [source replaceObjectAtIndex:index withObject:word];
            [word release];
        }];
    }];
     */
    
    Word *word = [[Word alloc] initWithWord:[wordSource objectAtIndex:index] font:font renderingBounds:rBounds];
    [word setOpacity:0.0];
    // Replace object in array on main thread
    [source replaceObjectAtIndex:index withObject:word];
    [word release];
}

//
// Set the sound sample ids.
// @param fwd id of forward sound
// @param bwd id of backward sound
//
/*
-(void) setAudio:(int)fwd bwd:(int)bwd {
    forwardSnd = fwd;
    backwardSnd = bwd;
}
 */
-(void) setAudioString:(NSString*)fwd bwd:(NSString*)bwd {
    forwardSndString = fwd;
    backwardSndString = bwd;
}
//
 // Set fade durations.
 // @param in fade in duration in millis
 // @param out fade out duration in millis
 //
-(void) setFadeDurations:(int)in out:(int) out {
    fadeInDuration = in;
    fadeOutDuration = out;
}


#pragma mark - DRAW

- (void) draw
{
    //Transform
    glPushMatrix();
    glTranslatef(pos.x + xScroll, pos.y + touchOffset, pos.z);
    for(Word *word in words)
    {
        [word draw];
    }
    
    glPopMatrix();
}

- (void) drawFill
{
    //Transform
    glPushMatrix();
    glTranslatef(pos.x + xScroll, pos.y + touchOffset, pos.z);
    
    for(Word *word in words)
    {
        [word drawFill];
    }
    glPopMatrix();
    
    [self drawUnderline];
}

- (void) drawOutline
{
    //Transform
    glPushMatrix();
    glTranslatef(pos.x + xScroll, pos.y + touchOffset, pos.z);
    for(Word *word in words)
    {
        [word drawOutline];
    }
    glPopMatrix();
}

//
// drawUnderline : will draw the underline under the lind of word
//
-(void) drawUnderline
{
    glPushMatrix();
    //draw an underline
    if([self isTouched])
    {
        //draw line if more than 2 points
        if([underline count]>1)
        {
            if(vxScroll<0)
            {
                glTranslatef(pos.x - [underline count]*3 , pos.y + 20, pos.z);
                
                //draw the underline
                for(int i=1; i<[underline count]; i++){
                    glColor4f(0.0, 0.0, 0.0, i/(float)[underline count]);
                    float line_vertex[]={i*3, [[underline objectAtIndex:i-1] floatValue], (i+1)*3, [[underline objectAtIndex:i] floatValue] };
                    glVertexPointer(2, GL_FLOAT, 0, line_vertex);
                    glDrawArrays(GL_LINES, 0, 2);
                }
            }
            else
            {
                glTranslatef(pos.x, pos.y + 20, pos.z);
                
                //draw the underline
                for(int i=[underline count]-1; i>0; i--){
                    glColor4f(0.0, 0.0, 0.0, i/(float)[underline count]); //
                    float line_vertex[]={([underline count]-i)*3, [[underline objectAtIndex:i-1] floatValue], ([underline count]-i-1)*3, [[underline objectAtIndex:i] floatValue] };
                    glVertexPointer(2, GL_FLOAT, 0, line_vertex);
                    glDrawArrays(GL_LINES, 0, 2);
                }
            }
        }
    }
    
    glPopMatrix();

}
- (void) update:(long)dt
{
    [super update:dt];
    
    Word *w = nil;
    int index;
    
    // Touch
    NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
    KineticObject *ko = [ctrlPts objectForKey:[keyEnum nextObject]]; // Finger "1" (key = 0)
    
    // Drag
    if(ko != nil) [self setPos:ko.pos];
    
    // Scroll
    float dx=0;
    if(ko != nil)
    {            
        dx=pos.x - pPos.x;
        axScroll -= dx/SCROLL_SPEED;
    }
    vxScroll += axScroll;
    vxScroll *= dragScroll;
    xScroll += vxScroll;
    axScroll = 0.0f;
    
    //NSLog(@"VxScroll = %f", vxScroll);
    
    //adjust audio
    int d=0;
    if(ko!=nil)
    {
        //NSLog(@"Velo: %f", dx);
        if(dx>0)
            d=FORWARD; //forward
        else if(dx<0)
            d=BACKWARD; //backward
        else
            d=UNKNOWN;
    }
    
    if(direction!=d){
        if(d==FORWARD){
            //[soundManager crossfade:forwardSnd out:backwardSnd duration:fadeInDuration];
            [soundManager crossfadeWithString:forwardSndString out:backwardSndString duration:fadeInDuration];
        }
        else if(d==BACKWARD){
            //[soundManager crossfade:backwardSnd out:forwardSnd duration:fadeInDuration];
            [soundManager crossfadeWithString:backwardSndString out:forwardSndString duration:fadeInDuration];
        }
        direction=d;
    }

    // Limited scroll to first last words
    w = [words objectAtIndex:0];
    if(w.pos.x + xScroll > 0.0f) {
        xScroll = -w.pos.x;
        //[soundManager fadeout:backwardSndString duration:fadeOutDuration];
    }
    w = [words lastObject];
    if(w.pos.x + xScroll < 0.0f){
        xScroll = -w.pos.x;
        //[soundManager fadeout:forwardSndString duration:fadeOutDuration];

    }
    
    // Find higlithed middle word
    index = 0;
    for(Word *word in words)
    {
        if(word.pos.x - [word getSize].width/2.0f + xScroll < 0 && word.pos.x + [word getSize].width/2.0f + xScroll > 0)
        {
            highlight = index;
            break;
        }
        index++;
    }
    
     // Adjust word list
    if(highlight < MAX_SIDE_WORD)
    {
        while(highlight < MAX_SIDE_WORD) if(![self addLeft]) break;
    }
    else
    {
       
        while(highlight > MAX_SIDE_WORD) [self removeLeft];
    }
    
    if(([words count] - 1 - highlight) < MAX_SIDE_WORD)
    {
        while(([words count] - 1 - highlight) < MAX_SIDE_WORD){
            if(![self addRight]) {
                break;
            }
        }
    }
    else
    {
       while(([words count] - 1 - highlight) > MAX_SIDE_WORD) [self removeRight];
    }
    
    // Set fading values based on scroll offset and speed
    index = 0;
    float maxDist = vxScroll * MAX_DISTANCE_MULTIPLIER;    
    if(maxDist < 0.0f) maxDist *= -1;
    maxDist += MAX_DISTANCE_PADDING;
    double maxLog = log(maxDist);
    
    for(Word *word in words)
    {
        if(ko != nil)
        {
            float offset = word.pos.x + xScroll;
            if(offset < 0.0f) offset *= -1;
            offset += 1;
            
            if(index == highlight) [word fadeTo:FADE_IN_OPACITY speed:FADE_IN_SPEED_HIGHLIGHT];
            else if(offset > maxDist) [word fadeTo:FADE_OUT_OPACITY speed:FADE_SPEED_SCROLL];
            else [word fadeTo:(float)(maxLog - log(offset)) speed:FADE_SPEED_SCROLL];
        }
        
        index++;
    }
    
    for(Word *word in words)
    {
        [word update:dt];
    }

    [self updateTouchOffset:dt];
    
    [self updateUnderline];
    
    
}

//
// updateUnderline : will update datas for underline under the lind of word
//                  uses velocity to calculate the desired lenght
//
-(void) updateUnderline
{
    //calculate lenght of the underline based on scrolling, as a factor of maximum lenght set by MAX_UNDERLINE_POINTS
    int underlineLenght=abs(MAX_UNDERLINE_POINTS*vxScroll/25);
    //NSLog(@"VxScroll=%f, UnderlineLenght = %d", vxScroll, underlineLenght);
    
    //remove the oldest point if max reached
    if([underline count]==MAX_UNDERLINE_POINTS)
        [underline removeObjectAtIndex:0];
    
    //remove oldest point if lenght is too long
    if([underline count]>0 && [underline count]>underlineLenght)
        [underline removeObjectAtIndex:0];
    
    //add a new object if count is not long enough
    if([underline count]<underlineLenght)
        [underline addObject:[NSNumber numberWithFloat:0]];
    
    //update the underline points will slight movement
    if([underline count]>0)
    {
        for(int i=0; i<[underline count]; i++){
            float value=[[underline objectAtIndex:i] floatValue];
            //Update differently for the 1/5 of the points (the oldest), to make the line straight at fade out
            if(i<[underline count]/5)
                value = value + (arc4random()%2)-1;
            else
                value = value + (arc4random()%3)-1;
            
            if(value<0)
                value=0;
            if(value>MAX_UNDERLINE_HEIGHT)
                value=MAX_UNDERLINE_HEIGHT;
            [underline replaceObjectAtIndex:i  withObject:[NSNumber numberWithFloat:value]];
        }
        
    }

}

- (void) updateTouchOffset:(long)dt
{
    float dy = TOUCH_OFFSET - touchOffset;
    
    if(dy > 0.1) {
        touchOffset += offsetSpeed;
    } else {
        touchOffset = TOUCH_OFFSET;
    }
}

#pragma mark - TOUCHES

- (void) setCtrlPts:(KineticObject*)aCtrlPt forID:(int)aID
{
    [ctrlPts setObject:aCtrlPt forKey:[NSString stringWithFormat:@"%i", aID]];
}

- (void) removeCtrlPts:(int)aID
{
    [ctrlPts removeObjectForKey:[NSString stringWithFormat:@"%i", aID]];
        
    // Detach (release from java)
    [self detach];
    
    // Remove unneccassary overhead
    [queue cancelAllOperations];
    
    //erase underline data
    [underline removeAllObjects];
}

- (BOOL) isTouched
{
    if(ctrlPts.count==0)
        return FALSE;
    else
        return TRUE;
}

- (float) getVxScroll
{
    return vxScroll;
}


#pragma mark - BAHVIOURS

- (void) detach
{
    // Fade out words
    for(int i = 0; i < [words count]; i++)
    {
        Word *word = [words objectAtIndex:i];
        
        if(i == highlight) [word fadeOut:FADE_OUT_OPACITY speed:FADE_OUT_SPEED_HIGHLIGHT];
        else [word fadeOut:FADE_OUT_OPACITY speed:FADE_OUT_SPEED];
    }
        
    // Start dragging
    dragScroll = SCROLL_DRAG;
    
    //fade out audio
    [soundManager fadeout:forwardSndString duration:fadeOutDuration];
    [soundManager fadeout:backwardSndString duration:fadeOutDuration];
}

- (void) quickFadeOut {
    // Fade the center word faster to remove line from existance and free up memory
    
    
    int index = [self highlightedWordIndex];
    
    if(index != -1) {
        Word *word = [words objectAtIndex:index];
        [word fadeOut:FADE_OUT_OPACITY speed:FADE_OUT_SPEED_HIGHLIGHT_MAX];
    } else {
        // Fade out all the words because we haven't found the highlighted one
        // Fail safe
        for(Word *word in words)
        {
            [word fadeOut:FADE_OUT_OPACITY speed:FADE_OUT_SPEED_HIGHLIGHT_MAX];
        }
    }
}

- (void) removeLeft
{
    [words removeObjectAtIndex:0];
    left++;
    highlight--;
}

- (BOOL) addLeft
{
    if(left <= 0) return NO;
    
    [self backgroundLoadWordAtIndex:(left - 1)];
    
    // Fail safe in case the thread wasn't able to load up to there
    // The thread will keep on going and we should just see a slow delay
    if([source objectAtIndex:(left - 1)] == [NSNull null]) return NO;
    
    Word *word;
    word = [words objectAtIndex:0];
    OKPoint aPos = word.pos;
    aPos.x -= [word getSize].width/2.0f + SPACE_WIDTH;
    
    word = [source objectAtIndex:(left - 1)];
    aPos.x -= [word getSize].width/2.0f;
    [word setPosition:aPos];
    [words insertObject:word atIndex:0];
    
    left--;
    highlight++;
    
    return YES;
}

- (void) removeRight
{
    [words removeLastObject];
    right--;
}

- (BOOL) addRight
{
    if(right >= ([source count] - 1)) {
        return NO;
    }
    
    [self backgroundLoadWordAtIndex:(right + 1)];
    
    // Fail safe in case the thread wasn't able to load up to there
    // The thread will keep on going and we should just see a slow delay
    if([source objectAtIndex:(right + 1)] == [NSNull null]) {
        return NO;
    }
    
    Word *word;
    word = [words lastObject];
    OKPoint aPos = word.pos;
    aPos.x += [word getSize].width/2.0 + SPACE_WIDTH;
    
    word = [source objectAtIndex:(right + 1)];        
    aPos.x += [word getSize].width/2.0f;
    [word setPosition:aPos];
    [words addObject:word]; // Should add to last position
    
    right++;
    
    return YES;
}

- (BOOL) isFadedOut
{
    for(Word *word in words)
    {
        if(![word isFadedOut]) return NO;
    }
    
    return YES;
}

- (BOOL) isTouchingAt:(OKPoint)aPos
{
    int index = [self highlightedWordIndex];

    if(index == -1) return NO;
    
    Word *word = [words objectAtIndex:index];
    return [word isInsideLarger:aPos px:50];  //add 50px border for selection
    //return [word isInside:aPos];
}

- (int) highlightedWordIndex
{
    int index = -1;
    int count = 0;
    float maxOpacity = 0.0;
    
    for(Word *word in words)
    {
        if([word opacity] > maxOpacity)
        {
            maxOpacity = [word opacity];
            index = count;
        }
        
        count++;
    }
    //NSLog(@"Index:%d", index);
    return index;
}

- (int) sourceIndexForWordIndex:(int)index
{
    if(index==-1)
        return -1;
    
    id obj = [words objectAtIndex:index];
    
    // Make sure we have an word object (id instead of word to grab anytype of object)
    if(!obj) return -1;
    
    int sIndex = [source indexOfObject:obj];
    
    // Make sure we get an index in bounds of array
    if(sIndex < 0 || sIndex > [source count] - 1) return -1;
        
    return sIndex;
}

- (NSString*) description
{
    int index = [self highlightedWordIndex];
    NSString *description;
    
    if(index == -1) {
        description = [NSString stringWithFormat:@"MAX_SIDE_WORD %i FADE_IN_OPACITY %f FADE_OUT_OPACITY %f FADE_OUT_SPEED %f FADE_IN_SPEED_HIGHLIGHT %f FADE_OUT_SPEED_HIGHLIGHT %f FADE_SPEED_SCROLL %f SCROLL_DRAG %f SCROLL_SPEED %f MAX_DISTANCE_MULTIPLIER %f MAX_DISTANCE_PADDING %f", MAX_SIDE_WORD, FADE_IN_OPACITY, FADE_OUT_OPACITY, FADE_OUT_SPEED, FADE_IN_SPEED_HIGHLIGHT, FADE_OUT_SPEED_HIGHLIGHT, FADE_SPEED_SCROLL, SCROLL_DRAG, SCROLL_SPEED, MAX_DISTANCE_MULTIPLIER, MAX_DISTANCE_PADDING];
    } else {
        Word *word = [words objectAtIndex:index];
        description = [word value];
    }
    
    return description;
}

- (void) dealloc
{
    [queue release];
    [source release];
    [wordSource release];
    [words release];
    [ctrlPts release];
    
    [super dealloc];
}

@end
