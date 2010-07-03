#import "ChasingArrowsView.h"

static NSImage *arrowsImage;

@implementation ChasingArrowsView

+ (void)initialize;
{
    arrowsImage = [[NSImage imageNamed:@"ChasingArrows"] retain];
}

- (BOOL)isFlipped
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
        return NO;
    else
        return [super isFlipped];
}

- (BOOL)isOpaque;
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
        return NO;
    else
        return [super isOpaque];
}

- initWithFrame:(NSRect)theFrame;
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_1)
        theFrame = NSInsetRect(theFrame, 1, 1);
    self = [super initWithFrame:theFrame];
    [self setIndeterminate:YES];
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
        [self setAnimationDelay:0.0625];
    else
    {
        [self setStyle:NSProgressIndicatorSpinningStyle];
        [self setDisplayedWhenStopped:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)drawingRect;
{
	if ( cautionStatus )
	{
		NSRect		destRect = [self bounds];
		
		CGContextRef myContextRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(myContextRef);
		
		if ( [self isFlipped] )
		{
            CGContextTranslateCTM(myContextRef, NSWidth(destRect)/2.0, NSHeight(destRect)/2.0);
            CGContextScaleCTM(myContextRef, 1.0, -1.0);
            CGContextTranslateCTM(myContextRef, -NSWidth(destRect)/2.0, -NSHeight(destRect)/2.0);
		}
		
		[[NSImage imageNamed:@"caution"] drawInRect:destRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		CGContextRestoreGState(myContextRef);
		return;
	}
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
    {
        if (animationRunning)
        {
            float angle = -((currentFrame%16)/8.0)*M_PI;
            NSRect myRect = [self bounds];
            CGContextRef myContextRef;
            currentFrame++;
            myContextRef = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            CGContextSaveGState(myContextRef);
            CGContextTranslateCTM(myContextRef, NSWidth(myRect)/2.0, NSHeight(myRect)/2.0);
            CGContextRotateCTM(myContextRef, angle);
            CGContextTranslateCTM(myContextRef, -NSWidth(myRect)/2.0, -NSHeight(myRect)/2.0);
            [arrowsImage drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
            CGContextRestoreGState(myContextRef);
        }
    }
    else
        [super drawRect:drawingRect];
}

- (void)startAnimation:(id)sender
{
    animationRunning = YES;
    [super startAnimation:sender];
}

- (void)stopAnimation:(id)sender
{
    [super stopAnimation:sender];
    animationRunning = NO;
    currentFrame = 0;
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1)
        [self setNeedsDisplay:YES];
}

- (void)setCautionStatus:(BOOL)flag
{
	cautionStatus = flag;
	[self setNeedsDisplay:YES];
}

@end
