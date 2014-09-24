#import "SVGTextElement.h"

#import <CoreText/CoreText.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "CALayerWithChildHitTest.h"
#import "SVGElement_ForParser.h" // to resolve Xcode circular dependencies; in long term, parsing SHOULD NOT HAPPEN inside any class whose name starts "SVG" (because those are reserved classes for the SVG Spec)
#import "SVGTSpanElement.h"
#import "SVGHelperUtilities.h"


@implementation SVGTextElement
{
    CGPoint _currentTextPosition;
    CTFontRef _baseFont;
	CGFloat _baseFontAscent;
    CGFloat _baseFontDescent;
    CGFloat _baseFontLeading;
    CGFloat _baseFontLineHeight;
    BOOL _didAddTrailingSpace;
}

@synthesize transform; // each SVGElement subclass that conforms to protocol "SVGTransformable" has to re-synthesize this to work around bugs in Apple's Objective-C 2.0 design that don't allow @properties to be extended by categories / protocols

- (void)dealloc {
    [super dealloc];
}

- (CALayer *) newLayer
{
	/**
	 BY DESIGN: we work out the positions of all text in ABSOLUTE space, and then construct the Apple CALayers and CATextLayers around
	 them, as required.
	 
	 And: SVGKit works by pre-baking everything into position (its faster, and avoids Apple's broken CALayer.transform property)
	 */

    // Set up the text elements base font
    _baseFont = [self newFontFromElement:self];
	_baseFontAscent = CTFontGetAscent(_baseFont);
    _baseFontDescent = CTFontGetDescent(_baseFont);
    _baseFontLeading = CTFontGetLeading(_baseFont);
    _baseFontLineHeight = _baseFontAscent + _baseFontDescent + _baseFontLeading;

    // Set up the main layer to put text in to
    CALayer *layer = [CALayer layer];
    [SVGHelperUtilities configureCALayer:layer usingElement:self];
    // Don't care about the size - the sublayers containing text will be positioned relative to the baseline of _baseFont
    layer.bounds = CGRectMake(0, 0, 0, _baseFontAscent+_baseFontDescent);
    // Position the anchor point at the base font's baseline so that the text elements transform are applied properly
    layer.anchorPoint = CGPointMake(0, _baseFontAscent/(_baseFontAscent+_baseFontDescent));
    layer.position = CGPointMake(0, 0);
    // Transform according to 
    layer.affineTransform = [SVGHelperUtilities transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:self];;

    // Add sublayers for the text elements
    _didAddTrailingSpace = NO;
    [self addLayersForElement:self toLayer:layer];
    
    CFRelease(_baseFont);

    return [layer retain];
}

- (void)layoutLayer:(CALayer *)layer
{
}


#pragma mark -

/**
 * Handling x, y, dx, and dy according to http://www.w3.org/TR/SVG/text.html
 */
- (void)updateCurrentTextPositionBasedOnElement:(SVGTextPositioningElement *)element font:(CTFontRef)font
{
    if (element.x.unitType!=SVG_LENGTHTYPE_UNKNOWN) {
        _currentTextPosition.x = [self pixelValueForLength:element.x withFont:font];
    } else if ([element isKindOfClass:[SVGTextElement class]]) {
        _currentTextPosition.x = 0;
    }
    if (element.y.unitType!=SVG_LENGTHTYPE_UNKNOWN) {
        _currentTextPosition.y = [self pixelValueForLength:element.y withFont:font];
    } else if ([element isKindOfClass:[SVGTextElement class]]) {
        _currentTextPosition.y = 0;
    }
    if (element.dx.unitType!=SVG_LENGTHTYPE_UNKNOWN) {
        _currentTextPosition.x += [self pixelValueForLength:element.dx withFont:font];
    }
    if (element.dy.unitType!=SVG_LENGTHTYPE_UNKNOWN) {
        _currentTextPosition.y += [self pixelValueForLength:element.dy withFont:font];
    }
}


- (void)addLayersForElement:(SVGTextPositioningElement *)element toLayer:(CALayer *)layer
{
    CTFontRef font = [self newFontFromElement:element];
    [self updateCurrentTextPositionBasedOnElement:element font:font];

    for (Node *node in element.childNodes) {
        BOOL hasPreviousNode = (node!=element.firstChild);
        BOOL hasNextNode = (node!=element.lastChild);
        
        //NSLog(@"currentTextPosition : %@", NSStringFromCGPoint(_currentTextPosition));
        //NSLog(@"node.nextSibling : %@", node.nextSibling);
        switch (node.nodeType) {
            case DOMNodeType_TEXT_NODE: {
                BOOL hadLeadingSpace;
                BOOL hadTrailingSpace;
                NSString *text = [self stripText:node.textContent hadLeadingSpace:&hadLeadingSpace hadTrailingSpace:&hadTrailingSpace];
                if (hasPreviousNode && hadLeadingSpace && !_didAddTrailingSpace) {
                    text = [@" " stringByAppendingString:text];
                }
                if (hasNextNode && hadTrailingSpace) {
                    text = [text stringByAppendingString:@" "];
                    _didAddTrailingSpace = YES;
                } else {
                    _didAddTrailingSpace = NO;
                }
                if (text.length>0) {
                    CAShapeLayer *label = [self layerWithText:text font:font];
                    [SVGHelperUtilities configureCALayer:label usingElement:element];
                    [SVGHelperUtilities applyStyleToShapeLayer:label withElement:element];
                    [layer addSublayer:label];
                }
                break;
            }
                
            case DOMNodeType_ELEMENT_NODE: {
                if ([node isKindOfClass:[SVGTSpanElement class]]) {
                    SVGTSpanElement *tspanElement = (SVGTSpanElement *)node;
                    [self addLayersForElement:tspanElement toLayer:layer];
                }
                break;
            }
                
            default:
                break;
        }
    }
    CFRelease(font);
}

- (CGFloat)pixelValueForLength:(SVGLength *)length withFont:(CTFontRef)font
{
    if (length.unitType==SVG_LENGTHTYPE_EMS) {
        return length.value*CTFontGetSize(font);
    } else {
        return length.pixelsValue;
    }
}


- (NSString *)stripText:(NSString *)text hadLeadingSpace:(BOOL *)hadLeadingSpace hadTrailingSpace:(BOOL *)hadTrailingSpace
{
    // Remove all newline characters
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    // Convert tabs into spaces
    text = [text stringByReplacingOccurrencesOfString:@"\t" withString:@" "];
    // Consolidate all contiguous space characters
    while ([text rangeOfString:@"  "].location != NSNotFound) {
        text = [text stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    }
    if (hadLeadingSpace) {
        *hadLeadingSpace = (text.length==0 ? NO : [[text substringWithRange:NSMakeRange(0, 1)] isEqualToString:@" "]);
    }
    if (hadTrailingSpace) {
        *hadTrailingSpace = (text.length==0 ? NO : [[text substringFromIndex:text.length-1] isEqualToString:@" "]);
    }
    // Remove leading and trailing spaces
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return text;
}

- (CTFontRef)newFontFromElement:(SVGElement<SVGStylable> *)element
{
	NSString *fontSize = [element cascadedValueForStylableProperty:@"font-size"];
	NSString *fontFamily = [element cascadedValueForStylableProperty:@"font-family"];
    NSString *fontWeight = [element cascadedValueForStylableProperty:@"font-weight"];
	
	CGFloat effectiveFontSize = (fontSize.length > 0) ? [fontSize floatValue] : 12; // I chose 12. I couldn't find an official "default" value in the SVG spec.

    CTFontRef fontRef = NULL;
    if (fontFamily) {
        fontRef = CTFontCreateWithName((CFStringRef)fontFamily, effectiveFontSize, NULL);
    }
    if (!fontRef) {
        fontRef = CTFontCreateUIFontForLanguage(kCTFontUserFontType, effectiveFontSize, NULL);
    }
    if (fontWeight) {
        BOOL bold = [fontWeight isEqualToString:@"bold"];
        if (bold) {
            CTFontRef boldFontRef = CTFontCreateCopyWithSymbolicTraits(fontRef, effectiveFontSize, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
            if (boldFontRef) {
                CFRelease(fontRef);
                fontRef = boldFontRef;
            }
        }
    }
    return fontRef;
}


#pragma mark -

- (CAShapeLayer *)layerWithText:(NSString *)text font:(CTFontRef)font
{
    CAShapeLayer *label = [CAShapeLayer layer];
    label.anchorPoint = CGPointZero;
    label.position = _currentTextPosition;
    // Create path from the text
    CGFloat xStart = _currentTextPosition.x;
    UIBezierPath *textPath = [self bezierPathWithString1:text font:font];
    // Bounding and alignment with _baseFont baseline
    CGFloat fontAscent = CTFontGetAscent(font);
    CGFloat fontDescent = CTFontGetDescent(font);
    label.path = textPath.CGPath;
    CGPoint position = label.position;
    position.y += -(fontAscent-_baseFontAscent);
    label.position = position;
    label.bounds = CGRectMake(0, -fontAscent, _currentTextPosition.x-xStart, fontAscent+fontDescent);
    return label;
}

/**
 * Create a UIBezierPath rendering string in font.
 * textPath: Have a look at http://iphonedevsdk.com/forum/iphone-sdk-development/101053-cgpath-help.html
 */



- (UIBezierPath*)bezierPathWithString:(NSString*)string font:(CTFontRef)fontRef
{
    UIBezierPath *combinedGlyphsPath = nil;
    CGMutablePathRef combinedGlyphsPathRef = CGPathCreateMutable();
    if (combinedGlyphsPathRef)
    {
        CGRect rect = CGRectMake(0, 0, FLT_MAX, FLT_MAX);
        UIBezierPath *frameShape = [UIBezierPath bezierPathWithRect:rect];
        
        CGPoint basePoint = CGPointMake(_currentTextPosition.x, CTFontGetAscent(fontRef));
        CFStringRef keys[] = { kCTFontAttributeName };
        CFTypeRef values[] = { fontRef };
        CFDictionaryRef attributesRef = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values,
                                                           sizeof(keys) / sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        if (attributesRef)
        {
            CFAttributedStringRef attributedStringRef = CFAttributedStringCreate(NULL, (CFStringRef) string, attributesRef);
            
            if (attributedStringRef)
            {
                CTFramesetterRef frameSetterRef = CTFramesetterCreateWithAttributedString(attributedStringRef);
                
                if (frameSetterRef)
                {
                    CTFrameRef frameRef = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0,0), [frameShape CGPath], NULL);
                    
                    if (frameRef)
                    {
                        CFArrayRef lines = CTFrameGetLines(frameRef);
                        
                        ///
                        
                        if (CFArrayGetCount(lines)==1) {
                            CGPoint lineOrigin;
                            CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 1), &lineOrigin);
                            CTLineRef lineRef = CFArrayGetValueAtIndex(lines, 0);
                            
                            CFArrayRef runs = CTLineGetGlyphRuns(lineRef);
                            
                            CFIndex runCount = CFArrayGetCount(runs);
                            for (CFIndex runIndex = 0; runIndex<runCount; runIndex++)
                            {
                                CTRunRef runRef = CFArrayGetValueAtIndex(runs, runIndex);
                                
                                CFIndex glyphCount = CTRunGetGlyphCount(runRef);
                                CGGlyph glyphs[glyphCount];
                                CGSize glyphAdvances[glyphCount];
                                CGPoint glyphPositions[glyphCount];
                                
                                CFRange runRange = CFRangeMake(0, glyphCount);
                                CTRunGetGlyphs(runRef, CFRangeMake(0, glyphCount), glyphs);
                                CTRunGetPositions(runRef, runRange, glyphPositions);
                                
                                CTFontGetAdvancesForGlyphs(fontRef, kCTFontDefaultOrientation, glyphs, glyphAdvances, glyphCount);
                                
                                for (CFIndex glyphIndex = 0; glyphIndex<glyphCount; glyphIndex++)
                                {
                                    CGGlyph glyph = glyphs[glyphIndex];
                                    
                                    // For regular UIBezierPath drawing, we need to invert around the y axis.
                                    CGAffineTransform glyphTransform = CGAffineTransformMakeTranslation(lineOrigin.x+glyphPositions[glyphIndex].x, rect.size.height-lineOrigin.y-glyphPositions[glyphIndex].y);
                                    glyphTransform = CGAffineTransformScale(glyphTransform, 1, -1);
                                    // TODO[pdr] Idea for handling rotate: glyphTransform = CGAffineTransformRotate(glyphTransform, M_PI/8);
                                    
                                    CGPathRef glyphPathRef = CTFontCreatePathForGlyph(fontRef, glyph, &glyphTransform);
                                    if (glyphPathRef)
                                    {
                                        // Finally carry out the appending.
                                        CGPathAddPath(combinedGlyphsPathRef, NULL, glyphPathRef);
                                        CFRelease(glyphPathRef);
                                    }
                                    
                                    basePoint.x += glyphAdvances[glyphIndex].width;
                                    basePoint.y += glyphAdvances[glyphIndex].height;
                                    //NSLog(@"'%@' => %@", [string substringWithRange:NSMakeRange(glyphIndex, 1)], NSStringFromCGPoint(basePoint));
                                }
                                _currentTextPosition.x = basePoint.x; // TODO[pdr]
                            }
                        }
                        CFRelease(frameRef);
                    }
                    CFRelease(frameSetterRef);
                }
                CFRelease(attributedStringRef);
            }
            CFRelease(attributesRef);
        }

        // Casting a CGMutablePathRef to a CGPathRef seems to be the only way to convert what was just built into a UIBezierPath.
        combinedGlyphsPath = [UIBezierPath bezierPathWithCGPath:(CGPathRef) combinedGlyphsPathRef];
    
        CGPathRelease(combinedGlyphsPathRef);
    }
    return combinedGlyphsPath;
}


- (UIBezierPath*)bezierPathWithString1:(NSString*)string font:(CTFontRef)fontRef
{
    CGMutablePathRef letters = CGPathCreateMutable();
    
    CTFontRef font =  fontRef;//CTFontCreateWithName(CFSTR("Helvetica"), 17.0f, NULL);
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)font, kCTFontAttributeName,
                           nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string
                                                                     attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
    
    // for each RUN
    for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runArray); runIndex++)
    {
        // Get FONT for this run
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        // for each GLYPH in run
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < CTRunGetGlyphCount(run); runGlyphIndex++)
        {
            // get Glyph & Glyph-data
            CFRange thisGlyphRange = CFRangeMake(runGlyphIndex, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            // Get PATH of outline
            {
                CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
                CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
                t = CGAffineTransformScale(t, 1, -1);
                
                CGPathAddPath(letters, &t, letter);
                CGPathRelease(letter);
            }
        }
    }
    CFRelease(line);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointZero];
    [path appendPath:[UIBezierPath bezierPathWithCGPath:letters]];
    
    CGPathRelease(letters);
    [attrString release];
    //CFRelease(font);
    
    return path;
}

@end
