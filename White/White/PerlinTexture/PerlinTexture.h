//
//  PerlinTexture.h
//  White
//
//  Created by Serge Maheu on 2013-11-01.
//  Copyright (c) 2013 Serge Maheu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "perlin.h"

@interface PerlinTexture : NSObject
{
    long long age;
    int texSize;
    char *tex;
    char *snow;
    char *texOutput;
    int minRange, maxRange, range;
    int minR, minG, minB;				//minimum color values
    int rangeR, rangeG, rangeB;		//range of color values
    float minNoise;					//minimum noise
    float maxNoise;					//maximum noise
    float mass;						//general blood mass
    
    float scale;

    GLuint backgroundTexture;
    
    Perlin * perlin;
    int ageDir;
    int height;
    int width;
    char *texture;
}

- (id) initWithScale:(float)newScale;

- (void) drawX:(int)x y:(int)y w:(int)w h:(int)h;
- (void) update:(long)dt activity:(float)activity;
- (void) setNoise;

//-(char*)getPixels:(double)dt;


@end
