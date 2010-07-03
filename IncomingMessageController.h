/*
 * IncomingMessageController.h
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
@class OutgoingMessageController;
@class MPURLTextField;

@interface IncomingMessageController : NSWindowController <ICJIncomingMessageDisplay>
{
    IBOutlet NSTextField	*dateField;
    IBOutlet NSButton		*nextButton;
    NSToolbarItem		*nextToolbarItem;
    IBOutlet NSTextView		*messageField;
    IBOutlet MPURLTextField	*urlField;
    IBOutlet NSTextView		*urlMessageField;
    IBOutlet NSTextView		*authReqMessageField;
    IBOutlet NSTextView		*rejectionReasonField;
    IBOutlet NSTabView		*tabView;
    IBOutlet NSButton		*addToListButton;
    IBOutlet NSTextView		*fileMessageField;
    IBOutlet NSTextField	*fileListField;

    id				currentMessage;
    ICQUserDocument		*target;
    BOOL	isUnread;
    ICJContact	*messageSender;
}

- (IBAction)reply:(id)sender;
- (void)replySent:(NSNotification *)notification;
- (IBAction)goToNext:(id)sender;
- (IBAction)showContactHistory:(id)sender;
- (IBAction)authorize:(id)sender;
- (IBAction)denyAuthorization:(id)sender;
- (IBAction)makeContactPermanent:(id)sender;

- (IBAction)acceptFile:(id)sender;
- (IBAction)saveTo:(id)sender;
- (IBAction)declineFile:(id)sender;

+ (id)incomingMessageController:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget;
- (void)showCurrentMessage;
- (ICJContact *)selectedContact;
- (ICQUserDocument *)icqUserDocument;

@end
