/*
 * FindController.m
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

#import "FindController.h"
#import "ICQUserDocument.h"
#import "ContactListWindowController.h"

@implementation FindController

+ (id)sharedFindController {
    static FindController *sharedFindObject = nil;
    
    if (!sharedFindObject) {
        sharedFindObject = [[self alloc] init];
    }
    return sharedFindObject;
}

- (id)init {
    self = [self initWithWindowNibName:@"Find"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Find"];
        searching = NO;
        haveWhatToAdd = NO;
        haveWhereToAdd = NO;
    }
    currentSearchIdentifier = 0;
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged:) name:ICJLoginStatusChangedNotification object:nil];
    [self attachToDocument];
    [resultsView setTarget:self];
    [resultsView setDoubleAction:@selector(add:)];
    [findButton setEnabled:(currentDocument!=nil)];
    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [results release];
    [super dealloc];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}

- (void)updateAddButton
{
    [addButton setEnabled:(haveWhatToAdd && haveWhereToAdd)];
}

- (void)attachToDocument
{
    NSEnumerator *documentsEnumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
    id document;
    currentDocument = nil;
    while (document = [documentsEnumerator nextObject])
    {
        if ([document isLoggedIn])
        {
            currentDocument = document;
            break;
        }
    }
    if (currentDocument)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJLoginStatusChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged:) name:ICJLoginStatusChangedNotification object:currentDocument];
    }
}

- (void)setMainWindow:(NSWindow *)mainWindow {
    NSWindowController *windowController = [mainWindow windowController];
    haveWhereToAdd = (windowController && [windowController respondsToSelector:@selector(icqUserDocument)]);
    [self updateAddButton];
}

- (void)loginStatusChanged:(NSNotification *)theNotification
{
    [self attachToDocument];
    if (currentDocument) // have one
    {
        [findButton setEnabled:YES];
    }
    else
    {
        [findButton setEnabled:NO];
        if (searching)
            [self searchFinished:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged:) name:ICJLoginStatusChangedNotification object:nil];
    }
}

- (IBAction)startFind:(id)sender
{
    id tabIdentifier = [[tabs selectedTabViewItem] identifier];
    [self searchStarted:sender];
    if ([tabIdentifier isEqual:@"byNumber"])
        [currentDocument findContactsByUin:[icqNumberField intValue] refCon:[NSNumber numberWithInt:++currentSearchIdentifier]];
    if ([tabIdentifier isEqual:@"byEmail"])
        [currentDocument findContactsByEmail:[emailField stringValue] refCon:[NSNumber numberWithInt:++currentSearchIdentifier]];
    if ([tabIdentifier isEqual:@"byName"])
        [currentDocument findContactsByName:[nicknameField stringValue] firstName:[firstNameField stringValue] lastName:[lastNameField stringValue] refCon:[NSNumber numberWithInt:++currentSearchIdentifier]];
}

- (IBAction)stopFind:(id)sender
{
    [self searchFinished:nil];
}

- (void)searchStarted:(id)sender {
    [findButton setTitle:NSLocalizedString(@"Stop Find", @"Stop Find button title")];
    [findButton setAction:@selector(stopFind:)];
    [results release];
    results = [[NSMutableArray array] retain];
    [resultsView reloadData];
    searching = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addResult:) name:ICJSearchResultNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchFinished:) name:ICJSearchFinishedNotification object:nil];
}

- (void)searchFinished:(NSNotification *)theNotification {
    if (theNotification==nil || [[theNotification object] intValue] == currentSearchIdentifier)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJSearchResultNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJSearchFinishedNotification object:nil];
        searching = NO;
        [findButton setAction:@selector(startFind:)];
        [findButton setTitle:NSLocalizedString(@"Find", @"Find button title")];
    }
}

- (void)addResult:(NSNotification *)theNotification
{
    if ([[theNotification object] intValue] == currentSearchIdentifier)
    {
        if (!results) return;
        if (!searching) return;
        [results addObject:[theNotification userInfo]];
        [resultsView reloadData];
    }
}

- (IBAction)add:(id)sender
{
    NSEnumerator *selectedRows = [resultsView selectedRowEnumerator];
    NSNumber *row;
    while (row = [selectedRows nextObject])
        [[[[NSApp mainWindow] windowController] icqUserDocument] addSearchResult:[results objectAtIndex:[row intValue]]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (!results)
        return 0;
    return([results count]);
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    id result = [results objectAtIndex:rowIndex];
    ICJContact *contact = [result objectForKey:ICJContactKey];
    id columnId = [aTableColumn identifier];
    if (CFEqual(columnId, @"nickname"))
        return([contact ownNickname]);
    if (CFEqual(columnId, @"uin"))
        return([NSNumber numberWithUnsignedLong:[contact uin]]);
    if (CFEqual(columnId, @"email"))
        return([contact email]);
    if (CFEqual(columnId, @"name"))
        return([NSString stringWithFormat:@"%@ %@",[contact firstName], [contact lastName]]);
    if (CFEqual(columnId, @"authorization"))
        return([[result objectForKey:ICJAuthorizationRequiredKey] boolValue] ?
            NSLocalizedString(@"Yes", @"authorization is required") :
            NSLocalizedString(@"No", @"authorization is not required"));
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    haveWhatToAdd = ([resultsView numberOfSelectedRows]>0);
    [self updateAddButton];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSColor *color;
    if ([[[results objectAtIndex:row] objectForKey:ICJAuthorizationRequiredKey] boolValue])
        color = [NSColor redColor];
    else
        color = [NSColor blackColor];
    [cell setTextColor:color];
}

@end
