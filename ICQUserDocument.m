/*
 * ICQUserDocument.m
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

#import "ICQUserDocument.h"
#import "ContactList.h"
#import "User.h"
#import "ICQConnection.h"
#import "MainController.h"
#import "ContactListWindowController.h"
#import "DialogController.h"
#import "OutgoingAuthReqController.h"
#import "OutgoingFileController.h"
#import "ICJMessage.h"
#import "IncomingMessageController.h"
#import "IncomingFileController.h"
#import "NewUserAssistant.h"
#import "HistoryWindowController.h"
#import "UserDetailsController.h"
#import "ContactStatusMessageController.h"
#import "MPUserActivityMonitor.h"
#import "History.h"
#import "NetworkProblemAlert.h"
#import <Carbon/Carbon.h>

@implementation ICQUserDocument

- (id)init
{
    self = [super init];
    
    [self setHasUndoManager:YES];
    
    // initialize associated window controller sets and dictionaries
    outgoingMessageControllers = [[NSMutableSet set] retain];
    incomingMessageControllers = [[NSMutableDictionary dictionary] retain];
    historyControllers = [[NSMutableDictionary dictionary] retain];
    contactStatusMessageControllers = [[NSMutableDictionary dictionary] retain];
    _incomingFileTransferControllers = [[NSMutableArray array] retain];
    
    contactsPendingWindows = [[NSMutableArray array] retain];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(messageDidRequireAttention:)
        name:ICJMessageRequiresAttentionNotification
        object:self
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(messageDidGetAttention:)
        name:ICJMessageGotAttentionNotification
        object:self
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(systemWillSleep:)
        name:MPSystemWillSleepNotification
        object:NULL
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(systemDidWakeUp:)
        name:MPSystemDidWakeUpNotification
        object:NULL
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(networkConfigurationChanged:)
        name:MPSystemConfigurationChangedNotification
        object:NULL
    ];
    
    attentionRequirements = 0;
    
    welcomeNewUser = NO;
    
    // initialize histories dictionary
    histories = [[NSMutableDictionary dictionary] retain];
    
    // initialize settings dictionary
    settings = [[NSMutableDictionary dictionary] retain];
    
    dirty = NO;
    
    // initialize visible and invisible lists
    visibleList = [[NSMutableSet set] retain];
    invisibleList = [[NSMutableSet set] retain];
    
    // since we don't have a connection, we're currently offline
    [self setCurrentStatus:ICJOfflineStatusKey];
    
    // since we haven't been told otherwise, we want to be offline
    [self setTargetStatus:ICJOfflineStatusKey];
    
    [self setNetworkAvailable:YES];
    
    return self;
}

- (void)dealloc
{
    [_initialStatus release];
    [_currentStatus release];
    [_targetStatus release];
    [_lastSelectedStatus release];
    [invisibleList release];
    [visibleList release];
    [contactsPendingWindows release];
    [userDetailsController release];
    [settings release];
    [histories release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [savedContactListWindowFrame release];
    [connection terminateAndRelease];
    [historyControllers release];
    [contactStatusMessageControllers release];
    [_incomingFileTransferControllers release];
    [incomingMessageControllers release];
    [outgoingMessageControllers release];
    [sortColumnIdentifier release];
    [contactList release];
    [user release];
    [super dealloc];
}

- (void)close
{
    if ( attentionRequirements>0 )
        [[NSApp delegate] icqUserDocumentGotAttention:self];
    [[MPUserActivityMonitor sharedMonitor] unregister:self];
    // when quitting, we receive two -close messages (check why!). We don't want to deal with an invalidated (and thus probably deallocated) timer the second time around, hence the following:
/*
    if ( [saveHistoriesTimer isValid] )
        [saveHistoriesTimer invalidate];
*/
    [super close];
}

- (void)makeWindowControllers
{
    if ( [self fileName] )
    {
        ContactListWindowController *myController = [[[ContactListWindowController alloc] init] autorelease];
        [self addWindowController:myController];
    }
    else
    {
        NewUserAssistant *myController = [[[NewUserAssistant alloc] init] autorelease];
        [self addWindowController:myController];
    }
}

- (ContactListWindowController *)mainWindowController
{
    NSEnumerator *windowControllers = [[self windowControllers] objectEnumerator];
    NSWindowController *controller;
    while ( controller = [windowControllers nextObject] )
    {
        if ( [controller isKindOfClass:[ContactListWindowController class]] )
            return (ContactListWindowController *)controller;
    }
    return nil;
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)documentTypeName originalFile:(NSString *)fullOriginalDocumentPath saveOperation:(NSSaveOperationType)saveOperationType
{
    BOOL		success;
    NSMutableDictionary	*dataDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [contactList persistentContactListDictionary],		@"contacts",
        sortColumnIdentifier,					@"sortBy",
        (startsWithPreviousStatus ? _lastSelectedStatus : [self initialStatus]),
                                                                @"initialStatus",
        [NSNumber numberWithInt:textEncoding],			ICJTextEncodingSettingName,
        [NSNumber numberWithBool:descendingOrder],		@"descending",
        [NSNumber numberWithBool:useDialogWindows],		ICJUseDialogWindowsSettingName,
        [NSNumber numberWithBool:offlineHidden],		@"offlineHidden",
        [NSNumber numberWithBool:autoPopup],			@"autoPopup",
        [NSNumber numberWithBool:startsWithPreviousStatus],	@"startsWithPreviousStatus",
        settings,						ICJSettingsKey,
        NULL
    ];
    
    if ( [[self mainWindowController] window] )
        [dataDictionary
            setObject:[[[self mainWindowController] window] stringWithSavedFrame]
            forKey:@"NSWindow Frame ContactListWindow"
        ];
        
    success = [[NSFileManager defaultManager] createDirectoryAtPath:fileName attributes:nil];
    
    if ( success && dataDictionary )
        success = [dataDictionary
            writeToFile:[fileName stringByAppendingPathComponent:@"contactlist.plist"]
            atomically:NO
        ];
        
    if ( success && user )
        success = [[user dictionaryRepresentation]
            writeToFile:[fileName stringByAppendingPathComponent:@"user.plist"]
            atomically:NO
        ];
        
    if ( success )
    {
        NSEnumerator 		*contactEnumerator = [contactList objectEnumerator];
        ICJContact			*currentContact;
        History			*currentHistory;
        
        while ( success && (currentContact = [contactEnumerator nextObject]) )
        {
            if ( ![currentContact isTemporary] && ![currentContact isDeleted] )
            {
                currentHistory = [histories objectForKey:[currentContact uinKey]];

/*
                [currentHistory setPath:[self
                    historyFileNameForContact:currentContact
                    documentFileName:fullOriginalDocumentPath
                ]];
                [currentHistory lock];
*/
                if ( fullOriginalDocumentPath && [[NSFileManager defaultManager]
                    fileExistsAtPath:[self historyFileNameForContact:currentContact
                    documentFileName:fullOriginalDocumentPath]
                    ] )
                    success = [[NSFileManager defaultManager]
                        movePath:[self
                            historyFileNameForContact:currentContact
                            documentFileName:fullOriginalDocumentPath
                        ]
                        toPath:[self
                            historyFileNameForContact:currentContact
                            documentFileName:fileName
                        ]
                        handler:nil
                    ];
				[currentHistory quiesce];
/*
                [currentHistory setPath:[self
                    historyFileNameForContact:currentContact
                    documentFileName:fileName
                ]];
                [currentHistory unlock];
*/
            }
        }
    }
    return success;
}

- (void)observeContact:(ICJContact *)contact
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactStatusChanged:) name:ICJContactStatusChangedNotification object:contact];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactStatusChanged:) name:ICJContactQueueChangedNotification object:contact];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactInfoChanged:) name:ICJContactInfoChangedNotification object:contact];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type
{
    id			tempObject;
    NSEnumerator	*contactsEnumerator;
    ICJContact		*currentContact;
    NSDictionary	*dataDictionary = [NSDictionary
        dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/contactlist.plist", fileName]
    ];
    
    contactList = [[NSMutableDictionary alloc]
        initWithContactListDictionary:[dataDictionary objectForKey:@"contacts"]
    ];
    
    contactsEnumerator = [contactList objectEnumerator];
    while ( currentContact = [contactsEnumerator nextObject] )
    {
        attentionRequirements += [currentContact messageQueueCount];
        [self observeContact:currentContact];
        if ( [currentContact isOnVisibleList] )
            [visibleList addObject:currentContact];
/*else*/if ( [currentContact isOnInvisibleList] )
            [invisibleList addObject:currentContact];
        if ( [currentContact isPendingAuthorization] )
            [currentContact setStatus:ICJPendingAuthorizationStatusKey];
        else
            [currentContact setStatus:ICJOfflineStatusKey];
    }
    
    // if the document contained message queues, request attention and set window's dirty flag
    if (attentionRequirements)
    {
        [[NSApp delegate] icqUserDocumentRequiresAttention:self];
        [[[self mainWindowController] window] setDocumentEdited:YES];
    }
    
    // read settings that go into instance variables
    sortColumnIdentifier = [[dataDictionary objectForKey:@"sortBy"] retain];
    descendingOrder = [[dataDictionary objectForKey:@"descending"] boolValue];
    // usage of dialog windows defaults to YES
    tempObject = [dataDictionary objectForKey:ICJUseDialogWindowsSettingName];
    useDialogWindows = (tempObject ? [tempObject boolValue] : YES);
    offlineHidden = [[dataDictionary objectForKey:@"offlineHidden"] boolValue];
    savedContactListWindowFrame = [[dataDictionary objectForKey:@"NSWindow Frame ContactListWindow"] retain];
    autoPopup = [[dataDictionary objectForKey:@"autoPopup"] boolValue];
    startsWithPreviousStatus = [[dataDictionary objectForKey:@"startsWithPreviousStatus"] boolValue];
    // set the initial status
    [self setInitialStatus:[dataDictionary objectForKey:@"initialStatus"]];
    if ( ![self initialStatus] )
        [self setInitialStatus:ICJAvailableStatusKey];
    textEncoding = [[dataDictionary objectForKey:ICJTextEncodingSettingName] intValue];
    
    // read settings that go into the settings dictionary
    [settings addEntriesFromDictionary:[dataDictionary objectForKey:ICJSettingsKey]];
    
    // read user info from user.plist
    user = [[User alloc] initWithDictionary:[NSDictionary
        dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/user.plist", fileName]
    ]];
    
    // allocate and initialize a connection
    connection = [[ICQConnection
        connectionWithUIN:[user uin]
        password:[user password]
        nickname:[user nickname]
        target:self
        contactList:[contactList allValues]
    ] retain];
    
    // handle new web-aware and activity monitor settings
    [self settingsDidChange];
    
    if (!(GetCurrentKeyModifiers() & shiftKey))
        [self userDidRequestStatus:[self initialStatus]];
    else
        [self userDidRequestStatus:ICJOfflineStatusKey];

    return YES;
}

- (NSString *)displayName
{
    if ( user && [user nickname] )
        return [user nickname];
    return [super displayName];
}

- (void)document:(NSDocument *)theDocument whileClosingDidSave:(BOOL)didSave contextInfo:(void *)contextInfo
{
    CanCloseAlertContext *canCloseAlertContext = contextInfo;
    void (*callback)(id, SEL, NSDocument *, BOOL, void *) = (void (*)(id, SEL, NSDocument *, BOOL, void *))objc_msgSend;
    if (didSave)
    {
        // go ahead with closing
        [[incomingMessageControllers allValues] makeObjectsPerformSelector:@selector(close)];
        [[historyControllers allValues] makeObjectsPerformSelector:@selector(close)];
        [[contactStatusMessageControllers allValues] makeObjectsPerformSelector:@selector(close)];
        [_incomingFileTransferControllers makeObjectsPerformSelector:@selector(abort)];
        [outgoingMessageControllers makeObjectsPerformSelector:@selector(close)];
        [userDetailsController close];
        if (canCloseAlertContext->shouldCloseSelector)
            (*callback)(canCloseAlertContext->delegate, canCloseAlertContext->shouldCloseSelector, self, YES, canCloseAlertContext->contextInfo);
    }
    else
    {
        NSLog(@"Couldn't save while closing. Closing cancelled.");
        // MITZ should add code for when we can't autosave on close (alert the user or something)
        if (canCloseAlertContext->shouldCloseSelector)
            (*callback)(canCloseAlertContext->delegate, canCloseAlertContext->shouldCloseSelector, self, NO, canCloseAlertContext->contextInfo);
    }
    free(canCloseAlertContext);
}

- (void)canCloseDocumentWithDelegate:(id)inDelegate shouldCloseSelector:(SEL)inShouldCloseSelector contextInfo:(void *)inContextInfo {

    // This method may or may not have to actually present the alert sheet.

        // Create a record of the context in which the panel is being shown, so we can finish up when it's dismissed.
        CanCloseAlertContext *closeAlertContext = malloc(sizeof(CanCloseAlertContext));
        closeAlertContext->delegate = inDelegate;
        closeAlertContext->shouldCloseSelector = inShouldCloseSelector;
        closeAlertContext->contextInfo = inContextInfo;
    if (![self fileName])
    {
        // Document isn't associated with a file, so don't autosave. Simply go ahead with closing.
        free(closeAlertContext);
        if (inShouldCloseSelector)
        {
            void (*callback)(id, SEL, NSDocument *, BOOL, void *) = (void (*)(id, SEL, NSDocument *, BOOL, void *))objc_msgSend;
            (*callback)(inDelegate, inShouldCloseSelector, self, YES, inContextInfo);
        }
    }
    else if (!(attentionRequirements>0))
    {
        // Try to autosave. If successful, the delegate will go ahead with closing, otherwise it will abort it.
        [self saveDocumentWithDelegate:self didSaveSelector:@selector(document:whileClosingDidSave:contextInfo:) contextInfo:closeAlertContext];
    }
    else
    {
        // Figure out the window on which to present the alert sheet.  This should be easy if you only have one window per document.
        NSWindow *documentWindow = [[self mainWindowController] window]; 
        // Present a "unread open messages will be lost" alert as a document-modal sheet. When finished, the delegate will either go ahead with closing or abort it.
        [documentWindow makeKeyAndOrderFront:nil];
        NSBeginAlertSheet(NSLocalizedString(@"There are unread messages", @"alert sheet title"), NSLocalizedString(@"Close", @"Close button on alert sheet"), NSLocalizedString(@"Cancel", @"Cancel button on alert sheet"), nil, documentWindow, self, @selector(closeOpenMessagesSheetDidEnd:returnCode:contextInfo:), NULL, closeAlertContext, NSLocalizedString(@"There are new messages which you might have not read yet. Do you want to close anyway?", @"alert sheet message"));
    }
}


- (void)closeOpenMessagesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    CanCloseAlertContext *canCloseAlertContext = contextInfo;

	// The user's dismissed our "close open message windows?" alert sheet.  What happens next depends on how the dismissal was done.
    if (returnCode==NSAlertDefaultReturn)
    {
        // Try to autosave. If successful, the delegate will go ahead with closing, otherwise it will abort it.
        [self saveDocumentWithDelegate:self didSaveSelector:@selector(document:whileClosingDidSave:contextInfo:) contextInfo:canCloseAlertContext];
    }
    else
    {
        // The closing was cancelled.  Tell the delegate of the original -canCloseDocumentWithDelegate:... to not close.
        if (canCloseAlertContext->shouldCloseSelector)
        {
            void (*callback)(id, SEL, NSDocument *, BOOL, void *) = (void (*)(id, SEL, NSDocument *, BOOL, void *))objc_msgSend;
            (*callback)(canCloseAlertContext->delegate, canCloseAlertContext->shouldCloseSelector, self, NO, canCloseAlertContext->contextInfo);
            // Free up the memory that was allocated in -canCloseDocumentWithDelegate:shouldCloseSelector:contextInfo:.
            free(canCloseAlertContext);
        }
    }
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType
{
    // null implementation to override the default implementation which updates the window's eidted status, which in our case is reserved for something else - indicating unread messages
}

- (void)messageDidRequireAttention:(NSNotification *)theNotification
{
    if ( attentionRequirements++ == 0 )
    {
        [[NSApp delegate] icqUserDocumentRequiresAttention:self];
        [[[self mainWindowController] window] setDocumentEdited:YES];
    }
}

- (void)messageDidGetAttention:(NSNotification *)theNotification
{
    if ( --attentionRequirements == 0 )
    {
        [[NSApp delegate] icqUserDocumentGotAttention:self];
        [[[self mainWindowController] window] setDocumentEdited:NO];
    }
}

// accessors
- (User *)user
{
    return user;
}

- (NSMutableDictionary *)contactList
{
    return contactList;
}

- (id)sortColumnIdentifier
{
    return sortColumnIdentifier;
}

- (void)setSortColumnIdentifier:(id)identifier
{
    [sortColumnIdentifier autorelease];
    sortColumnIdentifier = [identifier retain];
}

- (History *)historyForContact:(ICJContact *)theContact
{
    History	*history;
    
    history = [histories objectForKey:[theContact uinKey]];
    if ( !history )
    {
        history = [History
            historyWithContact:theContact
            path:[self historyFileNameForContact:theContact]
        ];
        [histories setObject:history forKey:[theContact uinKey]];
    }
    return history;
}

- (NSArray *)contactsPendingWindows
{
    return contactsPendingWindows;
}

- (NSString *)currentStatus
{
    return _currentStatus;
}

- (void)setCurrentStatus:(NSString *)theStatus
{
    NSString	*oldCurrentStatus = _currentStatus;

    _currentStatus = [theStatus retain];
    [oldCurrentStatus release];
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJUserStatusChangedNotification object:self];
}

- (NSString *)targetStatus
{
    return _targetStatus;
}

- (void)setTargetStatus:(NSString *)theStatus
{
    NSString	*oldTargetStatus = _targetStatus;

    _targetStatus = [theStatus retain];
    [oldTargetStatus release];
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJUserStatusChangedNotification object:self];
}

- (BOOL)isNetworkAvailable
{
    return _networkAvailable;
}

- (void)setNetworkAvailable:(BOOL)flag
{
    _networkAvailable = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJUserStatusChangedNotification object:self];
}

- (id)settingWithName:(NSString *)name
{
    id setting = [settings objectForKey:name];
    if ( !setting )
        setting = [[NSApp delegate] settingWithName:name];
    return setting;
}

- (id)settingWithName:(NSString *)name forContact:(ICJContact *)contact
{
    id setting = [[contact settings] objectForKey:name];
    if ( !setting )
        setting = [self settingWithName:name];
    return setting;
}

- (void)setObject:(id)object forSettingName:(NSString *)name
{
    [settings setObject:object forKey:name];
}

- (void)settingsDidChange
{
    [connection setWebAware:[[self settingWithName:ICJWebAwareSettingName] boolValue]];
    [[MPUserActivityMonitor sharedMonitor] unregister:self];
    [[MPUserActivityMonitor sharedMonitor]
        registerForMessages:self
        ofInactivityPeriod:
            ([[self settingWithName:ICJAutoAwayIdleSettingName] boolValue]
                ? [[self settingWithName:ICJAutoAwayIdleSecondsSettingName] intValue]
                : 0)
        screenSaver:[[self settingWithName:ICJAutoAwayScreenSaverSettingName] boolValue]
    ];
    [outgoingMessageControllers makeObjectsPerformSelector:@selector(synchronizeAttributes)];
    [[historyControllers allValues] makeObjectsPerformSelector:@selector(synchronizeAttributes)];
}

- (void)removeSettingWithName:(NSString *)name
{
    [settings removeObjectForKey:name];
}

- (BOOL)contactIsOnList:(ICJContact *)contact
{
    return ([[contactList allKeysForObject:contact] count]>0 && ![contact isDeleted]);
}

- (BOOL)acceptsMessagesFromContact:(ICJContact *)aContact
{
    if ( [self contactIsOnList:aContact] )
        return (![aContact isOnIgnoreList]);
    else
        return (![[self settingWithName:ICJIgnoreIfNotOnListSettingName] boolValue]);
}

- (BOOL)descendingOrder
{
    return descendingOrder;
}

- (BOOL)offlineHidden
{
    return offlineHidden;
}

- (BOOL)autoPopup
{
    return autoPopup;
}

- (BOOL)usesDialogWindows
{
    return useDialogWindows;
}

- (BOOL)usesDialogWindowsForContact:(ICJContact *)theContact
{
    NSNumber *flag = [[theContact settings] objectForKey:ICJUseDialogWindowsSettingName];
    if ( flag )
        return [flag boolValue];
    return useDialogWindows;
}

- (BOOL)startsWithPreviousStatus
{
    return startsWithPreviousStatus;
}

- (NSString *)initialStatus
{
    return _initialStatus;
}

- (CFStringEncoding)textEncoding
{
    return textEncoding;
}

- (CFStringEncoding)textEncodingForContact:(ICJContact *)theContact
{
    NSNumber *encoding = [[theContact settings] objectForKey:ICJTextEncodingSettingName];
    if ( encoding )
        return (CFStringEncoding)[encoding intValue];
    return [self textEncoding];
}

- (CFStringEncoding)textEncodingForUin:(ICQUIN)theUin
{
    ICJContact *contact = [contactList contactForUin:theUin];
    if ( contact )
        return [self textEncodingForContact:contact];
    return [self textEncoding];
}

- (NSString *)savedContactListWindowFrame
{
    return savedContactListWindowFrame;
}

- (BOOL)isLoggedIn
{
    if ( connection )
        return [connection isLoggedIn];
    return NO;
}

- (void)setDescendingOrder:(BOOL)theOrder
{
    descendingOrder = theOrder;
}

- (void)setOfflineHidden:(BOOL)shouldHide
{
    offlineHidden = shouldHide;
}

- (void)setAutoPopup:(BOOL)shouldAutoPopup
{
    autoPopup = shouldAutoPopup;
}

- (void)setUsesDialogWindows:(BOOL)shouldUseDialogWindows
{
    useDialogWindows = shouldUseDialogWindows;
}

- (void)setStartsWithPreviousStatus:(BOOL)flag
{
    startsWithPreviousStatus = flag;
}

- (void)setInitialStatus:(NSString *)theStatus
{
    NSString	*oldInitialStatus = _initialStatus;
    
    _initialStatus = [theStatus retain];
    [oldInitialStatus release];
}

- (void)setTextEncoding:(CFStringEncoding)theEncoding
{
    textEncoding = theEncoding;
}

- (void)newUin:(ICQUIN)theUin password:(NSString *)thePassword
{
    ContactListWindowController *myController;
    
    // allocate and initialize user and contact list
    user = [[User alloc] initWithUin:theUin nickname:nil password:thePassword];
    contactList = [[NSMutableDictionary dictionary] retain];
    
    // initialize instance variables
    sortColumnIdentifier = @"status";
    textEncoding = 0/*(CFStringEncoding)[NSString defaultCStringEncoding]*/;
    useDialogWindows = YES;
    startsWithPreviousStatus = YES;
    [self setInitialStatus:ICJAvailableStatusKey];
    
    // allocate and initialize a connection
    connection = [[ICQConnection
        connectionWithUIN:[user uin]
        password:[user password]
        nickname:[user nickname]
        target:self
        contactList:[contactList allValues]
    ] retain];
        
    // handle new web-aware and activity monitor settings
    [self settingsDidChange];

    // allocate and contact list window controller and show window
    myController = [[[ContactListWindowController alloc] init] autorelease];
    [self addWindowController:myController];
    [myController showWindow:self];

    welcomeNewUser = YES;
    [self userDidRequestStatus:[self initialStatus]];
}

- (void)reconnectIfPossibleWithStatus:(NSString *)status
{
    SCNetworkConnectionFlags	flags;
    
    if ( SCNetworkCheckReachabilityByName([[self settingWithName:ICJServerHostSettingName] cString], &flags) )
    {
        if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ICJLog"] )
            NSLog(@"reachability flags obtained");
            
        if ( (flags | kSCNetworkFlagsTransientConnection | kSCNetworkFlagsConnectionAutomatic | kSCNetworkFlagsInterventionRequired)
            == (kSCNetworkFlagsReachable | kSCNetworkFlagsTransientConnection | kSCNetworkFlagsConnectionAutomatic | kSCNetworkFlagsInterventionRequired) )
        {
            [self setNetworkAvailable:YES];
            if ( disconnectedSheet )
                [NSApp endSheet:disconnectedSheet];
            [connection setStatus:status];
        }
        else
        {
            if ( [self isNetworkAvailable] ) // just lost network
                [self disconnected:ICJLowLevelDisconnectReason];
            [self setNetworkAvailable:NO];
            [connection setStatus:ICJOfflineStatusKey];
        }
    }
}

- (void)userDidRequestStatus:(NSString *)theStatus
{    
    if ( [theStatus isEqual:ICJOfflineStatusKey] ) // offline selected
    {
        [_lastSelectedStatus autorelease];
        _lastSelectedStatus = [theStatus retain];
        [self setTargetStatus:theStatus];
        [self reconnectIfPossibleWithStatus:theStatus];
    }
    else if ( ![self isNetworkAvailable] || [[self targetStatus] isEqual:ICJOfflineStatusKey] || _lastSelectedStatus!=theStatus ) // non-offline selected
    {
        [_lastSelectedStatus autorelease];
        _lastSelectedStatus = [theStatus retain];
        [self setTargetStatus:theStatus];
        [self reconnectIfPossibleWithStatus:theStatus];
    }
}

- (void)systemWillSleep:(NSNotification *)notification
{
    if ( [self isNetworkAvailable] )
    {
        [connection setStatus:ICJOfflineStatusKey];
    }
}

- (void)systemDidWakeUp:(NSNotification *)notification
{
    if ( ![[self targetStatus] isEqual:ICJOfflineStatusKey] )
    {
        [self reconnectIfPossibleWithStatus:[self targetStatus]];
    }
}

- (void)networkConfigurationChanged:(NSNotification *)notification
{
    if ( [self isNetworkAvailable] )	// this is either insignificant or a disconnection
        [self reconnectIfPossibleWithStatus:[self targetStatus]];
    else if ( ![[self targetStatus] isEqual:ICJOfflineStatusKey] ) // this could be a reconnection
        [self reconnectIfPossibleWithStatus:[self targetStatus]];
}

/* MPUserActivityMonitorClient */
- (void)userInactivityTimeoutOccured
{
    if (
        [_lastSelectedStatus isEqual: ICJAvailableStatusKey]
        && ![[self targetStatus] isEqual:ICJOfflineStatusKey]
        )
    {
        [self setTargetStatus:ICJAwayStatusKey];
        if ( [self isNetworkAvailable] )
        {
            [self reconnectIfPossibleWithStatus:[self targetStatus]];
        }
    }
}

- (void)userActivityResumed
{
    if (
        ![_lastSelectedStatus isEqual:[self targetStatus]]
        && ![[self targetStatus] isEqual:ICJOfflineStatusKey]
        )
    {
        [self setTargetStatus:_lastSelectedStatus];
        if ( [self isNetworkAvailable] )
        {
            [self reconnectIfPossibleWithStatus:[self targetStatus]];
        }
    }
}

- (OutgoingMessageController *)composeMessageTo:(NSMutableArray *)recipients
{
	return [self composeMessageTo:recipients text:nil];
}

- (OutgoingMessageController *)composeMessageTo:(NSMutableArray *)recipients text:(NSString *)text
{
    OutgoingMessageController	*messageController;

    if ( [recipients count]==1 && [self usesDialogWindowsForContact:[recipients objectAtIndex:0]] )
    {
        // Single recipient, so we want a dialog window
        if ( [[incomingMessageControllers objectForKey:[[recipients objectAtIndex:0] uinKey]]
            isKindOfClass:[OutgoingMessageController class]
        ] )
        {
            // already have one - use it
            messageController = [incomingMessageControllers objectForKey:[[recipients objectAtIndex:0] uinKey]];
            [messageController showWindow:self];
        }
        else
        {
            // don't have one - create it and make it the incoming message controller for that user too
            messageController = [DialogController
                outgoingMessageControllerTo:recipients
                forDocument:self
            ];
            [incomingMessageControllers setObject:messageController forKey:[[recipients objectAtIndex:0] uinKey]];
            [outgoingMessageControllers addObject:messageController];
        }
    }
    else
    {
        // multiple recipients - use a dedicated outgoing message window
        messageController = [OutgoingMessageController
            outgoingMessageControllerTo:recipients
            forDocument:self
        ];
        [outgoingMessageControllers addObject:messageController];
    }
	
	if ( text )
		[messageController setMessageText:text];
	
    return messageController;
}

- (void)composeAuthorizationRequestTo:(ICJContact *)contact
{
    OutgoingAuthReqController *messageController = [OutgoingAuthReqController
        outgoingMessageControllerTo:[NSArray arrayWithObject:contact]
        forDocument:self
    ];
    [outgoingMessageControllers addObject:messageController];
}

- (void)composeFileTransferTo:(ICJContact *)contact files:(NSArray *)files;
{
    OutgoingFileController *messageController = [OutgoingFileController
        outgoingMessageControllerTo:[NSArray arrayWithObject:contact]
        forDocument:self
    ];
    [outgoingMessageControllers addObject:messageController];
    if ( [files count]>0 )
    {
        [messageController addFilesFromArray:files];
        [[messageController window] makeKeyAndOrderFront:nil];
    }
    else
        [messageController addFiles:nil];
}

- (void)composeFileTransferTo:(ICJContact *)contact
{
    [self composeFileTransferTo:contact files:nil];
}

- (void)readStatusMessageOfContact:(ICJContact *)theContact
{
    ContactStatusMessageController	*controller;
    NSDictionary			*key = [NSDictionary dictionaryWithObjectsAndKeys:
        [theContact uinKey],	@"uin",
        [theContact statusKey],	@"status",
        nil
    ];
    
    controller = [contactStatusMessageControllers objectForKey:key];
    if (controller)
    {
        [controller showWindow:nil];
    }
    else
    {
        controller = [[[ContactStatusMessageController alloc]
            initWithContact:theContact
            document:self
        ] autorelease];
        [contactStatusMessageControllers setObject:controller forKey:key];
        [controller run];
    }
}

- (void)showHistoryOfContact:(ICJContact *)theContact
{
    HistoryWindowController	*historyController = [historyControllers objectForKey:[theContact uinKey]];
    
    if ( historyController )
        [historyController showWindow:nil];
    else
        [historyControllers
            setObject:[HistoryWindowController historyControllerForHistory:[self historyForContact:theContact] document:self]
            forKey:[theContact uinKey]
        ];
}

- (ICJContact *)contactWithUin:(ICQUIN)theUin create:(BOOL)flag
{
    ICJContact	*contact = [contactList contactForUin:theUin];
    
    if ( !contact && flag )
        contact = [[[ICJContact alloc] initWithNickname:NULL uin:theUin] autorelease];

    return contact;
}

- (NSString *)statusMessageForContact:(ICJContact *)theContact
{
    NSString *statusMessage = [[self
        settingWithName:ICJStatusMessagesSettingName
        forContact:theContact
    ] objectForKey:[self currentStatus]];
    return (statusMessage ? statusMessage : @"");
}

- (BOOL)showIncomingMessagesForContact:(ICJContact *)theContact
{
    if ( ![theContact hasMessageQueue] )
        return NO;
    else if ( [incomingMessageControllers objectForKey:[theContact uinKey]] )
        return NO;
    else
    {
        NSWindowController <ICJIncomingMessageDisplay> *incomingController;
        
        if ( [self usesDialogWindowsForContact:theContact] )
        {
            incomingController = [DialogController incomingMessageController:theContact forDocument:self];
            [outgoingMessageControllers addObject:incomingController];
        }
        else
            incomingController = [IncomingMessageController incomingMessageController:theContact forDocument:self];
        
        [incomingController messageAdded];
        [incomingMessageControllers setObject:incomingController forKey:[theContact uinKey]];
        [contactsPendingWindows removeObject:theContact];
    }

    return YES;
}

- (void)setUserPassword:(NSString *)thePassword
{
    [user setPassword:thePassword];
    [connection setPassword:thePassword];
    [self reconnectIfPossibleWithStatus:[self targetStatus]];
}

- (void)addSearchResult:(NSDictionary *)result
{
    ICJContact	*contact = [result objectForKey:ICJContactKey];
    ICJContact	*contactOnList = [contactList contactForUin:[contact uin]];

    if ( contactOnList && ![contactOnList isTemporary] )
    // trying to add a contact that's already permanently on the list
    {
        NSWindow *windowForAlert = [[self mainWindowController] window];
        
        if (windowForAlert)
        {
            [windowForAlert makeKeyAndOrderFront:nil];
            NSBeginInformationalAlertSheet(
                NSLocalizedString(@"This contact is already on your list", @""),
                NSLocalizedString(@"OK", @""),
                nil,
                nil,
                windowForAlert,
                nil,
                nil,
                nil,
                nil,
                [NSString
                    stringWithFormat:NSLocalizedString(@"ICQ user number %@ appears on your list as %@", @""),
                    [NSNumber numberWithUnsignedLong:[contact uin]],
                    [contactOnList displayName]
                ]
            );
        }
    }
    else
    {
        if (!contactOnList)
        // trying to add a contact that's not on the list
        {
            [self observeContact:contact];
            [contact setTemporary:YES];
            [contact setStatus:ICJNotOnListStatusKey];
        }
        // now that it's on the list, make it permanent
        [self addContactPermanently:contact];
    }
}

- (void)addContactPermanently:(ICJContact *)contact authorized:(BOOL)flag
{
    if ( !flag && [[contact detailForKey:ICJAuthorizationRequiredDetail] boolValue] )
    {
        [self composeAuthorizationRequestTo:contact];
    }
    else
    {
        if ( ![self contactIsOnList:contact] )
            [self observeContact:contact];

        [contact setTemporary:NO];
        [contact setPendingAuthorization:NO];
        [contact setDeleted:NO];
        [contact setStatus:ICJOfflineStatusKey];
        
        // play by the book: let the contact know they've been added to our list
        if (![[self undoManager] isUndoing])
            [self sendMessage:[ICQUserAddedMessage messageTo:contact]];

        [connection addContact:contact];
        [contactList setObject:contact forKey:[contact uinKey]];
        
        [[[self undoManager] prepareWithInvocationTarget:self] deleteContact:contact];
        
        [[NSNotificationQueue defaultQueue]
            enqueueNotification:[NSNotification
                notificationWithName:ICJContactListChangedNotification
                object:contactList
            ]
            postingStyle:NSPostASAP
            coalesceMask:NSNotificationCoalescingOnName
            forModes:nil
        ];
    }
}

- (void)addContactPermanently:(ICJContact *)contact
{
// next line used to be NO. now since we no longer receive auth acks, we just let
// everybody in
    [self addContactPermanently:contact authorized:YES];
}

- (void)addContactAsPendingAuthorization:(ICJContact *)contact
{
    if ( ![self contactIsOnList:contact] )
        [self observeContact:contact];

    [contact setDeleted:NO];
    [contact setTemporary:NO];
    [contact setStatus:ICJPendingAuthorizationStatusKey];
    [contact setPendingAuthorization:YES];
    
    [contactList setObject:contact forKey:[contact uinKey]];
    
    if ([[self undoManager] isUndoing])
        [[[self undoManager] prepareWithInvocationTarget:self] deleteContact:contact];
    
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification
            notificationWithName:ICJContactListChangedNotification
            object:contactList
        ]
        postingStyle:NSPostASAP
        coalesceMask:NSNotificationCoalescingOnName
        forModes:nil
    ];
}


- (BOOL)addContactTemporarily:(ICJContact *)contact
// After this, the contact is definitely on the list. We return YES if it wasn't there before.
{
    BOOL	result;
    
    if ( ![self contactIsOnList:contact] )
    {
        result = YES;
        
        [contact setTemporary:YES];
        [contact setDeleted:NO];
        [contact setStatus:ICJNotOnListStatusKey];
        
        [contactList setObject:contact forKey:[contact uinKey]];
        
        [self observeContact:contact];
        
        [[NSNotificationQueue defaultQueue]
            enqueueNotification:[NSNotification
                notificationWithName:ICJContactListChangedNotification
                object:contactList
            ]
            postingStyle:NSPostASAP
            coalesceMask:NSNotificationCoalescingOnName
            forModes:nil
        ];

        if ([[self undoManager] isUndoing])	// otherwise it's an auto-add due to the contact sending us a message, and it doesn't go on the undo stack
            [[[self undoManager] prepareWithInvocationTarget:self] deleteContact:contact];
    }
    else
        result = NO;

    return result;
}

- (void)deleteContact:(ICJContact *)theContact
{
    [connection deleteContact:theContact];
    
    [theContact setDeleted:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:theContact];
    
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification
            notificationWithName:ICJContactListChangedNotification
            object:contactList
        ]
        postingStyle:NSPostASAP
        coalesceMask:NSNotificationCoalescingOnName
        forModes:nil
    ];
    
//    [contactsPendingWindows removeObject:theContact];
    if ( [theContact isTemporary] )
        [[[self undoManager] prepareWithInvocationTarget:self] addContactTemporarily:theContact];
    else if ( [theContact isPendingAuthorization] )
        [[[self undoManager] prepareWithInvocationTarget:self] addContactAsPendingAuthorization:theContact];
    else
        [[[self undoManager] prepareWithInvocationTarget:self] addContactPermanently:theContact authorized:YES];

    [[self undoManager] setActionName:NSLocalizedString(@"Delete Contact", @"action name for undo/redo")];

    [theContact setStatus:ICJNotOnListStatusKey];
    [theContact setTemporary:YES];
}

- (void)renameContact:(ICJContact *)theContact to:(NSString *)nickname
{
    NSString	*oldNickname = [theContact nickname];
    
    [theContact setNickname:nickname];
    
    [[[self undoManager] prepareWithInvocationTarget:self] renameContact:theContact to:oldNickname];
    [[self undoManager] setActionName:NSLocalizedString(@"Rename Contact", @"action name for undo/redo")];
}

- (void)uploadDetails
{
    [connection uploadDetails:[user details]];
}

- (void)sendMessage:(ICJMessage *)theMessage
{
    [connection sendMessage:theMessage];
}

- (void)acceptFileTransfer:(ICQFileTransferMessage *)transfer promptForDestination:(BOOL)prompt
{
    IncomingFileController	*incomingController;
    
    incomingController = [IncomingFileController
        incomingFileControllerWithMessage:transfer
        forDocument:self
        promptForDestination:prompt
    ];
    [incomingController showWindow:self];
    [_incomingFileTransferControllers addObject:incomingController];
}

- (void)importServerBasedList
{
    [connection requestServerBasedList];
}

- (void)addToVisibleList:(ICJContact *)theContact
{
    [self removeFromInvisibleList:theContact];
    [theContact setOnVisibleList:YES];
    [visibleList addObject:theContact];
    [connection addVisible:theContact];
}

- (void)removeFromVisibleList:(ICJContact *)theContact
{
    [theContact setOnVisibleList:NO];
    [visibleList removeObject:theContact];
    [connection removeVisible:theContact];
}

- (void)addToInvisibleList:(ICJContact *)theContact
{
    [self removeFromVisibleList:theContact];
    [theContact setOnInvisibleList:YES];
    [invisibleList addObject:theContact];
    [connection addInvisible:theContact];
}

- (void)removeFromInvisibleList:(ICJContact *)theContact
{
    [theContact setOnInvisibleList:NO];
    [invisibleList removeObject:theContact];
    [connection removeInvisible:theContact];
}

- (void)findContactsByUin:(ICQUIN)theUin refCon:(id)object
{
    [connection findContactsByUin:theUin refCon:object];
}

- (void)findContactsByEmail:(NSString *)theEmail refCon:(id)object
{
    [connection findContactsByEmail:theEmail refCon:object];
}

- (void)findContactsByName:(NSString *)theNickname firstName:(NSString *)theFirstName lastName:(NSString *)theLastName refCon:(id)object
{
    [connection findContactsByName:theNickname firstName:theFirstName lastName:theLastName refCon:object];
}

- (void)refreshInfoForContact:(ICJContact *)theContact
{
    [connection refreshInfoForContact:theContact];
}

- (void)readStatusMessageForContact:(ICJContact *)theContact
{
    ICQAwayMessage *message = [[[ICQAwayMessage alloc] initTo:theContact] autorelease];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusMessageReceived:) name:ICJMessageAcknowledgedNotification object:message];
    [self sendMessage:message];
}

/*- (void)statusMessageReceived:(NSNotification *)ackNotification
{
    ICQMessage *message = [ackNotification object];
    if ([message isFinished])
    {
        ICJContact *theContact = [[message owners] objectAtIndex:0];
        if ([message isDelivered])
        {
            [theContact setStatusMessage:[message statusMessage]];
        }
        else
            [theContact setStatusMessage:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJMessageAcknowledgedNotification object:message];
}*/

- (void)retrieveUserInfo
{
    [connection retrieveUserInfo];
}

- (void)loggedOut
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJLoginStatusChangedNotification object:self];
}

- (void)loggedIn
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ICJLoginStatusChangedNotification object:self];
}

- (UserDetailsController *)userDetailsController
{
    if ( !userDetailsController )
        userDetailsController = [[UserDetailsController alloc] initForDocument:self];
    return userDetailsController;
}

- (void)userStatusChangedTo:(NSString *)statusKey
{
    [self setCurrentStatus:statusKey];

    if ( welcomeNewUser && ![statusKey isEqualToString:ICJOfflineStatusKey] )
    {
        welcomeNewUser = NO;
        [[NSApp delegate] showFindPanel:self];
        [self retrieveUserInfo];
        if ( [self mainWindowController] )
            NSBeginInformationalAlertSheet(
                NSLocalizedString(@"Adding Contacts to your List", @"title of informational alert"),
                NSLocalizedString(@"OK", @"OK button on informational alert"),
                nil,
                nil,
                [[self mainWindowController] window],
                nil,
                nil,
                nil,
                nil,
                NSLocalizedString(@"To add contacts to your contact list, use the Find Contacts panel. You can also use the Import from ICQ ServersÉ command if you have a contact list saved on the ICQ servers.", @"informational alert message")
            );
    }
}

- (void)setStatusOfContact:(ICQUIN)theUin toStatusKey:(NSString *)statusKey typingFlags:(TypingFlags)flags
{
    ICJContact	*contact = [contactList contactForUin:theUin];
    
    [contact setStatus:statusKey];
    [contact setTypingFlags:flags];
}

- (void)contactInfoChanged:(NSNotification *)aNotification
{
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification
            notificationWithName:ICJContactListChangedNotification
            object:contactList
        ]
        postingStyle:NSPostASAP
        coalesceMask:NSNotificationCoalescingOnName
        forModes:nil
    ];
}

- (void)contactStatusChanged:(NSNotification *)aNotification
{
    [[NSNotificationQueue defaultQueue]
        enqueueNotification:[NSNotification
            notificationWithName:ICJContactListChangedNotification
            object:contactList
        ]
        postingStyle:NSPostASAP
        coalesceMask:NSNotificationCoalescingOnName
        forModes:nil
    ];
}

- (void)disconnectedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if ( sheet==disconnectedSheet )
    {
		if ( [sheet isKindOfClass:[NetworkProblemAlert class]] )
			[self
				setObject:[NSNumber numberWithBool:![(NetworkProblemAlert *)sheet checkboxState]]
				forSettingName:ICJDisplayNetworkAlertsSettingName
			];

        [[[sheet retain] autorelease] close];
        
        // this prevents us from trying to dismiss the sheet twice
        disconnectedSheet = nil;
        
        if ( returnCode==NSAlertAlternateReturn ) // "retry now" clicked
        {
            [self setNetworkAvailable:YES];
            [self reconnectIfPossibleWithStatus:[self targetStatus]];
        }
    }
}

- (void)disconnected:(ICJDisconnectReason)reason
{
    if ( reason==ICJBadPasswordDisconnectReason || reason==ICJMismatchPasswordDisconnectReason )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJWrongPasswordNotification object:self];
    }
    else
    {
        if (reason!=ICJRequestedDisconnectReason)
        {
            NSString	*title;
            NSString	*message;
            NSString	*altButton = nil;
            NSWindow	*documentWindow = [[self mainWindowController] window];
            
            switch (reason)
            {
                case ICJDualLoginDisconnectReason:
                    title = NSLocalizedString(@"Disconnected", @"alert sheet title");
                    message = NSLocalizedString(@"Your ICQ number is being used on another computer.", @"alert sheet message");
                    [self setTargetStatus:ICJOfflineStatusKey];
                    break;
                case ICJLowLevelDisconnectReason:
                    title = NSLocalizedString(@"Network Problem", @"alert sheet title");
                    message = NSLocalizedString(@"Icy Juice will try to reconnect when the network becomes available.", @"alert sheet message");
                    altButton = NSLocalizedString(@"Retry Now", @"button on network problems alert sheet");
                    // note that we DO NOT reset the traget status
                    [self setNetworkAvailable:NO];
					if ( ![[self settingWithName:ICJDisplayNetworkAlertsSettingName] boolValue] )
						return;
                    break;
                case ICJUnknownDisconnectReason:
                default:
                    title = NSLocalizedString(@"Disconnected", @"alert sheet title");
                    message = NSLocalizedString(@"You were disconnected. Check your Internet connection and the Network section in the Settings sheet and try again.", @"alert sheet message");
                    [self setTargetStatus:ICJOfflineStatusKey];
            }
            
            if ( documentWindow )
            {
                if ( [documentWindow attachedSheet]==nil )
                {
                    [documentWindow makeKeyAndOrderFront:nil];
					if ( reason==ICJLowLevelDisconnectReason )
					{
						disconnectedSheet = [NetworkProblemAlert problemAlert];
						[(NetworkProblemAlert *)disconnectedSheet
							beginSheetModalForWindow:documentWindow
							modalDelegate:self
							didEndSelector:@selector(disconnectedSheetDidEnd:returnCode:contextInfo:)
							contextInfo:nil
						]; 
					}
					else
					{
						disconnectedSheet = NSGetAlertPanel(
							title,
							message,
							NSLocalizedString(@"OK", @"Button on alert sheet"),
							altButton,
							nil
						);
						[NSApp beginSheet:disconnectedSheet
							modalForWindow:documentWindow
							modalDelegate:self
							didEndSelector:@selector(disconnectedSheetDidEnd:returnCode:contextInfo:)
							contextInfo:nil
						];
					}
                }
                else
                    NSRunAlertPanel(
                        title,
                        message, 
                        NSLocalizedString(@"OK", @"Button on alert sheet"),
                        nil,
                        nil);
            }
        }
    }
}

- (NSString *)historyFileNameForContact:(ICJContact *)theContact documentFileName:(NSString *)aFileName;
{
    return [[aFileName
        stringByAppendingPathComponent:[[theContact uinKey] description]
    ] stringByAppendingPathExtension:@"icjhistory"];
}

- (NSString *)historyFileNameForContact:(ICJContact *)theContact
{
    return [self historyFileNameForContact:theContact documentFileName:[self fileName]];
}

/*
- (void)saveDirtyHistories:(NSTimer *)aTimer
{
    NSEnumerator	*historyEnumerator = [histories keyEnumerator];
    NSMutableDictionary	*currentHistory;
    NSNumber		*currentUinKey;
    
    while ( currentUinKey = [historyEnumerator nextObject] )
    {
        currentHistory = [histories objectForKey:currentUinKey];
        if (
            [[currentHistory objectForKey:@"isDirty"] boolValue]
            && [[currentHistory objectForKey:@"messageArray"] count]>0
            )
        {
            if ([self
                writeMessageArray:[currentHistory objectForKey:@"messageArray"]
                toFileForContact:[contactList objectForKey:currentUinKey]
            ])
                [currentHistory setObject:[NSNumber numberWithBool:NO] forKey:@"isDirty"];
        }
    }
}
*/

/*
- (NSMutableArray *)messageArrayFromFileForContact:(ICJContact *)theContact
{
    NSString	*historyPath = [self historyFileNameForContact:theContact];
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:historyPath] )
    {
        [ContactPlaceholder setReplacement:theContact];
        return [NSUnarchiver unarchiveObjectWithFile:historyPath];
    }

    return [NSMutableArray array];
    return [[History historyWithContact:theContact path:historyPath] messages];
}
*/

- (void)appendMessage:(ICJMessage *)theMessage toHistoryOfContact:(ICJContact *)theContact
{
    History	*history = [self historyForContact:theContact];

    [history appendMessage:theMessage];
}

- (void)receivedMessage:(id)theMessage
{
    NSWindowController <ICJIncomingMessageDisplay>
                        *incomingController;
    ICJContact		*sender = [theMessage sender];
    
    if ( [self acceptsMessagesFromContact:sender] || [theMessage isKindOfClass:[ICQAuthAckMessage class]] )
    // we don't ignore the message
    {
        NSString	*statusKey = [self currentStatus];
        BOOL		isUrgent = NO;
        BOOL		isToContactList = NO;
        
        // if this is a normal message, determine whether it's urgent or to contact list
        if ([theMessage isKindOfClass:[ICQMessage class]])
        {
            isUrgent = [theMessage isUrgent];
            isToContactList = [theMessage isToContactList];
        }
        
        if ( isUrgent || isToContactList || ![[[NSApp delegate] statusForKey:[self currentStatus]] blocksStandardMessages] )
        // we don't block the message
        {
            BOOL	silent = NO;
            
            // make sure the sender is on our list and fetch its info if it's new to us
            if ( [self addContactTemporarily:sender] )
                [self refreshInfoForContact:sender];

            [sender addMessage:theMessage];
            [self appendMessage:theMessage toHistoryOfContact:sender];
            
            [[NSNotificationCenter defaultCenter]
                postNotificationName:ICJMessageRequiresAttentionNotification
                object:self
            ];
            
            incomingController = [incomingMessageControllers objectForKey:[sender uinKey]];

            if ( incomingController )
            {
                if (
                    [[self settingWithName:ICJSilentFrontDialogSettingName] boolValue]
                    && [incomingController isKindOfClass:[DialogController class]]
                    && [[NSApp mainWindow] isEqual:[incomingController window]]
                    )
                    silent = YES;
                    
                [incomingController messageAdded];
            }
            else if (
                ([self autoPopup] || isUrgent)
                && !( isToContactList && [[[NSApp delegate] statusForKey:[self currentStatus]] blocksStandardMessages] )
                )
                [self showIncomingMessagesForContact:sender];
            else if ( ![contactsPendingWindows containsObject:sender] )
                [contactsPendingWindows addObject:sender];
            
            if (
                [theMessage isKindOfClass:[ICQAuthAckMessage class]]
                && [sender isPendingAuthorization]
                && [theMessage isGranted]
                )	// authorization granted
                [self addContactPermanently:sender authorized:YES];
            
            if ( !silent
                && ( isUrgent
                    || ![[[NSApp delegate] statusForKey:[self currentStatus]] blocksStandardMessages]
                    || ![[self settingWithName:ICJSilentOccupiedDNDSettingName] boolValue] )
                ) 
                [[[NSApp delegate] soundWithNameOrPath:[self settingWithName:ICJIncomingSoundSettingName] refetch:NO] play];

            [[NSApp delegate] requestUserAttention];

            [theMessage setDelivered:YES];
        }
        else
        // we block the message
        {
            [theMessage setDelivered:NO];
            if ( [statusKey isEqual:ICJDNDStatusKey] )
                [theMessage setDeliveryFailureReason:Failed_DND];
            else if ( [statusKey isEqual:ICJOccupiedStatusKey] )
                [theMessage setDeliveryFailureReason:Failed_Occupied];
        }
    }
    else
    // we ignore the message
    {
        [theMessage setDelivered:NO];
        [theMessage setDeliveryFailureReason:Failed_Ignored];
    }
}

- (void)messageAcknowledged:(ICQMessage *)theMessage
{
    NSEnumerator	*recipientEnumerator = [[theMessage owners] objectEnumerator];
    ICJContact		*recipient;

    if (
        [theMessage isFinished]
        && [theMessage isDelivered]
        && !(
                [theMessage isKindOfClass:[ICQAwayMessage class]]
                || [theMessage isKindOfClass:[ICQUserAddedMessage class]]
            )
        )
    {
        while ( recipient = [recipientEnumerator nextObject] )
            [self appendMessage:theMessage toHistoryOfContact:recipient];
    }
    
    if (
        [theMessage isFinished]
        && [[theMessage statusMessage] length]>0 
        && ![[[[theMessage owners] objectAtIndex:0] statusKey] isEqual:ICJAvailableStatusKey]
        && ![[[[theMessage owners] objectAtIndex:0] statusKey] isEqual:ICJInvisibleStatusKey]
        && ![[[[theMessage owners] objectAtIndex:0] statusKey] isEqual:ICJFreeForChatStatusKey]
        )
        [[[theMessage owners] objectAtIndex:0] setStatusMessage:[theMessage statusMessage]];

    [[NSNotificationCenter defaultCenter] postNotificationName:ICJMessageAcknowledgedNotification object:theMessage];
}

- (void)search:(id)theRefCon returnedResult:(NSDictionary *)theResult isLast:(BOOL)isLast;
{
    if ( theResult ) // no contact means nothing found at all, this is probably also last
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ICJSearchResultNotification
            object:theRefCon
            userInfo:theResult
        ];
    
    if (isLast)
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ICJSearchFinishedNotification
            object:theRefCon
        ];
}

- (void)serverAddedContact:(ICJContact *)theContact nickname:(NSString *)theNickname
{
    ICJContact *listContact = [contactList contactForUin:[theContact uin]];
    if ( listContact )
    {
        [listContact setDeleted:NO];
        if ( [listContact isTemporary] )
        {
            [listContact setNickname:theNickname];
            [listContact setTemporary:NO];
        }
    }
    else
    {
        [theContact setNickname:theNickname];
        [theContact setStatus:ICJOfflineStatusKey];
        [theContact setTemporary:NO];
        [contactList setObject:theContact forKey:[theContact uinKey]];
        [self observeContact:theContact];
    }
    [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:ICJContactListChangedNotification object:contactList] postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

- (void)userDetailsControllerWillClose:(UserDetailsController *)sender
{
    userDetailsController = nil;
}

- (void)incomingControllerWillClose:(NSWindowController <ICJIncomingMessageDisplay> *)sender
{
    [incomingMessageControllers removeObjectsForKeys:[incomingMessageControllers allKeysForObject:sender]]; //consider something nicer (still?)
}

- (void)historyControllerWillClose:(HistoryWindowController *)sender
{
    [historyControllers removeObjectsForKeys:[historyControllers allKeysForObject:sender]];
}

- (void)outgoingControllerWillClose:(OutgoingMessageController *)sender
{
    [outgoingMessageControllers removeObject:sender];
}

- (void)removeContactStatusMessageController:(ContactStatusMessageController *)sender
{
    [contactStatusMessageControllers removeObjectsForKeys:[contactStatusMessageControllers allKeysForObject:sender]];
}

- (void)removeIncomingFileController:(IncomingFileController *)sender
{
    [_incomingFileTransferControllers removeObject:sender];
}

// NSMenu validation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    if (action==@selector(saveDocumentAs:)
        || action==@selector(printDocument:)
        || action==@selector(runPageLayout:))
        return NO;
    return YES;
}

@end
