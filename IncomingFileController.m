/*
 * IncomingFileController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 14 2003.
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

#import "IncomingFileController.h"
#import "ICQFileTransfer.h"
#import "ICJMessage.h"

@implementation IncomingFileController

- (id)initWithMessage:(ICQFileTransferMessage *)message forDocument:(ICQUserDocument *)document promptForDestination:(BOOL)prompt
{
    self = [super initWithWindowNibName:@"IncomingFile"];

    _message = [message retain];
    _fileTransfer = [_message fileTransfer];
    _icqUserDocument = document;
    [self setDirectory:[_icqUserDocument settingWithName:ICJFilesDirectorySettingName]];
    [_fileTransfer setDelegate:self];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(fileTransferUpdated:)
        name:ICJFileTransferUpdatedNotification
        object:_fileTransfer
    ];
    
    if ( !prompt )
    {
        BOOL	isDirectory;
        BOOL	exists;
        
        exists = [[NSFileManager defaultManager]
            fileExistsAtPath:[self directory]
            isDirectory:&isDirectory
        ];
        if ( !exists || !isDirectory )
            prompt = YES;
    }
    if ( prompt )
    {
        NSOpenPanel	*panel = [NSOpenPanel openPanel];
        
        [panel setCanChooseFiles:NO];
        [panel setCanChooseDirectories:YES];
        [panel setPrompt:NSLocalizedString( @"Select", @"prompt for destination folder selection panel" )];
        [self showWindow:nil];
        [panel
            beginSheetForDirectory:[self directory]
            file:nil
            types:nil
            modalForWindow:[self window]
            modalDelegate:self 
            didEndSelector:@selector(chooseDirectoryPanel:endedWithReturnCode:contextInfo:)
            contextInfo:nil
        ];
    }
    else
    {
        [self window];
        [_fileTransfer accept];
    }
    return self;
}

- (void)chooseDirectoryPanel:(NSOpenPanel *)panel endedWithReturnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [panel orderOut:nil];
    if ( returnCode==NSOKButton )
    {
        [self setDirectory:[panel filename]];
        [_fileTransfer accept];
    }
    else
    {
        [_fileTransfer decline];
        [self close];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_directory release];
    [_fileTransfer setDelegate:nil];
    [_message release];
    [super dealloc];
}

+ (id)incomingFileControllerWithMessage:(ICQFileTransferMessage *)message forDocument:(ICQUserDocument *)document promptForDestination:(BOOL)prompt
{
    return [[[self alloc] initWithMessage:message forDocument:document promptForDestination:prompt] autorelease];
}

- (void)windowDidLoad
{
    unsigned long	size;
    
    [super windowDidLoad];
    
    size = [_fileTransfer size];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:nil];
    [progressBar setMaxValue:size];
	[skipButton setEnabled:NO];
    [totalSizeTextField setStringValue:[NSString stringWithByteSize:size]];
    [infoTextField
        setStringValue:[NSString
            stringWithFormat:NSLocalizedString(
                @"File transfer from %@",
                @"parameter is sender's name"
            ),
            [[_message sender] displayName]
        ]
    ];
    [filenameTextField setStringValue:NSLocalizedString( @"Waiting...", @"incoming file transfer starting" )];
}

- (void)abendSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [[self window] close];
}

- (IBAction)goToFolder:(id)sender
{
    [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:[self directory]];
    [self close];
}

- (void)fileTransferUpdated:(NSNotification *)notification
{
    ICJFTState		state = [_fileTransfer state];

    if ( state==FTReceive )
    {
        [progressBar setIndeterminate:NO];
        [progressBar setDoubleValue:0];
        [self startProgressTimer];
    }
    else if ( state==FTComplete )
    {
        [self stopProgressTimer];
        [progressBar removeFromSuperview];
        [fileIconView removeFromSuperview];
        [totalSizeTextField setStringValue:@""];
        [filenameTextField setStringValue:@""];
        [infoTextField
            setStringValue:[NSString
                stringWithFormat:NSLocalizedString(
                    @"Received %@ from %@",
                    @"incoming file transfer. first parameter is '1 file' or 'n files', second parameter is sender's name"
                ),
                ( [_fileTransfer fileCount]==1 ?
                    NSLocalizedString( @"1 file", @"" )
                :
                    [NSString
                        stringWithFormat:NSLocalizedString( @"%d files", @"" ),
                        [_fileTransfer fileCount]
                    ]
                ),
                [[_message sender] displayName]
            ]
        ];
        [skipButton setEnabled:NO];
        [stopButton setTitle:NSLocalizedString(
            @"Close",
            @"button on incoming file transfer window after transfer is complete"
        )];
        [goToFolderButton setEnabled:YES];
    }
    else if ( state==FTCanceled && !_canceling )
    {
        if ([[self window] attachedSheet])
            [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
        NSBeginAlertSheet(
            NSLocalizedString( @"Canceled", @"file transfer cancelation title" ),
            NSLocalizedString( @"OK", @"" ),
            nil,
            nil,
            [self window],
            self,
            @selector(abendSheetDidEnd:returnCode:contextInfo:),
            nil,
            nil,
            [NSString
                stringWithFormat:NSLocalizedString(
                    @"The file transfer was canceled by %@.",
                    @"file transfer cancellation message. parameter is sender's name"
                ),
                [[_message sender] displayName]
            ]
        );
    }
    else if ( state==FTError && !_canceling )
    {
        if ([[self window] attachedSheet])
            [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
        NSBeginAlertSheet(
            NSLocalizedString( @"Error", @"file transfer error title" ), 
            NSLocalizedString( @"OK", @"" ),
            nil,
            nil,
            [self window],
            self,
            @selector(abendSheetDidEnd:returnCode:contextInfo:),
            nil,
            nil,
            NSLocalizedString(
                @"The file transfer failed due to an error.",
                @"file transfer error message"
            )
        );
    }
/*
    else if ( state==FTTimeout )
    {
        NSBeginAlertSheet(
            NSLocalizedString( @"Timed out", @"file transfer error title" ), 
            NSLocalizedString( @"OK", @"" ),
            nil,
            nil,
            [self window],
            self,
            @selector(abendSheetDidEnd:returnCode:contextInfo:),
            nil,
            nil,
            NSLocalizedString(
                @"The file transfer request timed out.",
                @"file transfer time out message"
            )
        );
    }
*/
}

- (ICQFileTransfer *)fileTransfer
{
    return _fileTransfer;
}

- (ICQUserDocument *)icqUserDocument
{
    return _icqUserDocument;
}

- (NSString *)directory
{
    return _directory;
}

- (void)setDirectory:(NSString *)directory
{
    [_directory autorelease];
    _directory = [directory copy];
}

- (void)nameConflictSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode destination:(NSString *)destination
{
    [destination autorelease];
    switch( returnCode )
    {
        case ICJParentWindowClosing:
            break;
        case NSAlertDefaultReturn:	// replace
            [self updateFileInfo:destination];
            [_fileTransfer receiveFile:destination];
            break;
        case NSAlertAlternateReturn:	// skip
            [_fileTransfer skipFile];
            break;
        default:			// save as...
            {
                NSSavePanel	*savePanel = [NSSavePanel savePanel];
                int		returnCode;

/*
                [(NSButton *)[[savePanel contentView] viewWithTag:NSFileHandlingPanelCancelButton]
                    setTitle:NSLocalizedString( @"Skip", @"cancel button in save file as panel" )
                ];
*/
                returnCode = [savePanel runModalForDirectory:[self directory] file:[destination lastPathComponent]];
                if ( returnCode==NSFileHandlingPanelOKButton )
                {
                    [[NSFileManager defaultManager] createFileAtPath:[savePanel filename] contents:nil attributes:nil];
                    [self updateFileInfo:[savePanel filename]];
                    [_fileTransfer receiveFile:[savePanel filename]];
                }
                else
                    [_fileTransfer skipFile];
            }
            break;
    }
}

- (void)updateProgressBar:(NSTimer *)timer
{
    unsigned long position = [_fileTransfer position];
    [progressBar setDoubleValue:position];
    [totalSizeTextField
        setStringValue:[NSString
            stringWithFormat:NSLocalizedString(
                @"%@ of %@",
                @"incoming file transfer progress. parameters are transferred size and total size, units (KB, MB etc.) included"
            ),
            [NSString stringWithByteSize:position],
            [NSString stringWithByteSize:[_fileTransfer size]]
        ]
    ];
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

- (IBAction)skipCurrentFile:(id)sender
{
    [_fileTransfer skipFile];
}

// ICQFileTransferDelegate
- (void)fileTransfer:(ICQFileTransfer *)transfer receivedFile:(NSString *)path size:(unsigned long)size
{
    NSString	*destination = [[self directory] stringByAppendingPathComponent:[path lastPathComponent]];

	[skipButton setEnabled:YES];
    [infoTextField
        setStringValue:[NSString
            stringWithFormat:NSLocalizedString(
                @"Receiving %@ from %@",
                @"incoming file transfer. first parameter is '1 file' or 'n files', second parameter is sender's name"
            ),
            ( [_fileTransfer fileCount]==1 ?
                NSLocalizedString( @"1 file", @"" )
            :
                [NSString
                    stringWithFormat:NSLocalizedString( @"%d files", @"" ),
                    [_fileTransfer fileCount]
                ]
            ),
            [[_message sender] displayName]
        ]
    ];

    if ( [[NSFileManager defaultManager] fileExistsAtPath:destination] )
    {
        [self showWindow:nil];
        if ([[self window] attachedSheet])
            [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
        NSBeginAlertSheet(
            [NSString
                stringWithFormat:NSLocalizedString( @"The file %@ already exists. Do you want to replace it?", @"" ),
                [destination lastPathComponent]
            ],
            NSLocalizedString( @"Replace", @"button on name conflict sheet" ),
            NSLocalizedString( @"Skip", @"button on name conflict sheet" ),
            NSLocalizedString( @"Save As...", @"button on name conflict sheet" ),
            [self window],
            self,
            @selector(nameConflictSheetDidEnd:returnCode:destination:),
            nil,
            [destination retain],
            [NSString
                stringWithFormat:NSLocalizedString( @"A file with the same name already exists in %@. Replacing it will overwrite its current contents.", @"parameter is folder name" ),
                [[NSFileManager defaultManager] displayNameAtPath:[self directory]]
            ]
        );
    }
    else
    {
        [[NSFileManager defaultManager] createFileAtPath:destination contents:nil attributes:nil]; 
        [self updateFileInfo:destination];
        [transfer receiveFile:destination];
    }
}

- (void)updateFileInfo:(NSString *)path
{
    [filenameTextField setStringValue:[path lastPathComponent]];
    [fileIconView setImage:[[NSWorkspace sharedWorkspace] iconForFile:path]];
}

- (void)abort
{
    _canceling = YES;
    [_fileTransfer cancel];
    [self close];
}

- (void)abortSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if ( returnCode==NSAlertDefaultReturn && [_fileTransfer state]==FTReceive )
    {
        [self abort];
    }
}

// NSWindow delegate
- (BOOL)windowShouldClose:(id)sender
{
    if ( [_fileTransfer state]==FTReceive )
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

- (void)windowWillClose:(NSNotification *)notification
{
    [self stopProgressTimer];
    if ([[self window] attachedSheet])
        [NSApp endSheet:[[self window] attachedSheet] returnCode:ICJParentWindowClosing];
    [[self retain] autorelease];
    [[self icqUserDocument] removeIncomingFileController:self];
}

@end
