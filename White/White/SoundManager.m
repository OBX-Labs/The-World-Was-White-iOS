//
//  SoundManager.m
//  White
//
//  Created by Serge on 2013-10-18.
//  Copyright (c) 2013 Serge. All rights reserved.
//

#import "SoundManager.h"
#import "Fade.h"

@implementation SoundManager

@synthesize player;

-(id) init
{
    //initiate the array of sound
    samples = [[NSMutableArray alloc] init];   //loaded samples
    samplesDict = [[NSMutableDictionary alloc] init];
    //shifts = [[NSMutableArray alloc] init];     //shifting samples
    shiftsDict = [[NSMutableDictionary alloc] init];
    heads = [[NSMutableArray alloc] init];      //current frames

    return self;
}


 // Load a sample and associate it with an id.
 // @param id id of the sample
 // @param path of the sample
 //
-(void) loadSample:(NSString*)sampleId folder:(NSString*)folder {
    
    NSString *aString = [NSString stringWithFormat:@"%@/%@/%@", [[NSBundle mainBundle] resourcePath], folder, sampleId];
    NSURL *filePath = [NSURL fileURLWithPath:aString isDirectory:NO];
    
    NSLog(@"%@", aString);
    AVAudioPlayer *theAudio;
    theAudio = [[AVAudioPlayer alloc] initWithContentsOfURL:filePath error:nil];
    
    //make sure to load with volume at 0
    [theAudio setVolume:0];
    
    if(theAudio){
        NSLog(@"Adding a sample");
        [samples addObject:theAudio];
        [samplesDict setObject:theAudio forKey:sampleId];
    }
    
    for (NSString *key in samplesDict) {
		NSLog(@"%@ is %@",key, [samplesDict objectForKey:key]);
	}
    
    
}


//
// Crossfade between two samples.
// @param in: string of sample to fade in
// @param out: string of sample to fade out
// @param duration duration of the crossfade
//
-(void) crossfadeWithString:(NSString*)in out:(NSString*)out duration:(int) duration
{
    
   // AVAudioPlayer *sin = [samples objectAtIndex:in];
    AVAudioPlayer *sin = [samplesDict objectForKey:in];
    //AVAudioPlayer *sout = [samples objectAtIndex:out];
    AVAudioPlayer *sout = [samplesDict objectForKey:out];
    
        
    //keep track of outgoing sample frame
    //heads.put(out, sout.getCurrentFrame()/(float)sout.getNumFrames() > 0.95f ? 0 : sout.getCurrentFrame());
    
    //shift samples
    Fade *aFadeIn = [[Fade alloc] initWithSample:sin to:1 in:duration delay:0 stopWhenDone:false];
    Fade *aFadeOut = [[Fade alloc] initWithSample:sout to:0 in:duration delay:0 stopWhenDone:true];
    //[shifts addObject:aFadeIn];
    //[shifts addObject:aFadeOut];
    [shiftsDict setObject:aFadeIn forKey:in];
    [shiftsDict setObject:aFadeOut forKey:out];
    
    if(![sin isPlaying]){
        NSLog(@"Not playing");
        //[sin setVolume:1];
        [sin setNumberOfLoops:-1];
        [sin play];
    }
}

//
// Start looping a sample.
// @param id id of the sample
//
-(void) repeat:(NSString*)soundString {

    AVAudioPlayer *s = [samplesDict objectForKey:soundString];
    [s setNumberOfLoops:-1];
    [s play];
}


//
//Fade out a sample to mute
//@param samples samples to fade and release
//@param duration fade duration
//@param delay delay before fade
//
-(void) fadeout:(NSString*)out duration:(int)duration {
    
    AVAudioPlayer *s = [samplesDict objectForKey:out];
    
    //add samples to shift queue
    Fade *aFade = [[Fade alloc] initWithSample:s to:0 in:duration delay:0 stopWhenDone:TRUE];
    
    //[shifts addObject:aFade];
    [shiftsDict setObject:aFade forKey:out];
    
}


//
//Fade a sample.
//@param id id of the sample
//@param target target volume
//@param duration duration of fade
//

-(void) fade:(NSString*)soundString target:(float)target duration:(int)duration
{
    AVAudioPlayer *s = [samplesDict objectForKey:soundString];
    
    //add samples to shift queue
    Fade *aFade = [[Fade alloc] initWithSample:s to:target in:duration delay:0 stopWhenDone:false];
    
    //shift sample
    //[shifts addObject:aFade];
    [shiftsDict setObject:aFade forKey:soundString];

}

//
//Update the samples.
//
-(void) update {
    
    int temp=0;
    //update the shifting samples
    NSMutableArray *discardedItems = [NSMutableArray array];
    /*
    for(Fade* aFade in shifts){
        [aFade update];
        if([aFade isDone]){
            [discardedItems addObject:aFade];
        }
        temp++;
    }
    [shifts removeObjectsInArray:discardedItems];
    */
    
    
    for(NSString *key in shiftsDict){
        Fade *aFade=[shiftsDict objectForKey:key];
        [aFade update];
        if([aFade isDone])
           [discardedItems addObject:key];
       //
    }
    [shiftsDict removeObjectsForKeys:discardedItems];
     
     
    //NSLog(@"Number of shifts: %d", temp);

    
}


//
// Stop the sound manager.
//
-(void) stop {
    //Sonia.stop();
}



/**
 * Get the list of files in a passed relative director.
 */
-(NSArray*) aifFilesInDirectory:(NSString*) dir {
   
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    
    NSLog(@"THERE ARE %d SAMPLES in %@", [directoryContent count], dir);
    return directoryContent;
    return nil;
}

-(long long) getMillis{
    
    //long long nowMillis = (long long)([[NSDate date] timeIntervalSince1970])*1000;
    
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t machTime = mach_absolute_time();
    
    // Convert to nanoseconds - if this is the first time we've run, get the timebase.
    if (sTimebaseInfo.denom == 0 )
    {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    
    // Convert the mach time to milliseconds
    uint64_t millis = ((machTime / 1000000) * sTimebaseInfo.numer) / sTimebaseInfo.denom;
    
    long long nowMillis = (long long)millis;
    return nowMillis;
}


@end
