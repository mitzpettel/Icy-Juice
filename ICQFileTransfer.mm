/*
 * ICQFileTransfer.mm
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

// #include "config.h"
#import "Client.h" /* this is libICQ2000 */
#import "ICQFileTransfer.h"
#import "fileTransferGlue.h"
#import "LibContactRef.h"
#import "ICQUserDocument.h"
#import "ICJMessage.h"
#import "User.h"
#include <fstream>

@implementation ICQFileTransfer

- (id)init
{
    self = [super init];
    _state = FTNotConnected;
    _glue = new fileTransferGlue( self );
    return self;
}

- (void)dealloc
{
    delete _glue;
    [_files release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self files]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    [self setFiles:[aDecoder decodeObject]];
    return self;
}

- (unsigned long)position
{
    return _glue->position();
}

- (void)setState:(ICJFTState)theState
{
    if ( _state!=theState )
    {
        _state = theState;
        [[NSNotificationCenter defaultCenter] postNotificationName:ICJFileTransferUpdatedNotification object:self];
    }
}

- (ICJFTState)state
{
    return _state;
}

- (void)cancel
{
    _glue->cancel();
}

- (void)decline
{
    _glue->decline();
//    [self setState:FTRejected];
}

- (void)accept
{
    _glue->accept();
}

- (void)receiveFile:(NSString *)path
{
    [_files addObject:path];
    _glue->receiveFile( path );
}

- (void)skipFile
{
    _glue->skip();
}

- (void)setFiles:(NSArray *)theFiles
{
    unsigned long	size = 0;
    NSEnumerator	*fileEnumerator;
    NSString		*currentFile;
    
    [_files autorelease];
    _files = [[NSMutableArray arrayWithArray:theFiles] retain];
    
    fileEnumerator = [_files objectEnumerator];
    while ( currentFile = [fileEnumerator nextObject] )
        size += [[[NSFileManager defaultManager] 
            fileAttributesAtPath:currentFile
            traverseLink:YES
        ] fileSize];
    [self setSize:size];
}

- (NSArray *)files
{
    return _files;
}

- (unsigned int)fileCount
{
    return _glue->fileCount();
}

- (unsigned long)size
{
    return _size;
}

- (void)setSize:(unsigned long)s
{
    _size = s;
}

- (void)setDelegate:(id)object
{
    _delegate = object;
}

- (id)delegate
{
    return _delegate;
}

- (fileTransferGlue *)glue
{
    return _glue;
}

@end

// C++ object implementation

fileTransferGlue::fileTransferGlue( ICQFileTransfer *owner ) : _owner(owner)
{
}

void fileTransferGlue::setEvent( ICQ2000::Client *client, ICQ2000::FileTransferEvent *event )
{
    _client = client;
    _event = event;
    // set up Callbacks
    _client->filetransfer_incoming_signal.connect( this, &fileTransferGlue::incoming_cb );
    _client->filetransfer_update_signal.connect( this, &fileTransferGlue::progress_cb );
    _client->filetransfer_want_file_signal.connect( this, &fileTransferGlue::want_file_cb );
}

void fileTransferGlue::cancel()
{
    _client->CancelFileTransfer( _event );
}

void fileTransferGlue::decline()
{
    _event->setState( ICQ2000::FileTransferEvent::REJECTED );
    _client->SendFileTransferACK( _event );
}

void fileTransferGlue::accept()
{
    _event->setState( ICQ2000::FileTransferEvent::ACCEPTED );
    _client->SendFileTransferACK( _event );
}

unsigned int fileTransferGlue::fileCount()
{
    return _event->getTotalFiles();
}

void fileTransferGlue::incoming_cb(ICQ2000::FileTransferEvent *fte)
{
    // implement me!
}

void fileTransferGlue::want_file_cb(ICQ2000::FileTransferEvent *fte, std::ios *stream)
{
    if ( fte!=_event )
        return;

    NSString	*path;
    if ( fte->getState()==ICQ2000::FileTransferEvent::SEND )
    {
        path = [[_owner files] objectAtIndex:(fte->getCurrFile() - 1)];
        
        fte->setSize( [[[NSFileManager defaultManager]
            fileAttributesAtPath:path
            traverseLink:YES
        ] fileSize] );
        
        fte->setCurrFilename( [[path lastPathComponent] cString] ); 
            
        std::ifstream *istream = dynamic_cast<std::ifstream *>(stream);
        
        if ( istream->is_open() )
        {
            istream->clear();
            istream->close();
        }
            
        istream->open( [path fileSystemRepresentation] , std::ios::in | std::ios::binary);
        if ( !istream->good() )
        {
            // handle problems
        }
    }
    else if ( fte->getState()==ICQ2000::FileTransferEvent::RECEIVE )
    {
        path = [NSString stringWithCString:fte->getCurrFilename().c_str()];
        
        _ostream = dynamic_cast<std::ofstream *>(stream);

        if ( [_owner delegate] && [[_owner delegate] respondsToSelector:@selector(fileTransfer:receivedFile:size:)] )
            [[_owner delegate] fileTransfer:_owner receivedFile:path size:fte->getSize()];
    }
}

void fileTransferGlue::receiveFile( NSString *path )
{
    if ( _ostream->is_open() )
    {
        _ostream->clear();
        _ostream->close();
    }
    
    _ostream->open( [path fileSystemRepresentation] , std::ios::out | std::ios::binary);
    if ( !_ostream->good() )
    {
        // handle problems
    }
    else
        _client->SendFileTransfer( _event );
}

void fileTransferGlue::skip()
{
    _client->FileTransferSkipFile( _event );
}

unsigned long fileTransferGlue::position()
{
    return _event->getTotalPos();
}

void fileTransferGlue::progress_cb(ICQ2000::FileTransferEvent *fte)
{
    if ( fte!=_event )
        return;

    ICJFTState state;

    switch ( fte->getState() )
    {
        case ICQ2000::FileTransferEvent::NOT_CONNECTED:
            state = FTNotConnected;
            // the library thinks that file transfer messages shouldn't always be acked, so we do it instead
            if ( fte->isFinished() )
                _client->messageack.emit( fte );
            break;
        case ICQ2000::FileTransferEvent::SEND:
            state = FTSend;
            break;
        case ICQ2000::FileTransferEvent::RECEIVE:
            state = FTReceive;
            break;
        case ICQ2000::FileTransferEvent::WAIT_RESPONS:
            state = FTWaitingForResponse;
            break;
        case ICQ2000::FileTransferEvent::ACCEPTED:
            state = FTAccepted;
            _client->SendFileTransfer( fte );
            break;
        case ICQ2000::FileTransferEvent::REJECTED:
            state = FTRejected;
            break;
        case ICQ2000::FileTransferEvent::ERROR:
            state = FTError;
            break;
        case ICQ2000::FileTransferEvent::COMPLETE:
            state = FTComplete;
            break;
        case ICQ2000::FileTransferEvent::CANCELLED:
            state = FTCanceled;
            break;
        case ICQ2000::FileTransferEvent::TIMEOUT:
            state = FTTimeout;
            // the library thinks that file transfer messages shouldn't always be acked, so we do it instead
            if ( fte->isFinished() )
                _client->messageack.emit( fte );
            break;
        case ICQ2000::FileTransferEvent::CLOSE:
            state = FTClose;
            break;
        default:
            state = FTError;
            break;
    }
    
    [_owner setState:state];
        
/*    [(id)target
        fileTransfer:[NSData dataWithBytes:&fte length:sizeof(fte)]
        changedStateTo:state
        size:fte->getTotalSize()
        position:fte->getTotalPos()
    ];
*/
}
