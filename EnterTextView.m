/*
 * EnterTextView.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 16 2001.
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

#import "EnterTextView.h"


@implementation EnterTextView
/*
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if ([[NSUserDefaults standardUserDefaults] integerForKey:ICJSendMessageKeyUserDefault] == ICJCmdReturnKey
        && [[theEvent charactersIgnoringModifiers] characterAtIndex:0]==13)
    {
        [self doCommandBySelector:@selector(defaultButtonAction:)];
        return YES;
    }
    else
        return [super performKeyEquivalent:theEvent];
}
*/
- (void)keyDown:(NSEvent *)theEvent
{
    NSString *chars = [theEvent charactersIgnoringModifiers];
    if ([chars length]>0 && (([chars characterAtIndex:0]==3 && [[NSUserDefaults standardUserDefaults] integerForKey:ICJSendMessageKeyUserDefault]==ICJEnterKey)
        || ([chars characterAtIndex:0]==13 && [[NSUserDefaults standardUserDefaults] integerForKey:ICJSendMessageKeyUserDefault]==ICJReturnKey)))
    {
        [self doCommandBySelector:@selector(defaultButtonAction:)];
    }
    else
        [super keyDown:theEvent];
}

- (void)awakeFromNib
{
    paragraphStyle = [NSMutableParagraphStyle new];
    writingDirection = NSWritingDirectionLeftToRight;
    if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 )
        [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [self setTypingAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            paragraphStyle, NSParagraphStyleAttributeName,
            nil]];
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
            insertItemWithTitle:NSLocalizedString( @"Left_to_Right", @"writing direction item in contextual menu" )
            action:@selector(toggleBaseWritingDirection:)
            keyEquivalent:@""
            atIndex:0
        ];
        [menu
            insertItemWithTitle:NSLocalizedString( @"Right_to_Left", @"writing direction item in contextual menu" )
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
        if (direction!=writingDirection)
        {
            NSTextStorage *textStorage = [self textStorage];
            [textStorage beginEditing];
            writingDirection = direction;
            [paragraphStyle setAlignment:
                (direction==NSWritingDirectionRightToLeft ? NSRightTextAlignment : NSLeftTextAlignment)];
            [paragraphStyle setBaseWritingDirection:writingDirection];
            [textStorage endEditing];
            [[self layoutManager] textStorage:textStorage edited:NSTextStorageEditedAttributes range:NSMakeRange(0, [textStorage length]) changeInLength:0 invalidatedRange:NSMakeRange(0, [textStorage length])];
        }
    }
}

- (void)toggleBaseWritingDirection:(id)sender
{
    if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_2 || 
        ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 && [sender state]==NSOffState ) )
    {
        if ([self baseWritingDirection]==NSWritingDirectionLeftToRight)
            [self setBaseWritingDirection:NSWritingDirectionRightToLeft];
        else
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
    }
}

- (NSWritingDirection)baseWritingDirection
{
    return writingDirection;
}

@end
