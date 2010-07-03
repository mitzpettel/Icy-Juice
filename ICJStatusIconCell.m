/*
 * ICJStatusIconCell.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 23 2001.
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

#import "ICJStatusIconCell.h"
#import "Contact.h"

static NSImage *messageImage;

@implementation ICJStatusIconCell

+ (void)initialize
{
    messageImage = [NSImage imageNamed:@"message.tiff"];
}

- (id)init
{
    self = [super initImageCell:nil];
    alternate = NO;
    opacity = 1;
    return self;
}

- (void)dealloc
{
    [value release];
    [super dealloc];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    ICJContact *contact = [self objectValue];
    NSImage *icon;
    double drawingOpacity;
    if (!alternate || ![contact hasMessageQueue])
    {
        icon = [[contact status] icon];
        drawingOpacity = opacity;
    }
    else
    {
        icon = messageImage;
        drawingOpacity = 1;
    }
    if ([controlView isFlipped])
        cellFrame.origin.y += [icon size].height;
    [icon compositeToPoint:cellFrame.origin operation:NSCompositeSourceOver fraction:drawingOpacity];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[ICJStatusIconCell allocWithZone:zone] init];
    [copy setAlternateState:alternate];
    [copy setObjectValue:value];
    [copy setOpacity:opacity];
    return copy;
}

- (void)setOpacity:(double)fraction
{
    opacity = fraction;
}

- (void)setAlternateState:(BOOL)isAlternate
{
    alternate = isAlternate;
}

- (void)setObjectValue:(id)theValue
{
    [value autorelease];
    value = [theValue retain];
//    [super setObjectValue:[imageArray objectAtIndex:(alternate ? ([imageArray count]-1) : 0)]];
}

- (id)objectValue
{
    return value;
}

@end