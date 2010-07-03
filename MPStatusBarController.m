/*
 * MPStatusBarController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sun Feb 24 2002.
 *
 * Copyright (c) 2001 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of Mitz Pettel may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MPStatusBarController.h"


@implementation MPStatusBarController

- (void)awakeFromNib
{
    NSRect belowViewFrame = [belowView frame];
    NSRect statusBarFrame = [statusBarView frame];
    containerView = [[NSView new] autorelease];
    [containerView setFrameOrigin:NSMakePoint(belowViewFrame.origin.x,belowViewFrame.origin.y+belowViewFrame.size.height)];
    [containerView setFrameSize:NSMakeSize(statusBarFrame.size.width, statusBarFrame.size.height)];
    [containerView addSubview:statusBarView];
    [statusBarView setFrameOrigin:NSZeroPoint];
    // now stretch/shrink
    [containerView setFrameSize:NSMakeSize(belowViewFrame.size.width, /*statusBarFrame.size.height*/ 0)];
    [containerView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
    
    [[window contentView] addSubview:containerView];
    isShown = NO;
}

- (BOOL)isVisible
{
    return isShown;
}

- (IBAction)show:(id)sender
{
    [self setVisible:YES];
}

- (IBAction)hide:(id)sender
{
    [self setVisible:NO];
}

- (IBAction)toggleVisible:(id)sender
{
    [self setVisible:![self isVisible]];
}

- (void)setVisible:(BOOL)shown
{
    [self setVisible:shown resizing:YES];
}

- (void)setVisible:(BOOL)shown resizing:(BOOL)flag
{
    if ([self isVisible]!=shown)
    {
        float change = (shown ? -1 : 1)*[statusBarView frame].size.height;
        if (flag)
        {
            NSRect windowFrame = [window frame];
            unsigned int oldAutoresizingMask = [belowView autoresizingMask];
            windowFrame.size.height -= change;
            windowFrame.origin.y += change;
    
            [belowView setAutoresizingMask:NSViewMaxYMargin];
            [containerView setAutoresizingMask: NSViewHeightSizable];
            
            [window setFrame:windowFrame display:YES animate:YES];
            
            [containerView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
            [belowView setAutoresizingMask:oldAutoresizingMask];
        }
        else
        {
            NSRect belowFrame = [belowView frame];
            NSRect containerFrame = [containerView frame];
            belowFrame.size.height += change;
            containerFrame.size.height -= change;
            containerFrame.origin.y += change;
            [belowView setFrame:belowFrame];
            [containerView setFrame:containerFrame];
            [window display];
        }
        
        isShown = shown;
    }
}

@end
