/*
 * NSString-MPAdditions.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Mar 15 2002.
 *
 * Modifications suggested by Nir Soffer
 *  	(see <456BF303-0BAF-11D8-851B-000502B6C537@freeshell.org>)
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

#import "NSString-MPAdditions.h"


@implementation NSString (NSStringMPAdditions)

- (NSString *)stringByReplacing:(NSString *)searchString with:(NSString *)replacement
{
    return [self stringByReplacing:searchString with:replacement options:0];
}

- (NSString *)stringByReplacing:(NSString *)searchString with:(NSString *)replacement options:(unsigned)mask
{
    NSMutableString *result = [self mutableCopy];
    NSRange searchRange = NSMakeRange(0, [self length]);
    NSRange matchRange;
    
    while (searchRange.length)
    {
        matchRange = [result rangeOfString:searchString options:mask range:searchRange];
        if (matchRange.location==NSNotFound)
            break;
        [result replaceCharactersInRange:matchRange withString:replacement];
        searchRange.location = matchRange.location+[replacement length];
        searchRange.length = [result length]-searchRange.location;
    }
    return [result autorelease];
}

+ (NSString *)stringWithCString:(const char *)bytes encoding:(NSStringEncoding)encoding
{
    if (bytes==nil)
        return nil;
    return [(NSString *)CFStringCreateWithCString(nil, bytes, encoding) autorelease];
}

- (const char *)cStringWithEncoding:(NSStringEncoding)encoding
{
    CFIndex length;
    NSMutableData *data;
    char *bytes;
    // get the required length
    CFStringGetBytes((CFStringRef)self, CFRangeMake(0, [self length]), encoding, '?', NO, nil, 0, &length);
    // allocate a buffer large enough
    data = [NSMutableData dataWithLength:length+1];
    bytes = [data mutableBytes];
    // do the actual conversion
    CFStringGetBytes((CFStringRef)self, CFRangeMake(0, [self length]), encoding, '?', NO, bytes, length, &length);
    bytes[length] = 0;
    return bytes;
}

- (NSComparisonResult)displayNameCompare:(NSString *)string
{
    NSFileManager *manager = [NSFileManager defaultManager];
    return [[manager displayNameAtPath:self] caseInsensitiveCompare:[manager displayNameAtPath:string]];
}

+ (NSString *)stringWithByteSize:(unsigned int)size
{
    return ( size==0 ?
        @""
        : ( size<1024 ?
            [NSString stringWithFormat:NSLocalizedString( @"%d bytes", @"" ), size]
            : ( size<1024*1024 ? 
                [NSString stringWithFormat:NSLocalizedString( @"%d KB", @"" ), size/1024]
                : [NSString stringWithFormat:NSLocalizedString( @"%d MB", @"" ), size/1024/1024]
            )
        )
    );
}

@end
