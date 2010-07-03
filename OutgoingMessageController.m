/*
 * OutgoingMessageController.m
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

#import "OutgoingMessageController.h"
#import "ICQUserDocument.h"
#import "ChasingArrowsView.h"
#import "ContactStatusMessageController.h"
#import "MainController.h"
#import "MPStatusBarController.h"
#import "ContactListWindowController.h"

@implementation OutgoingMessageController

- (NSArray *)recipients
{
    return _recipients;
}

- (ICJContact *)recipient
{
    return [[self recipients] objectAtIndex:0];
}

- (BOOL)sendsToContactList
{
    return _sendsToContactList;
}

- (BOOL)sendsUrgent
{
    return _sendsUrgent;
}

- (void)setSendsToContactList:(BOOL)flag
{
    _sendsToContactList = flag;
}

- (void)setSendsUrgent:(BOOL)flag
{
    _sendsUrgent = flag;
}

- (BOOL)isSending
{
    return _isSending;
}

- (void)setSending:(BOOL)flag
{
    _isSending = flag;
    [self setNeedsUpdate:YES];
}

- (void)setMessageText:(NSString *)text
{
	if ( ![self isSending] )
		[messageField replaceCharactersInRange:[messageField selectedRange] withString:text];
}

- (BOOL)needsUpdate
{
    return _needsUpdate;
}

- (void)setNeedsUpdate:(BOOL)flag
{
    _needsUpdate = flag;
}

- (IBAction)showContactHistory:(id)sender
{
    [[self icqUserDocument] showHistoryOfContact:[self recipient]];
}

- (IBAction)send:(id)sender
{
    ICQNormalMessage	*message = [[[ICQNormalMessage alloc] autorelease]
        initIncoming:NO
        date:[NSDate date]
        owners:[self recipients]
    ];
    
    [message setText:[messageField string]];
    [message setToContactList:[self sendsToContactList]];
    [message setUrgent:[self sendsUrgent]];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(messageAcknowledged:)
        name:ICJMessageAcknowledgedNotification
        object:message
    ];
    [self setSending:YES];
    [[self icqUserDocument] sendMessage:message];
    if ( [[[self icqUserDocument] settingWithName:ICJHideWhenSendingSettingName] boolValue] )
        [[self window] orderOut:nil];
    [self setNeedsUpdate:YES];
}

- (IBAction)focusOnRecipient:(id)sender
{
    if ( [[self recipients] count]==1 )
        [[[self icqUserDocument] mainWindowController]
            focusOnContact:[self recipient]
        ];
}

- (IBAction)toggleStatusBarShown:(id)sender
{
    [statusBarController toggleVisible:sender];
    [[self icqUserDocument]
        setObject:[NSNumber numberWithBool:[statusBarController isVisible]]
        forSettingName:ICJOutgoingStatusBarShownSettingName
    ];
}

- (IBAction)readStatusMessage:(id)sender
{
    ContactStatusMessageController	*controller;
    
    controller = [[[ContactStatusMessageController alloc]
        initWithContact:[self recipient]
        document:[self icqUserDocument]
    ] autorelease];
    [controller beginSheetModalForWindow:[self window]];
}

- (IBAction)defaultButtonAction:(id)sender
{
    if ( [self canSend] )
        [self send:sender];
}

- (BOOL)canSend
{
    return (
        [[self icqUserDocument] isLoggedIn]
        && [[self recipients] count]>0
        && [[messageField textStorage] length]>0
        && ![self isSending]
    );
}

- (void)messageNotDelivered:(ICQMessage *)message
{
    ICJDeliveryFailureReason	reason = [message deliveryFailureReason];
    ICJContact			*recipient = [[message owners] objectAtIndex:0];
    
    switch (reason)
    {
        case Failed_Occupied:
        case Failed_DND:
            [NSBundle loadNibNamed:@"RejectMessage" owner:self];
            if ( reason==Failed_DND )
            {
                [rejectUrgentButton setEnabled:NO];
                [rejectDescriptionField
                    setStringValue:[NSString
                        stringWithFormat:NSLocalizedString( @"You can send the message to his/her Contact List, or cancel sending. %@ message:", @"parameter is abbreviated status name" ),
                        [[recipient status] shortName]
                    ]
                ];
            }
            else
                [rejectDescriptionField
                    setStringValue:[NSString
                        stringWithFormat:NSLocalizedString( @"You can send the message as an urgent one, send it to his/her Contact List, or cancel sending. %@ message:", @"parameter is abbreviated status name" ),
                        [[recipient status] shortName]
                    ]
                ];
            
            [rejectTitleField
                setStringValue:[NSString
                    stringWithFormat:NSLocalizedString( @"%@ is in %@ mode", @"urgent / CL / cancel sheet title; parameters are name and status" ),
                    [recipient displayName],
                    [[recipient status] name]
                ]
            ];
            [rejectStatusMessageField setString:[message statusMessage]];
            [[self window] makeKeyAndOrderFront:nil];
            [NSApp
                beginSheet:rejectMessageSheet
                modalForWindow:[self window]
                modalDelegate:nil
                didEndSelector:nil
                contextInfo:nil
            ];
            break;
            
        default:
            break;
    }
}

- (void)messageDelivered:(ICQMessage *)message
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ICJOutGoingMessageSentNotification
        object:self
    ];
    [[self window] close];
}

- (void)messageAcknowledged:(NSNotification *)theNotification
{
    ICQMessage		*message = [theNotification object];
    
    if ( [message isFinished] )
    {
        [self setSending:NO];
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJMessageAcknowledgedNotification
            object:message
        ];
        
        if ( [message isDelivered] )
            [self messageDelivered:message];
        else
        {
            [self messageNotDelivered:message];
        }
        [self update];
    }
}


- (IBAction)rejectCancelClicked:(id)sender
{
    [NSApp endSheet:rejectMessageSheet];
    [rejectMessageSheet close];
}

- (IBAction)rejectResendClicked:(id)sender
{
    [NSApp endSheet:rejectMessageSheet];
    [rejectMessageSheet close];
    if ( [sender tag]==1 )	// the Urgent button is tagged 1
        [self setSendsUrgent:YES];
    else
        [self setSendsToContactList:YES];
    [self send:nil];
}

- (IBAction)removeRecipient:(id)sender // this is not very efficient
{
    NSEnumerator	*selectedRows = [recipientsView selectedRowEnumerator];
    NSNumber		*row;
    NSMutableArray	*selectedRecipients = [NSMutableArray arrayWithCapacity:[recipientsView numberOfSelectedRows]];
    NSEnumerator	*selectedRecipientsEnum;
    ICJContact		*recipient;
    
    while ( row = [selectedRows nextObject] )
        [selectedRecipients addObject:[[self recipients] objectAtIndex:[row intValue]]];
        
    selectedRecipientsEnum = [selectedRecipients objectEnumerator];
    while ( recipient = [selectedRecipientsEnum nextObject] )
    {
        [_recipients removeObject:recipient];
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJContactInfoChangedNotification
            object:recipient
        ];
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJContactStatusChangedNotification
            object:recipient
        ];
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJContactStatusMessageChangedNotification
            object:recipient
        ];
    }
    [self setNeedsUpdate:YES];
}

- (void)addRecipient:(ICJContact *)theRecipient atIndex:(int)index
{
    [_recipients insertObject:theRecipient atIndex:index];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(recipientChanged:)
        name:ICJContactInfoChangedNotification
        object:theRecipient
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(recipientStatusChanged:)
        name:ICJContactStatusChangedNotification
        object:theRecipient
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(recipientStatusMessageChanged:)
        name:ICJContactStatusMessageChangedNotification
        object:theRecipient
    ];
    
    if ( [[[NSApp delegate] statusMessageStatuses] containsObject:[theRecipient statusKey]]
            && ![theRecipient statusMessage]
        )
    {
        NSDate		*statusChangeTime = [theRecipient statusChangeTime];
        NSTimeInterval	interval = 15/*MITZ*/+(statusChangeTime ? [statusChangeTime timeIntervalSinceNow] : 0);
        
        [NSTimer scheduledTimerWithTimeInterval:interval
            target:self
            selector:@selector(fetchStatusMessage:)
            userInfo:theRecipient
            repeats:NO
        ];
    }
    [self setNeedsUpdate:YES];
}

- (void)loginStatusChanged:(NSNotification *)aNotification
{
    [self update];
}

- (void)recipientChanged:(NSNotification *)aNotification
{
    [self update];
}

- (void)recipientStatusChanged:(NSNotification *)aNotification
{
    ICJContact	*recipient = [aNotification object];
        
    [self setSendsToContactList:NO];
    [self setSendsUrgent:NO];
    if ( [[[NSApp delegate] statusMessageStatuses] containsObject:[recipient statusKey]] )
        [NSTimer
            scheduledTimerWithTimeInterval:15/*MITZ*/
            target:self
            selector:@selector(fetchStatusMessage:)
            userInfo:recipient
            repeats:NO
        ];
        
    [self update];
}

- (void)fetchStatusMessage:(NSTimer *)timer
{
    ICJContact	*recipient = [timer userInfo];
    // by the time we got here the contact could have changed to another status
    if ( [[[NSApp delegate] statusMessageStatuses] containsObject:[recipient statusKey]] )
        [[self icqUserDocument] readStatusMessageForContact:recipient];
}

- (void)recipientStatusMessageChanged:(NSNotification *)aNotification
{
    [self update];
}

- (NSString *)nibName
{
    return @"OutgoingMessage";
}

- (void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: ICJOutgoingToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
}

- (void)synchronizeAttributes
{
    [messageField
        setFont:[NSFont
            fontWithName:[[self icqUserDocument] settingWithName:ICJOutgoingFontSettingName]
            size:[[[self icqUserDocument] settingWithName:ICJOutgoingSizeSettingName] floatValue]
        ]
    ];
    [messageField
        setBackgroundColor:[NSColor
            colorWithRGB:[[self icqUserDocument] settingWithName:ICJOutgoingBackgroundSettingName]
        ]
    ];
    [messageField
        setTextColor:[NSColor
            colorWithRGB:[[self icqUserDocument] settingWithName:ICJOutgoingColorSettingName]
        ]
    ];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [self setupToolbar];
    
    [self synchronizeAttributes];

    [messageField
        setContinuousSpellCheckingEnabled:[[[self icqUserDocument]
            settingWithName:ICJSpellCheckAsYouTypeSettingName
        ] boolValue]
    ];
    [messageField setAllowsUndo:YES];
    [messageField setRichText:NO];
    [messageField setUsesFontPanel:NO];
    
    [[self window] makeFirstResponder:messageField];
    
    [recipientsView
        registerForDraggedTypes:[NSArray arrayWithObject:ICJContactRefPboardType]
    ];
    
    if ( [[[self icqUserDocument] settingWithName:ICJOutgoingStatusBarShownSettingName] boolValue] )
        [statusBarController setVisible:YES resizing:NO];

    [messageField
        setBaseWritingDirection:[[[self icqUserDocument]
            settingWithName:@"Writing Direction"
            forContact:[self recipient]
        ] intValue]
    ];
    
    [self setNeedsUpdate:YES];
}

- (id)initTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget
{
    NSEnumerator	*recipientsEnumerator = [theRecipients objectEnumerator];
    ICJContact		*recipient;
    
    _recipients = [[NSMutableArray array] retain];
    _target = theTarget;
    
    self = [self initWithWindowNibName:[self nibName]];
    
    [self setWindowFrameAutosaveName:[self nibName]];
    
    while ( recipient = [recipientsEnumerator nextObject] )
        [self addRecipient:recipient atIndex:[[self recipients] count]];

    _statusChangeTimeFormat = [[NSUserDefaults standardUserDefaults] objectForKey:NSTimeFormatString];
    {
        // we try to eliminate the seconds component while preserving the user-defined format
        NSRange		hoursRange = [_statusChangeTimeFormat rangeOfString:@"H"];
        if ( hoursRange.location==NSNotFound )
            hoursRange = [_statusChangeTimeFormat rangeOfString:@"I"];
        if ( hoursRange.location!=NSNotFound )
        {
            if ( [[_statusChangeTimeFormat
                     substringWithRange:NSMakeRange(hoursRange.location+1,1)
                 ] isEqual:@"%"] )
                hoursRange.location--;
            _statusChangeTimeFormat = [[[_statusChangeTimeFormat
                substringToIndex:hoursRange.location+2
            ]
                stringByAppendingString:@"%M"
            ] retain];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(loginStatusChanged:)
        name:ICJLoginStatusChangedNotification
        object:[self icqUserDocument]
    ];
    
    return self;
}

+ (id)outgoingMessageControllerTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget
{
    id newController = [[self alloc] initTo:theRecipients forDocument:theTarget];
    
    [newController showWindow:nil];
    return [newController autorelease];
}

- (void)dealloc
{
    [_statusChangeTimeFormat release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_recipients release];
    [super dealloc];
}

- (ICJContact *)selectedContact
{
    if ( [[self recipients] count]==1 )
        return [self recipient];
    return nil;
}

- (ICQUserDocument *)icqUserDocument
{
    return _target;
}

// NSWindow delegate
- (void)windowWillClose:(id)sender
{
    [progressIndicator stopAnimation:self];
    [[self retain] autorelease];
    [[self icqUserDocument] outgoingControllerWillClose:self];
//    [recipientsView removeFromSuperviewWithoutNeedingDisplay];
    if ( [[self window] attachedSheet] )
        [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
    if ( [[self recipients] count]==1 )
        [[[self recipient] settings]
            setObject:[NSNumber numberWithInt:[messageField baseWritingDirection]]
            forKey:@"Writing Direction"
        ];
}

- (NSString *)windowTitle
{
        switch ( [[self recipients] count] )
        {
            case 0:
                return NSLocalizedString( @"Message (no recipients)", @"" );
                break;
            case 1:
                return [NSString
                    stringWithFormat:NSLocalizedString( @"Message to %@", @"" ),
                    [[self recipient] displayName]
                ];
                break;
            default:
                return [NSString
                    stringWithFormat:NSLocalizedString( @"Message to %@ and others", @"" ),
                    [[self recipient] displayName]
                ];
                break;
        }
}

- (void)update
{
    [recipientsView reloadData];
    [[self window] setTitle:[self windowTitle]];
    [messageField setEditable:![self isSending]];
    if ( [self isSending] )
        [progressIndicator startAnimation:nil];
    else
        [progressIndicator stopAnimation:nil];

    switch ( [[self recipients] count] )
    {
        case 0:
            [statusIcon setImage:nil];
            [statusTextField setStringValue:NSLocalizedString(@"No recipients", @"")];
            break;
        case 1:
            {
                ICJContact		*recipient = [self recipient];
                ContactStatus 	*status = [recipient status];
                NSCalendarDate 	*statusChangeTime = [recipient statusChangeTime];
                NSString		*statusMessage = [recipient statusMessage];
                
                [statusIcon setImage:[status icon]];
                [statusTextField setStringValue:[NSString
                    stringWithFormat:@"%@ (%@) %@",
                    [recipient displayName],
                    (statusChangeTime ?
                        [NSString
                            stringWithFormat:NSLocalizedString( @"%@ since %@", @"status text in outgoing message window status bar; parameters are status and time" ), 
                            [status shortName],
                            [statusChangeTime descriptionWithCalendarFormat:_statusChangeTimeFormat]
                        ]
                        : [status shortName]
                    ),
                    (statusMessage ?
                        [statusMessage stringByReplacing:@"\n" with:@" "]
                        : @""
                    )
                ]];
                [statusTextField setTextColor:(
                    [recipient typingFlags] ?
                        [NSColor redColor]
                        : [NSColor blackColor]
                )];
            }
            break;
        default:
            [statusIcon setImage:[NSImage imageNamed:@"Multiple.tiff"]];
            [statusTextField setStringValue:NSLocalizedString( @"Multiple recipients", @"" )];
            break;
    }
}

- (void)windowDidUpdate:(NSNotification *)notification
{
    if ( [self needsUpdate] )
    {
        [self setNeedsUpdate:NO];
        [self update];
    }
}

// NSTableDataSource
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self recipients] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return [[[self recipients] objectAtIndex:row] displayName];
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    ICJContact		*contact;
    BOOL		success = NO;
    NSArray		*contactRefsArray = [[info draggingPasteboard] propertyListForType:ICJContactRefPboardType];
    unsigned int	i;
    int			j=0;
    
    for ( i=0; i<[contactRefsArray count]; i++ )
    {
        [[contactRefsArray objectAtIndex:i] getBytes:&contact];
        if ( ![[self recipients] containsObject:contact] )
        {
            [self
                addRecipient:contact
                atIndex:( row==-1 ? [[self recipients] count] : row+j++ )
            ];
            success = YES;
        }
    }
    return success;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if ( op==NSTableViewDropOn && row!=-1 )
        [tv setDropRow:row dropOperation:NSTableViewDropAbove];
    return NSDragOperationGeneric;
}

// Informal protocol NSMenuValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL		action = [menuItem action];
    
    if ( action==@selector(showContactHistory:) )
        return ( [[self recipients] count]==1 );
        
    if ( action==@selector(send:) )
        return ( [self canSend] );
    if (action==@selector(readStatusMessage:))
    {
        if ( [[self recipients] count]==1 
                && [[self icqUserDocument] isLoggedIn]
                && [[[NSApp delegate] statusMessageStatuses] containsObject:[[self recipient] statusKey]]
            )
        {
            [menuItem setTitle:[NSString
                stringWithFormat:NSLocalizedString( @"Read %@ Message", @"menu command, parameter is the status" ),
                [[(ICJContact *)[self recipient] status] name]
            ]];
            return YES;
        }
        else
        {
            [menuItem setTitle:NSLocalizedString( @"Read Status Message", @"generic menu command, appears when status message is unavailable" )];
            return NO;
        }
    }
    
    if ( action==@selector(toggleStatusBarShown:) )
    {
        BOOL	statusBarShown = [statusBarController isVisible];
        
        if ( [menuItem tag]!=statusBarShown )
        {
            [menuItem setTitle:(statusBarShown ?
                NSLocalizedString(@"Hide Status Bar", @"menu command to hide the status bar")
                : NSLocalizedString(@"Show Status Bar", @"menu command to show the status bar")
            )];
            [menuItem setTag:statusBarShown];
        }
        return YES;
    }
    return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    NSString	*itemIdentifier = [theItem itemIdentifier];

    if ( [itemIdentifier isEqual:ICJShowHistoryToolbarItemIdentifier] )
        return ( [[self recipients] count]==1 );
        
    if ( [itemIdentifier isEqual:ICJSendToolbarItemIdentifier] )
        return [self canSend];
    return YES;
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
    } else if ([itemIdentifier isEqual: ICJSendToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Send", @"Send message toolbar item label")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Send", @"Send message toolbar item palette label")];
        [toolbarItem setToolTip: NSLocalizedString(@"Send Message", @"Send message toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"envelope.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(send:)];
    } else if ([itemIdentifier isEqual: ICJShowInfoToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Info", @"Show Info toolbar item label")];
        [toolbarItem setPaletteLabel:  NSLocalizedString(@"Info", @"Show Info toolbar item palette label")];
        [toolbarItem setToolTip:  NSLocalizedString(@"Show Info", @"Show Info toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"user info.tiff"]];
        [toolbarItem setTarget: [NSApp delegate]];
        [toolbarItem setAction: @selector(showInfoPanel:)];
    } else if ([itemIdentifier isEqual: ICJAddContactToolbarItemIdentifier]) {
        [toolbarItem setLabel:  NSLocalizedString(@"Add To List", @"Add To List toolbar item label")];
        [toolbarItem setPaletteLabel:  NSLocalizedString(@"Add To Contact List", @"Add To List toolbar item palette label")];
        [toolbarItem setToolTip:  NSLocalizedString(@"Add The Sender To Your Contact List", @"Add To List toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"add to contact list.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(makeContactPermanent:)];
    } else if ([itemIdentifier isEqual: ICJShowRecipientsToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Recipients", @"Show recipients toolbar item label")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Recipients", @"Show recipients toolbar item palette label")];
        [toolbarItem setToolTip: NSLocalizedString(@"Show Recipients", @"Show recipients toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"recipients.tiff"]];
        [toolbarItem setTarget:recipientsDrawer];
        [toolbarItem setAction: @selector(toggle:)];
    } else
        toolbarItem = nil;
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJSendToolbarItemIdentifier,
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        ICJShowRecipientsToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJShowHistoryToolbarItemIdentifier,
        ICJShowInfoToolbarItemIdentifier,
        ICJSendToolbarItemIdentifier,
        ICJShowRecipientsToolbarItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

@end
