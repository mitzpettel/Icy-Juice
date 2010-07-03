/*
 * DialogController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Dec 01 2001.
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

#import "DialogController.h"
#import "HistoryView.h"
#import "Contact.h"
#import "ICQUserDocument.h"
#import "ContactListWindowController.h"
#import "MainController.h"
#import "ICQFileTransfer.h"

@implementation DialogController

- (NSString *)nibName
{
    return @"Dialog";
}

- (id)initTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget
{
    self = [super initTo:theRecipients forDocument:theTarget];
    if ( self )
    {
        _dialogHistory = [[NSMutableArray array] retain];
        _unreadMessages = 0;
    }
    return self;
}

- (void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: ICJDialogToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
}

- (void)synchronizeAttributes
{
    [super synchronizeAttributes];
    
    [historyView setAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJIncomingBackgroundSettingName]],	ICJIncomingBackgroundAttributeName,
            [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJIncomingColorSettingName]],	ICJIncomingColorAttributeName,
            [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJOutgoingBackgroundSettingName]],	ICJOutgoingBackgroundAttributeName,
            [NSColor colorWithRGB:[[self icqUserDocument] settingWithName:ICJOutgoingColorSettingName]],	ICJOutgoingColorAttributeName,
            [NSFont fontWithName:[[self icqUserDocument] settingWithName:ICJIncomingFontSettingName]
                size:[[[self icqUserDocument] settingWithName:ICJIncomingSizeSettingName] floatValue]],
                                                                                        ICJIncomingFontAttributeName,
            [NSFont fontWithName:[[self icqUserDocument] settingWithName:ICJOutgoingFontSettingName]
                size:[[[self icqUserDocument] settingWithName:ICJOutgoingSizeSettingName] floatValue]],
                                                                                        ICJOutgoingFontAttributeName,
            nil
        ]
    ];
}

- (void)windowDidLoad
{
    ICJContact	*recipient = [self recipient];
    
    [super windowDidLoad];
    
    if ( [recipient incomingMessageWindowFrame] )
    {
        [self setShouldCascadeWindows:NO];
        [[self window] setFrameFromString:[recipient incomingMessageWindowFrame]];
    }
    [historyView setBaseWritingDirection:[messageField baseWritingDirection]];
    [historyView setHistory:_dialogHistory];
    [addToListButton setEnabled:[recipient isTemporary]];
}

- (void)dealloc
{
/*
    if ([hideInactiveTimer isValid])
    {
        [hideInactiveTimer invalidate];
        hideInactiveTimer = nil;
    }
*/    
    [_dialogHistory release];
    [super dealloc];
}

- (BOOL)hideInactiveDisabled
{
    return _hideInactiveDisabled;
}

- (void)setHideInactiveDisabled:(BOOL)flag
{
    _hideInactiveDisabled = flag;
    if ( flag )
        [self setInactive:NO];
}

- (void)hideInactive:(NSTimer *)aTimer
{
    [[self window] orderOut:nil];
    _hideInactiveTimer = nil;
}

- (void)setInactive:(BOOL)flag
{
    if ( flag )
    {
        if ( _hideInactiveTimer==nil && ![self hideInactiveDisabled] )
        {
            NSTimeInterval	timeToHide = [[[self icqUserDocument]
                settingWithName:ICJTimeToHideInactiveSettingName
                forContact:[self recipient]
            ] intValue];
            
            if ( timeToHide )
                _hideInactiveTimer = [NSTimer
                    scheduledTimerWithTimeInterval:timeToHide
                    target:self
                    selector:@selector(hideInactive:)
                    userInfo:nil
                    repeats:NO
                ];
        }
    }
    else
    {
        [_hideInactiveTimer invalidate];
        _hideInactiveTimer = nil;
    }
}

- (void)messageDelivered:(ICJMessage *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJOutGoingMessageSentNotification object:self];
    [_dialogHistory addObject:message];
    [historyView reloadDataByAppending:YES andScrollToEnd:YES];
    [messageField setString:@""];
//    [self setPhase:CanSend];
    if (![[self window] isMainWindow] && [[self window] attachedSheet]==nil)
        [self setInactive:YES];
}

- (NSString *)windowTitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"Conversation with %@", @""),[[self recipient] displayName]];
}

// NSWindow delegate
- (void)windowWillClose:(NSNotification *)notification
{
    [[self recipient] setIncomingMessageWindowFrame:[[self window] stringWithSavedFrame]];

    // get rid of attention requests and inactivity state
    [self windowDidBecomeMain:notification];
    
    [[self retain] autorelease];
    [[self icqUserDocument] incomingControllerWillClose:self];
    [[self icqUserDocument] outgoingControllerWillClose:self];

    if ([[self window] attachedSheet])
        [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
    [[[self recipient] settings] setObject:[NSNumber numberWithInt:[messageField baseWritingDirection]] forKey:@"Writing Direction"];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    while ( _unreadMessages>0 )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
        _unreadMessages--;
    }
    [self setInactive:NO];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    if ( ![self isSending] && [[self window] attachedSheet]==nil )
        [self setInactive:YES];
}


// Formal protocol ICJIncomingMessageDisplay
+ (id)incomingMessageController:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget
{
    return [[[self alloc] initWithContact:theSender forDocument:theTarget] autorelease];
}

- (id)initWithContact:(ICJContact *)theContact forDocument:(ICQUserDocument *)theTarget
{
    [self initTo:[NSMutableArray arrayWithObject:theContact] forDocument:theTarget];
    return self;
}

- (IBAction)makeContactPermanent:(id)sender
{
    [[self icqUserDocument] addContactPermanently:[self recipient]];
}

- (IBAction)authorize:(id)sender
{
    ICQAuthAckMessage *message = [[[ICQAuthAckMessage alloc] autorelease] initTo:[self recipient]];
    [message setGranted:YES];
    [[self icqUserDocument] sendMessage:message];
    [NSApp endSheet:authReqSheet];
}

- (IBAction)denyAuthorization:(id)sender
{
    ICQAuthAckMessage *message = [[[ICQAuthAckMessage alloc] autorelease] initTo:[self recipient]];
    [message setGranted:NO];
    [[self icqUserDocument] sendMessage:message];
    [NSApp endSheet:authReqSheet];
}

- (IBAction)ignoreAuthorizationRequest:(id)sender
{
    [NSApp endSheet:authReqSheet];
}

- (IBAction)acceptFile:(id)sender
{
    [NSApp endSheet:fileSheet returnCode:NSAlertDefaultReturn];
}

- (IBAction)saveTo:(id)sender
{
    [NSApp endSheet:fileSheet returnCode:NSAlertOtherReturn];
}

- (IBAction)declineFile:(id)sender
{
    [NSApp endSheet:fileSheet returnCode:NSAlertAlternateReturn];
}

- (IBAction)toggleWindowAutoHiding:(id)sender
{
    [self setHideInactiveDisabled:![self hideInactiveDisabled]];
}

- (void)authReqSheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)context
{
    if (sheet)
        [sheet orderOut:nil];
}

- (void)fileSheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)context
{
    ICQFileTransferMessage	*transfer = context;
    if ( sheet )
        [sheet orderOut:nil];
    switch ( returnCode )
    {
        case NSAlertDefaultReturn:
            [[self icqUserDocument] acceptFileTransfer:transfer promptForDestination:NO];
            break;
        case NSAlertOtherReturn:
            [[self icqUserDocument] acceptFileTransfer:transfer promptForDestination:YES];
            break;
        case NSAlertAlternateReturn:
            [[transfer fileTransfer] decline];
            break;
        default:
            break;
    }
    [transfer release];
}

- (void)recipientChanged:(NSNotification *)aNotification
{
    [super recipientChanged:aNotification];
    [addToListButton setEnabled:[[aNotification object] isTemporary]];
}

- (void)messageAdded
{
    int newMessageCount = 0;
    ICJContact *recipient = [self recipient];
    NSEnumerator *newMessages = [[recipient drainedMessages] objectEnumerator];
    id currentMessage;
    while (currentMessage = [newMessages nextObject])
    {
        newMessageCount++;
        if ([currentMessage isKindOfClass:[ICQAuthReqMessage class]])
        {
            [[self window] makeKeyAndOrderFront:nil];
            [authReqMessageField setString:[currentMessage text]];
            [NSApp beginSheet:authReqSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(authReqSheet:didEndAndReturned:contextInfo:) contextInfo:nil];
        }
        else if ( [currentMessage isKindOfClass:[ICQFileTransferMessage class]] )
        {
            [[self window] makeKeyAndOrderFront:nil];
            [fileMessageView setString:[currentMessage text]];
            [fileListField setStringValue:[currentMessage description]];
            [NSApp
                beginSheet:fileSheet
                modalForWindow:[self window]
                modalDelegate:self
                didEndSelector:@selector(fileSheet:didEndAndReturned:contextInfo:)
                contextInfo:[currentMessage retain]
            ];
        }
        else
            [_dialogHistory addObject:currentMessage];
    }
    if ([[self window] isMainWindow])
    {
        int i;
        for (i = newMessageCount; i>0; i--)
            [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageGotAttentionNotification object:[self icqUserDocument]];
    }
    else
    {
        _unreadMessages += newMessageCount;
        [self orderWindowAsNewMessage];
    }
    [historyView reloadDataByAppending:YES andScrollToEnd:YES];
    [self setInactive:NO];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];
    if (action==@selector(makeContactPermanent:))
        return [[self recipient] isTemporary];
    if (action==@selector(toggleWindowAutoHiding:))
    {
        [menuItem setState:[self hideInactiveDisabled]];
        return ([[[self icqUserDocument] settingWithName:ICJTimeToHideInactiveSettingName forContact:[self recipient]] intValue]!=0);
    }
    return [super validateMenuItem:menuItem];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    NSString *itemIdentifier = [theItem itemIdentifier];
    if ([itemIdentifier isEqual:ICJAddContactToolbarItemIdentifier])
        return [[self recipient] isTemporary];
    return [super validateToolbarItem:theItem];
}

// NSToolbar delegate
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJSendToolbarItemIdentifier,
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        ICJSendToolbarItemIdentifier,
        ICJAddContactToolbarItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

@end
