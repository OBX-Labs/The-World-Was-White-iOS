//
//  OKPoEMMProperties.h
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "OKAppProperties.h"

// Properties name constants of static parameters (plist)
// These values can be used throughout different poemm apps, they should not change
extern NSString* const Text; // current package
extern NSString* const Title;
extern NSString* const Default;
extern NSString* const TextFile;
extern NSString* const TextVersion;
extern NSString* const AuthorImage;
extern NSString* const FontFile;
extern NSString* const FontOutlineFile;
extern NSString* const FontTessellationFile;

// This will be unique to each poemm app, you will need to create a unique property for each different value that appears in the plist
extern NSString* const BackgroundFontFile;
extern NSString* const BackgroundFontTessellationFile;

// White.mm
extern NSString* const BackgroundColor;
extern NSString* const BackgroundTextSpeed;
extern NSString* const BackgroundTextHorizontalMargin;
extern NSString* const BackgroundTextVerticalMargin;
extern NSString* const BackgroundTextScale;
extern NSString* const BackgroundTextLeadingScalar;
extern NSString* const MaximumSentences;
extern NSString* const BackgroundFlickerSpeed;
extern NSString* const BackgroundFlickerPropability;
extern NSString* const BackgroundFlickerScalar;
extern NSString* const MaximumFadingLines;

// Line.m
extern NSString* const MaximumSideWords;
extern NSString* const FadeInOpacity;
extern NSString* const FadeOutOpacity;
extern NSString* const FadeOutSpeed;
extern NSString* const FadeInSpeedHighlight;
extern NSString* const FadeOutSpeedHighlight;
extern NSString* const FadeSpeedScroll;
extern NSString* const ScrollDrag;
extern NSString* const ScrollSpeed;
extern NSString* const MaximumDistanceMultiplier;
extern NSString* const MaximumDistancePadding;
extern NSString* const MaximumSidePreloadWords;
extern NSString* const MaximumFadeOutSpeedHighlight;
extern NSString* const TouchOffset;
extern NSString* const OffsetSpeedScalar;

// Word.m
extern NSString* const WordFillColor;
extern NSString* const WordTessellationAccurracy;

// OutlinedWord.m
extern NSString* const OutlinedWordFillColor;
extern NSString* const OutlinedWordOutlineColor;
extern NSString* const OutlinedWordTessellationAccurracy;

// TessGlyph.mm
extern NSString* const OutlineWidth;
extern NSString* const RenderPadding;

// Property name constant of dynamic paramaters
extern NSString* const Orientation;
extern NSString* const UprightAngle;

@interface OKPoEMMProperties : OKAppProperties

// Get the device orientation
+ (UIDeviceOrientation) orientation;

// Keep track of the device orientation (only the ones supported by the app)
+ (void) setOrientation:(UIDeviceOrientation)aOrientation;

// Get the upright angle which is recomputed when the orientation is set
+ (int) uprightAngle;

+ (void) initWithContentsOfFile:(NSString *)aPath;

+ (id) objectForKey:(id)aKey;

+ (void) setObject:(id)aObject forKey:(id)aKey;

// Fills the properties with a loaded package dictionary (Properties-iPhone, Properties-iPhone-Retina, Properties-iPhone-568h, Properties-iPad, Properties-iPad-Retina)
+ (void) fillWith:(NSDictionary*)aTextDict;

+ (void) listProperties;

@end
