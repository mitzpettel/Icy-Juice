/*
 * ICQUserDocument.h
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

#import <AppKit/AppKit.h>
#import "IcyJuice.h"
#import "Contact.h"

typedef struct {
    id delegate;
    SEL shouldCloseSelector;
    void *contextInfo;
} CanCloseAlertContext;

@class User;
@class ICQConnection;
@class OutgoingMessageController;
@class ICQMessage;
@class ICQFileTransferMessage;
@class IncomingMessageController;
@class HistoryWindowController;
@class UserDetailsController;
@class ContactStatusMessageController;
@class ContactListWindowController;
@class IncomingFileController;
@class History;

@interface ICQUserDocument : NSDocument {
    NSMutableDictionary	*contactList;
    NSMutableSet	*visibleList;
    NSMutableSet	*invisibleList;
    // _targetStatus is the status we would like to be in, sleep and network permitting
    NSString		*_targetStatus;
    // _currentStatus is the status we've last been told we're in
    NSString		*_currentStatus;
    // _initialStatus is the status we want to be in when the document is opened
    NSString		*_initialStatus;
    // _lastSelectedStatus is the last status the user has actually selected
    NSString		*_lastSelectedStatus;
    BOOL		_networkAvailable;
    User		*user;
    id			sortColumnIdentifier;
    ICQConnection	*connection;
    BOOL		descendingOrder;
    BOOL		offlineHidden;
    BOOL		autoPopup;
    NSMutableSet	*outgoingMessageControllers;
    NSMutableDictionary	*incomingMessageControllers;
    NSMutableDictionary *historyControllers;
    NSMutableDictionary	*contactStatusMessageControllers;
    NSMutableArray	*_incomingFileTransferControllers;
    CFStringEncoding	textEncoding;
    BOOL		startsWithPreviousStatus;
    int			attentionRequirements;
    NSString		*savedContactListWindowFrame;
    BOOL		welcomeNewUser;
    BOOL		useDialogWindows;
    NSMutableDictionary	*histories;
    NSMutableDictionary *settings;
    UserDetailsController	*userDetailsController;
    BOOL		dirty;
    // contacts with incoming messages and no incoming message window currently open
    NSMutableArray	*contactsPendingWindows;
    NSPanel		*disconnectedSheet;
}

- (User *)user;
- (NSMutableDictionary *)contactList;
- (id)sortColumnIdentifier;
- (void)setSortColumnIdentifier:(id)identifier;
- (NSString *)historyFileNameForContact:(ICJContact *)theContact documentFileName:(NSString *)aFileName;
- (NSString *)historyFileNameForContact:(ICJContact *)theContact;
//- (NSMutableArray *)messageArrayFromFileForContact:(Contact *)theContact;
//- (BOOL)writeMessageArray:(NSArray *)messageArray toFileForContact:(Contact *)theContact;
- (History *)historyForContact:(ICJContact *)theContact;
- (void)appendMessage:(ICJMessage *)theMessage toHistoryOfContact:(ICJContact *)theContact;
- (NSArray *)contactsPendingWindows;
- (id)settingWithName:(NSString *)name;
- (id)settingWithName:(NSString *)name forContact:(ICJContact *)contact;
- (void)setObject:(id)object forSettingName:(NSString *)name;
- (void)settingsDidChange;
- (void)removeSettingWithName:(NSString *)name;
- (BOOL)acceptsMessagesFromContact:(ICJContact *)aContact;
- (BOOL)descendingOrder;
- (BOOL)offlineHidden;
- (BOOL)autoPopup;
- (BOOL)usesDialogWindows;
- (BOOL)startsWithPreviousStatus;
- (NSString *)initialStatus;
- (CFStringEncoding)textEncoding;
- (CFStringEncoding)textEncodingForContact:(ICJContact *)theContact;
- (CFStringEncoding)textEncodingForUin:(ICQUIN)theUin;
- (NSString *)savedContactListWindowFrame;
- (void)setDescendingOrder:(BOOL)theOrder;
- (void)setOfflineHidden:(BOOL)shouldHide;
- (void)setAutoPopup:(BOOL)shouldAutoPopup;
- (void)setUsesDialogWindows:(BOOL)shouldUseDialogWindows;
- (void)setStartsWithPreviousStatus:(BOOL)flag;
- (void)setInitialStatus:(NSString *)theStatus;
- (void)setTextEncoding:(CFStringEncoding)theEncoding;
- (BOOL)isLoggedIn;

- (UserDetailsController *)userDetailsController;
- (ContactListWindowController *)mainWindowController;

- (void)newUin:(ICQUIN)theUin password:(NSString *)thePassword;
- (void)userDidRequestStatus:(NSString *)theStatus;
- (NSString *)currentStatus;
- (void)setCurrentStatus:(NSString *)theStatus;
- (NSString *)targetStatus;
- (void)setTargetStatus:(NSString *)theStatus;
- (BOOL)isNetworkAvailable;
- (void)setNetworkAvailable:(BOOL)flag;
- (OutgoingMessageController *)composeMessageTo:(NSMutableArray *)recipients;
- (OutgoingMessageController *)composeMessageTo:(NSMutableArray *)recipients text:(NSString *)text;
- (void)composeAuthorizationRequestTo:(ICJContact *)contact;
- (void)composeFileTransferTo:(ICJContact *)contact files:(NSArray *)files;
- (void)composeFileTransferTo:(ICJContact *)contact;
- (void)readStatusMessageOfContact:(ICJContact *)theContact;
- (void)showHistoryOfContact:(ICJContact *)theContact;
- (ICJContact *)contactWithUin:(ICQUIN)theUin create:(BOOL)flag;
- (NSString *)statusMessageForContact:(ICJContact *)theContact;
- (BOOL)showIncomingMessagesForContact:(ICJContact *)theContact;
- (void)setUserPassword:(NSString *)thePassword;
- (void)addSearchResult:(NSDictionary *)result;
- (void)addContactPermanently:(ICJContact *)contact authorized:(BOOL)flag;
- (void)addContactPermanently:(ICJContact *)contact;
- (void)addContactAsPendingAuthorization:(ICJContact *)contact;
- (void)deleteContact:(ICJContact *)theContact;
- (void)renameContact:(ICJContact *)theContact to:(NSString *)nickname;
- (void)uploadDetails;
- (void)sendMessage:(ICJMessage *)theMessage;
- (void)acceptFileTransfer:(ICQFileTransferMessage *)transfer promptForDestination:(BOOL)prompt;
- (void)importServerBasedList;

- (void)addToVisibleList:(ICJContact *)theContact;
- (void)removeFromVisibleList:(ICJContact *)theContact;
- (void)addToInvisibleList:(ICJContact *)theContact;
- (void)removeFromInvisibleList:(ICJContact *)theContact;

- (void)findContactsByUin:(ICQUIN)theUin refCon:(id)object;
- (void)findContactsByEmail:(NSString *)theEmail refCon:(id)object;
- (void)findContactsByName:(NSString *)theNickname firstName:(NSString *)theFirstName lastName:(NSString *)theLastName refCon:(id)object;
- (void)refreshInfoForContact:(ICJContact *)theContact;
- (void)readStatusMessageForContact:(ICJContact *)theContact;
- (void)retrieveUserInfo;

// The following 2 mean only one thing: can we or can we not send messages
- (void)loggedOut;
- (void)loggedIn;

- (void)userStatusChangedTo:(NSString *)statusKey;
- (void)setStatusOfContact:(ICQUIN)theUin toStatusKey:(NSString *)statusKey typingFlags:(TypingFlags)flags;
- (void)disconnected:(ICJDisconnectReason)reason;
- (void)receivedMessage:(id)theMessage;
- (void)messageAcknowledged:(ICQMessage *)theMessage;
- (void)search:(id)theRefCon returnedResult:(NSDictionary *)theResult isLast:(BOOL)isLast;
- (void)serverAddedContact:(ICJContact *)theContact nickname:(NSString *)theNickname;

- (void)userDetailsControllerWillClose:(UserDetailsController *)sender;
- (void)incomingControllerWillClose:(NSWindowController <ICJIncomingMessageDisplay> *)sender;
- (void)historyControllerWillClose:(HistoryWindowController *)sender;
- (void)outgoingControllerWillClose:(OutgoingMessageController *)sender;
- (void)removeContactStatusMessageController:(ContactStatusMessageController *)sender;
- (void)removeIncomingFileController:(IncomingFileController *)sender;
@end
