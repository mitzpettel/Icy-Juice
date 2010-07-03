/*
 * ContactListView.m
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

#import "ContactListView.h"
#import "ICJStatusIconCell.h"

@implementation ContactListView

- (void)awakeFromNib
{
    [[self tableColumnWithIdentifier:@"status"] setDataCell:[[ICJStatusIconCell new] autorelease]];
    flashingThreadLock = [[NSLock alloc] init];
    initialKeyRepeat = [[[NSUserDefaults standardUserDefaults] objectForKey:@"initialKeyRepeat"] intValue];
    if (initialKeyRepeat==0)
        initialKeyRepeat = 25;
    selectByTypingString = [[NSMutableString string] retain];
}

- (void)dealloc
{
    [selectByTypingString release];
    [flashingThreadLock release];
    [super dealloc];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    [super textDidEndEditing:[NSNotification notificationWithName:[notification name] object:[notification object] userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"]]];
    [[self window] makeFirstResponder:self];
}

- (void)keyDown:(NSEvent *)theEvent
{
    UniChar keyChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if (keyChar==13 || keyChar==3)
    {
        [self sendAction:[self doubleAction] to:[self target]];
        [selectByTypingString setString:@""];
    }
    else if (keyChar>=32 && keyChar<0xF700)
    {
        int matchingRow;
        if ([theEvent timestamp]-lastKeyTime>(initialKeyRepeat/50.0))
            [selectByTypingString setString:[theEvent characters]];
        else
            [selectByTypingString appendString:[theEvent characters]];
        lastKeyTime = [theEvent timestamp];
//        NSLog(@"string: %@ at row: %d", selectByTypingString, [[self dataSource] tableView:self rowWithPrefix:selectByTypingString]);
        matchingRow = [[self dataSource] tableView:self rowWithPrefix:selectByTypingString];
        if (matchingRow!=-1)
        {
            [self selectRow:matchingRow byExtendingSelection:NO];
            [self scrollRowToVisible:matchingRow];
        }
    }
    else
    {
        [selectByTypingString setString:@""];
        [super keyDown:theEvent];
    }
}

- (BOOL)resignFirstResponder
{
    [selectByTypingString setString:@""];
    return [super resignFirstResponder];
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    // If it's the left mouse button, then respond only if it's a ctrl-click (caps lock may be on). If it's something else - respond anyway
    if ([event type]!=NSLeftMouseDown
        || ([event modifierFlags] & 0xffff0000 | NSAlphaShiftKeyMask | NSNumericPadKeyMask) == (NSControlKeyMask | NSAlphaShiftKeyMask | NSNumericPadKeyMask))
    {
        int row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
        if (row!=-1 && ![self isRowSelected:row])
            [self selectRow:row byExtendingSelection:NO];
        return [self menu];
    }
    return nil;
}

// This is a safeguard. The owner of this view should call stopFlashing: anyway
- (void)removeFromSuperviewWithoutNeedingDisplay
{
    [self stopFlashing:nil];
    [super removeFromSuperviewWithoutNeedingDisplay];
}

- (void)startFlashing:(id)sender
{
    if (!isFlashing)
    {
        isFlashing = YES;
        [NSApplication detachDrawingThread:@selector(flash:) toTarget:self withObject:nil];
    }
}

- (void)stopFlashing:(id)sender
{
    if (isFlashing)
    {
        isFlashing = NO;
        [flashingThreadLock lock];
        [flashingThreadLock unlock];
    }
}

- (void)setFlashing:(BOOL)flash
{
    if (flash)
        [self startFlashing:nil];
    else
        [self stopFlashing:nil];
}

- (void)dataWillChange
{
    [flashingThreadLock lock];
}

- (void)dataDidChange
{
    [flashingThreadLock unlock];
    [self reloadData];
}

- (void)flash:(id)object
{
    ICJStatusIconCell *myCell = [[self tableColumnWithIdentifier:@"status"] dataCell];
    NSAutoreleasePool *myPool = [[NSAutoreleasePool alloc] init];
    BOOL alternate = YES;
    while (isFlashing)
    {
        NSAutoreleasePool *loopPool = [NSAutoreleasePool new];
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.5]];
        if ([flashingThreadLock tryLock])
        {
            [myCell setAlternateState:alternate];
            if ([self lockFocusIfCanDraw])
            {
                if ([[self headerView] draggedColumn]==-1)
                {
                    int column = [self columnWithIdentifier:@"status"];
                    NSRect drawRect = NSIntersectionRect([self rectOfColumn:column], [self visibleRect]);
                    NSRange rows = [self rowsInRect:drawRect];
                    int row;
                    int lastRow = rows.location+rows.length;

                    [NSGraphicsContext saveGraphicsState];
                    NSRectClip(drawRect);
                    for (row = rows.location ; row<lastRow; row++)
                    {
                        NSEraseRect([self frameOfCellAtColumn:column row:row]);
                        [self drawRow:row clipRect:drawRect];
                    }
                    [NSGraphicsContext restoreGraphicsState];
                [[self window] flushWindow];
                }
                [self unlockFocus];
            }
            [flashingThreadLock unlock];
        }
        alternate = !alternate;
        [loopPool release];
    }
    [myPool release];
}

@end
