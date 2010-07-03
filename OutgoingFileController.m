/*
 * OutgoingFileController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Jun 21 2003.
 *
 * Copyright (c) 2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "OutgoingFileController.h"
#import "ICJMessage.h"
#import "ICQUserDocument.h"
#import "ICQFileTransfer.h"

@implementation OutgoingFileController

- (id)initTo:(NSMutableArray *)theRecipients forDocument:(ICQUserDocument *)theTarget
{
    self = [super initTo:theRecipients forDocument:theTarget];
    
    _files = [[NSMutableArray array] retain];
    
    return self;
}

- (void)dealloc
{
    [_fileTransfer release];
    [_files release];
    [progressBar release];
    [super dealloc];
}

- (IBAction)send:(id)sender
{
    ICQFileTransferMessage	*message = [[[ICQFileTransferMessage alloc]
        initIncoming:NO
        date:[NSDate date]
        owners:[self recipients]
    ] autorelease];
    
    if ( _fileTransfer )
        [_fileTransfer release];
    _fileTransfer = [ICQFileTransfer new];
    
    [_fileTransfer setFiles:[self files]];

    [message setText:[messageField string]];
    [message setFileTransfer:_fileTransfer];

    [self setSending:YES];
    [progressBar setMaxValue:[_fileTransfer size]];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(messageAcknowledged:)
        name:ICJMessageAcknowledgedNotification
        object:message
    ];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(transferUpdated:)
        name:ICJFileTransferUpdatedNotification
        object:_fileTransfer
    ];
    _canceling = NO;
    [[self icqUserDocument] sendMessage:message];
}

- (NSString *)nibName
{
    return @"OutgoingFile";
}

- (NSString *)windowTitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"File Transfer to %@", @""),[[self recipient] displayName]];
}

- (void)setProgressBarVisible:(BOOL)flag
{
    BOOL	isVisible = ( [progressBar superview]!=nil );
    
    if ( isVisible==flag )
        return;
    if ( flag )
    {
        NSSize		containerSize = [progressBarContainer frame].size;
        NSSize		barSize = [progressBar frame].size;
        
        barSize.width = containerSize.width-_progressBarRightMargin;
        [progressBar setFrameSize:barSize];
        [progressBarContainer addSubview:progressBar];
    }
    else
        [progressBar removeFromSuperview];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    _progressBarRightMargin = [progressBarContainer frame].size.width - [progressBar frame].size.width;
    [progressBar retain];
    [progressBar removeFromSuperviewWithoutNeedingDisplay];
    [filesTable
        registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
    ];
    [filesTable reloadData];
}

- (NSMutableArray *)files
{
    return _files;
}

- (void)messageNotDelivered:(ICQMessage *)message
{
}

- (void)messageDelivered:(ICQMessage *)message
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ICJOutGoingMessageSentNotification
        object:self
    ];
}

- (void)messageAcknowledged:(NSNotification *)theNotification
{
    ICQMessage		*message = [theNotification object];
    
    if ( [message isFinished] )
    {
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJMessageAcknowledgedNotification
            object:message
        ];
        
        if ( [message isDelivered] )
            [self messageDelivered:message];
        else
        {
            [self messageNotDelivered:message];
        }
        [self update];
    }
}

- (void)transferUpdated:(NSNotification *)theNotification
{
    ICQFileTransfer	*transfer = [theNotification object];
    ICJFTState		state = [transfer state];

    if ( state==FTAccepted )
    {
        [progressBar setIndeterminate:NO];
        [progressBar setDoubleValue:0];
        [self startProgressTimer];
    }
    else if ( state==FTWaitingForResponse )
    {
        [progressBar setIndeterminate:YES];
        [progressBar startAnimation:nil];
        [self setProgressBarVisible:YES];
    }
    else if ( state==FTSend )
    {
    }
    else
    {
        [self setProgressBarVisible:NO];
        [progressBar setIndeterminate:NO];
        [self stopProgressTimer];
/*
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:ICJMessageAcknowledgedNotification
            object:message
        ];
*/
        [self setSending:NO];

        if ( state==FTComplete || ( state==FTNotConnected && _canceling ) )
        {
            [[self window] close];
//            [self messageDelivered:message];
        }
        else if ( state==FTRejected )
        {
            NSBeginAlertSheet(
                NSLocalizedString( @"Declined", @"file transfer rejection title" ), 
                NSLocalizedString( @"OK", @"" ),
                nil,
                nil,
                [self window],
                self,
                nil, // didEndSelector
                nil,
                nil,
                NSLocalizedString( @"The file transfer request was declined.", @"file transfer rejection message" )
            );
        }
        else if ( state==FTError )
        {
            NSBeginAlertSheet(
                NSLocalizedString( @"Error", @"file transfer error title" ), 
                NSLocalizedString( @"OK", @"" ),
                nil,
                nil,
                [self window],
                self,
                nil, // didEndSelector
                nil,
                nil,
                NSLocalizedString(
                    @"The file transfer failed due to an error.",
                    @"file transfer error message"
                )
            );
        }
        else if ( state==FTTimeout )
	{
            NSBeginAlertSheet(
                NSLocalizedString( @"Timed out", @"file transfer error title" ), 
                NSLocalizedString( @"OK", @"" ),
                nil,
                nil,
                [self window],
                self,
                nil, // didEndSelector
                nil,
                nil,
                NSLocalizedString(
                    @"The file transfer request timed out.",
                    @"file transfer time out message"
                )
            );
        }
        else if ( state==FTCanceled && !_canceling )
        {
            NSBeginAlertSheet(
                NSLocalizedString( @"Canceled", @"file transfer cancellation title" ), 
                NSLocalizedString( @"OK", @"" ),
                nil,
                nil,
                [self window],
                self,
                nil, // didEndSelector
                nil,
                nil,
                NSLocalizedString( @"The file transfer was canceled.", @"file transfer cancellation message" )
            );
        }
    }
}

- (void)addFilesFromArray:(NSArray *)array
{
    NSEnumerator	*fileEnumerator = [array objectEnumerator];
    NSString		*file;
    
    while ( file = [fileEnumerator nextObject] )
        if ( ![[self files] containsObject:file] )
            [[self files] addObject:file];

    [filesTable reloadData];
    [self update];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if ( returnCode==NSOKButton )
    {
        [self addFilesFromArray:[sheet filenames]];
    }
}

- (IBAction)addFiles:(id)sender
{
    NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
    
    [openPanel
        setPrompt:NSLocalizedString( @"Select", @"prompt in file transfer file selection panel" )
    ];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel
        beginSheetForDirectory:nil
        file:nil
        types:nil
        modalForWindow:[self window]
        modalDelegate:self
        didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil
    ];
}

- (IBAction)removeFiles:(id)sender
{
    int		row = [filesTable selectedRow];
    
    if ( row!=-1 )
    {
        [[self files] removeObjectAtIndex:row];
        [filesTable reloadData];
        [self update];
    }
}

- (BOOL)canSend
{
    return (
        [[self icqUserDocument] isLoggedIn]
        && ![[[self recipient] statusKey] isEqual:ICJOfflineStatusKey]
        && [[self files] count]>0
        && ![self isSending]
    );
}

- (void)setupToolbar
{
}

- (void)updateProgressBar:(NSTimer *)timer
{
    [progressBar setDoubleValue:[_fileTransfer position]];
}

- (void)startProgressTimer
{
    if ( !_progressTimer )
        _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateProgressBar:) userInfo:nil repeats:YES];
}

- (void)stopProgressTimer
{
    [_progressTimer invalidate];
    _progressTimer = nil;
}

- (void)update
{
    NSEnumerator	*fileEnumerator;
    NSString		*file;
    unsigned long	size;
    
    [sendButton setEnabled:[self canSend]];
    [addButton setEnabled:![self isSending]];
    [removeButton setEnabled:( ![self isSending] && [filesTable selectedRow]!=-1 )];
    
    size = 0;
    fileEnumerator = [[self files] objectEnumerator];
    while ( file = [fileEnumerator nextObject] )
        size += [[[NSFileManager defaultManager] 
            fileAttributesAtPath:file
            traverseLink:YES
        ] fileSize];

    [sizeTextField setStringValue:( size==0 ?
        @""
        : ( size<1024 ?
            [NSString stringWithFormat:NSLocalizedString( @"%d bytes", @"" ), size]
            : ( size<1024*1024 ? 
                [NSString stringWithFormat:NSLocalizedString( @"%d KB", @"" ), size/1024]
                : [NSString stringWithFormat:NSLocalizedString( @"%d MB", @"" ), size/1024/1024]
            )
        )
    )];
    [super update];
}

- (void)abortSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if ( returnCode==NSAlertDefaultReturn && [self isSending] )
    {
        _canceling = YES;
        [_fileTransfer cancel];
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    if ( [self isSending] )
    {
        NSBeginAlertSheet(
            NSLocalizedString( @"Do you want to stop the file transfer?", @"" ),
            NSLocalizedString( @"Stop", @"stop file transfer button" ),
            NSLocalizedString( @"Cancel", @"" ),
            nil,
            [self window],
            self,
            @selector(abortSheetDidEnd:returnCode:contextInfo:),
            nil,
            nil,
            @""
        );
        return NO;
    }
    return YES;
}

- (void)windowWillClose:(id)sender
{
    if ( [self isSending] )
    {
        _canceling = YES;
//        [[self icqUserDocument] cancelFileTransfer:_message];
    }
    [super windowWillClose:sender];
}

// NSObject(NSTableDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self files] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return [[NSFileManager defaultManager]
        displayNameAtPath:[[self files] objectAtIndex:row]
    ];
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSEnumerator	*pathEnumerator;
    NSString		*path;
    NSDragOperation	result = NSDragOperationEvery;
    BOOL		isDir;
    NSFileManager	*fileManager = [NSFileManager defaultManager];
    
    pathEnumerator = [[[info draggingPasteboard]
        propertyListForType:NSFilenamesPboardType
    ] objectEnumerator];
    
    while ( result!=NSDragOperationNone && (path = [pathEnumerator nextObject]) )
    {
        if ( ![fileManager fileExistsAtPath:path isDirectory:(&isDir)] || isDir )
            result = NSDragOperationNone;
    }
        
    if ( result!=NSDragOperationNone )
        [tv setDropRow:-1 dropOperation:NSTableViewDropOn];

    return result;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    [self
        addFilesFromArray:[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType]
    ];
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [removeButton setEnabled:[filesTable selectedRow]!=-1];
}

@end