/*
 * ICQConnection.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Jun 01 2001.
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

#import <Foundation/Foundation.h>
#import "IcyJuice.h"
#import "Contact.h"
#import "ICJMessage.h"

@class ICQUserDocument;
#ifdef CLIENT_H
class icq2000Glue;
#else
@class icq2000Glue;
#endif

@interface ICQConnection : NSObject {
    BOOL			isLoggedIn;
    ICQUserDocument		*target;
#ifdef CLIENT_H
    ICQ2000::Client		*myClient;
#else
    void			*myClient;
#endif
    icq2000Glue			*_glue;
    NSTimer			*routineTaskTimer;
    NSDate			*lastPollTime;
    NSArray			*socketArrays;
    NSMutableDictionary		*messagesPendingAck;
    NSMutableDictionary		*searchesPendingResult;
}

+ (id)connectionWithUIN:(ICQUIN)theUin password:(NSString *)thePassword nickname:(NSString *)theNickname target:(ICQUserDocument *)theTarget contactList:(NSArray *)theContactList;
- (id)initWithUIN:(ICQUIN)theUin password:(NSString *)thePassword nickname:(NSString *)theNickname target:(ICQUserDocument *)theTarget contactList:(NSArray *)theContactList;

- (void)routineTask:(NSTimer *)timer;
- (void)terminateAndRelease;

// contact list
- (void)addContact:(ICJContact *)theContact;
- (void)deleteContact:(ICJContact *)theContact;
- (void)addVisible:(ICJContact *)theContact;
- (void)removeVisible:(ICJContact *)theContact;
- (void)addInvisible:(ICJContact *)theContact;
- (void)removeInvisible:(ICJContact *)theContact;

// sending messages
- (void)sendMessage:(id)theMessage;

// connection and user status
- (BOOL)isLoggedIn;

- (void)setWebAware:(BOOL)flag;
- (BOOL)isWebAware;

- (void)setStatus:(NSString *)statusKey;

- (void)uploadDetails:(NSDictionary *)details;
- (void)retrieveUserInfo;

- (void)setPassword:(NSString *)thePassword;

// contact info
- (void)refreshInfoForContact:(ICJContact *)theContact;

// find
- (void)findContactsByUin:(ICQUIN)theUin refCon:(id)object;
- (void)findContactsByEmail:(NSString *)theEmail refCon:(id)object;
- (void)findContactsByName:(NSString *)theNickname firstName:(NSString *)theFirstName lastName:(NSString *)theLastName refCon:(id)object;

// SBL
- (void)requestServerBasedList;

#ifdef CLIENT_H
/* ---- library callbacks ---- */
// contacts
- (void)contact:(ICQUIN)theUin statusChangedTo:(ICQ2000::Status)theStatusCode invisible:(BOOL)flag typingFlags:(TypingFlags)flags;
- (void)contact:(ICQUIN)theUin detailsChangedTo:(NSDictionary *)details;
- (ICJContact *)contactWithLibContact:(ICQ2000::ContactRef)c2k;

// connection and user status
- (void)loggedIn;
- (void)disconnected:(ICJDisconnectReason)reason;
- (void)userStatusCodeChangedTo:(ICQ2000::Status)theStatusCode invisible:(BOOL)invisible;
- (void)userInfoChangedTo:(NSDictionary *)details;

// sockects
- (void)addSocket:(int)theSocket toArrayIndex:(int)theSocketArrayIndex;
- (void)removeSocket:(int)theSocket fromArrayIndex:(int)theSocketArrayIndex;

// messages and acknowledgements
- (void)receivedMessage:(id)message;
- (void)messageAcknowledged:(NSData *)messageEvent finished:(BOOL)isFinished delivered:(BOOL)wasDelivered failureReason:(ICJDeliveryFailureReason)reason awayMessage:(NSString *)theAwayMessage;

// find
- (void)searchResult:(ICJContact *)contact authorizationRequired:(BOOL)authReq last:(BOOL)isLast resultEvent:(NSData *)theResultEvent;

// SBL
- (void)serverAddedContact:(ICJContact *)theContact nickname:(NSString *)theNickname;

// misc
- (const char *)statusMessageForUIN:(ICQUIN)theUin;
- (CFStringEncoding)textEncodingForUin:(ICQUIN)theUin;
#endif

@end
