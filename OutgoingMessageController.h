/*
 * OutgoingMessageController.h
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

#import <Cocoa/Cocoa.h>
#import "IcyJuice.h"
#import "ICJMessage.h"

@class ICQUserDocument;
@class ChasingArrowsView;
@class MPStatusBarController;

@interface OutgoingMessageController : NSWindowController
{
    IBOutlet id				messageField;
    
    // recepients drawer
    IBOutlet NSDrawer			*recipientsDrawer;
    IBOutlet id				recipientsView;
    
    // status bar
    IBOutlet MPStatusBarController	*statusBarController;
    IBOutlet ChasingArrowsView		*progressIndicator;
    IBOutlet NSImageView		*statusIcon;
    IBOutlet NSTextField		*statusTextField;
    
    // rejected message sheet
    IBOutlet NSPanel			*rejectMessageSheet;
    IBOutlet NSTextField		*rejectTitleField;
    IBOutlet NSTextField		*rejectDescriptionField;
    IBOutlet NSTextView			*rejectStatusMessageField;
    IBOutlet NSButton			*rejectUrgentButton;

    NSMutableArray			*_recipients;
    ICQUserDocument			*_target;
    BOOL				_needsUpdate;
    BOOL				_sendsToContactList;
    BOOL				_sendsUrgent;
    
    BOOL				_isSending;
    
    NSString				*_statusChangeTimeFormat;
}

// NOTE: this is not NSWindowController's -windowNibName!
- (NSString *)nibName;

- (id)initTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget;
+ (id)outgoingMessageControllerTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget;

- (IBAction)showContactHistory:(id)sender;
- (IBAction)send:(id)sender;
- (IBAction)toggleStatusBarShown:(id)sender;
- (IBAction)focusOnRecipient:(id)sender;
- (IBAction)readStatusMessage:(id)sender;
- (IBAction)removeRecipient:(id)sender;

- (IBAction)rejectCancelClicked:(id)sender;
- (IBAction)rejectResendClicked:(id)sender;

- (ICJContact *)selectedContact;
- (ICQUserDocument *)icqUserDocument;
- (BOOL)canSend;
- (BOOL)isSending;
- (void)setSending:(BOOL)flag;
- (void)setMessageText:(NSString *)text;

- (NSArray *)recipients;
- (ICJContact *)recipient;
- (BOOL)sendsToContactList;
- (BOOL)sendsUrgent;
- (void)setSendsToContactList:(BOOL)flag;
- (void)setSendsUrgent:(BOOL)flag;

- (void)messageAcknowledged:(NSNotification *)theNotification;
- (void)messageDelivered:(ICQMessage *)message;
- (void)messageNotDelivered:(ICQMessage *)message;

- (void)update;
- (BOOL)needsUpdate;
- (void)setNeedsUpdate:(BOOL)flag;
- (void)synchronizeAttributes;

@end
