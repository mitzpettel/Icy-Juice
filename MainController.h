/*
 * MainController.h
 * Icy Juice
 *
 * Created by Mitz Pettel in May 2001.
 *
 * Copyright (c) 2001-2002 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "IcyJuice.h"
#import "Contact.h"

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import <SystemConfiguration/SystemConfiguration.h>

@class ICQUserDocument;

@interface MainController : NSObject
{
    NSMutableDictionary	*contactStatuses;
    NSMutableDictionary *contactInfoControllers;
    NSCountedSet	*documentsRequiringAttention;
    BOOL		requiresAttention;
    NSMenu		*dockMenu;
    NSMutableDictionary	*documentDockMenus;
    NSDictionary	*countryTable;
    NSDictionary	*languageTable;
    NSDictionary	*sexTable;
    NSDictionary	*settings;
    NSArray		*userStatuses;
    NSArray		*statusMessageStatuses;
    NSMutableDictionary	*sounds;
    NSMutableArray	*windowsToOrderFrontWhenUnhidden;
    IBOutlet NSMenuItem	*sendMessageMenuItem;
	    
    SCDynamicStoreRef SCDStore;
}

- (void)icqUserDocumentRequiresAttention:(ICQUserDocument *)theDocument;
- (void)icqUserDocumentGotAttention:(ICQUserDocument *)theDocument;
- (void)registerDockMenu:(NSMenu *)theMenu forDocument:(ICQUserDocument *)theDocument;
- (void)unregisterDockMenu:(NSMenu *)theMenu;
//- (IBAction)newContactList:(id)sender;
- (IBAction)showInfoPanel:(id)sender;
- (IBAction)showFindPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;
- (IBAction)orderFrontStandardAboutPanel:(id)sender;
- (ContactStatus *)statusForKey:(id)key;
- (NSArray *)userStatuses;
- (NSArray *)statusMessageStatuses;
// NSApplication delegate
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (id)settingWithName:(NSString *)name;
- (NSDictionary *)sexTable;
- (NSString *)nameForSexCode:(NSNumber *)sexCode;
- (NSDictionary *)countryTable;
- (NSString *)nameForCountryCode:(NSNumber *)countryCode;
- (NSDictionary *)languageTable;
- (NSString *)nameForLanguageCode:(NSNumber *)languageCode;
- (NSSound *)soundWithNameOrPath:(NSString *)name refetch:(BOOL)flag;
- (void)requestUserAttention;

- (void)updateSendMessageMenuItem;

- (void)orderFrontWindowWhenUnhidden:(NSWindow *)aWindow;

@end
