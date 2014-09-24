#import "SVGHelperUtilities.h"

#import "CAShapeLayerWithHitTest.h"
#import "SVGUtils.h"
#import "SVGGradientElement.h"
#import "CGPathAdditions.h"

#import "SVGTransformable.h"
#import "SVGSVGElement.h"

@implementation SVGHelperUtilities


+(CGAffineTransform) transformRelativeIncludingViewportForTransformableOrViewportEstablishingElement:(SVGElement*) transformableOrSVGSVGElement
{
	NSAssert([transformableOrSVGSVGElement conformsToProtocol:@protocol(SVGTransformable)] || [transformableOrSVGSVGElement isKindOfClass:[SVGSVGElement class]], @"Illegal argument, sent a non-SVGTransformable, non-SVGSVGElement object to a method that requires an SVGTransformable (NB: Apple's Xcode is rubbish, it should have thrown a compiler error that you even tried to do this, but it often doesn't bother). Incoming instance = %@", transformableOrSVGSVGElement );
	
	/**
	 Each time you hit a viewPortElement in the DOM Tree, you
	 have to insert an ADDITIONAL transform into the flow of:
	 
	 parent-transform -> child-transform
	 
	 has to become:
	 
	 parent-transform -> VIEWPORT-TRANSFORM -> child-transform
	 */
	
	CGAffineTransform currentRelativeTransform;
	CGAffineTransform optionalViewportTransform;
		
	/**
	 Current relative transform: for an incoming "SVGTransformable" it's .transform, for everything else its identity
	 */
	if( [transformableOrSVGSVGElement conformsToProtocol:@protocol(SVGTransformable)])
	{
		currentRelativeTransform = ((SVGElement<SVGTransformable>*)transformableOrSVGSVGElement).transform;
	}
	else
	{
		currentRelativeTransform = CGAffineTransformIdentity;
	}
	
	/**
	 Optional relative transform: if incoming element establishes a viewport, do something clever; for everything else, use identity
	 */
	if( transformableOrSVGSVGElement.viewportElement == nil // if it's nil, it means THE OPPOSITE of what you'd expect - it means that it IS the viewport element - SVG Spec REQUIRES this
	   || transformableOrSVGSVGElement.viewportElement == transformableOrSVGSVGElement // ?? I don't understand: ?? if it's something other than itself, then: we simply don't need to worry about it ??
	   )
	{
		SVGElement<SVGFitToViewBox>* svgSVGElement = (SVGElement<SVGFitToViewBox>*) transformableOrSVGSVGElement;
		
		/**
		 Calculate the "implicit" viewport transform (caused by the <SVG> tag's possible "viewBox" attribute)
		 
		 */
		SVGRect frameViewBox = svgSVGElement.viewBox;
		if( SVGRectIsInitialized( frameViewBox ) )
		{
			/* (NB: the viewport will ALWAYS have a value: UNLESS the SVG is so crappy it has NEITHER a viewbox NOR an explicit width
		     and height in the root <SVG> tag.
			 
			 ...but since we know we already have a viewbox, we can rely upon there being a viewport too.
			 */
			SVGRect frameViewport = ((SVGSVGElement*)svgSVGElement).viewport;
			
			CGAffineTransform translateToViewBox = CGAffineTransformMakeTranslation( -frameViewBox.x, -frameViewBox.y );
			CGAffineTransform scaleToViewBox = CGAffineTransformMakeScale( frameViewport.width / frameViewBox.width, frameViewport.height / frameViewBox.height);
			optionalViewportTransform = CGAffineTransformConcat( translateToViewBox, scaleToViewBox );
		}
		else
			optionalViewportTransform = CGAffineTransformIdentity;
		
	}
	else
	{
		optionalViewportTransform = CGAffineTransformIdentity;
	}
	
	/**
	 TOTAL relative based on the local "transform" property and the viewport (if present)
	 */
	CGAffineTransform result = CGAffineTransformConcat( currentRelativeTransform, optionalViewportTransform);
	
	return result;
}

/*!
 Re-calculates the absolute transform on-demand by querying parent's absolute transform and appending self's relative transform.
 
 Can take ONLY TWO kinds of element:
  - something that implements SVGTransformable (non-transformables shouldn't be performing transforms!)
  - something that defines a new viewport co-ordinate system (i.e. the SVG tag itself; this is AN IMPLICIT TRANSFORMABLE!)
 */
+(CGAffineTransform) transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:(SVGElement*) transformableOrSVGSVGElement
{
	NSAssert([transformableOrSVGSVGElement conformsToProtocol:@protocol(SVGTransformable)] || [transformableOrSVGSVGElement isKindOfClass:[SVGSVGElement class]], @"Illegal argument, sent a non-SVGTransformable, non-SVGSVGElement object to a method that requires an SVGTransformable (NB: Apple's Xcode is rubbish, it should have thrown a compiler error that you even tried to do this, but it often doesn't bother). Incoming instance = %@", transformableOrSVGSVGElement );
	
	CGAffineTransform parentAbsoluteTransform = CGAffineTransformIdentity;
	
	NSAssert( transformableOrSVGSVGElement.parentNode == nil || [transformableOrSVGSVGElement.parentNode isKindOfClass:[SVGElement class]], @"I don't know what to do when parent node is NOT an SVG element of some kind; presumably, this is when SVG root node gets embedded inside something else? The Spec IS UNCLEAR and doesn't clearly define ANYTHING here, and provides very few examples" );
	
	/**
	 Parent Absolute transform: one of the following
	 
	 a. parent is an SVGTransformable (so recurse this method call to find it)
	 b. parent is a viewport-generating element (so recurse this method call to find it)
	 c. parent is nil (so treat it as Identity)
	 d. parent is something else (so do a while loop until we hit an a, b, or c above)
	 */
	SVGElement* parentSVGElement = transformableOrSVGSVGElement;
	while( (parentSVGElement = (SVGElement*) parentSVGElement.parentNode) != nil )
	{
		if( [parentSVGElement conformsToProtocol:@protocol(SVGTransformable)] )
		{
			parentAbsoluteTransform = [self transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:parentSVGElement];
			break;
		}
		
		if( [parentSVGElement isKindOfClass:[SVGSVGElement class]] )
		{
			parentAbsoluteTransform = [self transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:parentSVGElement];
			break;
		}
	}
		
	/**
	 TOTAL absolute based on the parent transform with relative (and possible viewport) transforms
	 */
	CGAffineTransform result = CGAffineTransformConcat( [self transformRelativeIncludingViewportForTransformableOrViewportEstablishingElement:transformableOrSVGSVGElement], parentAbsoluteTransform );
	
	//DEBUG: NSLog( @"[%@] self.transformAbsolute: returning: affine( (%2.2f %2.2f %2.2f %2.2f), (%2.2f %2.2f)", [self class], result.a, result.b, result.c, result.d, result.tx, result.ty);
	
	return result;
}

+(void) configureCALayer:(CALayer*) layer usingElement:(SVGElement*) nonStylableElement
{
	layer.name = nonStylableElement.identifier;
	[layer setValue:nonStylableElement.identifier forKey:kSVGElementIdentifier];
	
#if FORCE_RASTERIZE_LAYERS
	if ([layer respondsToSelector:@selector(setShouldRasterize:)]) {
		[layer performSelector:@selector(setShouldRasterize:)
						  withObject:[NSNumber numberWithBool:YES]];
	}
	
	/** If you're going to rasterize, Apple's code is dumb, and needs to be "told" if its using a Retina display */
	layer.contentsScale = [[UIScreen mainScreen] scale];
	layer.rasterizationScale = _shapeLayer.contentsScale;
#endif
	
	if( [nonStylableElement conformsToProtocol:@protocol(SVGStylable)])
	{
		SVGElement<SVGStylable>* stylableElement = (SVGElement<SVGStylable>*) nonStylableElement;
		
		NSString* actualOpacity = [stylableElement cascadedValueForStylableProperty:@"opacity"];
		layer.opacity = actualOpacity.length > 0 ? [actualOpacity floatValue] : 1.0f; // svg's "opacity" defaults to 1!
	}
}

+(CALayer *) newCALayerForPathBasedSVGElement:(SVGElement<SVGTransformable>*) svgElement withPath:(CGPathRef) pathRelative
{
	CAShapeLayer* _shapeLayer = [[CAShapeLayerWithHitTest layer] retain];
	
	[self configureCALayer:_shapeLayer usingElement:svgElement];
	
	/** transform our LOCAL path into ABSOLUTE space */
	CGAffineTransform transformAbsolute = [self transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:svgElement];
	CGMutablePathRef pathToPlaceInLayer = CGPathCreateMutable();
	CGPathAddPath( pathToPlaceInLayer, &transformAbsolute, pathRelative);
	
	/** find out the ABSOLUTE BOUNDING BOX of our transformed path */
    //BIZARRE: Apple sometimes gives a different value for this even when transformAbsolute == identity! : CGRect localPathBB = CGPathGetPathBoundingBox( _pathRelative );
	//DEBUG ONLY: CGRect unTransformedPathBB = CGPathGetBoundingBox( _pathRelative );
	CGRect transformedPathBB = CGPathGetBoundingBox( pathToPlaceInLayer );

#if IMPROVE_PERFORMANCE_BY_WORKING_AROUND_APPLE_FRAME_ALIGNMENT_BUG
	transformedPathBB = CGRectIntegral( transformedPathBB ); // ridiculous but improves performance of apple's code by up to 50% !
#endif
	
	/** NB: when we set the _shapeLayer.frame, it has a *side effect* of moving the path itself - so, in order to prevent that,
	 because Apple didn't provide a BOOL to disable that "feature", we have to pre-shift the path forwards by the amount it
	 will be shifted backwards */
	CGPathRef finalPath = CGPathCreateByOffsettingPath( pathToPlaceInLayer, transformedPathBB.origin.x, transformedPathBB.origin.y );
	
	/** Can't use this - iOS 5 only! path = CGPathCreateCopyByTransformingPath(path, transformFromSVGUnitsToScreenUnits ); */
	
	_shapeLayer.path = finalPath;
	CGPathRelease(finalPath);
	CGPathRelease(pathToPlaceInLayer);
	
	/**
	 NB: this line, by changing the FRAME of the layer, has the side effect of also changing the CGPATH's position in absolute
	 space! This is why we needed the "CGPathRef finalPath =" line a few lines above...
	 */
	_shapeLayer.frame = transformedPathBB;
	
	
	//DEBUG ONLY: CGRect shapeLayerFrame = _shapeLayer.frame;
	
	NSString* actualStroke = [svgElement cascadedValueForStylableProperty:@"stroke"];
	NSString* actualStrokeWidth = [svgElement cascadedValueForStylableProperty:@"stroke-width"];
	if( actualStroke.length > 0
	   && (! [@"none" isEqualToString:actualStroke]) )
	{
		CGFloat strokeWidth = actualStrokeWidth.length > 0 ? [actualStrokeWidth floatValue] : 1.0f;
		
		/*
		 We have to apply any scale-factor part of the affine transform to the stroke itself (this is bizarre and horrible, yes, but that's the spec for you!)
		 */
		CGSize fakeSize = CGSizeMake( strokeWidth, 0 );
		fakeSize = CGSizeApplyAffineTransform( fakeSize, transformAbsolute );
		_shapeLayer.lineWidth = fakeSize.width;
		
		SVGColor strokeColorAsSVGColor = SVGColorFromString([actualStroke UTF8String]); // have to use the intermediate of an SVGColor so that we can over-ride the ALPHA component in next line
		NSString* actualStrokeOpacity = [svgElement cascadedValueForStylableProperty:@"stroke-opacity"];
		if( actualStrokeOpacity.length > 0 )
			strokeColorAsSVGColor.a = (uint8_t) ([actualStrokeOpacity floatValue] * 0xFF);
		
		_shapeLayer.strokeColor = CGColorWithSVGColor( strokeColorAsSVGColor );
		
		/**
		 Line joins + caps: butt / square / miter
		 */
		NSString* actualLineCap = [svgElement cascadedValueForStylableProperty:@"stroke-linecap"];
		NSString* actualLineJoin = [svgElement cascadedValueForStylableProperty:@"stroke-linejoin"];
		NSString* actualMiterLimit = [svgElement cascadedValueForStylableProperty:@"stroke-miterlimit"];
		if( actualLineCap.length > 0 )
		{
			if( [actualLineCap isEqualToString:@"butt"] )
				_shapeLayer.lineCap = kCALineCapButt;
			else if( [actualLineCap isEqualToString:@"round"] )
				_shapeLayer.lineCap = kCALineCapRound;
			else if( [actualLineCap isEqualToString:@"square"] )
				_shapeLayer.lineCap = kCALineCapSquare;
		}
		if( actualLineJoin.length > 0 )
		{
			if( [actualLineJoin isEqualToString:@"miter"] )
				_shapeLayer.lineJoin = kCALineJoinMiter;
			else if( [actualLineJoin isEqualToString:@"round"] )
				_shapeLayer.lineJoin = kCALineJoinRound;
			else if( [actualLineJoin isEqualToString:@"bevel"] )
				_shapeLayer.lineJoin = kCALineJoinBevel;
		}
		if( actualMiterLimit.length > 0 )
		{
			_shapeLayer.miterLimit = [actualMiterLimit floatValue];
		}
	}
	else
	{
		if( [@"none" isEqualToString:actualStroke] )
		{
			_shapeLayer.strokeColor = nil; // This is how you tell Apple that the stroke is disabled; a strokewidth of 0 will NOT achieve this
			_shapeLayer.lineWidth = 0.0f; // MUST set this explicitly, or Apple assumes 1.0
		}
		else
		{
			_shapeLayer.lineWidth = 1.0f; // default value from SVG spec
		}
	}
	
	
	NSString* actualFill = [svgElement cascadedValueForStylableProperty:@"fill"];
	if ( [actualFill hasPrefix:@"none"])
	{
		_shapeLayer.fillColor = nil;
	}
	else if ( [actualFill hasPrefix:@"url"] )
	{
		NSRange idKeyRange = NSMakeRange(5, actualFill.length - 6);
		NSString* _fillId = [actualFill substringWithRange:idKeyRange];
		
		/** Replace the return layer with a special layer using the URL fill */
		/** fetch the fill layer by URL using the DOM */
		NSAssert( svgElement.rootOfCurrentDocumentFragment != nil, @"This SVG shape has a URL fill type; it needs to search for that URL (%@) inside its nearest-ancestor <SVG> node, but the rootOfCurrentDocumentFragment reference was nil (suggests the parser failed, or the SVG file is corrupt)", _fillId );
		
		SVGGradientElement* svgGradient = (SVGGradientElement*) [svgElement.rootOfCurrentDocumentFragment getElementById:_fillId];
		NSAssert( svgGradient != nil, @"This SVG shape has a URL fill (%@), but could not find an XML Node with that ID inside the DOM tree (suggests the parser failed, or the SVG file is corrupt)", _fillId );
		
		//if( _shapeLayer != nil && svgGradient != nil ) //this nil check here is distrubing but blocking
		{
			CAGradientLayer *gradientLayer = [svgGradient newGradientLayerForObjectRect:_shapeLayer.frame viewportRect:svgElement.rootOfCurrentDocumentFragment.viewBox];
			
			NSLog(@"DOESNT WORK, APPLE's API APPEARS BROKEN???? - About to mask layer frame (%@) with a mask of frame (%@)", NSStringFromCGRect(gradientLayer.frame), NSStringFromCGRect(_shapeLayer.frame));
			gradientLayer.mask =_shapeLayer;
			[_shapeLayer release]; // because it was created with a +1 retain count
			
			return gradientLayer;
		}
	}
	else if( actualFill.length > 0 )
	{
		SVGColor fillColorAsSVGColor = SVGColorFromString([actualFill UTF8String]); // have to use the intermediate of an SVGColor so that we can over-ride the ALPHA component in next line
		NSString* actualFillOpacity = [svgElement cascadedValueForStylableProperty:@"fill-opacity"];
		if( actualFillOpacity.length > 0 )
			fillColorAsSVGColor.a = (uint8_t) ([actualFillOpacity floatValue] * 0xFF);
		
		_shapeLayer.fillColor = CGColorWithSVGColor(fillColorAsSVGColor);
	}
	else
	{
		
	}
    
	NSString* actualOpacity = [svgElement cascadedValueForStylableProperty:@"opacity"];
	_shapeLayer.opacity = actualOpacity.length > 0 ? [actualOpacity floatValue] : 1; // unusually, the "opacity" attribute defaults to 1, not 0
	
	return _shapeLayer;
}

+ (void)applyStyleToShapeLayer:(CAShapeLayer *)layer withElement:(SVGElement *)svgElement
{
	CGAffineTransform transformAbsolute = CGAffineTransformIdentity; // TODO[pdr]  [self transformAbsoluteIncludingViewportForTransformableOrViewportEstablishingElement:svgElement];
    
	NSString* actualStroke = [svgElement cascadedValueForStylableProperty:@"stroke"];
	NSString* actualStrokeWidth = [svgElement cascadedValueForStylableProperty:@"stroke-width"];
	if( actualStroke.length > 0
	   && (! [@"none" isEqualToString:actualStroke]) )
	{
		CGFloat strokeWidth = actualStrokeWidth.length > 0 ? [actualStrokeWidth floatValue] : 1.0f;
		
		/*
		 We have to apply any scale-factor part of the affine transform to the stroke itself (this is bizarre and horrible, yes, but that's the spec for you!)
		 */
		CGSize fakeSize = CGSizeMake( strokeWidth, 0 );
		fakeSize = CGSizeApplyAffineTransform( fakeSize, transformAbsolute );
		layer.lineWidth = fakeSize.width;
		
		SVGColor strokeColorAsSVGColor = SVGColorFromString([actualStroke UTF8String]); // have to use the intermediate of an SVGColor so that we can over-ride the ALPHA component in next line
		NSString* actualStrokeOpacity = [svgElement cascadedValueForStylableProperty:@"stroke-opacity"];
		if( actualStrokeOpacity.length > 0 )
			strokeColorAsSVGColor.a = (uint8_t) ([actualStrokeOpacity floatValue] * 0xFF);
		
		layer.strokeColor = CGColorWithSVGColor( strokeColorAsSVGColor );
		
		/**
		 Line joins + caps: butt / square / miter
		 */
		NSString* actualLineCap = [svgElement cascadedValueForStylableProperty:@"stroke-linecap"];
		NSString* actualLineJoin = [svgElement cascadedValueForStylableProperty:@"stroke-linejoin"];
		NSString* actualMiterLimit = [svgElement cascadedValueForStylableProperty:@"stroke-miterlimit"];
		if( actualLineCap.length > 0 )
		{
			if( [actualLineCap isEqualToString:@"butt"] )
				layer.lineCap = kCALineCapButt;
			else if( [actualLineCap isEqualToString:@"round"] )
				layer.lineCap = kCALineCapRound;
			else if( [actualLineCap isEqualToString:@"square"] )
				layer.lineCap = kCALineCapSquare;
		}
		if( actualLineJoin.length > 0 )
		{
			if( [actualLineJoin isEqualToString:@"miter"] )
				layer.lineJoin = kCALineJoinMiter;
			else if( [actualLineJoin isEqualToString:@"round"] )
				layer.lineJoin = kCALineJoinRound;
			else if( [actualLineJoin isEqualToString:@"bevel"] )
				layer.lineJoin = kCALineJoinBevel;
		}
		if( actualMiterLimit.length > 0 )
		{
			layer.miterLimit = [actualMiterLimit floatValue];
		}
	}
	else
	{
		if( [@"none" isEqualToString:actualStroke] )
		{
			layer.strokeColor = nil; // This is how you tell Apple that the stroke is disabled; a strokewidth of 0 will NOT achieve this
			layer.lineWidth = 0.0f; // MUST set this explicitly, or Apple assumes 1.0
		}
		else
		{
			layer.lineWidth = 1.0f; // default value from SVG spec
		}
	}
	
	
	NSString* actualFill = [svgElement cascadedValueForStylableProperty:@"fill"];
	if ( [actualFill hasPrefix:@"none"])
	{
		layer.fillColor = nil;
	}
	else if ( [actualFill hasPrefix:@"url"] )
	{
        /* TODO[pdr]
         NSRange idKeyRange = NSMakeRange(5, actualFill.length - 6);
         NSString* _fillId = [actualFill substringWithRange:idKeyRange];
         
         // Replace the return layer with a special layer using the URL fill
         // fetch the fill layer by URL using the DOM
         NSAssert( svgElement.rootOfCurrentDocumentFragment != nil, @"This SVG shape has a URL fill type; it needs to search for that URL (%@) inside its nearest-ancestor <SVG> node, but the rootOfCurrentDocumentFragment reference was nil (suggests the parser failed, or the SVG file is corrupt)", _fillId );
         
         SVGGradientElement* svgGradient = (SVGGradientElement*) [svgElement.rootOfCurrentDocumentFragment getElementById:_fillId];
         NSAssert( svgGradient != nil, @"This SVG shape has a URL fill (%@), but could not find an XML Node with that ID inside the DOM tree (suggests the parser failed, or the SVG file is corrupt)", _fillId );
         
         //if( _shapeLayer != nil && svgGradient != nil ) //this nil check here is distrubing but blocking
         {
         CAGradientLayer *gradientLayer = [svgGradient newGradientLayerForObjectRect:layer.frame viewportRect:svgElement.rootOfCurrentDocumentFragment.viewBox];
         
         NSLog(@"DOESNT WORK, APPLE's API APPEARS BROKEN???? - About to mask layer frame (%@) with a mask of frame (%@)", NSStringFromCGRect(gradientLayer.frame), NSStringFromCGRect(layer.frame));
         gradientLayer.mask =_shapeLayer;
         [layer release]; // because it was created with a +1 retain count
         
         return gradientLayer;
         }
         */
	}
	else if( actualFill.length > 0 )
	{
		SVGColor fillColorAsSVGColor = SVGColorFromString([actualFill UTF8String]); // have to use the intermediate of an SVGColor so that we can over-ride the ALPHA component in next line
		NSString* actualFillOpacity = [svgElement cascadedValueForStylableProperty:@"fill-opacity"];
		if( actualFillOpacity.length > 0 )
			fillColorAsSVGColor.a = (uint8_t) ([actualFillOpacity floatValue] * 0xFF);
		
		layer.fillColor = CGColorWithSVGColor(fillColorAsSVGColor);
	}
	else
	{
		
	}
    
	NSString* actualOpacity = [svgElement cascadedValueForStylableProperty:@"opacity"];
	layer.opacity = actualOpacity.length > 0 ? [actualOpacity floatValue] : 1; // unusually, the "opacity" attribute defaults to 1, not 0
}

@end
