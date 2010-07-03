/*
 * ICJMessage.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Wed Apr 03 2002.
 *
 * Copyright (c) 2002-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "ICJMessage.h"
#import "ICQFileTransfer.h"

@implementation ICJMessage

- (id)initIncoming:(BOOL)incoming date:(NSDate *)theDate owners:(NSArray *)theOwners
{
    self = [super init];
    [self setIncoming:incoming];
    [self setSentDate:theDate];
    [self setOwners:theOwners];
    return self;
}

+ (id)messageFrom:(ICJContact *)owner date:(NSDate *)theDate
{
    return [[[self alloc] initFrom:owner date:theDate] autorelease];
}

- (id)initFrom:(ICJContact *)owner date:(NSDate *)theDate
{
    return [self initIncoming:YES date:theDate owners:[NSArray arrayWithObject:owner]];
}

+ (id)messageFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    Class messageClass = NSClassFromString([dictionary objectForKey:@"ICJMessageClass"]);
    id message = [[[messageClass alloc] autorelease] initFrom:owner withDictionary:dictionary];
    return message;
}

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    return [self initFrom:owner date:[dictionary objectForKey:@"sentDate"]];
}

+ (id)messageTo:(ICJContact *)recipient
{
    return [[[self alloc] initTo:recipient] autorelease];
}

- (id)initTo:(ICJContact *)recipient
{
    return [self initIncoming:NO date:[NSDate date] owners:[NSArray arrayWithObject:recipient]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeValueOfObjCType:@encode(BOOL) at:&_isIncoming];
    [aCoder encodeObject:[self sentDate]];
    [aCoder encodeObject:[self owners]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    BOOL incoming;
    NSDate *theDate;
    NSArray *theOwners;
    [aDecoder decodeValueOfObjCType:@encode(BOOL) at:&incoming];
    theDate = [aDecoder decodeObject];
    theOwners = [aDecoder decodeObject];
    return [self initIncoming:incoming date:theDate owners:theOwners];
}

- (void)dealloc
{
    [_sentDate release];
    [_owners release];
    [super dealloc];
}

- (BOOL)isIncoming
{
    return _isIncoming;
}

- (void)setIncoming:(BOOL)flag
{
    _isIncoming = flag;
}

- (NSDate *)sentDate
{
    return _sentDate;
}

- (void)setSentDate:(NSDate *)theDate
{
    [_sentDate autorelease];
    _sentDate = [theDate copy];
}

- (NSArray *)owners
{
    return _owners;
}

- (void)setOwners:(NSArray *)theOwners
{
    [_owners autorelease];
    _owners = [theOwners copy];
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (BOOL)isDelivered
{
    return _isDelivered;
}

- (void)setFinished:(BOOL)flag
{
    _isFinished = flag;
}

- (void)setDelivered:(BOOL)flag
{
    _isDelivered = flag;
}

- (ICJDeliveryFailureReason)deliveryFailureReason
{
    return _failureReason;
}

- (void)setDeliveryFailureReason:(ICJDeliveryFailureReason)reason
{
    _failureReason = reason;
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:NSStringFromClass([self class]) forKey:@"ICJMessageClass"];
    [dictionary setObject:[self sentDate] forKey:@"sentDate"];
    return dictionary;
}

- (ICJContact *)sender
{
    return [[self owners] objectAtIndex:0];
}

@end

@implementation ICQMessage

+ (void)initialize
{
    [ICQMessage setVersion:1];
}

- (void)dealloc
{
    [_statusMessage release];
    [super dealloc];
}

- (BOOL)isUrgent
{
    return _isUrgent;
}

- (BOOL)isToContactList
{
    return _isToContactList;
}

- (BOOL)isOffline
{
    return _isOffline;
}

- (void)setUrgent:(BOOL)flag
{
    _isUrgent = flag;
}

- (void)setToContactList:(BOOL)flag;
{
    _isToContactList = flag;
}

- (void)setOffline:(BOOL)flag;
{
    _isOffline = flag;
}

- (NSString *)statusMessage
{
    return _statusMessage;
}

- (void)setStatusMessage:(NSString *)theStatusMessage
{
    [_statusMessage autorelease];
    _statusMessage = [theStatusMessage copy];
}

@end

@implementation ICQNormalMessage

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    self = [super initFrom:owner withDictionary:dictionary];
    [self setText:[dictionary objectForKey:@"text"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self text]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setText:[aDecoder decodeObject]];
    return self;
}

- (void)dealloc
{
    [_text release];
    [super dealloc];
}

- (NSString *)text
{
    return _text;
}

- (void)setText:(NSString *)theText
{
    [_text autorelease];
    _text = [theText copy];
}

- (BOOL)isMultiRecipient
{
    return _isMultiRecipient;
}

- (void)setMultiRecipient:(BOOL)flag
{
    _isMultiRecipient = flag;
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [super persistentDictionary];
    [dictionary setObject:[self text] forKey:@"text"];
    return dictionary;
}

@end

@implementation ICQURLMessage

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    self = [super initFrom:owner withDictionary:dictionary];
    [self setUrl:[dictionary objectForKey:@"url"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self url]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setUrl:[aDecoder decodeObject]];
    return self;
}

- (void)dealloc
{
    [_url release];
    [super dealloc];
}

- (NSString *)url
{
    return _url;
}

- (void)setUrl:(NSString *)theUrl
{
    [_url autorelease];
    _url = [theUrl copy];
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [super persistentDictionary];
    [dictionary setObject:[self url] forKey:@"url"];
    return dictionary;
}

@end

@implementation ICQAwayMessage
@end

@implementation ICQAuthReqMessage
@end

@implementation ICQFileTransferMessage

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    ICQFileTransfer	*fileTransfer;
    
    self = [super initFrom:owner withDictionary:dictionary];
    [self setDescription:[dictionary objectForKey:@"description"]];
    fileTransfer = [[ICQFileTransfer new] autorelease];
    [fileTransfer setFiles:[dictionary objectForKey:@"files"]];
    [self setFileTransfer:fileTransfer];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self description]];
    [aCoder encodeObject:[self fileTransfer]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setDescription:[aDecoder decodeObject]];
    [self setFileTransfer:[aDecoder decodeObject]];
    return self;
}

- (void)dealloc
{
    [_fileTransfer release];
    [_description release];
    [super dealloc];
}

- (void)setDescription:(NSString *)theDescription
{
    [_description autorelease];
    _description = [theDescription copy];
}

- (NSString *)description
{
    return _description;
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [super persistentDictionary];
    [dictionary setObject:[self description] forKey:@"description"];
    [dictionary setObject:[[self fileTransfer] files] forKey:@"files"];
    return dictionary;
}

- (void)setFileTransfer:(ICQFileTransfer *)transfer
{
    [_fileTransfer autorelease];
    _fileTransfer = [transfer retain];
}

- (ICQFileTransfer *)fileTransfer
{
    return _fileTransfer;
}

@end

@implementation ICQAuthAckMessage

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValueOfObjCType:@encode(BOOL) at:&_isGranted];
}

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    self = [super initFrom:owner withDictionary:dictionary];
    [self setGranted:[[dictionary objectForKey:@"isGranted"] boolValue]];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [aDecoder decodeValueOfObjCType:@encode(BOOL) at:&_isGranted];
    return self;
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [super persistentDictionary];
    [dictionary setObject:[NSNumber numberWithBool:_isGranted] forKey:@"isGranted"];
    return dictionary;
}

- (BOOL)isGranted
{
    return _isGranted;
}

- (void)setGranted:(BOOL)flag
{
    _isGranted = flag;
}

@end

@implementation ICQUserAddedMessage
@end

@implementation SMSMessage

- (id)initFrom:(ICJContact *)owner withDictionary:(NSDictionary *)dictionary
{
    self = [super initFrom:owner withDictionary:dictionary];
    [self setText:[dictionary objectForKey:@"text"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self text]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setText:[aDecoder decodeObject]];
    return self;
}

- (void)dealloc
{
    [_text release];
    [super dealloc];
}

- (NSString *)text
{
    return _text;
}

- (void)setText:(NSString *)theText
{
    [_text autorelease];
    _text = [theText copy];
}

- (NSMutableDictionary *)persistentDictionary
{
    NSMutableDictionary *dictionary = [super persistentDictionary];
    [dictionary setObject:[self text] forKey:@"text"];
    return dictionary;
}

@end

@implementation EmailExpressMessage

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self text]];
    [aCoder encodeObject:[self senderName]];
    [aCoder encodeObject:[self senderEmail]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setText:[aDecoder decodeObject]];
    [self setSenderName:[aDecoder decodeObject]];
    [self setSenderEmail:[aDecoder decodeObject]];
    return self;
}

- (void)dealloc
{
    [_text release];
    [_senderName release];
    [_senderEmail release];
    [super dealloc];
}

- (NSString *)text
{
    return _text;
}

- (NSString *)senderName;
{
    return _senderName;
}

- (NSString *)senderEmail
{
    return _senderEmail;
}

- (void)setText:(NSString *)theText
{
    [_text autorelease];
    _text = [theText copy];
}

- (void)setSenderName:(NSString *)theName;
{
    [_senderName autorelease];
    _senderName = [theName copy];
}

- (void)setSenderEmail:(NSString *)theEmail;
{
    [_senderEmail autorelease];
    _senderEmail = [theEmail copy];
}

@end