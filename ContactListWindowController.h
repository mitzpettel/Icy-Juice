/*
 * ContactListWindowController.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Thu Nov 15 2001.
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

#import <AppKit/AppKit.h>
#import "IcyJuice.h"
#import "Contact.h"

@interface  NSTableView (NSTableViewIcyJuice)
+ (NSImage *)_defaultTableHeaderSortImage;
+ (NSImage *)_defaultTableHeaderReverseSortImage;
@end

@class ContactListView;
@class MPStatusBarController;
@class ICQUserDocument;

struct sortContextStruct
{
    id		columnIdentifier;
    BOOL	descending;
};

@interface ContactListWindowController : NSWindowController
{
    IBOutlet id contactListView;
    IBOutlet id statusPopUp;
    IBOutlet id chasingArrows;
    IBOutlet id contactCountText;
    IBOutlet MPStatusBarController *statusBarController;
    IBOutlet NSButton	*popNextMessageButton;

    NSArray		*displayList;
    BOOL		needsUpdate;
    BOOL		isClosing;
    float		statusBarHeight;
}

- (IBAction)readStatusMessage:(id)sender;
- (IBAction)toggleStatusBarShown:(id)sender;
- (IBAction)changeStatus:(id)sender;
- (IBAction)toggleOfflineContacts:(id)sender;
- (IBAction)composeMessage:(id)sender;
- (IBAction)composeAuthorizationRequest:(id)sender;
- (IBAction)composeFileTransfer:(id)sender;
- (IBAction)receiveAction:(id)sender;
- (IBAction)defaultAction:(id)sender;
- (IBAction)deleteSelectedContacts:(id)sender;
- (IBAction)renameContact:(id)sender;
- (IBAction)makeContactPermanent:(id)sender;
- (IBAction)toggleVisibleList:(id)sender;
- (IBAction)toggleInvisibleList:(id)sender;
- (IBAction)showContactHistory:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)showDetails:(id)sender;
- (IBAction)importServerBasedList:(id)sender;
- (IBAction)popNextMessage:(id)sender;
//- (NSMenu *)dockMenu;
- (void)focusOnContact:(ICJContact *)theContact;
- (ICJContact *)selectedContact;
- (void)initStatusMenu;
- (void)setNeedsUpdate:(BOOL)isUpdateNeeded;
- (ICQUserDocument *)icqUserDocument;
- (void)userStatusChanged:(NSNotification *)theNotification;

@end

int compContacts(ICJContact *first, ICJContact *second, void *context);