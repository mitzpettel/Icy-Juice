/*
 * FindController.h
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

#import <Cocoa/Cocoa.h>
#import "IcyJuice.h"
@class ICJContact;
@class ICQUserDocument;

@interface FindController : NSWindowController
{
    IBOutlet id		findButton;
    IBOutlet id		addButton;
    IBOutlet id 	icqNumberField;
    IBOutlet id 	emailField;
    IBOutlet id 	nicknameField;
    IBOutlet id 	firstNameField;
    IBOutlet id 	lastNameField;
    IBOutlet id		resultsView;
    IBOutlet id		tabs;
    BOOL		searching;
    NSMutableArray	*results;
    ICQUserDocument	*currentDocument;
    BOOL		haveWhatToAdd;
    BOOL		haveWhereToAdd;
    int			currentSearchIdentifier;
}
+ (id)sharedFindController;
- (IBAction)startFind:(id)sender;
- (IBAction)stopFind:(id)sender;
- (IBAction)add:(id)sender;
- (void)attachToDocument;
- (void)setMainWindow:(NSWindow *)mainWindow;
- (void)searchStarted:(id)sender;
- (void)searchFinished:(id)sender;
- (void)addResult:(NSNotification *)theNotification;
// NSTableDataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
// NSTableView delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end
