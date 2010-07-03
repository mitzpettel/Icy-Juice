/*
 * MainController.m
 * Icy Juice
 *
 * Created by Mitz Pettel in May 2001.
 *
 * Copyright (c) 2001-2002 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "MainController.h"
#import "ContactInfoController.h"
#import "FindController.h"
#import "PreferencesWindowController.h"
#import "ICQUserDocument.h"
#import "DockMenuTrampoline.h"
#import "EnterTextView.h"
#import <Carbon/Carbon.h>
#import "AboutPanelController.h"

io_connect_t    root_port;

void sleepCallback(void * controller,io_service_t y,natural_t messageType,void * messageArgument)
{
    switch ( messageType ) {
    case kIOMessageSystemWillSleep:
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:MPSystemWillSleepNotification object:nil] postingStyle:NSPostNow];
        IOAllowPowerChange(root_port,(long)messageArgument);
        break;
    case kIOMessageSystemHasPoweredOn:
        [[NSNotificationCenter defaultCenter] postNotificationName:MPSystemDidWakeUpNotification object:nil];
        IOAllowPowerChange(root_port,(long)messageArgument);
        break;
    }
}

void SCCallback(SCDynamicStoreRef SCStore, CFArrayRef changedKeys, void *info)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MPSystemConfigurationChangedNotification object:nil];
}

@implementation MainController

+ (void)initialize{
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:ICJDockIconBounceOnce] forKey:ICJDockIconBehaviorUserDefault]];
}

- (id)init
{
    self = [super init];
    
    {
        IONotificationPortRef   notify;
        io_object_t             anIterator;

        root_port = IORegisterForSystemPower (self, &notify, sleepCallback, &anIterator);
        if ( root_port == NULL )
                NSLog(@"IORegisterForSystemPower failed");
        else
            CFRunLoopAddSource(CFRunLoopGetCurrent(),
                                IONotificationPortGetRunLoopSource(notify),
                                kCFRunLoopDefaultMode);
    }

    {
        NSArray *keys = [NSArray arrayWithObjects:
            (id)SCDynamicStoreKeyCreateNetworkGlobalEntity(
                                            nil,
                                            kSCDynamicStoreDomainState,
                                            kSCEntNetIPv4),
            (id)SCDynamicStoreKeyCreateNetworkGlobalEntity(
                                            nil,
                                            kSCDynamicStoreDomainState,
                                            kSCEntNetDNS),
            NULL];
        SCDStore = SCDynamicStoreCreate(nil, (CFStringRef)@"Icy Juice", SCCallback, nil);
        SCDynamicStoreSetNotificationKeys(SCDStore, (CFArrayRef)keys, nil);
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                            SCDynamicStoreCreateRunLoopSource(nil, SCDStore, 0),
                            kCFRunLoopDefaultMode);
    }
    
    contactStatuses = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
        [[ContactStatus alloc] initWithKey:ICJOfflineStatusKey name:NSLocalizedString(@"Offline", @"") color:[NSColor redColor] icon:[NSImage imageNamed:@"offline.tiff"] sortOrder:[NSNumber numberWithInt:50] shortName:NSLocalizedStringFromTable(@"Offline", @"Abbreviated", @"")], ICJOfflineStatusKey,
    [[ContactStatus alloc] initWithKey:ICJAvailableStatusKey name:NSLocalizedString(@"Available", @"") color:[NSColor greenColor] icon:[NSImage imageNamed:@"Contact online.tiff"] sortOrder:[NSNumber numberWithInt:0] shortName:NSLocalizedStringFromTable(@"Available", @"Abbreviated", @"")], ICJAvailableStatusKey,
    [[ContactStatus alloc] initWithKey:ICJAwayStatusKey name:NSLocalizedString(@"Away", @"") color:[NSColor orangeColor] icon:[NSImage imageNamed:@"Contact away.tiff"] sortOrder:[NSNumber numberWithInt:10] shortName:NSLocalizedStringFromTable(@"Away", @"Abbreviated", @"")], ICJAwayStatusKey,
    [[ContactStatus alloc] initWithKey:ICJDNDStatusKey name:NSLocalizedString(@"Do Not Disturb", @"") color:[NSColor brownColor] icon:[NSImage imageNamed:@"Contact DND.tiff"] sortOrder:[NSNumber numberWithInt:40] shortName:NSLocalizedStringFromTable(@"Do Not Disturb", @"Abbreviated", @"")], ICJDNDStatusKey,
    [[ContactStatus alloc] initWithKey:ICJNAStatusKey name:NSLocalizedString(@"Not Available", @"") color:[NSColor darkGrayColor] icon:[NSImage imageNamed:@"Contact NA.tiff"] sortOrder:[NSNumber numberWithInt:20] shortName:NSLocalizedStringFromTable(@"Not Available", @"Abbreviated", @"")], ICJNAStatusKey,
    [[ContactStatus alloc] initWithKey:ICJOccupiedStatusKey name:NSLocalizedString(@"Occupied", @"") color:[NSColor magentaColor] icon:[NSImage imageNamed:@"Contact occupied.tiff"] sortOrder:[NSNumber numberWithInt:30] shortName:NSLocalizedStringFromTable(@"Occupied", @"Abbreviated", @"")], ICJOccupiedStatusKey,
    [[ContactStatus alloc] initWithKey:ICJInvisibleStatusKey name:NSLocalizedString(@"Invisible", @"") color:[NSColor grayColor] icon:[NSImage imageNamed:@"Contact invisible.tiff"] sortOrder:[NSNumber numberWithInt:0] shortName:NSLocalizedStringFromTable(@"Invisible", @"Abbreviated", @"")], ICJInvisibleStatusKey,
    [[ContactStatus alloc] initWithKey:ICJFreeForChatStatusKey name:NSLocalizedString(@"Free for Chat", @"") color:[NSColor grayColor] icon:[NSImage imageNamed:@"Contact online.tiff"] sortOrder:[NSNumber numberWithInt:1] shortName:NSLocalizedStringFromTable(@"Free for Chat", @"Abbreviated", @"")], ICJFreeForChatStatusKey,
    [[ContactStatus alloc] initWithKey:ICJPendingAuthorizationStatusKey name:NSLocalizedString(@"Pending Authorization", @"") color:[NSColor grayColor] icon:[NSImage imageNamed:@"Contact pending authorization.tif"] sortOrder:[NSNumber numberWithInt:45] shortName:NSLocalizedStringFromTable(@"Pending Authorization", @"Abbreviated", @"")], ICJPendingAuthorizationStatusKey,
    [[ContactStatus alloc] initWithKey:ICJNotOnListStatusKey name:NSLocalizedString(@"Not on your list", @"") color:[NSColor grayColor] icon:[NSImage imageNamed:@"offline.tiff"] sortOrder:[NSNumber numberWithInt:0] shortName:NSLocalizedStringFromTable(@"Not on your list", @"Abbreviated", @"")], ICJNotOnListStatusKey,
    NULL] retain];
    [[contactStatuses objectForKey:ICJDNDStatusKey] setBlocksStandardMessages:YES];
    [[contactStatuses objectForKey:ICJOccupiedStatusKey] setBlocksStandardMessages:YES];
    
    userStatuses = [[NSArray arrayWithObjects:
        ICJAvailableStatusKey,
        ICJAwayStatusKey,
        ICJDNDStatusKey,
        ICJNAStatusKey,
        ICJOccupiedStatusKey,
        ICJInvisibleStatusKey,
        ICJOfflineStatusKey,
        nil] retain];
    statusMessageStatuses = [[NSArray arrayWithObjects:
        ICJAwayStatusKey,
        ICJDNDStatusKey,
        ICJNAStatusKey,
        ICJOccupiedStatusKey,
        nil] retain];
    documentsRequiringAttention = [[NSCountedSet set] retain];
    documentDockMenus = [[NSMutableDictionary dictionary] retain];
    dockMenu = [[NSMenu alloc] init];
    requiresAttention = NO;
    languageTable = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"plist"]] retain];
    countryTable = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Countries" ofType:@"plist"]] retain];
    sexTable = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sex" ofType:@"plist"]] retain];
    settings = [[NSDictionary dictionaryWithObjectsAndKeys:
        @"login.icq.com",		ICJServerHostSettingName,
        @"5190",			ICJServerPortSettingName,
		[NSNumber numberWithInt:0],		ICJPortRangeStartSettingName,
		[NSNumber numberWithInt:0],		ICJPortRangeEndSettingName,
		[NSNumber numberWithBool:YES],  ICJDisplayNetworkAlertsSettingName,
        [NSNumber numberWithBool:NO],	ICJSpellCheckAsYouTypeSettingName,
        [NSNumber numberWithBool:YES],	ICJStatusBarShownSettingName,
        [NSNumber numberWithBool:YES],	ICJOutgoingStatusBarShownSettingName,
        [NSDictionary dictionaryWithObjectsAndKeys:
            NSLocalizedString(@"User is currently away\nYou can leave him/her a message", @"default away message"),
                                            ICJAwayStatusKey,
            NSLocalizedString(@"User is currently in DND mode", @"default DND message"),
                                            ICJDNDStatusKey,
            NSLocalizedString(@"User is currently N/A\nYou can leave him/her a message", @"default N/A message"),
                                            ICJNAStatusKey,
            NSLocalizedString(@"User is currently busy", @"default occupied message"),
                                            ICJOccupiedStatusKey,
            nil],			ICJStatusMessagesSettingName,
        [NSNumber numberWithBool:YES],	ICJPromptForStatusMessageSettingName,
        [NSNumber numberWithBool:NO],	ICJHideWhenSendingSettingName,
        [NSNumber numberWithBool:NO],	ICJWebAwareSettingName,
        [NSNumber numberWithBool:NO],	ICJSilentFrontDialogSettingName,
        [NSNumber numberWithBool:YES],	ICJSilentOccupiedDNDSettingName,
        @"Incoming.aiff",		ICJIncomingSoundSettingName,
        [[NSColor colorWithCalibratedRed:1 green:1 blue:0.9 alpha:1] RGBComponents],
                                        ICJIncomingBackgroundSettingName,
        [[NSColor textColor] RGBComponents],		
                                        ICJIncomingColorSettingName,
        [[NSFont userFontOfSize:12] fontName],
                                        ICJIncomingFontSettingName,
        [NSNumber numberWithFloat:12],	ICJIncomingSizeSettingName,
        [[NSColor textBackgroundColor] RGBComponents],
                                        ICJOutgoingBackgroundSettingName,
        [[NSColor textColor] RGBComponents],
                                        ICJOutgoingColorSettingName,
        [[NSFont userFontOfSize:12] fontName],
                                        ICJOutgoingFontSettingName,
        [NSNumber numberWithFloat:12],	ICJOutgoingSizeSettingName,
        [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"],
        				ICJFilesDirectorySettingName,
        nil] retain];
    sounds = [[NSMutableDictionary dictionary] retain];
    windowsToOrderFrontWhenUnhidden = [[NSMutableArray array] retain];
        
    return(self);
}

- (void)dealloc
{
    CFRelease(SCDStore);
    [windowsToOrderFrontWhenUnhidden release];
    [sounds release];
    [settings release];
    [languageTable release];
    [countryTable release];
    [sexTable release];
    [dockMenu release];
    [documentDockMenus release];
    [documentsRequiringAttention release];
    [userStatuses release];
    [statusMessageStatuses release];
    [contactStatuses release];
    [super dealloc];
    return;
}

- (IBAction)showInfoPanel:(id)sender
{
    [[ContactInfoController sharedContactInfoController] showWindow:sender];
}

- (IBAction)showFindPanel:(id)sender
{
    [[FindController sharedFindController] showWindow:sender];
}

- (IBAction)orderFrontStandardAboutPanel:(id)sender
{
    [[AboutPanelController sharedAboutPanelController] showPanel:nil];
}

- (IBAction)orderFrontPreferencesPanel:(id)sender
{
    [[PreferencesWindowController sharedPreferencesWindowController] showWindow:sender];
}

- (ContactStatus *)statusForKey:(id)key
{
    return [contactStatuses objectForKey:key];
}

- (NSArray *)userStatuses
{
    return userStatuses;
}

- (NSArray *)statusMessageStatuses
{
    return statusMessageStatuses;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

/*
- (void)systemWillSleep
{
    ICQUserDocument *document;
    NSEnumerator *documentsEnumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    while (document = [documentsEnumerator nextObject])
        [document tryToChangeStatusTo:[self statusForKey:ICJOfflineStatusKey]];
}

- (void)systemDidWakeUp
{
    ICQUserDocument *document;
    NSEnumerator *documentsEnumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    while (document = [documentsEnumerator nextObject])
        [document tryToChangeStatusTo:[self statusForKey:ICJOccupiedStatusKey]];
}
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self updateSendMessageMenuItem];
    if (!(GetCurrentKeyModifiers() & shiftKey))
    {
        if ([[[NSDocumentController sharedDocumentController] documents] count]==0)
        {
            id defaultDocument = [[NSUserDefaults standardUserDefaults] objectForKey:ICJDefaultContactListUserDefault];
            if (defaultDocument)
                [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:defaultDocument display:YES];
        }
    }
}

- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo
{
    [NSApp replyToApplicationShouldTerminate:didCloseAll];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self didCloseAllSelector:@selector(documentController:didCloseAll:contextInfo:) contextInfo:nil];
    return NSTerminateLater;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return dockMenu;
}

- (void)blinkDockIcon:(id)unused
{
    NSAutoreleasePool	*threadPool = [NSAutoreleasePool new];
    NSImage			*glowing = [NSImage imageNamed:@"full glass glowing.tiff"];
    NSImage			*full = [NSImage imageNamed:@"full glass.tiff"];

    while ( requiresAttention )
    {
        NSAutoreleasePool	*myPool = [NSAutoreleasePool new];
        
        [NSApp setApplicationIconImage:glowing];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [NSApp setApplicationIconImage:full];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        [myPool release];
    }
    [threadPool release];
}

- (void)updateHasMessages
{
    int messageDocumentCount = [documentsRequiringAttention count];
    if (requiresAttention && messageDocumentCount==0)
    {
        requiresAttention = NO;
        [NSApp setApplicationIconImage:[NSImage imageNamed:@"full glass.tiff"]];
    }
    else if (!requiresAttention && messageDocumentCount>0)
    {
        requiresAttention = YES;
        [NSThread detachNewThreadSelector:@selector(blinkDockIcon:) toTarget:self withObject:nil];
    }
}

- (void)icqUserDocumentRequiresAttention:(ICQUserDocument *)theDocument
{
    [documentsRequiringAttention addObject:theDocument];
    [self updateHasMessages];
}

- (void)icqUserDocumentGotAttention:(ICQUserDocument *)theDocument
{
    [documentsRequiringAttention removeObject:theDocument];
    [self updateHasMessages];
}

- (void)rebuildDockMenu
{
    NSEnumerator *documentsEnumerator = [documentDockMenus keyEnumerator];
    NSString *currentDocument;
    NSMenu *newDockMenu = [[NSMenu alloc] init];
    while (currentDocument = [documentsEnumerator nextObject])
    {
        NSEnumerator *itemEnumerator = [[[documentDockMenus objectForKey:currentDocument] itemArray] objectEnumerator];
        NSMenuItem *currentItem;
        NSMenuItem *documentItem = [newDockMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
        while (currentItem = [itemEnumerator nextObject])
        {
            NSMenuItem *newItem = [[currentItem copy] autorelease];
            [newDockMenu addItem:newItem];
            [newItem setTarget:[DockMenuTrampoline trampolineForItem:newItem]];
            [newItem setAction:@selector(jump:)];
            if ([newItem state]==NSOnState)
                [documentItem setTitle:[NSString stringWithFormat:@"%@: %@", [[NSFileManager defaultManager] displayNameAtPath:currentDocument], [newItem title]]];
        }
    }
    [dockMenu autorelease];
    dockMenu = newDockMenu;
}

- (void)dockMenuDidChangeItem:(NSNotification *)theNotification
{
    [self rebuildDockMenu];
}

- (void)registerDockMenu:(NSMenu *)theMenu forDocument:(ICQUserDocument *)theDocument
{
    [documentDockMenus setObject:theMenu forKey:[theDocument fileName]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dockMenuDidChangeItem:) name:NSMenuDidChangeItemNotification object:theMenu];
    [self rebuildDockMenu];
}

- (void)unregisterDockMenu:(NSMenu *)theMenu
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidChangeItemNotification object:theMenu];
    [documentDockMenus removeObjectsForKeys:[documentDockMenus allKeysForObject:theMenu]];
    [self rebuildDockMenu];
}

- (id)settingWithName:(NSString *)name
{
    return [settings objectForKey:name];
}

- (NSDictionary *)sexTable
{
    return sexTable;
}

- (NSString *)nameForSexCode:(NSNumber *)sexCode
{
    return [sexTable objectForKey:[sexCode description]];
}

- (NSDictionary *)countryTable
{
    return countryTable;
}

- (NSString *)nameForCountryCode:(NSNumber *)countryCode
{
    return [countryTable objectForKey:[countryCode description]];
}

- (NSDictionary *)languageTable
{
    return languageTable;
}

- (NSString *)nameForLanguageCode:(NSNumber *)languageCode
{
    return [languageTable objectForKey:[languageCode description]];
}

- (NSSound *)soundWithNameOrPath:(NSString *)name refetch:(BOOL)flag
{
    NSSound *result = nil;
    if ([name length]==0)
        return nil;
    if (!flag)
        result = [sounds objectForKey:name];
    if (!result)
    {
        result = [NSSound soundNamed:name];
        if (result)
            [sounds setObject:result forKey:name];
    }
    if (!result)
    {
        result = [[NSSound alloc] initWithContentsOfFile:name byReference:YES];
        [result autorelease];
        [sounds setObject:result forKey:name];
    }
    return result;
}

- (void)requestUserAttention
{
    ICJDockIconBehavior behavior = [[NSUserDefaults standardUserDefaults] integerForKey:ICJDockIconBehaviorUserDefault];
    switch (behavior)
    {
        case ICJDockIconBlinkOnly:
            break;
        case ICJDockIconBounceOnce:
            [NSApp requestUserAttention:NSInformationalRequest];
            break;
        case ICJDockIconBounceMany:
            [NSApp requestUserAttention:NSCriticalRequest];
            break;
        default:
            break;
    }
}

- (void)updateSendMessageMenuItem
{
    EnterTextViewKey selectedKey = [[NSUserDefaults standardUserDefaults] integerForKey:ICJSendMessageKeyUserDefault];
    if (selectedKey==ICJEnterKey)
        [sendMessageMenuItem setKeyEquivalent:@"\x03"];
    else
        [sendMessageMenuItem setKeyEquivalent:@"\r"];
    if (selectedKey==ICJCmdReturnKey)
        [sendMessageMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    else
        [sendMessageMenuItem setKeyEquivalentModifierMask:0];
}

- (void)orderFrontWindowWhenUnhidden:(NSWindow *)aWindow
{
    if (![windowsToOrderFrontWhenUnhidden containsObject:aWindow])
        [windowsToOrderFrontWhenUnhidden addObject:aWindow];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    NSEnumerator	*windowsEnumerator = [windowsToOrderFrontWhenUnhidden reverseObjectEnumerator];
    NSWindow		*window;
    NSWindow		*lastWindow = nil;
    
    while ( window = [windowsEnumerator nextObject] )
    {
        [window orderFront:nil];
        lastWindow = window;
    }
    
    [lastWindow makeKeyWindow];
    
    [windowsToOrderFrontWhenUnhidden removeAllObjects];
}

@end
