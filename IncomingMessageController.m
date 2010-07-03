/*
 * IncomingMessageController.m
 * Icy Juice
 *
 * Created by Mitz Pettel in May 2001.
 *
 * Copyright (c) 2001-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "IncomingMessageController.h"
#import "ContactListWindowController.h"
#import "ICQUserDocument.h"
#import "MPURLTextField.h"
#import "ICQFileTransfer.h"

@implementation IncomingMessageController

- (IBAction)reply:(id)sender
{
    OutgoingMessageController *replyController = [target composeMessageTo:[NSMutableArray arrayWithObject:messageSender]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replySent:) name:ICJOutGoingMessageSentNotification object:replyController];
}

- (void)replySent:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJOutGoingMessageSentNotification object:[notification object]];
    if (![messageSender hasMessageQueue])
    {
        [[self window] close];
    }
    else
        [self goToNext:self];
}

- (IBAction)goToNext:(id)sender
{
    if (isUnread)
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
    [currentMessage autorelease];
    currentMessage = [[messageSender drainedMessage] retain];
    if ([[NSApp mainWindow] isEqual:[self window]])
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
    else
        isUnread = YES;
    [self showCurrentMessage];
}

- (IBAction)showContactHistory:(id)sender
{
    [[self icqUserDocument] showHistoryOfContact:messageSender];
}

- (IBAction)makeContactPermanent:(id)sender
{
    [target addContactPermanently:messageSender];
}

- (IBAction)authorize:(id)sender
{
    ICQAuthAckMessage *message = [[[ICQAuthAckMessage alloc] autorelease] initTo:messageSender];
    [message setGranted:YES];
    [target sendMessage:message];
    if ([messageSender hasMessageQueue])
        [self goToNext:self];
    else
        [[self window] close];
}

- (IBAction)denyAuthorization:(id)sender
{
    ICQAuthAckMessage *message = [[[ICQAuthAckMessage alloc] autorelease] initTo:messageSender];
    [message setGranted:NO];
    [target sendMessage:message];
    if ([messageSender hasMessageQueue])
        [self goToNext:self];
    else
        [[self window] close];
}

- (IBAction)acceptFile:(id)sender
{
    [[self icqUserDocument] acceptFileTransfer:currentMessage promptForDestination:NO];
    if ([messageSender hasMessageQueue])
        [self goToNext:self];
    else
        [[self window] close];
}

- (IBAction)saveTo:(id)sender
{
    [[self icqUserDocument] acceptFileTransfer:currentMessage promptForDestination:YES];
    if ([messageSender hasMessageQueue])
        [self goToNext:self];
    else
        [[self window] close];
}

- (IBAction)declineFile:(id)sender
{
    [[currentMessage fileTransfer] decline];
    if ([messageSender hasMessageQueue])
        [self goToNext:self];
    else
        [[self window] close];
}

- (id)init
{
    self = [super initWithWindowNibName:@"IncomingMessage"];
    [self setWindowFrameAutosaveName:@"IncomingMessage"];
    isUnread = NO;
    return self;
}

- (void)setupToolbar
{
    NSToolbar *toolbar;

    nextToolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:ICJNextMessageToolbarItemIdentifier];
    [nextToolbarItem setLabel: NSLocalizedString(@"Next", @"Show next message toolbar item label")];
    [nextToolbarItem setPaletteLabel: NSLocalizedString(@"Next", @"Show next message toolbar item palette label")];
    [nextToolbarItem setToolTip: NSLocalizedString(@"Show Next Message", @"Show next message toolbar item tool tip")];
    [nextToolbarItem setView:nextButton];
    [nextToolbarItem setMinSize:[nextButton frame].size];
    [nextToolbarItem setMaxSize:[nextButton frame].size];
    [nextToolbarItem setTarget: self];
    [nextToolbarItem setAction: @selector(goToNext:)];
    [nextToolbarItem setMenuFormRepresentation:[[[NSMenuItem alloc] autorelease] initWithTitle:NSLocalizedString(@"Next", @"Show next message toolbar item menu representation") action:@selector(goToNext:) keyEquivalent:@""]];
    [[nextToolbarItem menuFormRepresentation] setTarget:self];

    toolbar = [[[NSToolbar alloc] initWithIdentifier: ICJIncomingToolbarIdentifier] autorelease];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setupToolbar];

    [urlField setEditable:NO];
    [urlField setSelectable:YES];
    [urlField setTextColor:[NSColor blueColor]];
    [urlField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
}

- (id)initWithContact:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget
{
    self = [self init];
    target = theTarget;
    if ([theSender incomingMessageWindowFrame])
    {
        [self setShouldCascadeWindows:NO];
        [[self window] setFrameFromString:[theSender incomingMessageWindowFrame]];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactChanged:) name:ICJContactInfoChangedNotification object:theSender];
//    messages = [theSender messageQueue];
    messageSender = theSender;
    [self goToNext:self];
    [addToListButton setEnabled:[theSender isTemporary]];
/*    if (![NSApp isHidden])
    {
        NSWindow *mainWindow = [NSApp mainWindow];
        if (!mainWindow || [[mainWindow windowController] isKindOfClass:[ContactListWindowController class]])
        {
            [[self window] orderWindow:NSWindowAbove relativeTo:[[[NSApp windows] objectAtIndex:0] windowNumber]];
            [[self window] makeKeyWindow];
        }
        else
            [[self window] orderWindow:NSWindowBelow relativeTo:[mainWindow windowNumber]];
    }
    else
    {
        [[NSApp delegate] orderFrontWindowWhenUnhidden:[self window]];
    }
*/
    [self orderWindowAsNewMessage];
    return self;
}

- (void)showCurrentMessage
{
    NSColor *backgroundColor = [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJIncomingBackgroundSettingName]];
    NSColor *textColor = [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJIncomingColorSettingName]];
    NSFont *font = [NSFont fontWithName:[[self icqUserDocument] settingWithName:ICJIncomingFontSettingName] size:[[[self icqUserDocument] settingWithName:ICJIncomingSizeSettingName] floatValue]];
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Message from %@", @"incoming message window title"), [messageSender displayName]]];
    
    if ([currentMessage isKindOfClass:[ICQAuthReqMessage class]])
    {
        [authReqMessageField setBackgroundColor:backgroundColor];
        [authReqMessageField setTextColor:textColor];
        [authReqMessageField setFont:font];
        [authReqMessageField setString:[currentMessage text]];
        [tabView selectTabViewItemWithIdentifier:@"authreq"];
    }
    else if ([currentMessage isKindOfClass:[ICQURLMessage class]])
    {
        [urlMessageField setBackgroundColor:backgroundColor];
        [urlMessageField setTextColor:textColor];
        [urlMessageField setFont:font];
        [urlMessageField setString:[currentMessage text]];
        [urlField setStringValue:[currentMessage url]];
        [urlField setURL:[currentMessage url]];
        [tabView selectTabViewItemWithIdentifier:@"url"];
    }
    else if ([currentMessage isKindOfClass:[ICQFileTransferMessage class]])
    {
        [fileMessageField setBackgroundColor:backgroundColor];
        [fileMessageField setTextColor:textColor];
        [fileMessageField setFont:font];
        [fileMessageField setString:[currentMessage text]];
        [fileListField setStringValue:[currentMessage description]];
        [tabView selectTabViewItemWithIdentifier:@"file"];
    }
    else if ([currentMessage isKindOfClass:[ICQUserAddedMessage class]])
    {
        [tabView selectTabViewItemWithIdentifier:@"added"];
    }
    else if ([currentMessage isKindOfClass:[ICQAuthAckMessage class]])
    {
        if ([currentMessage isGranted])
            [tabView selectTabViewItemWithIdentifier:@"granted"];
        else
        {
            [tabView selectTabViewItemWithIdentifier:@"rejected"];
            [rejectionReasonField setBackgroundColor:backgroundColor];
            [rejectionReasonField setTextColor:textColor];
            [rejectionReasonField setFont:font];
            [rejectionReasonField setString:[currentMessage text]];
        }
    }
    else
    {
        [messageField setBackgroundColor:backgroundColor];
        [messageField setTextColor:textColor];
        [messageField setFont:font];
        [messageField setString:[currentMessage text]];
        [tabView selectTabViewItemWithIdentifier:@"message"];
    }
    [dateField setStringValue:[NSString stringWithFormat: NSLocalizedString(@"Sent: %@", @"timestamp in incoming message window"),[[currentMessage sentDate] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] 
objectForKey:NSShortTimeDateFormatString] timeZone:nil locale:nil]]];
    [nextToolbarItem setEnabled:([messageSender hasMessageQueue])];
    [nextToolbarItem validate];
}

- (void)contactChanged:(NSNotification *)theNotification
{
    ICJContact *contact = [theNotification object];
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"Message from %@", @"incoming message window title"), [contact displayName]]];
    [addToListButton setEnabled:[contact isTemporary]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if (isUnread)
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
    [messageSender setIncomingMessageWindowFrame:[[self window] stringWithSavedFrame]];
    [[self retain] autorelease];
    [target incomingControllerWillClose:self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    if (isUnread)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
        isUnread = NO;
    }
}

- (void)dealloc
{
    [nextToolbarItem release];
    [currentMessage release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)messageAdded
{
    if ([messageSender hasMessageQueue])
    {
        [nextToolbarItem setEnabled:YES];
        [nextToolbarItem validate];
    }
}

+ (id)incomingMessageController:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget
{
    return [[[self alloc] initWithContact:theSender forDocument:theTarget] autorelease];
}

- (ICJContact *)selectedContact
{
    return messageSender;
}

- (ICQUserDocument *)icqUserDocument
{
    return target;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];
    if (action==@selector(makeContactPermanent:))
        return [messageSender isTemporary];
    if (action==@selector(goToNext:))
        return [messageSender hasMessageQueue];
    return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    NSString *itemIdentifier = [theItem itemIdentifier];
    if ([itemIdentifier isEqual:ICJAddContactToolbarItemIdentifier])
        return [messageSender isTemporary];
    return YES;
}

// MPActiveTextField delegate
- (void)control:(NSControl *)control textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

// NSToolbar delegate
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];

    if ([itemIdentifier isEqual: ICJShowHistoryToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"History", @"Show history toolbar item label")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"History", @"Show history toolbar item palette label")];
        [toolbarItem setToolTip: NSLocalizedString(@"Show Message History", @"Show history toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"history book.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(showContactHistory:)];
    } else if ([itemIdentifier isEqual: ICJShowInfoToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Info", @"Show Info toolbar item label")];
        [toolbarItem setPaletteLabel:  NSLocalizedString(@"Info", @"Show Info toolbar item palette label")];
        [toolbarItem setToolTip:  NSLocalizedString(@"Show Info", @"Show Info toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"user info.png"]];
        [toolbarItem setTarget: [NSApp delegate]];
        [toolbarItem setAction: @selector(showInfoPanel:)];
    } else if ([itemIdentifier isEqual: ICJAddContactToolbarItemIdentifier]) {
        [toolbarItem setLabel:  NSLocalizedString(@"Add To List", @"Add To List toolbar item label")];
        [toolbarItem setPaletteLabel:  NSLocalizedString(@"Add To Contact List", @"Add To List toolbar item palette label")];
        [toolbarItem setToolTip:  NSLocalizedString(@"Add The Sender To Your Contact List", @"Add To List toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"add to contact list.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(makeContactPermanent:)];
    } else if ([itemIdentifier isEqual: ICJNextMessageToolbarItemIdentifier]) {
        toolbarItem = nextToolbarItem;
    } else if ([itemIdentifier isEqual: ICJReplyToolbarItemIdentifier]) {
        [toolbarItem setLabel:  NSLocalizedString(@"Reply", @"Reply toolbar item label")];
        [toolbarItem setPaletteLabel:  NSLocalizedString(@"Reply", @"Reply toolbar item palette label")];
        [toolbarItem setToolTip:  NSLocalizedString(@"Reply to this Message", @"Reply toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"reply envelope.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(reply:)];
    } else
        toolbarItem = nil;
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJNextMessageToolbarItemIdentifier,
        ICJReplyToolbarItemIdentifier,
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJNextMessageToolbarItemIdentifier,
        ICJReplyToolbarItemIdentifier,
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        ICJAddContactToolbarItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

@end