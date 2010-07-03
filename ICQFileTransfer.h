/*
 * ICQFileTransfer.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed Nov 12 2003.
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

#import <Foundation/Foundation.h>

#define ICJFileTransferUpdatedNotification	@"ICJFileTransferUpdatedNotification"

typedef enum _ICJFTState {
      FTNotConnected,
      FTSend,
      FTReceive,
      FTWaitingForResponse,
      FTAccepted,
      FTRejected,
      FTError,
      FTComplete,
      FTCanceled,
      FTTimeout,
      FTClose
} ICJFTState;

#ifdef CLIENT_H
class fileTransferGlue;
#else
@class fileTransferGlue;
#endif

@class ICQFileTransferMessage;

@interface ICQFileTransfer : NSObject <NSCoding>
{
    fileTransferGlue	*_glue;
    id			_delegate;

    ICJFTState		_state;
//    ICQFileTransferMessage	*_message;
    NSMutableArray	*_files;
    unsigned long	_size;
}

- (unsigned long)position;

- (void)cancel;
- (void)decline;
- (void)accept;
- (void)receiveFile:(NSString *)path;
- (void)skipFile;

- (void)setState:(ICJFTState)theState;
- (ICJFTState)state;

- (void)setFiles:(NSArray *)theFiles;
- (NSArray *)files;
- (unsigned int)fileCount;

- (void)setSize:(unsigned long)s;
- (unsigned long)size;

- (void)setDelegate:(id)object;
- (id)delegate;

- (fileTransferGlue *)glue;

@end

@interface NSObject (ICQFileTransferDelegate)

- (void)fileTransfer:(ICQFileTransfer *)transfer receivedFile:(NSString *)path size:(unsigned long)size;

@end