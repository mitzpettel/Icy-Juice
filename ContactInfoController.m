/*
 * ContactInfoController.m
 * Icy Juice
 *
 * Created by Mitz Pettel in May 2001.
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

#import "ContactInfoController.h"
#import "ContactListWindowController.h"
#import "ICQUserDocument.h"
#import "MainController.h"
#import "MPURLTextField.h"

@implementation ContactInfoController

+ (id)sharedContactInfoController {
    static ContactInfoController *sharedContactInfoObject = nil;
    
    if (!sharedContactInfoObject) {
        sharedContactInfoObject = [[self alloc] init];
    }
    return sharedContactInfoObject;
}

- (id)init {
    self = [self initWithWindowNibName:@"ContactInfo"];
    if (self) {
        [self setWindowFrameAutosaveName:@"ContactInfo"];
        needsUpdate = NO;
    }
    return self;
}

- (void)initTextEncodingMenu
{
    NSMenuItem *menuItem;
    const CFStringEncoding *encodingList = CFStringGetListOfAvailableEncodings();
    int i = 0;
    while (encodingList[i]!=kCFStringEncodingInvalidId)
    {
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:(NSString *)CFStringGetNameOfEncoding(encodingList[i])];
        [menuItem setTag:encodingList[i]];
        [[textEncodingPopup menu] addItem:menuItem];
        i++;
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
    [refreshButton retain];
    
    [homepageField setEditable:NO];
    [homepageField setSelectable:YES];
    [homepageField setDrawsBackground:NO];
    [homepageField setBezeled:NO];
    [homepageField setTextColor:[NSColor blueColor]];
    [homepageField setFont:[genderField font]];
    
    [emailField setEditable:NO];
    [emailField setSelectable:YES];
    [emailField setDrawsBackground:NO];
    [emailField setBezeled:NO];
    [emailField setTextColor:[NSColor blueColor]];
    [emailField setFont:[genderField font]];
    
    [self initTextEncodingMenu];
    [self setMainWindow:[NSApp mainWindow]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
    needsUpdate = YES;
}

- (void)dealloc
{
    [refreshButton release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (IBAction)refresh:(id)sender
{
    [refreshButton setEnabled:NO];
    [currentDocument refreshInfoForContact:inspectingContact];
}

- (IBAction)changeWindowType:(id)sender
{
    int selection = [[sender selectedCell] tag];
    if (selection==0)
        [[inspectingContact settings] removeObjectForKey:ICJUseDialogWindowsSettingName];
    else
        [[inspectingContact settings] setObject:[NSNumber numberWithBool:(selection==1)]
                                     forKey:ICJUseDialogWindowsSettingName];
}

- (IBAction)changeTextEncoding:(id)sender
{
    if ([sender indexOfSelectedItem]==0)
        [[inspectingContact settings] removeObjectForKey:ICJTextEncodingSettingName];
    else
        [[inspectingContact settings] setObject:[NSNumber numberWithInt:[[sender selectedItem] tag]]
                                         forKey:ICJTextEncodingSettingName];
}

- (IBAction)visibleListCheckboxChanged:(id)sender
{
    if ([visibleListCheckbox state])
        [currentDocument addToVisibleList:inspectingContact];
    else
        [currentDocument removeFromVisibleList:inspectingContact];
}

- (IBAction)invisibleListCheckboxChanged:(id)sender
{
    if ([invisibleListCheckbox state])
        [currentDocument addToInvisibleList:inspectingContact];
    else
        [currentDocument removeFromInvisibleList:inspectingContact];
}

- (IBAction)ignoreCheckboxChanged:(id)sender
{
    [inspectingContact setOnIgnoreList:[ignoreCheckbox state]];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJContactListSelectionDidChangeNotification object:nil];
    [self setMainWindow:nil];
}

- (void)selectionChanged:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJContactInfoChangedNotification object:inspectingContact];
    inspectingContact = [[notification object] selectedContact];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:ICJContactInfoChangedNotification object:inspectingContact];       
    needsUpdate = YES;
}

- (void)infoChanged:(NSNotification *)notification
{
    needsUpdate = YES;
    [[self window] update];
}

- (void)setMainWindow:(NSWindow *)mainWindow {
    id delegate = [mainWindow delegate];
    id oldInspectingContact = inspectingContact;

    if (inspectingContact)
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJContactInfoChangedNotification object:inspectingContact];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ICJLoginStatusChangedNotification object:nil];
    if (delegate && [delegate respondsToSelector:@selector(selectedContact)]) {
        inspectingContact = [(ContactListWindowController *)delegate selectedContact];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChanged:) name:ICJContactListSelectionDidChangeNotification object:delegate];       
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:ICJContactInfoChangedNotification object:inspectingContact];
        currentDocument = [[mainWindow windowController] icqUserDocument];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoChanged:) name:ICJLoginStatusChangedNotification object:currentDocument];
    } else {
        inspectingContact = nil;
    }
    if (inspectingContact!=oldInspectingContact)
        needsUpdate = YES;
}

- (void)windowDidUpdate:(NSNotification *)notification
{
    if (needsUpdate)
    {
        needsUpdate = NO;
        if (inspectingContact)
        {
            NSDictionary *settings = [inspectingContact settings];
            id setting;
            [[self window] setTitle:[NSString stringWithFormat: NSLocalizedString(@"Info on %@", @"info panel title when showing a single contact"), [inspectingContact displayName]]];
            [firstNameField setObjectValue:[inspectingContact firstName]];
            [lastNameField setObjectValue:[inspectingContact lastName]];
            [emailField setObjectValue:[inspectingContact email]];
            [emailField setURL:[NSString stringWithFormat:@"mailto:%@", [inspectingContact email]]];
            [nicknameField setObjectValue:[inspectingContact ownNickname]];
            [uinField setIntValue:[inspectingContact uin]];
            [ageField setObjectValue:[inspectingContact detailForKey:ICJStaticAgeDetail]];
            if ([inspectingContact detailForKey:ICJAboutDetail])
                [aboutField setString:[inspectingContact detailForKey:ICJAboutDetail]];
            else
                [aboutField setString:@""];
            [birthDateField setObjectValue:[[inspectingContact detailForKey:ICJBirthDateDetail] sameDateInTimezone:[NSTimeZone defaultTimeZone]]];
            {
                NSColor *ageFieldColor = ([inspectingContact detailForKey:ICJBirthDateDetail] ? [NSColor grayColor] : [NSColor blackColor]);
                [ageField setTextColor:ageFieldColor];
                [ageLabel setTextColor:ageFieldColor];
            }
            [genderField setObjectValue:[[NSApp delegate] nameForSexCode:[inspectingContact detailForKey:ICJSexCodeDetail]]];
            [homeCityField setObjectValue:[inspectingContact detailForKey:ICJHomeCityDetail]];
            [homeCountryField setObjectValue:[[NSApp delegate] nameForCountryCode:[inspectingContact detailForKey:ICJHomeCountryCodeDetail]]];
            {
                NSMutableArray *languageNames = [NSMutableArray arrayWithCapacity:3];
                NSEnumerator *languageCodes = [[inspectingContact detailForKey:ICJLanguageCodesDetail] objectEnumerator];
                NSNumber *currentLanguageCode;
                NSString *currentLanguageName;
                while (currentLanguageCode = [languageCodes nextObject])
                    if (currentLanguageName = [[NSApp delegate] nameForLanguageCode:currentLanguageCode])
                        [languageNames addObject:currentLanguageName];
                [languagesField setObjectValue:[languageNames componentsJoinedByString:NSLocalizedString(@", ", @"list separator for language list")]];
            }
            [homeCellularField setObjectValue:[inspectingContact detailForKey:ICJHomeCellularDetail]];
            [homeFaxField setObjectValue:[inspectingContact detailForKey:ICJHomeFaxDetail]];
            
            [homepageField setObjectValue:[inspectingContact detailForKey:ICJHomepageDetail]];
            [homepageField setURL:[inspectingContact detailForKey:ICJHomepageDetail]];
            [homePhoneField setObjectValue:[inspectingContact detailForKey:ICJHomePhoneDetail]];
            [homeStateField setObjectValue:[inspectingContact detailForKey:ICJHomeStateDetail]];
            [homeStreetField setObjectValue:[inspectingContact detailForKey:ICJHomeStreetDetail]];
            [homeZipField setObjectValue:[inspectingContact detailForKey:ICJHomeZipDetail]];
            [refreshButton setEnabled:[currentDocument isLoggedIn]];
            [textEncodingPopup setEnabled:YES];
            if (settings && (setting = [settings objectForKey:ICJTextEncodingSettingName]))
                [textEncodingPopup selectItemAtIndex:[textEncodingPopup indexOfItemWithTag:[setting intValue]]];
            else
                [textEncodingPopup selectItemAtIndex:0];
            [windowTypeMatrix setEnabled:YES];
            if (settings && (setting = [settings objectForKey:ICJUseDialogWindowsSettingName]))
                [windowTypeMatrix selectCellWithTag:([setting boolValue] ? 1 : 2)];
            else
                [windowTypeMatrix selectCellWithTag:0];
            [visibleListCheckbox setEnabled:YES];
            [invisibleListCheckbox setEnabled:YES];
            [ignoreCheckbox setEnabled:YES];
            [visibleListCheckbox setState:[inspectingContact isOnVisibleList]];
            [invisibleListCheckbox setState:[inspectingContact isOnInvisibleList]];
            [ignoreCheckbox setState:[inspectingContact isOnIgnoreList]];
        }
        else
        {
            [[self window] setTitle:NSLocalizedString(@"Info", @"info panel title when not showing anything")];
            [firstNameField setObjectValue:nil];
            [lastNameField setObjectValue:nil];
            [emailField setObjectValue:nil];
            [emailField setURL:nil];
            [nicknameField setObjectValue:nil];
            [uinField setObjectValue:nil];
            [birthDateField setObjectValue:nil];
            [ageField setObjectValue:nil];
            [aboutField setString:@""];
            [genderField setObjectValue:nil];
            [homeCityField setObjectValue:nil];
            [homeCountryField setObjectValue:nil];
            [homeCellularField setObjectValue:nil];
            [homeFaxField setObjectValue:nil];
            [homepageField setObjectValue:nil];
            [homepageField setURL:nil];
            [homePhoneField setObjectValue:nil];
            [homeStateField setObjectValue:nil];
            [homeStreetField setObjectValue:nil];
            [homeZipField setObjectValue:nil];
            [languagesField setObjectValue:nil];
            [textEncodingPopup setEnabled:NO];
            [windowTypeMatrix setEnabled:NO];
            [refreshButton setEnabled:NO];
            [visibleListCheckbox setState:NO];
            [invisibleListCheckbox setState:NO];
            [ignoreCheckbox setState:NO];
            [visibleListCheckbox setEnabled:NO];
            [invisibleListCheckbox setEnabled:NO];
            [ignoreCheckbox setEnabled:NO];
        }
    }
}

// NSTabView delegate
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([refreshButton superview])
        [refreshButton removeFromSuperview];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if (![[tabViewItem identifier] isEqual:@"settings"])
        [[tabViewItem view] addSubview:refreshButton];
}

// MPActiveTextField delegate
- (void)control:(NSControl *)control textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
}

@end
