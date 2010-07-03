/*
 * HistoryView.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 30 2001.
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

#define ICJIncomingBackgroundAttributeName		@"IncomingBackgroundAttribute"
#define ICJIncomingColorAttributeName			@"IncomingColorAttribute"
#define ICJIncomingFontAttributeName			@"IncomingFontAttribute"
#define ICJOutgoingBackgroundAttributeName		@"OutgoingBackgroundAttribute"
#define ICJOutgoingColorAttributeName			@"OutgoingColorAttribute"
#define ICJOutgoingFontAttributeName			@"OutgoingFontAttribute"

@interface HistoryView : NSTextView {
    NSArray		*history;
    NSMutableArray	*messageEnds;
    NSMutableArray	*timestampEnds;
    NSDateFormatter	*dateFormatter;
    NSString		*separatorString;
    NSMutableDictionary *receivedMessageAttributes;
    NSMutableDictionary *sentMessageAttributes;
    NSMutableDictionary *receivedTimeStampAttributes;
    NSMutableDictionary *sentTimeStampAttributes;
    BOOL		scrollToEnd;
    int			loadedMessageCount;

    NSWritingDirection	writingDirection;
    NSMutableParagraphStyle	*paragraphStyle;

}

- (NSArray *)history;
- (void)setHistory:(NSArray *)theHistory;
- (void)setDateFormatter:(NSDateFormatter *)theFormatter;
- (void)setAttributes:(NSDictionary *)attributes;
- (void)reloadData;
- (void)reloadDataByAppending:(BOOL)append andScrollToEnd:(BOOL)flag;

- (NSWritingDirection)baseWritingDirection;
- (void)setBaseWritingDirection:(NSWritingDirection)direction;
- (void)toggleBaseWritingDirection:(id)sender;

@end
