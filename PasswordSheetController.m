/*
 * PasswordSheetController.m
 * Icy Juice
 *
 * Created by Mitz Pettel in May 2001.
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

#import "PasswordSheetController.h"

@implementation PasswordSheetController

+ (void)beginPasswordSheetForWindow:(NSWindow *)theWindow withPrompt:(NSString *)thePrompt delegate:(id)theDelegate didEndSelector:(SEL)theDidEndSelector
{
    self = [[self alloc] init];
    [NSBundle loadNibNamed:@"PasswordSheet" owner:self];
    [promptText setStringValue:thePrompt];
    delegate = theDelegate;
    didEndSelector = theDidEndSelector;
    [NSApp beginSheet:window modalForWindow:theWindow modalDelegate:self didEndSelector:@selector(passwordSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)passwordSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)context
{
    if (sheet) [sheet orderOut:self];
}

/*+ (id)passwordSheetWithPrompt:(NSString *)thePrompt forWindow:(NSWindow *)docWindow ofContactList:(ContactListController *)theContactListController
{
    return [[self alloc] initWithPrompt:thePrompt forWindow:docWindow ofContactList:theContactListController];
}

- (id)initWithPrompt:(NSString *)thePrompt forWindow:(NSWindow *)docWindow ofContactList:(ContactListController *)theContactListController
{
    self = [self init];
    prompt = [thePrompt retain];
    target = theContactListController;
    [NSBundle loadNibNamed:@"PasswordSheet" owner:self];
    [promptText setStringValue:thePrompt];
    [NSApp beginSheet:window modalForWindow:docWindow modalDelegate:NULL didEndSelector:nil contextInfo:NULL];
    return self;
}*/

- (IBAction)doOK:(id)sender
{
    [NSApp endSheet:[sender window]];
    [self autorelease];
    [delegate performSelector:didEndSelector withObject:[passwordField stringValue]];
}

- (IBAction)doCancel:(id)sender
{
    [NSApp endSheet:[sender window]];
    [self autorelease];
    [delegate performSelector:didEndSelector withObject:nil];
}

- (NSString *)password
{
    return [passwordField stringValue];
}

@end