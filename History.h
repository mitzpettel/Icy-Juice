/*
 * History.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed Nov 19 2003.
 *
 * Copyright (c) 2003-2004 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#define	ICJHistoryChangedNotification	@"ICJHistoryChangedNotification"
#define ICJHistoryChangeIncrementalKey	@"incremental"

@class ICJContact;
@class ICJMessage;

@interface History : NSObject {
    NSString		*_path;
    ICJContact		*_contact;
	
    NSMutableArray	*_messages;
    NSMutableArray	*_unsavedMessages;
	NSLock		*_messagesLock;
	
    BOOL		_periodicTaskIsScheduled;
	
	NSString	*_temporaryPath;
	BOOL		_needsWriting;
	NSLock		*_needsWritingLock;
	BOOL		_needsMoving;
	NSLock		*_needsMovingLock;
}

- (id)initWithContact:(ICJContact *)contact path:(NSString *)path;
+ (id)historyWithContact:(ICJContact *)contact path:(NSString *)path;

- (ICJContact *)contact;
- (void)setPath:(NSString *)path;
- (NSString *)path;

- (void)appendMessage:(ICJMessage *)message;
- (void)clearMessagesSentBefore:(NSDate *)uptoDate;
- (NSArray *)messages;
- (NSArray *)messagesFromDate:(NSCalendarDate *)fromDate through:(NSCalendarDate *)throughDate;

- (void)writeMessages:(NSArray *)messageArray;
- (void)quiesce;
- (void)saveMessages;
- (void)schedulePeriodicTask;
- (void)periodicTask:(NSTimer *)timer;

@end