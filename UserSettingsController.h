/*
 * UserSettingsController.h
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Nov 30 2001.
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

#import <AppKit/AppKit.h>
#import "HistoryView.h"

@class ICQUserDocument;

@interface UserSettingsController : NSWindowController {
    ICQUserDocument	*document;
    IBOutlet NSButton	*autoPopupCheckbox;
    IBOutlet id		initialStatusPopup;
    IBOutlet id		textEncodingPopup;
    IBOutlet id		windowTypeMatrix;
    IBOutlet NSButton		*ignoreIfNotOnListCheckbox;
    IBOutlet NSButton		*webAwareCheckbox;
    IBOutlet NSButton		*checkSpellingCheckbox;
    IBOutlet NSPopUpButton 	*timeToHideInactivePopup;
    IBOutlet NSTextField	*serverHostField;
    IBOutlet NSTextField	*serverPortField;
    IBOutlet NSTextField	*portRangeStartTextField;
    IBOutlet NSTextField	*portRangeEndTextField;
	IBOutlet NSButton		*displayNetworkAlertCheckbox;
	
    IBOutlet NSTableView	*statusTable;
    IBOutlet NSButton		*promptForStatusCheckbox;
    IBOutlet NSButton		*hideWhenSendingCheckbox;
    IBOutlet NSTextView		*statusMessageField;
    IBOutlet NSView		*paneView;
    
    IBOutlet NSView		*generalPaneView;
    IBOutlet NSView		*messageWindowsPaneView;
    IBOutlet NSView		*statusPaneView;
    IBOutlet NSView		*colorPaneView;
    IBOutlet NSView		*notificationPaneView;
    IBOutlet NSView		*networkPaneView;
    
    IBOutlet NSButton		*silentOccupiedDNDCheckbox;
    IBOutlet NSButton		*silentFrontmostConversationCheckbox;
    IBOutlet NSPopUpButton	*messageSoundPopup;
    IBOutlet NSButton		*idleMinutesCheckbox;
    IBOutlet NSButton		*screenEffectCheckbox;
    IBOutlet NSTextField	*idleMinutesTextField;
    
    IBOutlet NSColorWell	*receivedBackgroundColorWell;
    IBOutlet NSColorWell	*receivedTextColorWell;
    IBOutlet NSColorWell	*sentBackgroundColorWell;
    IBOutlet NSColorWell	*sentTextColorWell;
    IBOutlet NSButton		*receivedFontButton;
    IBOutlet NSButton		*sentFontButton;
    IBOutlet NSTextField	*receivedFontTextField;
    IBOutlet NSTextField	*sentFontTextField;
    IBOutlet NSPopUpButton	*filesDirectoryPopUp;
    
    int				fontPanelAssociation;	// 0 = not ours, 1 = received, 2 = sent
    
    IBOutlet HistoryView	*sampleHistoryView;
    
    NSString			*selectedStatusKey;
    NSMutableDictionary		*statusMessages;
    
    NSFont			*receivedFont;
    NSFont			*sentFont;
    
}

- (IBAction)useDefaultICQServer:(id)sender;
- (IBAction)OK:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)tabChoiceChanged:(id)sender;
- (IBAction)messageSoundChanged:(id)sender;
- (IBAction)idleMinutesCheckboxChanged:(id)sender;
- (IBAction)colorChanged:(id)sender;
- (IBAction)fontButtonClicked:(id)sender;
- (IBAction)changedFilesDirectory:(id)sender;
- (id)initForWindow:(NSWindow *)theParentWindow document:(ICQUserDocument *)theDocument;

@end
