/*
 * HistoryWindowController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Thu Dec 20 2001.
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

#import "HistoryWindowController.h"
#import "ICQUserDocument.h"
#import "Contact.h"
#import "History.h"

@implementation HistoryWindowController

- (id)init
{
    NSMutableString *cleanShortDateFormatString = [NSMutableString string];
    NSString *tmpString;
    NSScanner *scanner = [NSScanner scannerWithString:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString]];
    
    self = [super initWithWindowNibName:@"History"];
    [self setWindowFrameAutosaveName:@"History"];
    shortTimeDateFormatter = [[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortTimeDateFormatString] allowNaturalLanguage:YES];
    
    while ([scanner scanUpToString:@"1" intoString:&tmpString])
    {
        [cleanShortDateFormatString appendString:tmpString];
        [scanner scanString:@"1" intoString:nil];
    }
    
    
    shortDateFormatter = [[NSDateFormatter alloc] initWithDateFormat:cleanShortDateFormatString allowNaturalLanguage:YES];
    return self;
}

- (void)dealloc
{
    [shortTimeDateFormatter release];
    [shortDateFormatter release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_history release];
    [super dealloc];
}

+ (id)historyControllerForHistory:(History *)theHistory document:(ICQUserDocument *)theDocument
{
    id newController = [[self alloc] initForHistory:theHistory document:theDocument];
    [newController showWindow:nil];
    return [newController autorelease];
}

- (id)initForHistory:(History *)theHistory document:(ICQUserDocument *)theDocument
{
    self = [self init];
    _history = [theHistory retain];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(historyChanged:)
        name:ICJHistoryChangedNotification
        object:_history
    ];
    document = theDocument;
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(contactInfoChanged:)
        name:ICJContactInfoChangedNotification
        object:[_history contact]
    ];
    return self;
}

- (void)setWindowTitle
{
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"History for %@", @"history window title"), [[_history contact] displayName]]];
}

- (void)historyChanged:(NSNotification *)aNotification
{
    BOOL	isIncremental = [[[aNotification userInfo]
        objectForKey:ICJHistoryChangeIncrementalKey
    ] boolValue];
    
    [historyView
        reloadDataByAppending:isIncremental
        andScrollToEnd:NO
    ];
}

- (void)contactInfoChanged:(NSNotification *)aNotification
{
    [self setWindowTitle];
}

- (void)synchronizeAttributes
{
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
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: ICJHistoryToolbarIdentifier] autorelease];
    [super windowDidLoad];
    [self setWindowTitle];
    
    [[self window] setFrameUsingName:@"History"];

    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeDefault];
    [toolbar setDelegate: self];
    [[self window] setToolbar: toolbar];
    
    [saveFromDateField setFormatter:shortDateFormatter];
    [saveThroughDateField setFormatter:shortDateFormatter];
    [printFromDateField setFormatter:shortDateFormatter];
    [printThroughDateField setFormatter:shortDateFormatter];
    [deleteUptoDateField setFormatter:shortDateFormatter];
    
    [historyView setDateFormatter:shortTimeDateFormatter];
    [historyView setBaseWritingDirection:[[document settingWithName:@"Writing Direction" forContact:[_history contact]] intValue]];
    [self synchronizeAttributes];
    [historyView setHistory:[_history messages]];
}

- (ICJContact *)selectedContact
{
    return [_history contact];
}

- (ICQUserDocument *)icqUserDocument
{
    return document;
}

- (IBAction)runPageLayout:(id)sender
{
    [[NSPageLayout pageLayout] beginSheetWithPrintInfo:[NSPrintInfo sharedPrintInfo] modalForWindow:[self window] delegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)printPanel:(NSPrintPanel *)printPanel didEndAndReturned:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode==NSOKButton)
    {
        NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
        NSPrintOperation *printOperation;
        HistoryView *printHistoryView = [[[HistoryView alloc] autorelease] initWithFrame:NSMakeRect(0, 0, [printInfo paperSize].width-[printInfo leftMargin]-[printInfo rightMargin], 0)];

        // to end editing in the date fields, in case it's still in progress. It shouldn't be our responsibility, but nobody else seems to do it
        [[printFromDateField window] makeFirstResponder:printDateRangeView];

        [printHistoryView setAutoresizingMask:NSViewHeightSizable];
        [printHistoryView setDateFormatter:shortTimeDateFormatter];
        [printHistoryView setHistory:[_history messagesFromDate:[printFromDateField objectValue] through:[printThroughDateField objectValue]]];

        printOperation = [NSPrintOperation printOperationWithView:printHistoryView printInfo:printInfo];

        [printOperation setShowPanels:NO];
        [printOperation runOperationModalForWindow:[self window] delegate:nil didRunSelector:nil contextInfo:nil];
    }
}

- (IBAction)printDocument:(id)sender
{
    NSPrintPanel *printPanel = [NSPrintPanel printPanel];
    [printPanel setAccessoryView:printDateRangeView];    
    [printPanel beginSheetWithPrintInfo:[NSPrintInfo sharedPrintInfo] modalForWindow:[self window] delegate:self didEndSelector:@selector(printPanel:didEndAndReturned:contextInfo:) contextInfo:nil];
}

- (void)savePanel:(NSSavePanel *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode==NSOKButton)
    {
        HistoryView *tmpHistoryView = [[[HistoryView alloc] autorelease] initWithFrame:NSMakeRect(0,0,1,1)];
        NSAttributedString *attributedString;
        [tmpHistoryView setDateFormatter:shortTimeDateFormatter];
        [tmpHistoryView setAttributes:
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
        [tmpHistoryView setHistory:[_history messagesFromDate:[saveFromDateField objectValue] through:[saveThroughDateField objectValue]]];
        attributedString = [tmpHistoryView textStorage];
        [[attributedString RTFFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:nil] writeToFile:[sheet filename] atomically:YES];
    }
}

- (BOOL)panel:(id)sender isValidFilename:(NSString *)filename;
{
    NSDate *fromDate;
    NSDate *throughDate;
    if ((fromDate = [saveFromDateField objectValue])
        && (throughDate = [saveThroughDateField objectValue])
        && [fromDate compare:throughDate]==NSOrderedDescending)
    {
        NSRunInformationalAlertPanel(NSLocalizedString(@"Invalid Date Range", @"information alert title"),  NSLocalizedString(@"You should enter a vaild range of dates. In order to save all the messages, leave both fields blank.", @"informational alert message"), NSLocalizedString(@"OK", @"OK button on informational alert"), nil, nil);
        return NO;
    }
    return YES;
}

- (IBAction)saveDocumentAs:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setRequiredFileType:@"rtf"];
    [panel setCanSelectHiddenExtension:YES];
    [panel setAccessoryView:saveDateRangeView];
    [panel setDelegate:self];
    [panel beginSheetForDirectory:nil file:[[self window] title] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanel:didEndAndReturned:contextInfo:) contextInfo:nil];
}

- (IBAction)doDelete:(id)sender
{
    [deleteSheet orderOut:nil];
    [NSApp endSheet:deleteSheet];
    [_history clearMessagesSentBefore:[deleteUptoDateField objectValue]];
}

- (IBAction)cancelDelete:(id)sender
{
    [deleteSheet orderOut:nil];
    [NSApp endSheet:deleteSheet];
}

- (IBAction)deleteHistory:(id)sender
{
    [NSApp beginSheet:deleteSheet modalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

// NSWindow delegate
- (void)windowWillClose:(NSNotification *)notification
{
    [[self retain] autorelease];
    [[self icqUserDocument] historyControllerWillClose:self];
    [[[_history contact] settings] setObject:[NSNumber numberWithInt:[historyView baseWritingDirection]] forKey:@"Writing Direction"];
}

// NSToolbar delegate
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];

    if ([itemIdentifier isEqual: ICJSaveHistoryToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Save", @"Save history toolbar item label")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Save", @"Save history toolbar item palette label")];
        [toolbarItem setToolTip: NSLocalizedString(@"Save history to file" ,@"Save history toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"saved history.png"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(saveDocumentAs:)];
    } else if ([itemIdentifier isEqual: ICJDeleteHistoryToolbarItemIdentifier]) {
        [toolbarItem setLabel: NSLocalizedString(@"Delete", @"Delete history toolbar item label")];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Delete", @"Delete history toolbar item palette label")];
        [toolbarItem setToolTip: NSLocalizedString(@"Delete this history", @"Delete history toolbar item tool tip")];
        [toolbarItem setImage:[NSImage imageNamed:@"Clean.tiff"]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(deleteHistory:)];
    } else
        toolbarItem = nil;
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJSaveHistoryToolbarItemIdentifier,
        NSToolbarPrintItemIdentifier,
        ICJDeleteHistoryToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:
        ICJSaveHistoryToolbarItemIdentifier,
        ICJDeleteHistoryToolbarItemIdentifier,
        NSToolbarPrintItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

// NSToolbarItem validation
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return ([[_history messages] count]>0);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL action = [menuItem action];
    if (action==@selector(saveDocumentAs:)
        || action==@selector(deleteHistory:)
        || action==@selector(printDocument:))
        return ([[_history messages] count]>0);
    return YES;
}

@end
