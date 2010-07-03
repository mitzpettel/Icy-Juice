/*
 * History.m
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

#import "History.h"
#import "Contact.h"
#import "ContactPlaceholder.h"
#import "ICJMessage.h"

@implementation History

- (id)initWithContact:(ICJContact *)contact path:(NSString *)path
{
    self = [super init];
    if ( self )
    {
        _contact = [contact retain];
        _path = [path retain];
        _unsavedMessages = [[NSMutableArray array] retain];
		_messagesLock = [NSLock new];
		_needsWritingLock = [NSLock new];
		_needsMovingLock = [NSLock new];
    }
    return self;
}

+ (id)historyWithContact:(ICJContact *)contact path:(NSString *)path
{
    return [[[self alloc] initWithContact:contact path:path] autorelease]; 
}

- (void)dealloc
{
    [self quiesce];
    if ( _messages )
    {
        [_messages release];
    }
    [_contact release];
    [_path release];
    [_unsavedMessages release];
	[_messagesLock release];
	[_needsWritingLock release];
	[_needsMovingLock release];
	[_temporaryPath release];
    [super dealloc];
}

- (ICJContact *)contact
{
    return _contact;
}

- (void)setPath:(NSString *)path
{
    [path retain];
    [_path release];
    _path = path;
}

- (NSString *)path
{
    return _path;
}

- (void)appendMessage:(ICJMessage *)message
{
	[_messagesLock lock];
    if ( _messages )
        [_messages addObject:message];
    [_unsavedMessages addObject:message];
	[_messagesLock unlock];
	
    [self schedulePeriodicTask];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ICJHistoryChangedNotification
        object:self
        userInfo:[NSDictionary
            dictionaryWithObject:[NSNumber numberWithBool:YES]
            forKey:ICJHistoryChangeIncrementalKey
        ]
    ];
}

- (void)schedulePeriodicTask
{
    if ( !_periodicTaskIsScheduled )
    {
        [NSTimer
            scheduledTimerWithTimeInterval:60
            target:self			// NSTimer retains its target
            selector:@selector(periodicTask:)
            userInfo:nil
            repeats:NO
        ];
        _periodicTaskIsScheduled = YES;
    }
}

- (void)periodicTask:(NSTimer *)timer
{
    _periodicTaskIsScheduled = NO;

	[self saveMessages];
	[_messagesLock lock];
	if ( [_unsavedMessages count]==0 && _messages && [_messages retainCount]==1 )
	{
		[_messages release];
		_messages = nil;
	}
	if ( _messages )
		[self schedulePeriodicTask];
	[_messagesLock unlock];
}

- (NSArray *)messages
{
    NSUnarchiver	*unarchiver;
    NSData			*fileData;
    
	[_messagesLock lock];
    if ( _messages==nil )
	{
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:[self path]] )
		{
			_messages = [NSMutableArray array];
		}
		else
		{
			fileData = [NSData dataWithContentsOfMappedFile:[self path]];
			unarchiver = [[[NSUnarchiver alloc] autorelease]
				initForReadingWithData:fileData
			];
			[ContactPlaceholder setReplacement:[self contact]];
			_messages = [unarchiver decodeObject];
		}
		[_messages addObjectsFromArray:_unsavedMessages];
		[self schedulePeriodicTask];
		[_messages retain];
	}
	[_messagesLock unlock];
    return _messages;
}

// after quiesce we promise to be quiet until the next append or clear (or deallocation)
- (void)quiesce
{
	[_needsWritingLock lock];
	// now _needsWriting is necessarily NO and nobody is touching _unsavedMessages
	if ( [_unsavedMessages count]!=0 )
	{
		[self messages];
		_needsWriting = YES;
	}
	[_needsWritingLock unlock];
	[self writeMessages:_messages];
	[self moveTempToPath:nil];
}

- (void)moveTempToPath:(id)ignore
{
	[_needsMovingLock lock];
	if ( _needsMoving )
	{

		NSString	*backupPath = [[[[self path]
					stringByDeletingPathExtension
				] stringByAppendingString:@"~"
			] stringByAppendingPathExtension:[[self path] pathExtension]
		];
    
		[[NSFileManager defaultManager]
			movePath:[self path]
			toPath:backupPath
			handler:nil
		];
		
		[[NSFileManager defaultManager]
			movePath:_temporaryPath
			toPath:[self path]
			handler:nil
		];

		[[NSFileManager defaultManager]
			removeFileAtPath:backupPath
			handler:nil
		];
		_needsMoving = NO;
	}
	[_needsMovingLock unlock];
}

- (void)writeMessages:(NSArray *)messageArray
{
	NSAutoreleasePool   *pool = [NSAutoreleasePool new];
	NSString			*basePath = [NSTemporaryDirectory()
		stringByAppendingPathComponent:[[[self contact] uinKey] stringValue]
	];
	int					repeat = 0;

	[_needsWritingLock lock];
	if ( _needsWriting )
	{
		[_needsMovingLock lock];
		[_temporaryPath release];
		_temporaryPath = basePath;
		while ( [[NSFileManager defaultManager] fileExistsAtPath:_temporaryPath] )
		{
			repeat++;
			_temporaryPath = [basePath stringByAppendingPathExtension:[NSString stringWithFormat:@"%d", repeat]];
		}
		[_temporaryPath retain];
		[_messagesLock lock];
		if ( [messageArray count]!=0 )
			[NSArchiver archiveRootObject:messageArray toFile:_temporaryPath];
		else
			[[NSFileManager defaultManager] removeFileAtPath:_temporaryPath handler:nil];
		[_unsavedMessages removeAllObjects];
		[_messagesLock unlock];
		
		_needsMoving = YES;
		[_needsMovingLock unlock];
		
		_needsWriting = NO;
		
		[self performSelectorOnMainThread:@selector(moveTempToPath:) withObject:nil waitUntilDone:NO];
	}
	[_needsWritingLock unlock];
	[pool release];
}

- (void)saveMessages
{
	[_needsWritingLock lock];
	// now _needsWriting is necessarily NO and nobody is touching _unsavedMessages
	if ( [_unsavedMessages count]!=0 )
	{
		[self messages];
		_needsWriting = YES;
	}
	[_needsWritingLock unlock];
	if ( _needsWriting )
		[NSThread detachNewThreadSelector:@selector(writeMessages:) toTarget:self withObject:_messages];
}

- (NSArray *)messagesFromDate:(NSCalendarDate *)fromDate through:(NSCalendarDate *)throughDate
{
    int 	first = 0;
    NSArray	*messages = [self messages];
    int 	last = [messages count]-1;
    
    if ( fromDate )
    {
        while (
            first<=last
            && [[[messages objectAtIndex:first] sentDate] compare:fromDate]==NSOrderedAscending
            )
            first++;
    }
    
    if ( throughDate )
    {
        NSDate	*toDate = [throughDate dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
        while (
            last>=first
            && [[[messages objectAtIndex:last] sentDate] compare:toDate]==NSOrderedDescending
            )
            last--;
    }
    if ( first>last )
        return [NSArray array];
    else
        return [messages subarrayWithRange:NSMakeRange(first, last-first+1)];
}

- (void)clearMessagesSentBefore:(NSDate *)uptoDate
{
    NSMutableArray	*messageArray = (NSMutableArray *)[self messages];
    int			last = [messageArray count]-1;
    
    if ( uptoDate )
    {
        while (
            last>=0
            && [[[messageArray objectAtIndex:last] sentDate] compare:uptoDate]==NSOrderedDescending
            )
            last--;
    }
    
	[_messagesLock lock];
    [messageArray removeObjectsInRange:NSMakeRange(0, last+1)];
	[_messagesLock unlock];

	[_needsWritingLock lock];
	_needsWriting = YES;
	[_needsWritingLock unlock];
	[NSThread detachNewThreadSelector:@selector(writeMessages:) toTarget:self withObject:_messages];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ICJHistoryChangedNotification
        object:self
        userInfo:[NSDictionary
            dictionaryWithObject:[NSNumber numberWithBool:NO]
            forKey:ICJHistoryChangeIncrementalKey
        ]
    ];
}


@end