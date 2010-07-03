/*
 * IcyJuice.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 23 2001.
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

#import <objc/objc-runtime.h>

#import "NSDate-MPAdditions.h"
#import "NSString-MPAdditions.h"
#import "NSSound-MPAdditions.h"
#import "NSColor-MPAdditions.h"
#import "NSWindowController-ICJAdditions.h"

// in seconds
#define ICJHistorySavingTimeInterval			60

#define ICJContactInfoChangedNotification		@"ICJContactInfoChangedNotification"
#define ICJContactStatusChangedNotification		@"ICJContactStatusChangedNotification"
#define ICJContactQueueChangedNotification		@"ICJContactQueueChangedNotification"
#define ICJContactStatusMessageChangedNotification	@"ICJContactStatusMessageChangedNotification"
#define ICJUserInfoChangedNotification			@"ICJUserInfoChangedNotification"
#define ICJContactListSelectionDidChangeNotification	@"ICJContactListSelectionDidChangeNotification"
#define ICJWrongPasswordNotification			@"ICJWrongPasswordNotification"
#define ICJNeedPasswordNotification			@"ICJNeedPasswordNotification"
#define ICJUserStatusChangedNotification		@"ICJUserStatusChangedNotification"
#define ICJContactListChangedNotification		@"ICJContactListChangedNotification"
#define ICJLoginStatusChangedNotification		@"ICJLoginStatusChangedNotification"
#define ICJOutGoingMessageSentNotification		@"ICJOutGoingMessageSentNotification"
#define ICJSearchResultNotification			@"ICJSearchResultNotification"
#define ICJSearchFinishedNotification			@"ICJSearchFinishedNotification"
#define ICJMessageAcknowledgedNotification		@"ICJMessageAcknowledgedNotification"
#define ICJMessageRequiresAttentionNotification		@"ICJMessageRequiresAttentionNotification"
#define ICJMessageGotAttentionNotification		@"ICJMessageGotAttentionNotification"

#define MPSystemWillSleepNotification			@"MPSystemWillSleepNotifiaction"
#define MPSystemDidWakeUpNotification			@"MPSystemDidWakeUpNotification"
#define MPSystemConfigurationChangedNotification			@"MPSystemConfigurationChangedNotification"

#define ICJContactRefPboardType				@"ICJContactRefPboardType"

#define ICJUseDialogWindowsSettingName			@"useDialogWindows"
#define ICJTextEncodingSettingName			@"textEncoding"
#define ICJIgnoreIfNotOnListSettingName			@"ignoreIfNotOnList"
#define ICJServerHostSettingName			@"serverHost"
#define ICJServerPortSettingName			@"serverPort"
#define ICJPortRangeStartSettingName		@"port range start"
#define ICJPortRangeEndSettingName			@"port range end"
#define ICJTimeToHideInactiveSettingName		@"timeToHideInactive"
#define ICJSpellCheckAsYouTypeSettingName		@"SpellCheckAsYouType"
#define ICJStatusBarShownSettingName			@"Status Bar Is Shown"
#define ICJStatusMessagesSettingName			@"Status Messages"
#define ICJPromptForStatusMessageSettingName		@"Prompt For Status Message"
#define ICJHideWhenSendingSettingName			@"Hide When Sending"
#define ICJOutgoingStatusBarShownSettingName		@"Outgoing Status Bar Is Shown"
#define ICJWebAwareSettingName				@"webAware"
#define ICJSilentFrontDialogSettingName			@"No Sounds in Frontmost Conversation"
#define ICJSilentOccupiedDNDSettingName			@"No Sounds in Occupied and DND"
#define ICJIncomingSoundSettingName			@"Incoming Message Sound"
#define ICJAutoAwayIdleSecondsSettingName		@"Idle Time For Auto-away"
#define ICJAutoAwayIdleSettingName			@"Auto-away After Idle Time"
#define ICJAutoAwayScreenSaverSettingName		@"Auto-away Follows Screen Saver"
#define ICJIncomingBackgroundSettingName		@"Incoming Message Background Color"
#define ICJIncomingColorSettingName			@"Incoming Message Text Color"
#define ICJIncomingFontSettingName			@"Incoming Message Font Name"
#define ICJIncomingSizeSettingName			@"Incoming Message Font Size"
#define ICJOutgoingBackgroundSettingName		@"Outgoing Message Background Color"
#define ICJOutgoingColorSettingName			@"Outgoing Message Text Color"
#define ICJOutgoingFontSettingName			@"Outgoing Message Font Name"
#define ICJOutgoingSizeSettingName			@"Outgoing Message Font Size"

#define ICJDisplayNetworkAlertsSettingName		@"display network alerts"

#define ICJFilesDirectorySettingName			@"Directory "

#define ICJIncomingToolbarIdentifier			@"ICJIncomingToolbarIdentifier"
#define ICJNextMessageToolbarItemIdentifier		@"ICJNextMessageToolbarItemIdentifier"
#define ICJReplyToolbarItemIdentifier			@"ICJReplyToolbarItemIdentifier"
#define ICJOutgoingToolbarIdentifier			@"ICJOutgoingToolbarIdentifier"
#define ICJDialogToolbarIdentifier			@"ICJDialogToolbarIdentifier"
#define ICJShowHistoryToolbarItemIdentifier		@"ICJShowHistoryToolbarItemIdentifier"
#define ICJShowInfoToolbarItemIdentifier		@"ICJShowInfoToolbarItemIdentifier"
#define ICJSendToolbarItemIdentifier			@"ICJSendToolbarItemIdentifier"
#define ICJHistoryToolbarIdentifier			@"ICJHistoryToolbarIdentifier"
#define ICJSaveHistoryToolbarItemIdentifier		@"ICJSaveHistoryToolbarItemIdentifier"
#define ICJDeleteHistoryToolbarItemIdentifier		@"ICJDeleteHistoryToolbarItemIdentifier"
#define ICJAddContactToolbarItemIdentifier		@"ICJAddContactToolbarItemIdentifier"
#define ICJShowRecipientsToolbarItemIdentifier		@"ICJShowRecipientsToolbarItemIdentifier"

#define ICJDefaultContactListUserDefault		@"Default contact list"
#define ICJDockIconBehaviorUserDefault			@"Dock icon behavior"
#define ICJSendMessageKeyUserDefault			@"Send Message keyboard shortcut"

#define ICJDetailsKey					@"details"
#define ICJSettingsKey					@"settings"

#define ICJContactKey					@"ICJContact"
#define ICJAuthorizationRequiredKey			@"ICJAuthorizationRequired"

#define ICJStaticAgeDetail				@"staticAge"
#define ICJBirthDateDetail				@"birthDate"
#define ICJSexCodeDetail				@"sexCode"
#define ICJHomeCityDetail				@"homeCity"
#define ICJHomeCountryCodeDetail			@"homeCountryCode"
#define ICJHomeCellularDetail				@"homeCellular"
#define ICJHomeFaxDetail				@"homeFax"
#define ICJHomepageDetail				@"homepage"
#define ICJHomePhoneDetail				@"homePhone"
#define ICJHomeStateDetail				@"homeState"
#define ICJHomeStreetDetail				@"homeStreet"
#define ICJHomeZipDetail				@"homeZip"
#define ICJHomeCityDetail				@"homeCity"
#define ICJNicknameDetail				@"nickname"
#define ICJFirstNameDetail				@"firstName"
#define ICJLastNameDetail				@"lastName"
#define ICJEmailDetail					@"email"
#define ICJAboutDetail					@"about"
#define ICJLanguageCodesDetail				@"languageCodes"
#define ICJAuthorizationRequiredDetail			@"authorizationRequired"

typedef enum {
    ICJDockIconBlinkOnly = 0,
    ICJDockIconBounceOnce,
    ICJDockIconBounceMany
} ICJDockIconBehavior;

typedef enum _ICJDisconnectReason {
      ICJRequestedDisconnectReason,
      ICJLowLevelDisconnectReason,
      ICJBadUserNameDisconnectReason,
      ICJTurboingDisconnectReason,
      ICJBadPasswordDisconnectReason,
      ICJMismatchPasswordDisconnectReason,
      ICJDualLoginDisconnectReason,
      ICJUnknownDisconnectReason
} ICJDisconnectReason;

enum {ICJParentWindowClosing = 99
};

@class ICJContact;
@class ICQUserDocument;

@protocol ICJIncomingMessageDisplay

+ (id)incomingMessageController:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget;
- (id)initWithContact:(ICJContact *)theSender forDocument:(ICQUserDocument *)theTarget;
- (void)messageAdded;

@end