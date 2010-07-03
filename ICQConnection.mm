/*
 * ICQConnection.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Jun 01 2001.
 *
 * Copyright (c) 2001-2003 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#include <sys/time.h>
#import <Foundation/Foundation.h>
// #include "config.h"
#import "Client.h" /* this is libICQ2000 */
#import "Capabilities.h"
#import "Translator.h"
#import "ICQConnection.h"
#import "icq2000Glue.h"
#import "LibContactRef.h"
#import "ICQUserDocument.h"
#import "ICJMessage.h"
#import "User.h"
#import "ICQFileTransfer.h"
#import "fileTransferGlue.h"

@implementation ICQConnection

+ (id)connectionWithUIN:(ICQUIN)theUin password:(NSString *)thePassword nickname:(NSString *)theNickname target:(ICQUserDocument *)theTarget contactList:(NSArray *)theContactList
{
    return [[[self alloc] initWithUIN:theUin password:thePassword nickname:theNickname target:theTarget contactList:theContactList] autorelease];
}

- (id)initWithUIN:(ICQUIN)theUin password:(NSString *)thePassword nickname:(NSString *)theNickname target:(ICQUserDocument *)theTarget contactList:(NSArray *)theContactList
{
    NSEnumerator	*contactsEnumerator = [theContactList objectEnumerator];
    ICJContact		*contact;
    
    self = [super init];
    
    socketArrays = [[NSArray
        arrayWithObjects:[NSMutableArray array],
        [NSMutableArray array],
        [NSMutableArray array],
        nil
    ] retain];

    myClient = new ICQ2000::Client(
        theUin,
        (thePassword ? [thePassword cString] : "")
    );
	
    
    _glue = new icq2000Glue(
        myClient,
        self,
        [[NSUserDefaults standardUserDefaults] boolForKey:@"ICJLog"],
        [[NSUserDefaults standardUserDefaults] boolForKey:@"ICJLogPackets"]
    );
        
    myClient->set_translator( new ICQ2000::CRLFTranslator() );
    
    myClient->setLoginServerHost([[theTarget settingWithName:ICJServerHostSettingName] cString]);
    myClient->setLoginServerPort([[theTarget settingWithName:ICJServerPortSettingName] intValue]);
	{
		int start = [[theTarget settingWithName:ICJPortRangeStartSettingName] intValue];
		int end = [[theTarget settingWithName:ICJPortRangeEndSettingName] intValue];
		if ( start>0 || end>0 )
		{
			myClient->setUsePortRange( true );
			myClient->setPortRangeLowerBound( start );
			myClient->setPortRangeUpperBound( end==0 ? 65535 : end );
		}
	}

    myClient->getContactTree().add_group( "General", 0x13a0 );

    isLoggedIn = NO;
    lastPollTime = [[NSDate date] retain];
    messagesPendingAck = [[NSMutableDictionary dictionary] retain];
    searchesPendingResult = [[NSMutableDictionary dictionary] retain];
    routineTaskTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(routineTask:) userInfo:nil repeats:YES];
    target = theTarget;
    while (contact = [contactsEnumerator nextObject])
        [self addContact:contact];
    return self;
}

- (void)dealloc
{
    delete _glue;
    [messagesPendingAck release];
    [searchesPendingResult release];
    [socketArrays release];
    [lastPollTime release];
    [super dealloc];
    return;
}

- (void)setPassword:(NSString *)thePassword
{
    myClient->setPassword([thePassword cString]);
}

- (void)setWebAware:(BOOL)flag
{
    myClient->setWebAware(flag);
}

- (BOOL)isWebAware
{
    return myClient->getWebAware();
}

- (void)terminateAndRelease
{
    delete myClient;
    [routineTaskTimer invalidate];
    [self autorelease];
}

/*
- (void)loginWithStatusCode:(UserStatusCode)theStatusCode
{
    if ( isConnected && !isLoggedIn )
        myClient->setStatus((ICQ2000::Status)theStatusCode);
}
*/

/*
- (void)connect
{
    if (isConnected)
        return;
    isConnected = YES;
}
*/

- (void)loggedIn
{
    isLoggedIn = YES;
    [target loggedIn];
}

- (void)userStatusCodeChangedTo:(ICQ2000::Status)theStatusCode invisible:(BOOL)invisible
{
    if (!invisible || theStatusCode==ICQ2000::STATUS_OFFLINE)
    {
        NSString *statusKey;
        switch (theStatusCode)
        {
            case ICQ2000::STATUS_ONLINE:
                statusKey = ICJAvailableStatusKey;
                break;
            case ICQ2000::STATUS_AWAY:
                statusKey = ICJAwayStatusKey;
                break;
            case ICQ2000::STATUS_NA:
                statusKey = ICJNAStatusKey;
                break;
            case ICQ2000::STATUS_OCCUPIED:
                statusKey = ICJOccupiedStatusKey;
                break;
            case ICQ2000::STATUS_DND:
                statusKey = ICJDNDStatusKey;
                break;
            case ICQ2000::STATUS_FREEFORCHAT:
                statusKey = ICJFreeForChatStatusKey;
                break;
            case ICQ2000::STATUS_OFFLINE:
                statusKey = ICJOfflineStatusKey;
                break;
            default:
                statusKey = ICJAvailableStatusKey;
        }
        [target userStatusChangedTo:statusKey];
    }
    else
        [target userStatusChangedTo:ICJInvisibleStatusKey];
}

- (void)disconnected:(ICJDisconnectReason)reason
{
    if ( isLoggedIn )
    {
        isLoggedIn = NO;
        [target loggedOut];
    }
    [target disconnected:reason];
}

- (void)routineTask:(NSTimer *)timer
{
    struct timeval	tv;
    fd_set		fdsets[3];
    int			max_fd = -1;
    NSEnumerator 	*socketEnumerator;
    NSNumber 		*curSocket;
    BOOL		processed = NO;

    for ( int i = 0; i<3; i++ )
    {
        FD_ZERO( &(fdsets[i]) );
        socketEnumerator = [[socketArrays objectAtIndex:i] objectEnumerator];
        while ( curSocket = [socketEnumerator nextObject] )
        {
            int		curSocketHandle = [curSocket intValue];
            
            FD_SET( curSocketHandle, &(fdsets[i]) );
            if ( curSocketHandle > max_fd )
                max_fd = curSocketHandle;
        }
    }
    // should ping server every minute
    tv.tv_sec = 0;
    tv.tv_usec = 0;
    if ( select(max_fd+1, &(fdsets[0]), &(fdsets[1]), &(fdsets[2]), &tv) )
    {
        ICQ2000::SocketEvent::Mode	mode;
        
        processed = YES;
        for ( int i=0; i<3; i++ )
        {
            switch ( i )
            {
                case 0:
                    mode = ICQ2000::SocketEvent::READ;
                    break;
                case 1:
                    mode = ICQ2000::SocketEvent::WRITE;
                    break;
                case 2:
                    mode =  ICQ2000::SocketEvent::EXCEPTION;
                    break;
                default:
                    break;
            }
            socketEnumerator = [[socketArrays objectAtIndex:i] objectEnumerator];
            while ( curSocket = [socketEnumerator nextObject] )
            {
                int	curSocketHandle = [curSocket intValue];
                
                if ( FD_ISSET( curSocketHandle, &(fdsets[i]) ) )
                    myClient->socket_cb( curSocketHandle, mode );
            }
        }
    }
    if ( isLoggedIn && [[NSDate date] timeIntervalSinceDate:lastPollTime]>5 )
    {
        myClient->Poll();
        [lastPollTime release];
        lastPollTime = [[NSDate date] retain];
    }
    if ( processed )
    {
        if ( floor(NSAppKitVersionNumber)>NSAppKitVersionNumber10_1 )
            [timer setFireDate:[NSDate distantPast]];
        else
            [[NSRunLoop currentRunLoop]
                performSelector:@selector(routineTask:)
                target:self
                argument:timer
                order:100
                modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]
            ];
     }
}

- (const char *)statusMessageForUIN:(ICQUIN)theUin
{
    ICJContact *theContact = [target contactWithUin:theUin create:NO];
    NSString *theMessage = [target statusMessageForContact:theContact];
    CFStringEncoding encoding = [target textEncodingForContact:theContact];
    return [theMessage cStringWithEncoding:encoding];
}

- (void)contact:(ICQUIN)theUin statusChangedTo:(ICQ2000::Status)theStatusCode invisible:(BOOL)flag typingFlags:(TypingFlags)flags
{
        NSString *statusKey;
        switch (theStatusCode)
        {
            case ICQ2000::STATUS_ONLINE:
                if (flag)
                    statusKey = ICJInvisibleStatusKey;
                else
                    statusKey = ICJAvailableStatusKey;
                break;
            case ICQ2000::STATUS_AWAY:
                statusKey = ICJAwayStatusKey;
                break;
            case ICQ2000::STATUS_NA:
                statusKey = ICJNAStatusKey;
                break;
            case ICQ2000::STATUS_OCCUPIED:
                statusKey = ICJOccupiedStatusKey;
                break;
            case ICQ2000::STATUS_DND:
                statusKey = ICJDNDStatusKey;
                break;
            case ICQ2000::STATUS_FREEFORCHAT:
                statusKey = ICJFreeForChatStatusKey;
                break;
            case ICQ2000::STATUS_OFFLINE:
                statusKey = ICJOfflineStatusKey;
                flags = 0;
                break;
            default:
                statusKey = ICJAvailableStatusKey;
        }
    [target setStatusOfContact:theUin toStatusKey:statusKey typingFlags:flags];
    return;
}

- (void)setStatus:(NSString *)statusKey
{
    ICQ2000::Status statusCode;

    if ( [statusKey isEqualToString:ICJOfflineStatusKey] )
    {
        myClient->setStatus( ICQ2000::STATUS_OFFLINE );
    }
    else if ( [statusKey isEqualToString:ICJInvisibleStatusKey] )
    {
        myClient->setStatus( ICQ2000::STATUS_ONLINE, YES );
    }
    else
    {
        if ( [statusKey isEqualToString:ICJAvailableStatusKey] )
            statusCode = ICQ2000::STATUS_ONLINE;
        else if ( [statusKey isEqualToString:ICJAwayStatusKey] )
            statusCode = ICQ2000::STATUS_AWAY;
        else if ( [statusKey isEqualToString:ICJNAStatusKey] )
            statusCode = ICQ2000::STATUS_NA;
        else if ( [statusKey isEqualToString:ICJOccupiedStatusKey] )
            statusCode = ICQ2000::STATUS_OCCUPIED;
        else if ( [statusKey isEqualToString:ICJDNDStatusKey] )
            statusCode = ICQ2000::STATUS_DND;
        else if ( [statusKey isEqualToString:ICJFreeForChatStatusKey] )
            statusCode = ICQ2000::STATUS_FREEFORCHAT;

        myClient->setStatus( statusCode, NO );
    }
}

- (void)sendMessage:(id)theMessage
{
	if ( !isLoggedIn )
		return;
    {
        NSEnumerator			*recipientsEnumerator = [[theMessage owners] objectEnumerator];
        ICJContact				*recipient;
        BOOL				multipleRecipients = ( [[theMessage owners] count]>1 );
        ICQ2000::ICQMessageEvent	*event;
        ICQ2000::ContactRef		contactRef;
        CFStringEncoding		encoding;
        
        while ( recipient = [recipientsEnumerator nextObject] )
        {
            contactRef = *(ICQ2000::ContactRef *)[[recipient connectionData] contactRef];
            encoding = [target textEncodingForContact:recipient];

            if ( [theMessage isKindOfClass:[ICQAuthAckMessage class]] )
            {
                event = new ICQ2000::AuthAckEvent( contactRef, [theMessage isGranted] );
            }
            else if ( [theMessage isKindOfClass:[ICQAwayMessage class]] )
            {
                event = new ICQ2000::AwayMessageEvent( contactRef );
            }
            else if ( [theMessage isKindOfClass:[ICQUserAddedMessage class]] )
            {
                event = new ICQ2000::UserAddEvent( contactRef );
            }
            else if ( [theMessage isKindOfClass:[ICQAuthReqMessage class]] )
            {
                event = new ICQ2000::AuthReqEvent( contactRef, [[theMessage text] cStringWithEncoding:encoding] );
            }
            else if ( [theMessage isKindOfClass:[ICQFileTransferMessage class]] )
            {
                ICQ2000::FileTransferEvent	*fte;
                
                event = new ICQ2000::FileTransferEvent(
                    contactRef,
                    [[theMessage text] cStringWithEncoding:encoding],
                    [[[[[theMessage fileTransfer] files] objectAtIndex:0] lastPathComponent] cStringWithEncoding:encoding],
                    0,		// size; what matters is total size
                    0		// seqnum
                );

                fte = dynamic_cast<ICQ2000::FileTransferEvent *>(event);

                [[theMessage fileTransfer] glue]->setEvent( myClient, fte );

                
                fte->setTotalSize( [[theMessage fileTransfer] size] );
                fte->setTotalFiles( [[[theMessage fileTransfer] files] count] );
            }
            else
            {
				if ( contactRef->get_capabilities().has_capability_flag(ICQ2000::Capabilities::ICQUTF8) )
				{
					event = new ICQ2000::NormalMessageEvent(
						contactRef,
						[[theMessage text] UTF8String],
						multipleRecipients
					);
					((ICQ2000::NormalMessageEvent *)event)->setTextEncoding( ICQ2000::ENCODING_UTF8 );
				}
				else
					event = new ICQ2000::NormalMessageEvent(
						contactRef,
						[[theMessage text] cStringWithEncoding:encoding],
						multipleRecipients
					);
                event->setToContactList( [theMessage isToContactList] );
                event->setUrgent( [theMessage isUrgent] );
            }
            
            [messagesPendingAck
                setObject:theMessage
                forKey:[NSData dataWithBytes:&event length:sizeof(event)]
            ];
            
            if ( [theMessage isKindOfClass:[ICQFileTransferMessage class]] )
                myClient->SendFileTransfer( (ICQ2000::FileTransferEvent *)event );
            else
                myClient->SendEvent( event );
        }
////////
//myClient->setTypingIndicator( *(ICQ2000::ContactRef *)[[recipient connectionData] contactRef] , 0x0002 );
////////
    }
}

- (void)uploadDetails:(NSDictionary *)details
{
    if (isLoggedIn)
    {
        ICQ2000::ContactRef		c2k = myClient->getSelfContact();
        ICQ2000::Contact::MainHomeInfo	mhi = c2k->getMainHomeInfo();
        ICQ2000::Contact::HomepageInfo	hpi = c2k->getHomepageInfo();
        CFStringEncoding		encoding = [target textEncoding];
        const char			*detailString;
        
        mhi.alias = ((detailString = [[details objectForKey:ICJNicknameDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.firstname = ((detailString = [[details objectForKey:ICJFirstNameDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.lastname = ((detailString = [[details objectForKey:ICJLastNameDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.email = ((detailString = [[details objectForKey:ICJEmailDetail] cString]) ? detailString : "");
        mhi.city = ((detailString = [[details objectForKey:ICJHomeCityDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.state = ((detailString = [[details objectForKey:ICJHomeStateDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.phone = ((detailString = [[details objectForKey:ICJHomePhoneDetail] cString]) ? detailString : "");
        hpi.homepage = ((detailString = [[details objectForKey:ICJHomepageDetail] cString]) ? detailString : "");
        mhi.fax = ((detailString = [[details objectForKey:ICJHomeFaxDetail] cString]) ? detailString : "");
        mhi.street = ((detailString = [[details objectForKey:ICJHomeStreetDetail] cStringWithEncoding:encoding]) ? detailString : "");
        mhi.setMobileNo( ((detailString = [[details objectForKey:ICJHomeCellularDetail] cString]) ? detailString : "") );
        mhi.zip =  ((detailString = [[details objectForKey:ICJHomeZipDetail] cString]) ? detailString : "");
        mhi.country = (ICQ2000::Country)[[details objectForKey:ICJHomeCountryCodeDetail] intValue];
        hpi.age = [[details objectForKey:ICJStaticAgeDetail] intValue];
        hpi.sex = (ICQ2000::Sex)[[details objectForKey:ICJSexCodeDetail] intValue];
        {
            NSCalendarDate *birthDate = [details objectForKey:ICJBirthDateDetail];
            if (birthDate)
            {
                hpi.birth_year = [birthDate yearOfCommonEra];
                hpi.birth_month = [birthDate monthOfYear];
                hpi.birth_day = [birthDate dayOfMonth];
            }
            else
            {
                hpi.birth_year = hpi.birth_month = hpi.birth_day = 0;
            }
        }
        {
            NSArray *languageCodes;
            if (languageCodes = [details objectForKey:ICJLanguageCodesDetail])
            {
                hpi.lang1 = (ICQ2000::Language)[[languageCodes objectAtIndex:0] intValue];
                hpi.lang2 = (ICQ2000::Language)[[languageCodes objectAtIndex:1] intValue];
                hpi.lang3 = (ICQ2000::Language)[[languageCodes objectAtIndex:2] intValue];
            }
        }
        c2k->setMainHomeInfo( mhi );
        c2k->setHomepageInfo( hpi );
        c2k->setAboutInfo( ((detailString = [[details objectForKey:ICJAboutDetail] cStringWithEncoding:encoding]) ? detailString : "") );
        myClient->uploadSelfDetails();
    }
}

- (void)requestServerBasedList
{
    if ( isLoggedIn )
        myClient->fetchServerBasedContactList();
}

- (void)messageAcknowledged:(NSData *)messageEvent finished:(BOOL)isFinished delivered:(BOOL)wasDelivered failureReason:(ICJDeliveryFailureReason)reason awayMessage:(NSString *)theAwayMessage
{
    id message = [messagesPendingAck objectForKey:messageEvent];
    
    if ( message )
    {
        if ( isFinished )
        {
            [[message retain] autorelease];
            [messagesPendingAck removeObjectForKey:messageEvent];
        }
        
        [message setFinished:isFinished];
        [message setDelivered:wasDelivered];
        [message setDeliveryFailureReason:reason];
        [message setStatusMessage:theAwayMessage];
        [target messageAcknowledged:message];
    }
}

- (void)findContactsByUin:(ICQUIN)theUin refCon:(id)object
{
    ICQ2000::SearchResultEvent *sre = myClient->searchForContacts(theUin);
    [searchesPendingResult setObject:object forKey:[NSData dataWithBytes:&sre length:sizeof (sre)]];
}

- (void)findContactsByEmail:(NSString *)theEmail refCon:(id)object
{
    ICQ2000::SearchResultEvent *sre = myClient->searchForContacts("", "", "", [theEmail cString],
                                ICQ2000::RANGE_NORANGE, (ICQ2000::Sex)0, (unsigned char)0, "", "", (short unsigned int)0, "", "", "", NO);
    [searchesPendingResult setObject:object forKey:[NSData dataWithBytes:&sre length:sizeof (sre)]];
}

- (void)findContactsByName:(NSString *)theNickname firstName:(NSString *)theFirstName lastName:(NSString *)theLastName refCon:(id)object
{
    ICQ2000::SearchResultEvent *sre = myClient->searchForContacts([theNickname cString], [theFirstName cString], [theLastName cString]);
    [searchesPendingResult setObject:object forKey:[NSData dataWithBytes:&sre length:sizeof (sre)]];
}

- (void)refreshInfoForContact:(ICJContact *)theContact
{
    myClient->fetchDetailContactInfo( *(ICQ2000::ContactRef *)[[theContact connectionData] contactRef] );
}

- (void)retrieveUserInfo
{
    myClient->fetchSelfDetailContactInfo();
}

- (void)contact:(ICQUIN)theUin detailsChangedTo:(NSDictionary *)details
{
    ICJContact	*contact = [target contactWithUin:theUin create:NO];

    if ( contact )
        [contact setDetails:details];
}

- (void)userInfoChangedTo:(NSDictionary *)details
{
    [[target user] setDetails:details];
}

- (void)searchResult:(ICJContact *)contact authorizationRequired:(BOOL)authReq last:(BOOL)isLast resultEvent:(NSData *)theResultEvent
{
    NSDictionary *result = nil;
    id myRefCon = [searchesPendingResult objectForKey:theResultEvent];
    if (contact)
    {
        result = [NSDictionary dictionaryWithObjectsAndKeys:
                    contact,				ICJContactKey,
                    [NSNumber numberWithBool:authReq],	ICJAuthorizationRequiredKey,
                    nil];
    }
    if (myRefCon)
    {
        [[myRefCon retain] autorelease];
        if (isLast)
            [searchesPendingResult removeObjectForKey:theResultEvent];
        [target search:myRefCon returnedResult:result isLast:isLast];
    }
}

- (void)serverAddedContact:(ICJContact *)theContact nickname:(NSString *)theNickname
{
    [target serverAddedContact:theContact nickname:theNickname];
}

- (BOOL)isLoggedIn
{
    return isLoggedIn;
}

- (void)addContact:(ICJContact *)theContact
{
    ICQ2000::ContactRef		*c2k = (ICQ2000::ContactRef *)[[theContact connectionData] contactRef];
    
    if ( !c2k )
    {
        [theContact
            setConnectionData:[LibContactRef
                libContactRefWithLibContact: new ICQ2000::Contact( [theContact uin] )
            ]
        ];
        c2k = (ICQ2000::ContactRef *)[[theContact connectionData] contactRef];
    }
    
    if ( ![theContact isDeleted] && ![theContact isPendingAuthorization] && ![theContact isTemporary] )
    {
        myClient->getContactTree().lookup_group( 0x13a0 ).add( *c2k );
        if ( [theContact isOnVisibleList] )
            [self addVisible:theContact];
        else if ( [theContact isOnInvisibleList] )
            [self addInvisible:theContact];
    }
    if ( (*c2k)->getStatus()!=ICQ2000::STATUS_OFFLINE )
        [self
            contact:(*c2k)->getUIN()
            statusChangedTo:(*c2k)->getStatus()
            invisible:(*c2k)->isInvisible()
            typingFlags:(*c2k)->getTypingFlags()
        ];
}

- (void)deleteContact:(ICJContact *)theContact
{
    ICQUIN	uin = [theContact uin];
    
    myClient->getContactTree().remove(uin);
}

- (void)addVisible:(ICJContact *)theContact
{
    myClient->addVisible( *(ICQ2000::ContactRef *)[[theContact connectionData] contactRef] );
}

- (void)removeVisible:(ICJContact *)theContact
{
    myClient->removeVisible( [theContact uin] );
}

- (void)addInvisible:(ICJContact *)theContact;
{
    myClient->addInvisible( *(ICQ2000::ContactRef *)[[theContact connectionData] contactRef] );
}

- (void)removeInvisible:(ICJContact *)theContact
{
    myClient->removeInvisible( [theContact uin] );
}

- (CFStringEncoding)textEncodingForUin:(ICQUIN)theUin
{
    return [target textEncodingForUin:theUin];
}

- (ICJContact *)contactWithLibContact:(ICQ2000::ContactRef)c2k
{
    ICQUIN	uin = c2k->getUIN();
    ICJContact	*contact = [target contactWithUin:uin create:YES];
    
    if ( [contact connectionData]==nil )
    {
        c2k->userinfo_change_signal.connect( _glue ,&icq2000Glue::contact_info_change_cb );
        [contact
            setConnectionData:[LibContactRef libContactRefWithLibContact:c2k.get()]
        ];
    }
    return contact;
}

- (void)receivedMessage:(id)message
{
    [target receivedMessage:message];
}

- (void)addSocket:(int)theSocket toArrayIndex:(int)theSocketArrayIndex
{
    [[socketArrays objectAtIndex:theSocketArrayIndex] addObject:[NSNumber numberWithInt:theSocket]];
}

- (void)removeSocket:(int)theSocket fromArrayIndex:(int)theSocketArrayIndex
{
    [[socketArrays objectAtIndex:theSocketArrayIndex] removeObject:[NSNumber numberWithInt:theSocket]];
}

@end

icq2000Glue::icq2000Glue(ICQ2000::Client *theclient, ICQConnection *owner, bool log, bool logPackets) : targetclient(theclient), isLogging(log), isLoggingPackets(logPackets)
{
    // who are we working for?
    _owner = owner;
    // set up Callbacks
    theclient->connected.connect( this, &icq2000Glue::connected_cb );
    theclient->disconnected.connect( this, &icq2000Glue::disconnected_cb );
    theclient->messaged.connect( this, &icq2000Glue::message_cb );
    theclient->filetransfer_incoming_signal.connect( this, &icq2000Glue::filetransfer_cb );
    theclient->messageack.connect( this, &icq2000Glue::messageack_cb );
    theclient->logger.connect( this, &icq2000Glue::logger_cb );
    theclient->socket.connect( this, &icq2000Glue::socket_cb );
    theclient->want_auto_resp.connect( this, &icq2000Glue::mywant_auto_resp_cb );
    theclient->self_contact_status_change_signal.connect( this, &icq2000Glue::self_status_change_cb );
    theclient->self_contact_userinfo_change_signal.connect( this, &icq2000Glue::self_info_change_cb );
    theclient->contact_status_change_signal.connect( this, &icq2000Glue::contact_status_change_cb );
    theclient->contact_userinfo_change_signal.connect( this, &icq2000Glue::contact_info_change_cb );
    theclient->search_result.connect( this, &icq2000Glue::search_result_cb );
    theclient->contactlist.connect( this, &icq2000Glue::server_based_list_cb );
}

NSDictionary *icq2000Glue::detailsDictionaryFromContact(ICQ2000::ContactRef c2k)
{
    CFStringEncoding encoding = [_owner textEncodingForUin:c2k->getUIN()];
    ICQ2000::Contact::HomepageInfo hpi = c2k->getHomepageInfo();
    ICQ2000::Contact::MainHomeInfo mhi = c2k->getMainHomeInfo();
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [NSString stringWithCString:c2k->getAlias().c_str() encoding:encoding], ICJNicknameDetail,
        [NSString stringWithCString:c2k->getFirstName().c_str() encoding:encoding], ICJFirstNameDetail,
        [NSString stringWithCString:c2k->getLastName().c_str() encoding:encoding], ICJLastNameDetail,
        [NSString stringWithCString:c2k->getEmail().c_str()], ICJEmailDetail,
        [NSString stringWithCString:mhi.city.c_str() encoding:encoding],	ICJHomeCityDetail,
        [NSString stringWithCString:mhi.state.c_str() encoding:encoding],	ICJHomeStateDetail,
        [NSString stringWithCString:mhi.phone.c_str()],	ICJHomePhoneDetail,
        [NSString stringWithCString:mhi.fax.c_str()],	ICJHomeFaxDetail,
        [NSString stringWithCString:mhi.street.c_str() encoding:encoding],	ICJHomeStreetDetail,
        [NSString stringWithCString:mhi.getMobileNo().c_str()],	ICJHomeCellularDetail,
        [NSString stringWithCString:mhi.zip.c_str()],	ICJHomeZipDetail,
        [NSNumber numberWithInt:mhi.country],		ICJHomeCountryCodeDetail,
        [NSNumber numberWithInt:hpi.age],			ICJStaticAgeDetail,
        [NSNumber numberWithInt:hpi.sex],			ICJSexCodeDetail,
        [NSString stringWithCString:hpi.homepage.c_str()],	ICJHomepageDetail,
        [NSString stringWithCString:c2k->getAboutInfo().c_str() encoding:encoding], ICJAboutDetail,
        [NSArray arrayWithObjects:
            [NSNumber numberWithChar:hpi.lang1],
            [NSNumber numberWithChar:hpi.lang2],
            [NSNumber numberWithChar:hpi.lang3],
            nil],						ICJLanguageCodesDetail,
        [NSNumber numberWithBool:c2k->getAuthReq()],		ICJAuthorizationRequiredDetail,
        nil];
    if (hpi.birth_year)
        [dictionary setObject:
            [NSCalendarDate dateWithYear:hpi.birth_year
                                month:hpi.birth_month
                                    day:hpi.birth_day
                                    hour:0 minute:0 second:0
                                timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]]
                            forKey:ICJBirthDateDetail];
    return dictionary;
}

void icq2000Glue::self_info_change_cb(ICQ2000::UserInfoChangeEvent *ev)
{
    if ( !ev->isTransientDetail() )
        [_owner userInfoChangedTo:detailsDictionaryFromContact(ev->getContact())];
}

void icq2000Glue::self_status_change_cb(ICQ2000::StatusChangeEvent *ev)
{
    [_owner userStatusCodeChangedTo:ev->getStatus() invisible:ev->getContact()->isInvisible()];
}

void icq2000Glue::contact_info_change_cb(ICQ2000::UserInfoChangeEvent *ev)
{
    if ( !ev->isTransientDetail() )
        [_owner contact:ev->getUIN() detailsChangedTo:detailsDictionaryFromContact(ev->getContact())];
}

void icq2000Glue::contact_status_change_cb(ICQ2000::StatusChangeEvent *ev)
{
    [_owner
        contact:ev->getUIN()
        statusChangedTo:ev->getStatus()
        invisible:ev->getContact()->isInvisible()
        typingFlags:ev->getContact()->getTypingFlags()
    ];
}

void icq2000Glue::mywant_auto_resp_cb(ICQ2000::ICQMessageEvent *me)
{
    const char		*message = [_owner statusMessageForUIN:me->getContact()->getUIN()];
    me->setAwayMessage( message );
}

void icq2000Glue::connected_cb(ICQ2000::ConnectedEvent *ce)
{
    [_owner loggedIn];
}

void icq2000Glue::disconnected_cb(ICQ2000::DisconnectedEvent *de)
{
    ICJDisconnectReason		reason;
    
    switch ( de->getReason() )
    {
        case ICQ2000::DisconnectedEvent::REQUESTED:
            reason = ICJRequestedDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_LOWLEVEL:
            reason = ICJLowLevelDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_TURBOING:
            reason = ICJTurboingDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_BADPASSWORD:
            reason = ICJBadPasswordDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_MISMATCH_PASSWD:
            reason = ICJMismatchPasswordDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_DUALLOGIN:
            reason = ICJDualLoginDisconnectReason;
            break;
        case ICQ2000::DisconnectedEvent::FAILED_UNKNOWN:
        default:
            reason = ICJUnknownDisconnectReason;
    }
    [_owner disconnected:reason];
}

void icq2000Glue::filetransfer_cb(ICQ2000::FileTransferEvent *fte) {
    message_cb(fte);
}

void icq2000Glue::message_cb(ICQ2000::MessageEvent *me)
{
    id		message = nil;
    ICJContact	*contact = [_owner contactWithLibContact:me->getContact()];
    
    switch ( me->getType() )
    {
        case ICQ2000::MessageEvent::Normal:
            {
                ICQ2000::NormalMessageEvent *nme = static_cast<ICQ2000::NormalMessageEvent *>(me);
                NSString *messageString;
				
				if ( nme->getTextEncoding()==ICQ2000::ENCODING_UCS2 ) {
                                    #if __BIG_ENDIAN__
                                        // Avoid using the 10.4-only kCFStringEncodingUTF16BE in the PPC build
					messageString = [NSString stringWithCharacters:(const unichar *)nme->getMessage().c_str() length:nme->getMessage().length()/2];
                                    #else
                                        messageString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, (const UInt8 *)nme->getMessage().c_str(), nme->getMessage().length(), kCFStringEncodingUTF16BE, false);
                                        [messageString autorelease];
                                    #endif
                                } else if ( nme->getTextEncoding()==ICQ2000::ENCODING_UTF8 )
					messageString = [NSString stringWithUTF8String:nme->getMessage().c_str()];
				else
					messageString = [NSString stringWithCString:nme->getMessage().c_str() encoding:[_owner textEncodingForUin:nme->getSenderUIN()]];

                message = [ICQNormalMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:nme->getTime()]];
                [message setUrgent:nme->isUrgent()];
                [message setToContactList:nme->isToContactList()];
                [message setText:messageString];
            }
            break;
        case ICQ2000::MessageEvent::FileTransfer:
            {
                ICQ2000::FileTransferEvent	*fte = static_cast<ICQ2000::FileTransferEvent *>(me);
                NSString			*messageString = [NSString
                    stringWithCString:fte->getMessage().c_str()
                    encoding:[_owner textEncodingForUin:fte->getSenderUIN()]
                ];
                ICQFileTransfer			*fileTransfer = [[ICQFileTransfer new] autorelease];
                
                message = [ICQFileTransferMessage
                    messageFrom:contact
                    date:[NSDate dateWithTimeIntervalSince1970:fte->getTime()]
                ];

                [message setFileTransfer:fileTransfer];
                (fileTransfer->_glue)->setEvent( targetclient, fte );

                [message setUrgent:fte->isUrgent()];
                [message setToContactList:fte->isToContactList()];
                [message setText:messageString];
                [message setDescription:[NSString stringWithCString:fte->getDescription().c_str()]];
                [fileTransfer setFiles:[NSArray array]];
                [fileTransfer setSize:fte->getTotalSize()];
                break;
            }
        case ICQ2000::MessageEvent::SMS:
            {
                ICQ2000::SMSMessageEvent *sme = static_cast<ICQ2000::SMSMessageEvent *>(me);
                NSString *messageString = [NSString stringWithCString:sme->getMessage().c_str() /* encoding:[_owner textEncodingForUin:nme->getSenderUIN()] */ ];

                message = [SMSMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:sme->getTime()]];
                [message setText:messageString];
            }
            break;
        case ICQ2000::MessageEvent::URL:
            {
                ICQ2000::URLMessageEvent *ume = static_cast<ICQ2000::URLMessageEvent *>(me);
                NSString *messageString = [NSString stringWithCString:ume->getMessage().c_str() encoding:[_owner textEncodingForUin:ume->getSenderUIN()]];

                message = [ICQURLMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:ume->getTime()]];
                [message setUrgent:ume->isUrgent()];
                [message setToContactList:ume->isToContactList()];
                [message setText:messageString];
                [message setUrl:[NSString stringWithCString:ume->getURL().c_str()]];
            }
            break;
        case ICQ2000::MessageEvent::AuthAck:
            {
                ICQ2000::AuthAckEvent *aae = static_cast<ICQ2000::AuthAckEvent *>(me);
                NSString *messageString = [NSString stringWithCString:aae->getMessage().c_str() encoding:[_owner textEncodingForUin:aae->getSenderUIN()]];

                message = [ICQAuthAckMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:aae->getTime()]];
                [message setUrgent:aae->isUrgent()];
                [message setToContactList:aae->isToContactList()];
                [message setText:messageString];
                [message setGranted:aae->isGranted()];
            }
            break;
        case ICQ2000::MessageEvent::AuthReq:
            {
                ICQ2000::AuthReqEvent *are = static_cast<ICQ2000::AuthReqEvent *>(me);
                NSString *messageString = [NSString stringWithCString:are->getMessage().c_str() encoding:[_owner textEncodingForUin:are->getSenderUIN()]];

                message = [ICQAuthReqMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:are->getTime()]];
                [message setUrgent:are->isUrgent()];
                [message setToContactList:are->isToContactList()];
                [message setText:messageString];
            break;
            }
        case ICQ2000::MessageEvent::UserAdd:
            {
                ICQ2000::UserAddEvent *uae = static_cast<ICQ2000::UserAddEvent *>(me);
                message = [ICQUserAddedMessage messageFrom:contact date:[NSDate dateWithTimeIntervalSince1970:uae->getTime()]];
                [message setUrgent:uae->isUrgent()];
                [message setToContactList:uae->isToContactList()];
            }
            break;
        default:
            break;
    }
    if ( message )
    {
        [_owner receivedMessage:message];
        me->setDelivered( [message isDelivered] );
        me->setDeliveryFailureReason( (ICQ2000::MessageEvent::DeliveryFailureReason)[message deliveryFailureReason] );
    }
}

void icq2000Glue::messageack_cb( ICQ2000::MessageEvent *me )
{
    NSString	*awayMessage;
    
    awayMessage = [NSString
        stringWithCString:static_cast<ICQ2000::ICQMessageEvent *>(me)->getAwayMessage().c_str()
        encoding:[_owner textEncodingForUin:me->getContact()->getUIN()]
    ];
    
    [_owner
        messageAcknowledged:[NSData dataWithBytes:&me length:sizeof(me)]
        finished:( me->isFinished()!=false )
        delivered:( me->isDelivered()!=false )
        failureReason:(ICJDeliveryFailureReason)(me->getDeliveryFailureReason())
        awayMessage:awayMessage
    ];
}

void icq2000Glue::logger_cb(ICQ2000::LogEvent *le)
{
    if ( isLogging )
    {
        if ( le->getType()!=ICQ2000::LogEvent::PACKET || isLoggingPackets )
            NSLog( @"%s", le->getMessage().c_str() );
    }
}

void icq2000Glue::search_result_cb(ICQ2000::SearchResultEvent *sre)
{
    ICQ2000::ContactRef		c2k = sre->getLastContactAdded();
    
    if ( c2k.get()!=NULL )
    {
        ICJContact		*contact = [[[ICJContact alloc] initWithNickname:@"" uin:c2k->getUIN()] autorelease];
        
        [contact setDetails:detailsDictionaryFromContact( c2k )];
        [contact setConnectionData:[LibContactRef libContactRefWithLibContact:c2k.get()]];

        [_owner
            searchResult:contact
            authorizationRequired:c2k->getAuthReq()
            last:sre->isFinished()
            resultEvent:[NSData dataWithBytes:&sre length:sizeof(sre)]
        ];
    }
    else
        [_owner
            searchResult:nil
            authorizationRequired:NO
            last:sre->isFinished()
            resultEvent:[NSData dataWithBytes:&sre length:sizeof(sre)]
        ];
}

void icq2000Glue::server_based_list_cb(ICQ2000::ContactListEvent *sbe)
{
    if ( sbe->getType()==ICQ2000::ContactListEvent::UserAdded )
    {
        ICQ2000::ContactRef	c2k = static_cast<ICQ2000::UserAddedEvent *>(sbe)->getContact();
        ICJContact			*contact = [_owner
            contactWithLibContact:c2k
        ];
        NSString		*nickname = [NSString
            stringWithUTF8String:c2k->getAlias().c_str()
        ];
        
        [_owner
            serverAddedContact:contact
            nickname:nickname
        ];
    }
}

void icq2000Glue::socket_cb(ICQ2000::SocketEvent *se)
{
    if ( dynamic_cast<ICQ2000::AddSocketHandleEvent*>(se) != NULL )
    {
        ICQ2000::AddSocketHandleEvent		*ase = dynamic_cast<ICQ2000::AddSocketHandleEvent*>(se);
        
        if ( ase->isRead() )
            [_owner addSocket:ase->getSocketHandle() toArrayIndex:0];
        if ( ase->isWrite() )
            [_owner addSocket:ase->getSocketHandle() toArrayIndex:1];
        if ( ase->isException() )
            [_owner addSocket:ase->getSocketHandle() toArrayIndex:2];
    }
    else if ( dynamic_cast<ICQ2000::RemoveSocketHandleEvent*>(se) != NULL )
    {
        ICQ2000::RemoveSocketHandleEvent	*rse = dynamic_cast<ICQ2000::RemoveSocketHandleEvent*>(se);
        
        [_owner removeSocket:rse->getSocketHandle() fromArrayIndex:0];
        [_owner removeSocket:rse->getSocketHandle() fromArrayIndex:1];
        [_owner removeSocket:rse->getSocketHandle() fromArrayIndex:2];
    }
}
