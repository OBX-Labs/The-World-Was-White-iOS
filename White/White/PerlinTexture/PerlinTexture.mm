//
//  PerlinTexture.m
//  White
//
//  Created by Serge Maheu on 2013-11-01.
//  Copyright (c) 2013 Serge Maheu. All rights reserved.
//

#import "PerlinTexture.h"
#import "OKNoise.h"
//#import "PerlinNoise.h"

static BOOL NO_SCALE = NO; // YES to render the texture 1:1, NO for full size

@implementation PerlinTexture

- (id) init
{
    return [self initWithScale:0.0f];
}

- (id) initWithScale:(float)newScale
{
    self = [super init];
    if(self) {        
        age = 0;
        texSize = 128;
        tex = new char[texSize * texSize * 3];
        snow = new char[texSize * texSize * 3];
        texOutput = new char[texSize * texSize * 3];
        minRange = 50;
        maxRange = 200;
        range = maxRange - minRange;
        scale = newScale;
        minNoise = 1.0f;
        maxNoise = 1.0f;
        minR = 150;
        minG = 0;
        minB = 23;
        rangeR = 255 - minR;
        rangeG = 255 - minG;
        rangeB = 255 - minB;
        mass = 0.8f;
        
        //perlin = new Perlin(1, 0.028, 1, 2, 0.3);
        perlin = new Perlin(1, 0.028, 1, 2, 0.3);
        ageDir = 1;
        
        height=320;
        width=480;
        texture = new char[width*height*3];
    }
    return self;
}

- (void) drawX:(int)x y:(int)y w:(int)w h:(int)h
{
    
    static const GLfloat perlinTexCoord[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f,  0.0f,
        1.0f,  1.0f,
    };

    static const GLfloat squareVertices[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f,  0.0f,
        1.0f,  1.0f,
    };
    
    //CGPoint center = CGPointMake(x - w/2.0f, y - w/2.0f);
    
    glPushMatrix();
    //glTranslatef(center.x, center.y, 0.0f);
    glTranslatef(x, y, 0.0f);
    
    if(NO_SCALE) glScalef(texSize, texSize, 0.0);
    else glScalef(w, h, 0.0);
    //else glScalef(300, 150, 0.0);
    
    glEnable (GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    
    //avoid weird edges
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //use white color for background
    glColor4f(1.0, 1.0, 1.0, 1);

    
    glTexImage2D (
                  GL_TEXTURE_2D,
                  0,
                  GL_RGB,
                  texSize,
                  texSize,
                  0,
                  GL_RGB,
                  GL_UNSIGNED_BYTE,
                  tex
                  );
    
    
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glTexCoordPointer(2,GL_FLOAT, 0, perlinTexCoord);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    

    
    
    glPopMatrix();
}

- (void) update:(long)dt activity:(float)activity
{
    age += dt;
    
    //adjust noise based on activity
    minNoise = 1 - activity;
    maxNoise = 1 - activity * mass;
    
    //NSLog(@"MinNoise=%f  MaxNoise=%f", minNoise, maxNoise);

    [self setNoise];
   
}

- (void) setNoise
{
    [OKNoise noiseDetail:2 falloff:0.5f];
    
    float fAge = age/100.0f;   //old value age/100.0f
    //float density = 0.5f;
    float value =0;
    int val = 0;
    
    for(int y = 0; y < texSize; y++)
    {
        for(int x = 0; x < texSize; x++)
        {
            val = 3 * (texSize * y + x);
            
            //NOTE: I tested using OKNoise class, but not great with use for z. Use perlin class instead
            //float aNoise = [OKNoise noiseX:x*density y:y*density z:fAge];
            
            //calcule perlin noise, output result is between -1:1
            //float aNoise = perlin->Get(x*4, y*4, fAge);
            float aNoise = perlin->Get(x*1, y*1, fAge);
            
            //rescale for 0:1
            aNoise = (aNoise + 1)/2;
            
            //map value from between [minNoise:maxNoise] to [0:1]
            //CGFloat out = outMin + (outMax - outMin) * (in - inMin) / (inMax - inMin);
            if(aNoise<minNoise)
                aNoise=minNoise;
            if(aNoise>maxNoise)
                aNoise=maxNoise;
            value = (aNoise - minNoise)/(maxNoise-minNoise);

            //constrain value (make sure it's between 0:1)
            if(value>1)
                value=1;
            if(value<0)
                value=0;
    
            value = 1 - value;
            
            //NSLog(@"value= %f", value);
            
            tex[val]= minR+ value*rangeR;
            tex[val+1]= minG+ value*rangeG;
            tex[val+2]= minB+ value*rangeB;
      
        }
    }
}

@end
