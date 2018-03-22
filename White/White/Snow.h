//
//  Snow.h
//  White
//
//  Created by Serge on 2013-10-10.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface Snow : NSObject
{
    int tileSize;		//size of the tiles
	int rows, cols;		//number of rows and columns
    //char *tiles;
    NSMutableArray *tiles; //will contain the array of tiles
    char *tileContent;
    GLuint snowTexture;
}

- (id) initWithWidth:(int)width height:(int)height;
- (void) draw;

@end
