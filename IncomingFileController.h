/*
 * IncomingFileController.h
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

#import <AppKit/AppKit.h>
#import "ICQUserDocument.h";

@class ICQFileTransfer;

@interface IncomingFileController : NSWindowController {
    IBOutlet NSProgressIndicator	*progressBar;
    IBOutlet NSTextField		*totalSizeTextField;
    IBOutlet NSTextField		*filenameTextField;
    IBOutlet NSTextField		*infoTextField;
    IBOutlet NSImageView		*fileIconView;
    IBOutlet NSButton			*goToFolderButton;
    IBOutlet NSButton			*skipButton;
    IBOutlet NSButton			*stopButton;

    ICQFileTransfer		*_fileTransfer;
    ICQFileTransferMessage	*_message;
    ICQUserDocument		*_icqUserDocument;
    NSString			*_directory;
    NSTimer			*_progressTimer;
    BOOL			_canceling;
}

- (IBAction)skipCurrentFile:(id)sender;
- (IBAction)goToFolder:(id)sender;

- (id)initWithMessage:(ICQFileTransferMessage *)message forDocument:(ICQUserDocument *)document promptForDestination:(BOOL)prompt;

+ (id)incomingFileControllerWithMessage:(ICQFileTransferMessage *)message forDocument:(ICQUserDocument *)document promptForDestination:(BOOL)prompt;

- (void)abort;
- (ICQFileTransfer *)fileTransfer;
- (ICQUserDocument *)icqUserDocument;
- (NSString *)directory;
- (void)setDirectory:(NSString *)directory;
- (void)updateFileInfo:(NSString *)path;

- (void)startProgressTimer;
- (void)stopProgressTimer;

@end
