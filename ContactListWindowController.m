/*
 * ContactListWindowController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Thu Nov 15 2001.
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

#import "ContactListWindowController.h"
#import "Contact.h"
#import "ICQUserDocument.h"
#import "ContactListView.h"
#import "MainController.h" // for our [NSApp delegate] stuff
#import "PasswordSheetController.h"
#import "ContactList.h"
#import "UserSettingsController.h"
#import "UserDetailsController.h"
#import "StatusMessageSheetController.h"
#import "MPStatusBarController.h"
#import "ICJStatusIconCell.h"
#import "ChasingArrowsView.h"


@implementation ContactListWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"ContactListWindow"];
    if ( self )
    {
        [self setWindowFrameAutosaveName:@"ContactListWindow"];
        [self setShouldCloseDocument:YES];
        [self setNeedsUpdate:NO];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [displayList release];
    [super dealloc];
}

// NSWindowController
- (void)windowDidLoad
{
    NSTableColumn	*sortColumn;
    NSString		*savedFrame = [[self document] savedContactListWindowFrame];
    
    [super windowDidLoad];
    
    if ( [[[self document] settingWithName:ICJStatusBarShownSettingName] boolValue] )
    {
        [statusBarController setVisible:YES resizing:NO];
    }
    
    if ( savedFrame )
    {
        [self setShouldCascadeWindows:NO];
        [[self window] setFrameFromString:savedFrame];
    }
    
    sortColumn = [contactListView tableColumnWithIdentifier:[[self document] sortColumnIdentifier]];
    
    [contactListView
        setIndicatorImage:( [[self document] descendingOrder]
            ? [NSTableView _defaultTableHeaderReverseSortImage]
            : [NSTableView _defaultTableHeaderSortImage] )
        inTableColumn:sortColumn
    ];
    [contactListView setHighlightedTableColumn:sortColumn];
    [contactListView setTarget:self];
    [contactListView setDoubleAction:@selector(defaultAction:)];
    [contactListView
        registerForDraggedTypes:[NSArray arrayWithObjects:
			NSFilenamesPboardType,
			NSStringPboardType,
			nil
		]
    ];

    isClosing = NO;
    [self setNeedsUpdate:YES];
    [self initStatusMenu];
    [[self window] makeFirstResponder:contactListView];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(contactListChanged:)
        name:ICJContactListChangedNotification
        object:[[self document] contactList]
    ];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(wrongPassword:)
        name:ICJWrongPasswordNotification
        object:[self document]
    ];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(wrongPassword:)
        name:ICJNeedPasswordNotification
        object:[self document]
    ];
    
    [self userStatusChanged:nil];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(userStatusChanged:)
        name:ICJUserStatusChangedNotification
        object:[self document]
    ];
    
    [[NSApp delegate]
        registerDockMenu:[statusPopUp menu]
        forDocument:[self document]
    ];
}

// accessors
- (NSMutableDictionary *)contactList
{
    return [[self document] contactList];
}

// IB actions
- (IBAction)toggleStatusBarShown:(id)sender
{
    [statusBarController toggleVisible:sender];

    [[self document]
        setObject:[NSNumber numberWithBool:[statusBarController isVisible]]
        forSettingName:ICJStatusBarShownSettingName
    ];
}

- (void)statusMessageSheetDidEndWithMessage:(NSString *)newStatusMessage forStatusKey:(id)statusKey keepPrompting:(BOOL)flag
{
    NSMutableDictionary	*statusMessages = [NSMutableDictionary
        dictionaryWithDictionary:[[self document] settingWithName:ICJStatusMessagesSettingName]
    ];

    [statusMessages setObject:newStatusMessage forKey:statusKey];
    [[self document] setObject:statusMessages forSettingName:ICJStatusMessagesSettingName];
    [[self document] setObject:[NSNumber numberWithBool:flag] forSettingName:ICJPromptForStatusMessageSettingName];
}

- (IBAction)changeStatus:(id)sender
{
    NSString		*newStatus = [sender representedObject];
    ICQUserDocument	*document = [self document];
    NSString		*oldStatus = [document targetStatus];
    
    [[self document] userDidRequestStatus:newStatus];
    
    if (
        [sender isKindOfClass:[NSMenuItem class]]
        && ![newStatus isEqual:oldStatus]
        && ( [[document settingWithName:ICJPromptForStatusMessageSettingName] boolValue]
            || ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) )
        && [[[NSApp delegate] statusMessageStatuses] containsObject:newStatus]
        && [[self window] attachedSheet]==nil
        )
    {
        NSString *statusMessage = [[document settingWithName:ICJStatusMessagesSettingName] objectForKey:newStatus];
        [[StatusMessageSheetController new]
            runModalForWindow:[self window]
            withStatusKey:newStatus
            message:statusMessage
            promptEachTime:[[document settingWithName:ICJPromptForStatusMessageSettingName] boolValue]
            modalDelegate:self
            didEndSelector:@selector(statusMessageSheetDidEndWithMessage:forStatusKey:keepPrompting:)
        ];
    }
}

- (IBAction)toggleOfflineContacts:(id)sender
{
    [[self document] setOfflineHidden:![[self document] offlineHidden]];
    [self setNeedsUpdate:YES];
}

- (IBAction)composeMessage:(id)sender
{
    if ( [contactListView selectedRow]!=-1 )
    {
        NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
        NSNumber	*row;
        NSMutableArray	*recipients = [NSMutableArray array];
        
        while ( row = [selectedRows nextObject] )
        {
            ICJContact *contact = [displayList objectAtIndex:[row intValue]];
            [recipients addObject:contact];
        }
        
        [[self document] composeMessageTo:recipients];
    }
}

- (IBAction)composeAuthorizationRequest:(id)sender
{
    [[self document] composeAuthorizationRequestTo:[displayList objectAtIndex:[contactListView selectedRow]]];
}

- (IBAction)composeFileTransfer:(id)sender
{
    [[self document] composeFileTransferTo:[displayList objectAtIndex:[contactListView selectedRow]]];
}

- (IBAction)receiveAction:(id)sender
{
    if ( [contactListView selectedRow]!=-1 )
    {
        NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
        NSNumber	*row;

        while ( row = [selectedRows nextObject] )
        {
            ICJContact *contact = [displayList objectAtIndex:[row intValue]];
            [[self document] showIncomingMessagesForContact:contact];
        }
    }
}

- (IBAction)goToNext:(id)sender
{
    [self popNextMessage:sender];
}

- (IBAction)popNextMessage:(id)sender
{
    [NSApp preventWindowOrdering];
    [[self document] showIncomingMessagesForContact:[[[self document] contactsPendingWindows] objectAtIndex:0]];
}

- (IBAction)defaultAction:(id)sender
{
    if ( [contactListView selectedRow]!=-1 )
    {
        NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
        NSNumber	*row;
        NSMutableArray	*recipients = [NSMutableArray array];
        
        while ( row = [selectedRows nextObject] )
        {
            ICJContact *contact = [displayList objectAtIndex:[row intValue]];
            if ( ![[self document] showIncomingMessagesForContact:contact] )
                [recipients addObject:contact];
        }
        
        if ( [recipients count]>0 )
            [[self document] composeMessageTo:recipients];
    }
}

- (IBAction)deleteSelectedContacts:(id)sender
{
    NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
    NSNumber		*row;
    NSMutableArray	*selectedContacts = [NSMutableArray arrayWithCapacity:[contactListView numberOfSelectedRows]];
    NSEnumerator	*selectedContactsEnum;
    ICJContact		*contact;
    
    while ( row = [selectedRows nextObject] )
        [selectedContacts addObject:[displayList objectAtIndex:[row intValue]]];

    selectedContactsEnum = [selectedContacts objectEnumerator];

    while ( contact = [selectedContactsEnum nextObject] )
        [[self document] deleteContact:contact];
}

- (IBAction)renameContact:(id)sender
{
    NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
    NSNumber		*row;
    
	[[self window] makeKeyWindow];
    while ( row = [selectedRows nextObject] )
        [contactListView
            editColumn:[contactListView columnWithIdentifier:@"nickname"]
            row:[row intValue]
            withEvent:nil
            select:YES
        ];
}

- (IBAction)makeContactPermanent:(id)sender
{
    NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
    NSNumber		*row;
    
    while ( row = [selectedRows nextObject] )
        [[self document] addContactPermanently:[displayList objectAtIndex:[row intValue]]];
}

- (IBAction)toggleVisibleList:(id)sender
{
    ICJContact	*contact = [displayList objectAtIndex:[contactListView selectedRow]];
    
    if ( [contact isOnVisibleList] )
        [[self document] removeFromVisibleList:contact];
    else
        [[self document] addToVisibleList:contact];
}

- (IBAction)toggleInvisibleList:(id)sender
{
    ICJContact	*contact = [displayList objectAtIndex:[contactListView selectedRow]];

    if ( [contact isOnInvisibleList] )
        [[self document] removeFromInvisibleList:contact];
    else
        [[self document] addToInvisibleList:contact];
}

- (IBAction)showContactHistory:(id)sender
{
    NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
    NSNumber		*row;
    
    while  (row = [selectedRows nextObject] )
        [[self document] showHistoryOfContact:[displayList objectAtIndex:[row intValue]]];
}

- (IBAction)showSettings:(id)sender
{
    [[UserSettingsController alloc] initForWindow:[self window] document:[self document]];
}

- (IBAction)showDetails:(id)sender
{
    [[[self document] userDetailsController] showWindow:nil];
}

- (void)focusOnContact:(ICJContact *)theContact
{
    int	i = [displayList indexOfObject:theContact];

    if ( i!=NSNotFound )
    {
        [contactListView selectRow:i byExtendingSelection:NO];
        [contactListView scrollRowToVisible:i];
        [[self window] makeKeyAndOrderFront:nil];
    }
}

- (IBAction)readStatusMessage:(id)sender
{
    NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
    NSNumber		*row;
    
    while ( row = [selectedRows nextObject] )
        [[self document] readStatusMessageOfContact:[displayList objectAtIndex:[row intValue]]];
}

- (void)importConfirmationSheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode
{
    if ( returnCode==NSOKButton )
        [[self document] importServerBasedList];
}

- (IBAction)importServerBasedList:(id)sender
{
    NSBeginInformationalAlertSheet(
        NSLocalizedString(@"Importing Contacts from ICQ Servers", @"information alert title"),
        NSLocalizedString(@"Import", @"Import button on informational alert"),
        NSLocalizedString(@"Cancel", @"Cancel button on informational alert"),
        nil,
        [self window],
        self,
        @selector(importConfirmationSheet:didEndAndReturned:),
        nil,
        nil,
        NSLocalizedString(@"All contacts on your server-stored contact list will be added to this contact list. Existing contacts will not be changed.", @"informational alert message")
    );
}
/*
- (NSMenu *)dockMenu
{
    return [statusPopUp menu];
}
*/
// The currently selected contact, if there is exactly one (used by Contact Info inspector)
- (ICJContact *)selectedContact
{
    ICJContact	*theContact;

    if ( [contactListView numberOfSelectedRows]!=1 )
        theContact = nil;
    else
        theContact = [displayList objectAtIndex:[contactListView selectedRow]];

    return theContact;
}

// Initialize the status popup
- (void)initStatusMenu
{
    NSMenu		*statusMenu = [[NSMenu alloc] init];
    NSEnumerator	*statuses = [[[NSApp delegate] userStatuses] objectEnumerator]; // this should probably come from somewhere else (document?)
    ContactStatus	*status;
    NSString		*statusKey;
    NSMenuItem		*menuItem;
    int			key = 1;

    while ( statusKey = [statuses nextObject] )
    {
        status = [[NSApp delegate] statusForKey:statusKey];
        menuItem = [[NSMenuItem alloc]
            initWithTitle:[status name]
            action:@selector(changeStatus:)
            keyEquivalent:[NSString stringWithFormat:@"%d", key++]
        ];
        [menuItem setRepresentedObject:statusKey];
        [menuItem setTarget:self];
        //            [menuItem setImage:[status icon]];
        [statusMenu addItem:menuItem];
    }
    
    [statusPopUp setMenu:statusMenu];
}

// The contacts we display, ordered as we display them
- (BOOL)updateDisplayList
{
    BOOL			needsFlashing = NO;
    ContactStatus		*offlineStatus = [[NSApp delegate] statusForKey:ICJOfflineStatusKey];
    struct sortContextStruct	sortContext;
    NSArray 			*contactsToDisplay;
    NSArray 			*allContacts = [[self contactList] allValues];
    int				contactCount = [allContacts count];
    int				i;
    BOOL			offlineHidden = [[self document] offlineHidden];

    [displayList autorelease];

    sortContext.columnIdentifier = [[contactListView highlightedTableColumn] identifier];
    sortContext.descending = [[self document] descendingOrder];

    contactsToDisplay = [NSMutableArray arrayWithCapacity:contactCount];

    for ( i = 0; i<contactCount; i++ )
    {
        ICJContact		*currentContact = [allContacts objectAtIndex:i];
        BOOL		hasMessageQueue = [currentContact hasMessageQueue];
        
        if (
            ![currentContact isDeleted]
            && ( !offlineHidden || !([currentContact status]==offlineStatus) || hasMessageQueue)
            )
        {
            [(NSMutableArray *)contactsToDisplay addObject:currentContact];
            needsFlashing |= hasMessageQueue;
        }
    }
    
    displayList = [[contactsToDisplay
        sortedArrayUsingFunction:compContacts
        context:&sortContext
    ] retain];
    
    return needsFlashing;
}

// refreshes the display list while maintaining the selection
- (void)updateView
{
    BOOL	needsFlashing;
    int		displayCount;
    NSString	*formatString;

    if ( [contactListView editedRow]==-1 )
    {
        NSEnumerator	*selectedRows = [contactListView selectedRowEnumerator];
        NSNumber	*row;
        NSMutableArray	*selectedContacts = [NSMutableArray arrayWithCapacity:[contactListView numberOfSelectedRows]];
        NSEnumerator	*selectedContactsEnum;
        ICJContact		*contact;

        while ( row = [selectedRows nextObject] )
            [selectedContacts addObject:[displayList objectAtIndex:[row intValue]]];

	[contactListView dataWillChange];
        needsFlashing = [self updateDisplayList];
        [contactListView deselectAll:self];
        [contactListView dataDidChange];
        [contactListView setFlashing:needsFlashing];

        selectedContactsEnum = [selectedContacts objectEnumerator];

        while ( contact = [selectedContactsEnum nextObject] )
        {
            unsigned indexOfContact = [displayList indexOfObject:contact];
            if ( indexOfContact!=NSNotFound )
                [contactListView
                    selectRow:[displayList indexOfObject:contact]
                    byExtendingSelection:YES
                ];
        }
    }

    displayCount = [displayList count];

    switch ( displayCount )
    {
        case 0:
            formatString = NSLocalizedString(@"no contacts", @"");
            break;
        case 1:
            formatString = NSLocalizedString(@"%d contact", @"one contact");
            break;
        default:
            formatString = NSLocalizedString(@"%d contacts", @"more than one contact");
            break;
    }
    
    [contactCountText setStringValue:[NSString stringWithFormat:formatString, displayCount]];
}

- (void)setNeedsUpdate:(BOOL)isUpdateNeeded
{
    needsUpdate = isUpdateNeeded;

    if (isUpdateNeeded && !isClosing)
    {
        [[self window] update];
    }
}

- (ICQUserDocument *)icqUserDocument
{
    return [self document];
}

// NSWindow delegate
- (void)windowDidUpdate:(NSNotification *)theNotification
{
    if ( needsUpdate )
    {
        needsUpdate = NO;
        [self updateView];
        [popNextMessageButton setEnabled:([[[self document] contactsPendingWindows] count]>0)];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApp delegate] unregisterDockMenu:[statusPopUp menu]];
    [chasingArrows stopAnimation:self];
    [contactListView stopFlashing:self];
    isClosing = YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
        
    if (action==@selector(toggleOfflineContacts:))
    {
        BOOL offlineHidden = [[self document] offlineHidden];
        if ([menuItem tag]!=offlineHidden)
        {
            [menuItem setTitle:(offlineHidden ? NSLocalizedString(@"Show Offline Contacts", @"menu command to show offline contacts") : NSLocalizedString(@"Hide Offline Contacts", @"menu command to hide offline contacts"))];
            [menuItem setTag:offlineHidden];
        }
        return YES;
    }
    if (action==@selector(toggleStatusBarShown:))
    {
        BOOL statusBarShown = [statusBarController isVisible];
        if ([menuItem tag]!=statusBarShown)
        {
            [menuItem setTitle:(statusBarShown ? NSLocalizedString(@"Hide Status Bar", @"menu command to hide the status bar") : NSLocalizedString(@"Show Status Bar", @"menu command to show the status bar"))];
            [menuItem setTag:statusBarShown];
        }
        return YES;
    }
    if (action==@selector(deleteSelectedContacts:)
        || action==@selector(defaultAction:)
        || action==@selector(composeMessage:)
        || action==@selector(showContactHistory:))
        return ([contactListView numberOfSelectedRows]>0 && [contactListView editedRow]==-1);
    if (action==@selector(renameContact:))
        return ([contactListView numberOfSelectedRows]==1 && [contactListView editedRow]==-1);
    if (action==@selector(composeAuthorizationRequest:))
        return ([contactListView numberOfSelectedRows]==1 && [[displayList objectAtIndex:[contactListView selectedRow]] isPendingAuthorization]);
    if (action==@selector(composeFileTransfer:))
        return ([contactListView numberOfSelectedRows]==1);
    if (action==@selector(receiveAction:))
    {
        if ([contactListView numberOfSelectedRows]==0)
            return NO;
        else
        {
            NSEnumerator *selectedRows = [contactListView selectedRowEnumerator];
            NSNumber *row;
            while (row = [selectedRows nextObject])
                if (![[displayList objectAtIndex:[row intValue]] hasMessageQueue])
                    return NO;
            return YES;
        }
    }
    if (action==@selector(importServerBasedList:))
        return [[self document] isLoggedIn];
    if (action==@selector(makeContactPermanent:))
    {
        if ([contactListView numberOfSelectedRows]==0)
            return NO;
        else
        {
            NSEnumerator *selectedRows = [contactListView selectedRowEnumerator];
            NSNumber *row;
            while (row = [selectedRows nextObject])
                if (![[displayList objectAtIndex:[row intValue]] isTemporary])
                    return NO;
            return YES;
        }
    }
    if (action==@selector(readStatusMessage:))
    {
        ContactStatus *contactStatus;
        if ([contactListView numberOfSelectedRows]==1 && [[[NSApp delegate] statusMessageStatuses] containsObject:[(contactStatus = [(ICJContact *)[displayList objectAtIndex:[contactListView selectedRow]] status]) key]])
        {
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Read %@ Message", @"menu command, parameter is the status"), [contactStatus name] ]];
        return YES;
        }
        else
        {
            [menuItem setTitle:NSLocalizedString(@"Read Status Message", @"generic menu command, appears when status message is unavailable")];
            return NO;
        }
    }
    if (action==@selector(toggleVisibleList:))
    {
        if ([contactListView numberOfSelectedRows]==1)
        {
            [menuItem setTitle:([[displayList objectAtIndex:[contactListView selectedRow]] isOnVisibleList] ? NSLocalizedString(@"Remove from Visible List", @"menu command") : NSLocalizedString(@"Add to Visible List", @"menu command"))];
        return YES;
        }
        else
            return NO;
    }
    if (action==@selector(toggleInvisibleList:))
    {
        if ([contactListView numberOfSelectedRows]==1)
        {
            [menuItem setTitle:([[displayList objectAtIndex:[contactListView selectedRow]] isOnInvisibleList] ? NSLocalizedString(@"Remove from Invisible List", @"menu command") : NSLocalizedString(@"Add to Invisible List", @"menu command"))];
        return YES;
        }
        else
            return NO;
    }
    return YES;
}

// NSTableDataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (displayList)
        return([displayList count]);
    else
        return 0;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    id columnIdentifier = [tableColumn identifier];
    ICJContact *contact = [displayList objectAtIndex:row];
    if ([columnIdentifier isEqual:@"nickname"])
    {
        [cell setTextColor:([contact isTemporary] ? [NSColor darkGrayColor] : [NSColor blackColor])];
    }
    else if ([columnIdentifier isEqual:@"status"])
    {
        BOOL invisible = [[[self document] currentStatus] isEqual:ICJInvisibleStatusKey];
        if ((invisible && ![contact isOnVisibleList]) || [contact isOnInvisibleList])
            [cell setOpacity:0.7];
        else
            [cell setOpacity:1];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    ICJContact *contact = [displayList objectAtIndex:rowIndex];
//    ContactStatus *status = [contact status];
    if (CFEqual([aTableColumn identifier], @"nickname"))
    {
        return [contact displayName];
    }
    if (CFEqual([aTableColumn identifier], @"status"))
    {
/*        if ([contact hasMessageQueue])
            return [NSArray arrayWithObjects:[status icon], [NSImage imageNamed:@"message.tiff"], nil];
        else
            return [NSArray arrayWithObject:[status icon]];
*/
        return contact;
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    [[self document] renameContact:[displayList objectAtIndex:rowIndex] to:anObject];
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    int i;
    NSMutableArray *contactRefsArray = [NSMutableArray arrayWithCapacity:[rows count]];
    [pboard declareTypes:[NSArray arrayWithObject:ICJContactRefPboardType] owner:nil];
    for (i=0; i<[rows count]; i++)
    {
        ICJContact *contact = [displayList objectAtIndex:[[rows objectAtIndex:i] intValue]];
        [contactRefsArray addObject:[NSData dataWithBytes:&contact length:sizeof(contact)]];
    }
    [pboard setPropertyList:contactRefsArray forType:ICJContactRefPboardType];
    return YES;
}

- (int)tableView:(NSTableView *)aTableView rowWithPrefix:(NSString *)prefix
{
    int matchingRow = -1;
    int i;
    int rows = [displayList count];
    NSString *matchingName = @"";
    BOOL matchDown = NO;
    
    for (i = 0; i<rows; i++)
    {
        NSString *currentName = [(ICJContact *)[displayList objectAtIndex:i] displayName];
        if (!matchDown)
        {
            switch ([matchingName localizedCaseInsensitiveCompare:currentName])
            {
                case NSOrderedAscending:
                    matchingRow = i;
                    matchingName = currentName;
                    if ([prefix localizedCaseInsensitiveCompare:currentName]!=NSOrderedDescending)
                        matchDown = YES;
                    break;
                default:
                    break;
            }
        }
        else if ([matchingName localizedCaseInsensitiveCompare:currentName]==NSOrderedDescending &&
                    [prefix localizedCaseInsensitiveCompare:currentName]!=NSOrderedDescending)
        {
                    matchingRow = i;
                    matchingName = currentName;
        }
    }
    
    return matchingRow;
}

// NSTableViewDelegate
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSEnumerator	*pathEnumerator;
    NSString		*path;
    NSDragOperation	result = NSDragOperationEvery;
    BOOL		isDir;
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    
    if ( op==NSTableViewDropAbove || row==-1 )
        return NSDragOperationNone;
    
    if ( [[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType] )
	{
		pathEnumerator = [[[info draggingPasteboard]
			propertyListForType:NSFilenamesPboardType
		] objectEnumerator];
		
		while ( result!=NSDragOperationNone && (path = [pathEnumerator nextObject]) )
		{
			if ( ![fileManager fileExistsAtPath:path isDirectory:(&isDir)] || isDir )
				result = NSDragOperationNone;
		}
	}

    return result;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	if ( [[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType] )
		[[self icqUserDocument]
			composeFileTransferTo:[displayList objectAtIndex:row]
			files:[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType]
		];
	else
		[[self icqUserDocument]
			composeMessageTo:[NSMutableArray arrayWithObject:[displayList objectAtIndex:row]]
			text:[[info draggingPasteboard] stringForType:NSStringPboardType]
		];
    return YES;
}

- (void) tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSTableColumn *currentColumn = [contactListView highlightedTableColumn];
    if (currentColumn!=tableColumn)
    {
        [contactListView setIndicatorImage:NULL inTableColumn:currentColumn];
        [contactListView setIndicatorImage:([[self document] descendingOrder] ? [NSTableView _defaultTableHeaderReverseSortImage] : [NSTableView _defaultTableHeaderSortImage]) inTableColumn:tableColumn];
        [contactListView setHighlightedTableColumn:tableColumn];
        [[self document] setSortColumnIdentifier:[tableColumn identifier]];
    }
    else
        [[self document] setDescendingOrder:![[self document] descendingOrder]];
        [contactListView setIndicatorImage:([[self document] descendingOrder] ? [NSTableView _defaultTableHeaderReverseSortImage] : [NSTableView _defaultTableHeaderSortImage]) inTableColumn:tableColumn];
    [self setNeedsUpdate:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJContactListSelectionDidChangeNotification object:self];
}

// ICJNotifications
- (void) contactListChanged:(NSNotification *)theNotification
{
    [self setNeedsUpdate:YES];
}

- (void)wrongPassword:(NSNotification *)theNotification
{
    NSString *prompt;
    if ([[theNotification name] isEqualToString:ICJWrongPasswordNotification])
        prompt = NSLocalizedString(@"The password you tried to log in with is incorrect. Please enter your password", @"");
    else if ([[theNotification name] isEqualToString:ICJNeedPasswordNotification])
        prompt = NSLocalizedString(@"Please enter your ICQ password", @"");
    [[self window] makeKeyAndOrderFront:nil];
    [PasswordSheetController beginPasswordSheetForWindow:[self window] withPrompt:prompt delegate:self didEndSelector:@selector(passwordSheetDidEnd:)];
}

- (void)passwordSheetDidEnd:(NSString *)thePassword
{
    if (thePassword)
    {
        if (![[[self document] currentStatus] isEqual:[[self document] targetStatus]])
            [chasingArrows startAnimation:self];
        [[self document] setUserPassword:thePassword];
    }
}

- (void)userStatusChanged:(NSNotification *)theNotification
{
    if ( [[self document] isNetworkAvailable] )
    {
		[chasingArrows setCautionStatus:NO];
        if ( [[[self document] targetStatus] isEqual:[[self document] currentStatus]] )
            [chasingArrows stopAnimation:nil];
        else
            [chasingArrows startAnimation:nil];

        [statusPopUp
            selectItemAtIndex:[statusPopUp
                indexOfItemWithRepresentedObject:[[self document] targetStatus]
            ]
        ];
    }
    else
    {
		[chasingArrows setCautionStatus:YES];
        [chasingArrows stopAnimation:nil];
        [statusPopUp selectItemAtIndex:
            [statusPopUp indexOfItemWithRepresentedObject:ICJOfflineStatusKey]
        ];
    }

    [self setNeedsUpdate:YES];
}
@end

int compContacts(ICJContact *first, ICJContact *second, void *context)
{
    struct sortContextStruct *sortContext = (struct sortContextStruct *)context;
    NSComparisonResult result;
    id columnIdentifier = sortContext->columnIdentifier;
    if ([columnIdentifier isEqual:@"status"])
        result = [[[first status] sortOrder] compare:[[second status] sortOrder]];
    if (result==NSOrderedSame || [columnIdentifier isEqual:@"nickname"])
        result = [[first displayName] caseInsensitiveCompare:[second displayName]];
    if (sortContext->descending)
        result = (NSComparisonResult)(-result);
    return result;
}