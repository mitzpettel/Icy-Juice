/*
 * StatusMessageSheetController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed Feb 20 2002.
 *
 * Copyright (c) 2002 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "StatusMessageSheetController.h"
#import "MainController.h"


@implementation StatusMessageSheetController

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"StatusMessagePanel" owner:self];
    [messageField setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    return self;
}

- (void)runModalForWindow:(NSWindow *)window withStatusKey:(id)theStatusKey message:(NSString *)message promptEachTime:(BOOL)flag modalDelegate:(id)theDelegate didEndSelector:(SEL)theSelector
{
    NSString *statusName;
    statusKey = [theStatusKey copy];
    statusName = [[[NSApp delegate] statusForKey:statusKey] name];
    [promptField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Change %@ Message", @""), statusName]];
    [messageField setAllowsUndo:YES];
    [messageField setString:message];
    [messageField setSelectedRange:NSMakeRange(0, [message length])];
    [sheet makeFirstResponder:messageField];
    [labelField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"This message will be displayed when you are marked as '%@'", @""), statusName]];
    [promptEachTimeCheckbox setState:flag];
    delegate = theDelegate;
    didEndSelector = theSelector;
    secondsRemaining = 10;
    [self updateCountdownField];
    [NSApp beginSheet:sheet modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdown:) userInfo:nil repeats:YES];
}

- (void)abortCountdown
{
    if (countdownTimer)
    {
        [countdownTimer invalidate];
        countdownTimer = nil;
    }
    [countdownField setObjectValue:nil];
}

- (IBAction)checkboxChanged:(id)sender
{
    [self abortCountdown];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    if ([countdownTimer isValid])
        [self abortCountdown];
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    if ([countdownTimer isValid])
        [self abortCountdown];
}

- (void)defaultButtonAction:(id)sender
{
    [OKButton performClick:sender];
}

- (void)updateCountdownField
{
    NSString *formatString;
    if (secondsRemaining>1)
        formatString = NSLocalizedString(@"This sheet will close in %d seconds", @"");
    else
        formatString = NSLocalizedString(@"This sheet will close in %d second", @"");
    [countdownField setStringValue:[NSString stringWithFormat:formatString, secondsRemaining]];
}

- (void)countdown:(id)unused
{
    secondsRemaining--;
    if (secondsRemaining==0)
    {
        [countdownTimer invalidate];
        countdownTimer = nil;
        [NSApp endSheet:sheet];
    }
    else
        [self updateCountdownField];
}

- (IBAction)OKclicked:(id)sender
{
    void (*callback)(id, SEL, NSString *, id, BOOL) = (void (*)(id, SEL, NSString *, id, BOOL))objc_msgSend;
    
    [NSApp endSheet:sheet];
    (*callback)(delegate, didEndSelector, [messageField string], statusKey, [promptEachTimeCheckbox state]);

    
}

- (void)sheetDidEnd:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [theSheet orderOut:self];
    if (countdownTimer)
    {
        [countdownTimer invalidate];
        countdownTimer = nil;
    }
    [self autorelease];
}

- (void)dealloc
{
    [statusKey release];
    [sheet release];
    [super dealloc];
}

@end
