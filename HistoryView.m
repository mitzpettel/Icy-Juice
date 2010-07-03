/*
 * HistoryView.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 30 2001.
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

#import "HistoryView.h"
#import "ICJHistoryCell.h"
#import "ICJMessage.h"
#import "IcyJuice.h"
#import "ICQFileTransfer.h"

@implementation HistoryView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if ( self )
    {
        NSMutableParagraphStyle		*timeStampParagraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        NSDictionary			*messageAttributes;
        NSDictionary			*timeStampAttributes;
        unichar				seperatorChar = NSCarriageReturnCharacter; //NSParagraphSeparatorCharacter
        
        paragraphStyle = [NSMutableParagraphStyle new];
        
        writingDirection = NSWritingDirectionLeftToRight;
        
        if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 )
            [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
            
        messageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            paragraphStyle ,	NSParagraphStyleAttributeName,
            nil];

        timeStampAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor darkGrayColor],		NSForegroundColorAttributeName,
            [NSFont labelFontOfSize:[NSFont labelFontSize]],
                                                NSFontAttributeName,
            timeStampParagraphStyle ,		NSParagraphStyleAttributeName,
            nil];        

        separatorString = [[NSString stringWithCharacters:&seperatorChar length:1] retain];

        receivedMessageAttributes = [[NSMutableDictionary dictionaryWithDictionary:messageAttributes] retain];
        sentMessageAttributes = [[NSMutableDictionary dictionaryWithDictionary:messageAttributes] retain];
        receivedTimeStampAttributes = [[NSMutableDictionary dictionaryWithDictionary:timeStampAttributes] retain];
        sentTimeStampAttributes = [[NSMutableDictionary dictionaryWithDictionary:timeStampAttributes] retain];

        if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 )
            [timeStampParagraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];

        [self setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor colorWithDeviceRed:1 green:1 blue:0.9 alpha:1],
                                                        ICJIncomingBackgroundAttributeName,
            [NSColor whiteColor],			ICJOutgoingBackgroundAttributeName,
            [NSColor textColor],			ICJIncomingColorAttributeName,
            [NSColor textColor],			ICJOutgoingColorAttributeName,
            [NSFont userFontOfSize:12],			ICJIncomingFontAttributeName,
            [NSFont userFontOfSize:12],			ICJOutgoingFontAttributeName,
            nil
        ]];

        [self setDateFormatter:[[[NSDateFormatter alloc]
            initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSTimeFormatString]
            allowNaturalLanguage:YES
        ] autorelease]];

        [self setEditable:NO];
        [self setSelectable:YES];
        [[self layoutManager] setDelegate:self];

        messageEnds = [[NSMutableArray array] retain];
        timestampEnds = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag
{
    if ( scrollToEnd )
    {
        [self scrollPoint:NSMakePoint(0,[self frame].size.height)];
        scrollToEnd = NO;
    }
}

- (void)setDateFormatter:(NSDateFormatter *)theFormatter
{
    [dateFormatter autorelease];
    dateFormatter = [theFormatter retain];
    [self reloadData];
}

- (void)setAttributes:(NSDictionary *)attributes
{
    NSTextStorage	*textStorage = [self textStorage];
    NSColor		*receivedBackground = [attributes objectForKey:ICJIncomingBackgroundAttributeName];
    NSColor		*sentBackground = [attributes objectForKey:ICJOutgoingBackgroundAttributeName];
    NSColor		*receivedForeground = [attributes objectForKey:ICJIncomingColorAttributeName];
    NSColor		*sentForeground = [attributes objectForKey:ICJOutgoingColorAttributeName];
    NSFont		*receivedFont = [attributes objectForKey:ICJIncomingFontAttributeName];
    NSFont		*sentFont = [attributes objectForKey:ICJOutgoingFontAttributeName];
    int			messageCount = [history count];
    NSRange		messageRange;
    unsigned int	timestampLocation;
    int			i;

    // update attributes dictionaries
    [receivedMessageAttributes setObject:receivedBackground forKey:NSBackgroundColorAttributeName];
    [receivedMessageAttributes setObject:receivedForeground forKey:NSForegroundColorAttributeName];
    [receivedTimeStampAttributes setObject:receivedBackground forKey:NSBackgroundColorAttributeName];
    [receivedMessageAttributes setObject:receivedFont forKey:NSFontAttributeName];
    [sentMessageAttributes setObject:sentBackground forKey:NSBackgroundColorAttributeName];
    [sentMessageAttributes setObject:sentForeground forKey:NSForegroundColorAttributeName];
    [sentTimeStampAttributes setObject:sentBackground forKey:NSBackgroundColorAttributeName];
    [sentMessageAttributes setObject:sentFont forKey:NSFontAttributeName];

    messageRange.location = 0;

    [textStorage beginEditing];

    for ( i = 0; i<messageCount; i++ )
    {
        messageRange.length = [[messageEnds objectAtIndex:i] intValue]-messageRange.location;
        if ([[history objectAtIndex:i] isIncoming])
        {
            [textStorage addAttribute:NSBackgroundColorAttributeName value:receivedBackground range:messageRange];
        }
        else
        {
            [textStorage addAttribute:NSBackgroundColorAttributeName value:sentBackground range:messageRange];
        }
        timestampLocation = [[timestampEnds objectAtIndex:i] intValue];
        messageRange.length += messageRange.location-timestampLocation;
        messageRange.location = timestampLocation;
        if ([[history objectAtIndex:i] isIncoming])
        {
            [textStorage addAttribute:NSForegroundColorAttributeName value:receivedForeground range:messageRange];
            [textStorage addAttribute:NSFontAttributeName value:receivedFont range:messageRange];
        }
        else
        {
            [textStorage addAttribute:NSForegroundColorAttributeName value:sentForeground range:messageRange];
            [textStorage addAttribute:NSFontAttributeName value:sentFont range:messageRange];
        }
        messageRange.location += messageRange.length;
    }
    
    [textStorage endEditing];
}

- (void)dealloc
{
    [timestampEnds release];
    [messageEnds release];
    [sentTimeStampAttributes release];
    [receivedTimeStampAttributes release];
    [sentMessageAttributes release];
    [receivedMessageAttributes release];
    [separatorString release];
    [dateFormatter release];
    [history release];
    [super dealloc];
}

- (NSArray *)history
{
    return history;
}

- (void)setHistory:(NSArray *)theHistory
{
    [history autorelease];
    history = [theHistory retain];
    [self reloadData];
}

- (void)reloadData
{
    [self reloadDataByAppending:NO andScrollToEnd:NO];
}

- (void)reloadDataByAppending:(BOOL)append andScrollToEnd:(BOOL)flag
{
    NSEnumerator	*messageEnumerator;
    ICJMessage		*currentMessage;
    NSTextStorage	*textStorage = [self textStorage];
    NSArray		*messageArray;
    int 		messageCount = [[self history] count];
    
    // determine the messages to process
    if ( append )
        messageArray = [[self history] subarrayWithRange:NSMakeRange(loadedMessageCount,messageCount-loadedMessageCount)];
    else
        messageArray = [self history];

    messageEnumerator = [messageArray objectEnumerator];

    [textStorage beginEditing];

    scrollToEnd = flag;

    if ( !append )
    {
        [textStorage setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
        [messageEnds removeAllObjects];
        [timestampEnds removeAllObjects];
    }
    
    while ( currentMessage = [messageEnumerator nextObject] )
    {
        NSDictionary	*currentTimeStampAttributes;
        NSDictionary	*currentMessageAttributes;
        NSString	*label;

        if ( [currentMessage isIncoming] )
        {
            currentMessageAttributes = receivedMessageAttributes;
            currentTimeStampAttributes = receivedTimeStampAttributes;
        }
        else
        {
            currentMessageAttributes = sentMessageAttributes;
            currentTimeStampAttributes = sentTimeStampAttributes;
        }
        
        if ( [currentMessage isKindOfClass:[ICQAuthReqMessage class]] )
        {
            label = [@" " stringByAppendingString:NSLocalizedString(@"Authorization Request", @"label in history view")];
        }
        else if ( [currentMessage isKindOfClass:[ICQAuthAckMessage class]] )
        {
            if ( [(ICQAuthAckMessage *)currentMessage isGranted] )
                label = [@" " stringByAppendingString:NSLocalizedString(@"Authorization Granted", @"label in history view")];
            else
                label = [@" " stringByAppendingString:NSLocalizedString(@"Authorization Denied", @"label in history view")];
        }
        else if ( [currentMessage isKindOfClass:[ICQUserAddedMessage class]] )
        {
            label = [@" " stringByAppendingString:NSLocalizedString(@"You were added to this user's contact list", @"description in history view")];
        }
        else if ( [currentMessage isKindOfClass:[ICQFileTransferMessage class]] )
        {
            int		i;
            NSArray	*files = [[(ICQFileTransferMessage *)currentMessage fileTransfer] files];
            int		fileCount = [files count];
            
            label = [NSMutableString
                stringWithFormat:@" %@",
                NSLocalizedString( @"File Transfer Request (", @"description in history view, a list of filenames follows" )
            ];
            for ( i = 0; i<fileCount; i++ )
            {
                [(NSMutableString *)label appendString:[[files objectAtIndex:i] lastPathComponent]];
                if ( i<fileCount-1 )
                    [(NSMutableString *)label appendString:NSLocalizedString( @", ", @"separator in list of filenames in history view" )];
            } 
            [(NSMutableString *)label appendString:NSLocalizedString( @")", @"terminator of list of filenames in history view" )];
        }
        else
            label = @"";
            
        [textStorage
            appendAttributedString:[[[NSAttributedString alloc]
                initWithString:[[dateFormatter stringForObjectValue:[currentMessage sentDate]] stringByAppendingString:label]
                attributes:currentTimeStampAttributes
            ] autorelease]
        ];
        
        [textStorage
            appendAttributedString:[[[NSAttributedString alloc]
                initWithString:separatorString
                attributes:currentTimeStampAttributes
            ] autorelease]
        ];
        
        [timestampEnds addObject:[NSNumber numberWithInt:[textStorage length]]];
        
        if ( [currentMessage isKindOfClass:[ICQURLMessage class]] )
        {
            NSMutableDictionary *urlAttributes = [NSMutableDictionary dictionaryWithDictionary:currentMessageAttributes];

            [urlAttributes setObject:[(ICQURLMessage *)currentMessage url]
                              forKey:NSLinkAttributeName];
            [urlAttributes setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle]
                              forKey:NSUnderlineStyleAttributeName];
            [urlAttributes setObject:[NSColor blueColor]
                              forKey:NSForegroundColorAttributeName];

            [textStorage
                appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:NSLocalizedString(@"URL: ", @"")
                    attributes:currentMessageAttributes
                ] autorelease]
            ];
            
            [textStorage
                appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:[(ICQURLMessage *)currentMessage url]
                    attributes:urlAttributes
                ] autorelease]
            ];
            
            [textStorage
                appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:separatorString
                    attributes:/*currentMessageAttributes*/currentTimeStampAttributes
                ] autorelease]
            ];
        }
        else if ( [currentMessage isKindOfClass:[ICQNormalMessage class]] && [(ICQNormalMessage *)currentMessage text] )
        {
            [textStorage
                appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:[(ICQNormalMessage *)currentMessage text]
                    attributes:currentMessageAttributes
                ] autorelease]
            ];
            
            [textStorage
                appendAttributedString:[[[NSAttributedString alloc]
                    initWithString:separatorString
                    attributes:/*currentMessageAttributes*/currentTimeStampAttributes
                ] autorelease]
            ];
        }
        
        [messageEnds addObject:[NSNumber numberWithInt:[textStorage length]]];
    }
    [textStorage endEditing];
    loadedMessageCount = messageCount;
}

- (void)clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

#ifndef NSAppKitVersionNumber10_2
#define NSAppKitVersionNumber10_2 663
#endif
- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSMenu *menu;
    if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 && floor(NSAppKitVersionNumber)<=NSAppKitVersionNumber10_2 )
    {
        menu = [[[super menuForEvent:event] copy] autorelease];
        [menu
            insertItemWithTitle:NSLocalizedString( @"Left to Right", @"writing direction item in contextual menu" )
            action:@selector(toggleBaseWritingDirection:)
            keyEquivalent:@""
            atIndex:0
        ];
        [menu
            insertItemWithTitle:NSLocalizedString( @"Right to Left", @"writing direction item in contextual menu" )
            action:@selector(toggleBaseWritingDirection:)
            keyEquivalent:@""
            atIndex:1
        ];
        [menu insertItem:[NSMenuItem separatorItem] atIndex:2];
    
        if ([self baseWritingDirection]==NSWritingDirectionLeftToRight)
            [[menu itemAtIndex:0] setState:NSOnState];
        else
            [[menu itemAtIndex:1] setState:NSOnState];
    }
    else
        menu = [super menuForEvent:event];
    return menu;
}

- (void)setBaseWritingDirection:(NSWritingDirection)direction
{
    if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 )
    {
        if ( direction!=writingDirection )
        {
            NSTextStorage	*textStorage = [self textStorage];
            
            [textStorage beginEditing];
            
            writingDirection = direction;
            
            [paragraphStyle
                setAlignment:( direction==NSWritingDirectionRightToLeft ? NSRightTextAlignment : NSLeftTextAlignment )];
            [paragraphStyle setBaseWritingDirection:writingDirection];
            
            [textStorage endEditing];
            
            [[self layoutManager]
                textStorage:textStorage
                edited:NSTextStorageEditedAttributes
                range:NSMakeRange(0, [textStorage length])
                changeInLength:0
                invalidatedRange:NSMakeRange(0, [textStorage length])
            ];
        }
    }
}

- (void)toggleBaseWritingDirection:(id)sender
{
    if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_2 || 
        ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 && [(id <NSMenuItem>)sender state]==NSOffState ) )
    {
        if ( [self baseWritingDirection]==NSWritingDirectionLeftToRight )
            [self setBaseWritingDirection:NSWritingDirectionRightToLeft];
        else
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
    }
}

- (NSWritingDirection)baseWritingDirection
{
    return writingDirection;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
{
    if ( [menuItem action]==@selector(toggleBaseWritingDirection:) )
    {
        if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_2 )
            [menuItem setState:( [self baseWritingDirection]==NSWritingDirectionRightToLeft )];
        return YES;
    }
    return [super validateMenuItem:menuItem];
}

@end