//
//  Snow.m
//  White
//
//  Created by Serge on 2013-10-10.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "Snow.h"
#import "OKNoise.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@implementation Snow

- (id) init
{
    return [self initWithWidth:0 height:0];
}

- (id) initWithWidth:(int)width height:(int)height
{
    self = [super init];
    if(self) {
        tileSize =128;
        cols = width/tileSize;
        rows = height/tileSize;
        
        NSLog(@"Init Snow: cols=%i row=%i", cols, rows);
        
        //tiles = new char [cols * rows];
        
        tiles = [[NSMutableArray alloc] init];
       
        int count=0;
        
        //set the noise values
		int bloodMaxOpacity = 255;
		float bloodSize = 0.008f;
		float bloodSnowRatio = 0.35f;
        
        
        //[OKNoise noiseX:(c*tileSize+x)*0.8 y:(r*tileSize+y)*0.8 z:[OKNoise noiseX:count++]*10000];
        //[OKNoise noiseX:(c*tileSize+x)*bloodSize y:(r*tileSize+y)*bloodSize];
        //[OKNoise noiseX:(c*tileSize+x)*0.001 y:(r*tileSize+y)*0.001]*0.1;

            
        /*
        p.color(255, PApplet.map(PApplet.constrain(255*(
                                                        
                                                        p.noise((c*tileSize+x)*0.8f, (r*tileSize+y)*0.8f, p.noise(count++)*10000)
                                                        * 1.0f
                                                        *  PApplet.constrain(PApplet.map(p.noise((c*tileSize+x)*bloodSize, (r*tileSize+y)*bloodSize), bloodSnowRatio, 1, 0, 1), 0, 1) +
                                                        p.noise((c*tileSize+x)*0.001f, (r*tileSize+y)*0.001f)*0.1f
                                                        ), 0, 255), 0, 255, 0, bloodMaxOpacity)
*/
        
        tileContent = new char[tileSize * tileSize];
        
        /*
        //generate the tiles
		for(int c = 0; c < cols; c++){
			for(int r = 0; r < rows; r++){
            
                //char *tileContent = new char[tileSize * tileSize];
                
                for(int y = 0; y < tileSize; y++) {
					for(int x = 0; x < tileSize; x++) {
                        float noise1 = [OKNoise noiseX:(c*tileSize+x)*0.8 y:(r*tileSize+y)*0.8 z:[OKNoise noiseX:count++]*10000];
                        float noise2 = [OKNoise noiseX:(c*tileSize+x)*bloodSize y:(r*tileSize+y)*bloodSize];
                        float noise3 = [OKNoise noiseX:(c*tileSize+x)*0.001 y:(r*tileSize+y)*0.001]*0.1;
                        
                        float temp = (noise1 * noise2 + noise3);
                        int temp2 = (int)(temp *255 * 5);
                        //NSLog(@"TileContent[%i] = %i", y*tileSize+x, temp2 );
                        tileContent[y*tileSize+x] = temp2;
                        NSLog(@"TileContent[%i] = %i", y*tileSize+x, tileContent[y*tileSize+x] );
                    }
                }
                //[tiles addObject:(id)tileContent];
                //[tiles addObject:tileContent];
            }
        }
         */
        
        
    }
    return self;
}

- (void) draw{
    
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

    
    /*
    for(int c = 0; c < cols; c++) {
        for(int r = 0; r < rows; r++) {
            glPushMatrix();
            glTranslatef(c, r, 0.0f);
     
            glEnable (GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, snowTexture);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            
            //avoid weird edges
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            //go for red color?
            glColor4f(1.0, 1.0, 0.0, 1);

            glTexImage2D (
                          GL_TEXTURE_2D,
                          0,
                          GL_RGB,
                          tileSize,
                          tileSize,
                          0,
                          GL_RGB,
                          GL_UNSIGNED_BYTE,
                          tileContent
                          //[tiles objectAtIndex:(c*rows+r)]
                          );
            
            
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glVertexPointer(2, GL_FLOAT, 0, squareVertices);
            glTexCoordPointer(2,GL_FLOAT, 0, perlinTexCoord);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            glDisable(GL_TEXTURE_2D);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            
            glPopMatrix();
        }
    }
     */
    
    for(int c = 0; c < cols; c++) {
        for(int r = 0; r < rows; r++) {

    
    glPushMatrix();
    //glTranslatef(center.x, center.y, 0.0f);
    glTranslatef(c*tileSize, r*tileSize, 0.0f);
    
    glScalef(tileSize, tileSize , 0.0);
    
    glEnable (GL_TEXTURE_2D);
    glEnable(GL_ALPHA_TEST);
    glBindTexture(GL_TEXTURE_2D, snowTexture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //avoid weird edges
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //go for red color?
    //glColor4f(1.0, 1.0, 0.0, 1);
    
    glTexImage2D (
                  GL_TEXTURE_2D,
                  0,
                  GL_LUMINANCE,
                  tileSize,
                  tileSize,
                  0,
                  GL_LUMINANCE,
                  GL_UNSIGNED_BYTE,
                  tileContent
                  );
    
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glTexCoordPointer(2,GL_FLOAT, 0, perlinTexCoord);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_ALPHA_TEST);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glPopMatrix();

        }
    }
    
}





@end
