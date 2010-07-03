#import <AppKit/AppKit.h>

@interface ChasingArrowsView : NSProgressIndicator
{
    BOOL		animationRunning;
    unsigned int	currentFrame;
	BOOL		cautionStatus;
}

- (void)setCautionStatus:(BOOL)flag;

@end
