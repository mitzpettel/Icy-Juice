/*
 * ContactStatusMessageController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Mar 01 2002.
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

#import "ContactStatusMessageController.h"
#import "Contact.h"
#import "ICQUserDocument.h"
#import "ICJMessage.h"

@implementation ContactStatusMessageController

- (id)initWithContact:(ICJContact *)theContact document:(ICQUserDocument *)theDocument
{
    self = [super initWithWindowNibName:@"ContactStatusMessage"];
    document = theDocument;
    contact = [theContact retain];
    [self setWindowFrameAutosaveName:@"ContactStatusMessage"];
    return self;
}

- (void)displayMessage
{
    [messageTitle setStringValue:[NSString stringWithFormat:NSLocalizedString(@"This User's %@ Message:", @"parameter is status name"), [[contact status] name]]];
    [messageField setString:[contact statusMessage]];
    [tabView selectTabViewItem:messageTabViewItem];
}

- (void)beginSheetModalForWindow:(NSWindow *)parentWindow
{
    NSWindow *window = [self window];	// loads it
    
    NSString *contactName = [contact displayName];
    NSString *statusName = [[contact status] name];
    NSString *statusMessage = [contact statusMessage];
    if (statusMessage)
    {
        [self displayMessage];
    }
    else
    {
        [tabView selectTabViewItem:readingTabViewItem];
        
        [readingTitle setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Reading User's %@ Message...", @"parameter is status name"), statusName]];
    }
    
    if (parentWindow)
    {
        [self retain];
        [NSApp beginSheet:window modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
    else
    {
        [window setTitle:[NSString stringWithFormat:NSLocalizedString(@"Status Message from %@", @"window title; parameter is status name"), contactName]];
        [window makeKeyAndOrderFront:nil];
    }
    
    if (!statusMessage)
    {
        [progressIndicator startAnimation:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusMessageChanged:) name:ICJContactStatusMessageChangedNotification object:contact];
        [document readStatusMessageForContact:contact];
    }
}

- (IBAction)refreshClicked:(id)sender
{
    [tabView selectTabViewItem:readingTabViewItem];
    
    [readingTitle setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Reading User's %@ Message...", @"parameter is status name"), [[contact status] name]]];
    [progressIndicator startAnimation:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusMessageChanged:) name:ICJContactStatusMessageChangedNotification object:contact];
    [document readStatusMessageForContact:contact];    
}

- (void)sheetDidEnd:(NSWindow *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    // when called with code ICJParentWindowClosing, it means the parent window is closing
    if (returnCode==ICJParentWindowClosing)
        [self windowWillClose:nil];
    else
        [theSheet close];
}

- (void)run
{
    [self beginSheetModalForWindow:nil];
}

- (void)statusMessageChanged:(NSNotification *)aNotification
{
    [progressIndicator stopAnimation:nil];
    if ([contact statusMessage])
        [self displayMessage];
    else
    {
        [tabView selectTabViewItem:errorTabViewItem];
        [contact setStatusMessage:nil];
    }
    // we're not a "status message inspector"! we want to remain displaying the message we got first
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJContactStatusMessageChangedNotification object:contact];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [contact release];
    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    if (![[self window] isSheet])
    {
        [[self retain] autorelease];
        [document removeContactStatusMessageController:self];
    }
    else
        [self autorelease];
}

- (IBAction)cancelClicked:(id)sender
{
    [self okClicked:sender];
}

- (IBAction)okClicked:(id)sender
{
    if ([[self window] isSheet])
        [NSApp endSheet:[self window]];
    else
        [self close];
}

@end
