/*
 * ContactStatus.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Jun 01 2001.
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

#define ICJOfflineStatusKey		@"offline"
#define ICJAvailableStatusKey		@"available"
#define ICJAwayStatusKey		@"away"
#define ICJDNDStatusKey			@"DND"
#define ICJNAStatusKey			@"N/A"
#define ICJOccupiedStatusKey		@"occupied"
#define ICJFreeForChatStatusKey		@"free for chat"
#define ICJInvisibleStatusKey		@"invisible"
#define ICJPendingAuthorizationStatusKey @"pending authorization"
#define ICJNotOnListStatusKey		@"not on list"

@interface ContactStatus : NSObject {
    NSString		*statusKey;
    NSString		*name;
    NSColor		*color;
    NSImage		*icon;
    NSNumber		*sortOrder;
    NSString		*shortName;
    BOOL		blocksStandardMessages;
}

- (id)initWithKey:(NSString *)theKey name:(NSString *)theName color:(NSColor *)theColor icon:(NSImage *)theIcon sortOrder:(NSNumber *)number shortName:(NSString *)theShortName;
- (NSString *)name;
- (NSColor *)color;
- (NSImage *)icon;
- (NSString *)key;
- (NSNumber *)sortOrder;
- (NSString *)shortName;
- (BOOL)blocksStandardMessages;
- (void)setBlocksStandardMessages:(BOOL)flag;

@end
