/*
 * DialogController.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Dec 01 2001.
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

#import <Foundation/Foundation.h>
#import "OutgoingMessageController.h"

@class HistoryView;

@interface DialogController : OutgoingMessageController <ICJIncomingMessageDisplay>
{
    IBOutlet HistoryView	*historyView;
    IBOutlet id			authReqMessageField;
    IBOutlet id			authReqSheet;
    IBOutlet id			addToListButton;
    
    IBOutlet NSPanel		*fileSheet;
    IBOutlet NSTextField	*fileListField;
    IBOutlet NSTextView		*fileMessageView;

    NSMutableArray		*_dialogHistory;
    unsigned int		_unreadMessages;
    NSTimer			*_hideInactiveTimer;
    BOOL			_hideInactiveDisabled;
}

- (IBAction)authorize:(id)sender;
- (IBAction)denyAuthorization:(id)sender;
- (IBAction)ignoreAuthorizationRequest:(id)sender;
- (IBAction)toggleWindowAutoHiding:(id)sender;

- (IBAction)acceptFile:(id)sender;
- (IBAction)saveTo:(id)sender;
- (IBAction)declineFile:(id)sender;

- (BOOL)hideInactiveDisabled;
- (void)setHideInactiveDisabled:(BOOL)flag;
- (void)setInactive:(BOOL)flag;

@end
