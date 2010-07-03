/*
 * NetworkProblemAlert.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Jan 17 2004.
 *
 * Copyright (c) 2004 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "NetworkProblemAlert.h"


@implementation NetworkProblemAlert

+ (id)problemAlert
{
	return [[[self alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES] autorelease];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag];
	if ( self )
	{
		[NSBundle loadNibNamed:@"NetworkProblemAlert" owner:self];
		[self setContentSize:[view frame].size];
		[self setContentView:view];
	}
	return self;
}

- (IBAction)buttonPressed:(id)sender
{
	[NSApp endSheet:self returnCode:[sender tag]];
}

- (void)sheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)contextInfo
{
	NSInvocation	*invocation = [NSInvocation invocationWithMethodSignature:[_modalDelegate methodSignatureForSelector:_didEndSelector]];
	
	[invocation setTarget:_modalDelegate];
	[invocation setSelector:_didEndSelector];
	[invocation setArgument:&sheet atIndex:2];
	[invocation setArgument:&returnCode atIndex:3];
	[invocation setArgument:&contextInfo atIndex:4];
	[invocation invoke];
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector contextInfo:(void *)contextInfo
{
	_modalDelegate = delegate;
	_didEndSelector = didEndSelector;
	[NSApp beginSheet:self modalForWindow:window modalDelegate:self didEndSelector:@selector(sheet:didEndAndReturned:contextInfo:) contextInfo:contextInfo];
}

- (int)checkboxState
{
	return [checkbox state];
}

@end
