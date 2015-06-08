//
//  White.m
//  White
//
//  Created by Christian Gratton on 2013-03-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "White.h"
#import "OKPoEMMProperties.h"

#import "OKTessFont.h"
#import "OKTextObject.h"
#import "OKSentenceObject.h"
#import "OKCharObject.h"
#import "OKTessData.h"
#import "OKCharDef.h"
#import "Line.h"
#import "Word.h"
#import "OutlinedWord.h"

#import "OKNoise.h"
#import "PerlinTexture.h"
#import "Snow.h"
#import "SoundManager.h"

static NSString *BG_TEXT = @"";
static float BG_COLOR[] = {0.0, 0.0, 0.0, 0.0};
static float BG_TEXT_SPEED;// iPad 6.0f iPhone 3.0f
static float BG_TEXT_HMARGIN;// iPad 350.0f iPhone 165.0f
static float BG_TEXT_VMARGIN;// iPad 250.0f iPhone 105.0f
static float BG_TEXT_SCALE;// iPad 7.75f iPhone 5.25f
static float BG_TEXT_TOP;
static float BG_TEXT_LEADING;
static float BG_TEXT_LEADING_SCALAR;// iPad 0.8f iPhone 0.8f
static int MAX_SENTENCES;// iPad 2 iPhone 2
static float BG_FLICKER_SPEED;// iPad 0.5f iPhone 0.5f
static float BG_FLICKER_PROPABILITY;// iPad 0.7f iPhone 0.7f
static float BG_FLICKER_SCALAR;// iPad 0.235f iPhone 0.235f
static int MAX_FADING_LINES;// iPad 10 iPhone 10
static NSString *SCROLL_TOUCH1_FWD_AUDIO = @"backwards.mp3";	//filename of sound for forward motion of first touch
static NSString *SCROLL_TOUCH1_BWD_AUDIO = @"bwd-01.mp3";		//filename of sound for backward motion of first touch
static NSString *SCROLL_TOUCH2_FWD_AUDIO = @"backwards.mp3";    //filename of sound for forward motion of second touch
static NSString *SCROLL_TOUCH2_BWD_AUDIO = @"bwd-03.mp3";       //filename of sound for backward motion of second touch
static NSString *SND_BLOOD = @"blood.mp3";       //filename of sound for backward motion of second touch
static int SCROLL_AUDIO_FADE_IN_DURATION;
static int SCROLL_AUDIO_FADE_OUT_DURATION;

@implementation White

- (id) initWithFont:(OKTessFont*)tFont text:(OKTextObject*)textObj andBounds:(CGRect)bounds
{
    self = [super init];
    if(self)
    {
        // Load propeties
        BG_TEXT = [OKPoEMMProperties objectForKey:Title];
        NSArray *bgColor = [OKPoEMMProperties objectForKey:BackgroundColor];
        BG_COLOR[0] = [[bgColor objectAtIndex:0] floatValue];
        BG_COLOR[1] = [[bgColor objectAtIndex:1] floatValue];
        BG_COLOR[2] = [[bgColor objectAtIndex:2] floatValue];
        BG_COLOR[3] = [[bgColor objectAtIndex:3] floatValue];
        BG_TEXT_SPEED = [[OKPoEMMProperties objectForKey:BackgroundTextSpeed] floatValue];
        BG_TEXT_HMARGIN = [[OKPoEMMProperties objectForKey:BackgroundTextHorizontalMargin] floatValue];
        BG_TEXT_VMARGIN = [[OKPoEMMProperties objectForKey:BackgroundTextVerticalMargin] floatValue];
        BG_TEXT_SCALE = [[OKPoEMMProperties objectForKey:BackgroundTextScale] floatValue];
        BG_TEXT_LEADING_SCALAR = [[OKPoEMMProperties objectForKey:BackgroundTextLeadingScalar] floatValue];
        MAX_SENTENCES = [[OKPoEMMProperties objectForKey:MaximumSentences] floatValue];
        BG_FLICKER_SPEED = [[OKPoEMMProperties objectForKey:BackgroundFlickerSpeed] floatValue];
        BG_FLICKER_PROPABILITY = [[OKPoEMMProperties objectForKey:BackgroundFlickerPropability] floatValue];
        BG_FLICKER_SCALAR = [[OKPoEMMProperties objectForKey:BackgroundFlickerScalar] floatValue];
        MAX_FADING_LINES = [[OKPoEMMProperties objectForKey:MaximumFadingLines] intValue];
        
        // Screen bounds
        sBounds = bounds;
        
        // Touches
        ctrlPts = [[NSMutableDictionary alloc] init];
        
        // Properties
        font = tFont;
        
        text = textObj;
        
        bgOpacity = 0.0f;
        bgCenter = OKPointMake(sBounds.size.width / 2.0f, sBounds.size.height / 2.0f, 0.0f);
        
        // Background words
        bgWords = [[NSMutableArray alloc] init];
        
        OKSentenceObject *outlinedSentence = [[OKSentenceObject alloc] initWithSentence:BG_TEXT withTessFont:font];
        [self buildOutlinedWords:outlinedSentence];
        [outlinedSentence release];
        
        // Count scroll text words
        scrollTextWords = [self scrollTextWordsCount:text];
        // Set the current index (next word shown on touch) to the first word
        nextWordLine1 = 0;
        nextWordLine2 = 0;
        
        // Create empty lines array
        scrollTextLines = [[NSMutableArray alloc] init];
        
        // Create array that holds max current sentences (this needs to match MAX_FINGERS in EAGLView)
        cScrollTextLines = [[NSMutableArray alloc] initWithCapacity:MAX_SENTENCES];
        // Insert null value in array
        for(int i = 0; i < MAX_SENTENCES; i++)
        {
            [cScrollTextLines insertObject:[NSNull null] atIndex:i];
        }
        
        // Create array that is used to dump "dead" sentences
        removableScrollTextLines = [[NSMutableArray alloc] init];
        
        // Create an array of words (all words)
        words = [[NSMutableArray alloc] init];
        
        for(OKSentenceObject *sentenceObj in textObj.sentenceObjects)
        {
            for(OKWordObject *wordObj in sentenceObj.wordObjects)
            {
                [words addObject:wordObj];
            }
        }
        
        // Animation time tracking
        lUpdate = [[NSDate alloc] init];
        now = [[NSDate alloc] init];
                
        // Stats
        NSLog(@"Total Sentences %i", [text.sentenceObjects count]);
        NSLog(@"Total Words %i", scrollTextWords);
        NSLog(@"Total Glyphs (with spaces) %i", [text.text length]);
        
        //blood = [[PerlinTexture alloc] init];
        blood = [[PerlinTexture alloc] init];
        snowTexture = [[Snow alloc] initWithWidth:500 height:500];
        BLOOD_START=0.75; 
        
        //audio
        [self setupAudio];
        SCROLL_AUDIO_FADE_IN_DURATION=2000;
        SCROLL_AUDIO_FADE_OUT_DURATION=500;
    }
    return self;
}

- (void) buildOutlinedWords:(OKSentenceObject*)aSentenceObj
{
    for(OKWordObject *word in aSentenceObj.wordObjects)
    {
        OutlinedWord *oWord = [[OutlinedWord alloc] initWithWord:word font:font renderingBounds:sBounds];
        [oWord setScale:BG_TEXT_SCALE];
        [bgWords addObject:oWord];
        [oWord release];
    }
    
    BG_TEXT_LEADING = ([aSentenceObj getHeight] * BG_TEXT_SCALE) * BG_TEXT_LEADING_SCALAR; // Overlaps texts
    BG_TEXT_TOP = sBounds.size.height/2.0f + (((BG_TEXT_LEADING * [bgWords count])/2.0f) - BG_TEXT_LEADING); // Centers text
}

- (int) scrollTextWordsCount:(OKTextObject*)textObj
{
    int cCount = 0;
    for(OKSentenceObject *sentenceObj in textObj.sentenceObjects)
    {
        for(OKWordObject *wordObj in sentenceObj.wordObjects)
        {
            cCount++;
        }
    }
    
    return cCount;
}

- (NSArray*) buildWords:(OKTextObject *)textObj
{
    NSMutableArray *source = [[NSMutableArray alloc] init];
    
    for(OKSentenceObject *sentenceObj in textObj.sentenceObjects)
    {
        for(OKWordObject *wordObj in sentenceObj.wordObjects)
        {
            Word *word = [[Word alloc] initWithWord:wordObj font:font renderingBounds:sBounds];
            [word setOpacity:0.0f];
            [source addObject:word];
            [word release];
        }
    }
    
    return source;
}

- (Line*) createLine:(int)start {
    return [[Line alloc] initWithFont:font source:words start:start renderingBounds:sBounds soundManager:soundManager];
    
}

//initialise audio
-(void) setupAudio
{
    //init sound manager
    soundManager = [[SoundManager alloc] init];
    
    //load sounds
    [soundManager loadSample:SCROLL_TOUCH1_FWD_AUDIO folder:@"Sounds"];
    [soundManager loadSample:SCROLL_TOUCH1_BWD_AUDIO folder:@"Sounds"];
    [soundManager loadSample:SCROLL_TOUCH2_FWD_AUDIO folder:@"Sounds"];
    [soundManager loadSample:SCROLL_TOUCH2_BWD_AUDIO folder:@"Sounds"];
    [soundManager loadSample:SND_BLOOD folder:@"Sounds"];
    
    //start play of blood sound on repeat
    [soundManager repeat:SND_BLOOD];
    
}


#pragma mark - DRAW

- (void) draw
{
    //Millis since last draw
    DT = (long)([now timeIntervalSinceDate:lUpdate] * 1000);
    [lUpdate release];
    
    //Clear - Draw bg color (open gl)
    glClearColor(BG_COLOR[0], BG_COLOR[1], BG_COLOR[2], BG_COLOR[3]);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //Enable Blending
    glEnable(GL_BLEND);
    
    // Update
    [self update:DT];
    
    [self updateActivity];

    [self updateBlood];
    
    // Draw blood
    [self drawBlood];
    
    //[self drawSnow];
    
    // Draw Text
    [self drawText];
        
    //Disable Blending
    glDisable(GL_BLEND);
    
    //Keep track of time    
    lUpdate = [[NSDate alloc] initWithTimeIntervalSince1970:[now timeIntervalSince1970]];
    [now release];
    now = [[NSDate alloc] init];
    frameCount++;
}

/**
 * Update the touch activity meter.
 */
-(void) updateActivity {
    int found = 0;
    float speed = 0;
    
    for(id iLine in cScrollTextLines)
    {
        // If we have a line for a given finger, get the velocity
        if(iLine != [NSNull null])
        {
            Line *line = (Line*)iLine;
            speed+= abs([line getVxScroll])/40.00f;
            found++;
        }
    }

    //NSLog(@"Speed = %f Activity=%f", speed, activity);
    
    //adjust the current level of activity towards target
    if (speed > activity) {
        activity += 0.001; //0.0005f;  //0.001f
        if (activity > found)
            activity -= 0.001f;
    }
    else {
        activity -= 0.0005f;  //0.001f
        if (activity < 0)
            activity = 0;
    }
    
}


- (void) update:(long)dt
{
    // Update control points
    for(NSString *aKey in ctrlPts)
    {
        KineticObject *ko = [ctrlPts objectForKey:aKey];
        [ko update:dt];
    }
    
    //update audio
    [soundManager update];

    // Update background text
    [self updateBgText:dt];
    
    // Update text
    [self updateText:dt];
    
    }

- (void) updateBgText:(long)dt
{
    float width = sBounds.size.width;
    float height = sBounds.size.height;

    // Set noise details
    [OKNoise noiseDetail:4 falloff:0.5f];
    
    float p = [OKNoise noiseX:((width/2.0f + bgCenter.x) * 0.005f) y:((height/2.0f + bgCenter.y) * 0.005f) z:(frameCount * 0.01f)];
    float r = p * M_TWO_PI * 4.0f;
    
    bgCenter.x += cosf(r) * BG_TEXT_SPEED * p;
    if(bgCenter.x < BG_TEXT_HMARGIN) bgCenter.x = BG_TEXT_HMARGIN;
    else if(bgCenter.x > width-BG_TEXT_HMARGIN) bgCenter.x = width - BG_TEXT_HMARGIN;
    
    bgCenter.y += sinf(r) * BG_TEXT_SPEED * p;
    if(bgCenter.y < BG_TEXT_VMARGIN) bgCenter.y = BG_TEXT_VMARGIN;
    else if(bgCenter.y > height - BG_TEXT_VMARGIN) bgCenter.y = height - BG_TEXT_VMARGIN;
    
    p = [OKNoise noiseX:((width/2.0f + bgCenter.x) * BG_FLICKER_SPEED) y:((height/2.0f + bgCenter.y) * BG_FLICKER_SPEED) z:(frameCount * BG_FLICKER_SPEED)] + BG_FLICKER_SCALAR;
   
    bgOpacity = (p > BG_FLICKER_PROPABILITY ? 1.0f : 0.0f);
    
    // Update bg text
    for(OutlinedWord *oWord in bgWords)
    {
        [oWord setOpacity:bgOpacity];
        [oWord update:dt];
    }
}

- (void) updateText:(long)dt
{
    // Update current lines
    for(id iLine in cScrollTextLines)
    {
        // If we have a line for a given finger draw it
        if(iLine != [NSNull null])
        {
            Line *line = (Line*)iLine;
            [line update:dt];
        }
    }
    
    // Update fading lines
    for(Line *line in scrollTextLines)
    {
        if([line isFadedOut]) [removableScrollTextLines addObject:line];
        
        [line update:dt];
    }
    
    // Remove "dead" linesremovableWords
    if([removableScrollTextLines count] > 0)
    {
        [scrollTextLines removeObjectsInArray:removableScrollTextLines];
        
        for(Line *line in removableScrollTextLines) {
            [line release];
        }
        
        [removableScrollTextLines removeAllObjects];
    }
}

- (void) drawText
{
    // If BG Text opacity is greater than 0.0f draw it, if not, save some cycles...
    if(bgOpacity > 0.0f)
    {
        //Transform
        glPushMatrix();
        
        float width = sBounds.size.width;
        float height = sBounds.size.height;
        
        glTranslatef((bgCenter.x - (width/2.0f)), (bgCenter.y - height/2.0f), 0.0f);
        float y = BG_TEXT_TOP;
        
        for(OutlinedWord *oWord in bgWords)
        {
            glPushMatrix();
            glTranslatef((width/2.0f), y, 0.0f);
            [oWord draw];
            y -= BG_TEXT_LEADING;
            glPopMatrix();
        }
        
        glPopMatrix();
    }
    
    glPushMatrix();
    glTranslatef(0.0f, 0.0f, 0.0f);
    // Draw current lines
    for(id iLine in cScrollTextLines)
    {
        // If we have a line for a given finger draw it
        if(iLine != [NSNull null])
        {
            Line *line = (Line*)iLine;
            [line drawFill];
        }
    }
    
    // Draw fading lines
    for(Line *line in scrollTextLines)
    {
        [line drawFill];
    }
    glPopMatrix();
}

//
// Update Blood based on activity
//
- (void) updateBlood
{
    //We map activity*activity value from [0:1] to [1-BLOOD_START:1]
    //CGFloat out = outMin + (outMax - outMin) * (in - inMin) / (inMax - inMin);
    //out =(1-BLOOD_START) + (1 - (1-BLOOD_START)) * (in - 0) / (1 - 0)
    
    float activityMult = (1-BLOOD_START) + BLOOD_START*(activity*activity) ;
    if(activityMult<0)
        activityMult=0;
    if(activityMult>1)
        activityMult=1;
    [blood update:DT activity:activityMult];
    
    //update blood sound based on activity
    // map multactivity from [0.5:1] to [0:1]
    float volume = (activityMult - 0.5) / 0.5;
    if(volume<0)
        volume=0;
    [soundManager fade:SND_BLOOD target:volume duration:0];
}

- (void) drawBlood
{
    if(activity>0)
        [blood drawX:0 y:0 w:sBounds.size.width h:sBounds.size.height];
}



- (void) drawSnow
{
   //[snowTexture draw];
}

#pragma mark - Touches

- (void) setCtrlPts:(int)aID atPosition:(CGPoint)aPosition
{    
    KineticObject *pt = [ctrlPts objectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    if(!pt)
    {
        KineticObject *ko = [[KineticObject alloc] init];
        [ko setPos:OKPointMake(aPosition.x, aPosition.y, 0.0)];
                
        [ctrlPts setObject:ko forKey:[NSString stringWithFormat:@"%i", aID]];
        pt = ko;
        
        [ko release];
    }
    else
    {
        [pt setPos:OKPointMake(aPosition.x, aPosition.y, 0.0)];
    }
    
    // Determine which finger is touching and which if we need to start a new line or update existing
    id iLine = [cScrollTextLines objectAtIndex:aID]; // Gets line at finger index
  
    //NSLog(@"Set CTRL PTS:%d", aID);
    
    // No line exists for this finger, create a new one or pickup an existing
    if(iLine == [NSNull null])
    {
        Line *line = nil;
        
        // Are we touching a line?
        for(Line *l in scrollTextLines)
        {
            if([l isTouchingAt:pt.pos]) {
                line = l;
                break;
            }
        }
        
        // We touched a line
        // Check if it can be revived
        BOOL revived = NO;
        if(line) {
            int highlightedWordIndex = [line highlightedWordIndex];
            
            // If we can't get the index of the highlighted word, return
            if(highlightedWordIndex == -1) return;
            
            // Flag if line if revived
            revived = [line revive:highlightedWordIndex];
        }
        
        // Check if we either didn't touch a line or if we weren't able to revive a line
        if(!line || !revived) {
            int start = -1;
            if(aID == 0) { // First finder
                start = nextWordLine1;
            } else if (aID == 1) {
                start = nextWordLine2;
            }
            
            if(start == -1) return;
            
            // Create line
            line = [self createLine:start];
            
            //setup audio for the new line depending if user touching with first or second finger
            //if([ctrlPts count]==0){
            if(aID==0){
                 NSLog(@"FIRST:%d", aID);
                [line setAudioString:SCROLL_TOUCH1_FWD_AUDIO bwd:SCROLL_TOUCH1_BWD_AUDIO];
            }
            else{
                NSLog(@"SECOND:%d", aID);
                [line setAudioString:SCROLL_TOUCH2_FWD_AUDIO bwd:SCROLL_TOUCH2_BWD_AUDIO];
            }
            [line setFadeDurations:SCROLL_AUDIO_FADE_IN_DURATION out:SCROLL_AUDIO_FADE_OUT_DURATION];
        }
        
        // Set ctrl points and properties
        [line setCtrlPts:pt forID:aID];
        [line setPos:pt.pos];
        [cScrollTextLines replaceObjectAtIndex:aID withObject:line];
    }
    else { // Already interacting with this object
        Line *line = (Line*)iLine;
        [line setCtrlPts:pt forID:aID];
    }
}

- (void) removeCtrlPts:(int)aID atPosition:(CGPoint)aPosition
{
    if([ctrlPts count] == 0) return;
    
    NSLog(@"Remove CTRL PTS:%d", aID);
    
    // Remove Ctrl Points
    [ctrlPts removeObjectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    // Determine which finger is touching and which if we have a line for that finger
    id iLine = [cScrollTextLines objectAtIndex:aID]; // Gets line at finger index
    
    if(iLine == [NSNull null]) return; // we don't have a line
    
    // We have a line
    Line *line = (Line*)iLine;
    [line removeCtrlPts:aID];
    
    // Update finger index stream only if new line
    if(![scrollTextLines containsObject:line]) {
        // Next time, show the next word (based on finger stream)
        int index = [line sourceIndexForWordIndex:[line highlightedWordIndex]];
        
        if(aID == 0) { // First finger
            // Make sure we have a highlighted word index
            if(index == -1) index = nextWordLine1;
            nextWordLine1 = (index + 2) % scrollTextWords;            
        } else if(aID == 1) { // Second finger
            // Make sure we have a highlighted word index
            if(index == -1) index = nextWordLine2;
            nextWordLine2 = (index + 2) % scrollTextWords;
        }
    } else {
        // Update position of object in array (so it fades out at the right time)
        [scrollTextLines removeObject:line];
    }
    
    
    // Add line to scroll text lines array
    [scrollTextLines addObject:line];
    
    // Remove line from current lines array
    [cScrollTextLines replaceObjectAtIndex:aID withObject:[NSNull null]];
    
    // Fade out lines faster if needed (for performance)
    if([scrollTextLines count] > MAX_FADING_LINES)
    {
        Line *lLine = [scrollTextLines objectAtIndex:([scrollTextLines count] - (MAX_FADING_LINES + 1))];
        [lLine quickFadeOut];
    }

}

- (void) touchesBegan:(int)aID atPosition:(CGPoint)aPosition
{        
    // Set Control Point
    [self setCtrlPts:aID atPosition:aPosition];
}

- (void) touchesMoved:(int)aID atPosition:(CGPoint)aPosition
{
    // Set Control Point
    [self setCtrlPts:aID atPosition:aPosition];
}

- (void) touchesEnded:(int)aID atPosition:(CGPoint)aPosition
{
    // Remove Control Point
    [self removeCtrlPts:aID atPosition:aPosition];
}

- (void) touchesCancelled:(int)aID atPosition:(CGPoint)aPosition
{
    // Remove Control Point
    [self removeCtrlPts:aID atPosition:aPosition];
}

- (void) dealloc
{    
    [ctrlPts release];
    [bgWords release];
    [scrollTextLines release];
    [removableScrollTextLines release];
    [words release];
    [lUpdate release];
    [now release];
    
    [super dealloc];
}

@end
