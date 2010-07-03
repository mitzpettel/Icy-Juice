/*
 * UserDetailsController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Dec 29 2001.
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

#import "UserDetailsController.h"
#import "ICQUserDocument.h"
#import "MainController.h"
#import "User.h"

@implementation UserDetailsController

- (id)init
{
    self = [self initWithWindowNibName:@"UserDetails"];
    needsUpdate = NO;
    inProgress = NO;
    return self;
}

- (id)initForDocument:(ICQUserDocument *)theDocument
{
    self = [self init];
    document = theDocument;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStatusChanged:) name:ICJLoginStatusChangedNotification object:theDocument];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userInfoChanged:) name:ICJUserInfoChangedNotification object:[theDocument user]];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)initMenu:(NSMenu *)menu fromTable:(NSDictionary *)table
{
    NSEnumerator *entries = [[[table allValues] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
    NSString *entry;
    NSMenuItem *menuItem;
    while (entry = [entries nextObject])
    {
        menuItem = [[NSMenuItem alloc] init];
            [menuItem setTitle:entry];
            // what a mess follows...
            [menuItem setTag:[[[table allKeysForObject:entry] objectAtIndex:0] intValue]];
            [menu addItem:menuItem];
        [menuItem release];
    }
}

- (void)initCountryMenu
{
    [self initMenu:[homeCountryPopup menu] fromTable:[[NSApp delegate] countryTable]];
}

- (void)initGenderMenu
{
    [self initMenu:[genderPopup menu] fromTable:[[NSApp delegate] sexTable]];
}

- (void)initLanguageMenus
{
    [self initMenu:[language1Popup menu] fromTable:[[NSApp delegate] languageTable]];
    [language2Popup setMenu:[[[language1Popup menu] copy] autorelease]];
    [language3Popup setMenu:[[[language1Popup menu] copy] autorelease]];
}

- (void)saveAndUploadDetails
{
    User *user = [document user];
    [user setDetail:[NSNumber numberWithInt:[[homeCountryPopup selectedItem] tag]] forKey:ICJHomeCountryCodeDetail];
    [user setDetail:[NSNumber numberWithInt:[[genderPopup selectedItem] tag]] forKey:ICJSexCodeDetail];
    [user setDetail:[NSArray arrayWithObjects:
        [NSNumber numberWithInt:[[language1Popup selectedItem] tag]],
        [NSNumber numberWithInt:[[language2Popup selectedItem] tag]],
        [NSNumber numberWithInt:[[language3Popup selectedItem] tag]],
        nil] forKey:ICJLanguageCodesDetail];
    [user setDetail:[nicknameField objectValue] forKey:ICJNicknameDetail];
    [user setDetail:[aboutField objectValue] forKey:ICJAboutDetail];
    [user setDetail:[ageField objectValue] forKey:ICJStaticAgeDetail];
    [user setDetail:[[birthdayField objectValue] midnightGMT] forKey:ICJBirthDateDetail];
    [user setDetail:[emailField objectValue] forKey:ICJEmailDetail];
    [user setDetail:[firstNameField objectValue] forKey:ICJFirstNameDetail];
    [user setDetail:[homeCellularField objectValue] forKey:ICJHomeCellularDetail];
    [user setDetail:[homeCityField objectValue] forKey:ICJHomeCityDetail];
    [user setDetail:[homeFaxField objectValue] forKey:ICJHomeFaxDetail];
    [user setDetail:[homepageField objectValue] forKey:ICJHomepageDetail];
    [user setDetail:[homePhoneField objectValue] forKey:ICJHomePhoneDetail];
    [user setDetail:[homeStateField objectValue] forKey:ICJHomeStateDetail];
    [user setDetail:[homeStreetField objectValue] forKey:ICJHomeStreetDetail];
    [user setDetail:[homeZipField objectValue] forKey:ICJHomeZipDetail];
    [user setDetail:[lastNameField objectValue] forKey:ICJLastNameDetail];
    [document uploadDetails];
}

- (IBAction)changed:(id)sender
{
    [self setDocumentEdited:YES];
}

- (IBAction)doCancel:(id)sender
{
    [[self window] performClose:sender];
}

- (IBAction)doOK:(id)sender
{
    [self saveAndUploadDetails];
    [[self window] close];
}

- (IBAction)doRetrieve:(id)sender
{
    [NSApp beginSheet:progressSheet modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    [progressIndicator startAnimation:nil];
    inProgress = YES;
    [document retrieveUserInfo];
}

- (void)loginStatusChanged:(NSNotification *)aNotification
{
    [retrieveButton setEnabled:[document isLoggedIn]];
    if (inProgress)
    {
        [progressSheet orderOut:nil];
        [progressIndicator stopAnimation:nil];
        [NSApp endSheet:progressSheet];
        inProgress = NO;
    }
}

- (void)userInfoChanged:(NSNotification *)aNotification
{
    if (inProgress)
    {
        [progressSheet orderOut:nil];
        [progressIndicator stopAnimation:nil];
        [NSApp endSheet:progressSheet];
        inProgress = NO;
    }
    needsUpdate = YES;
}

//NSWindowController
- (void)windowDidLoad
{
    [self initCountryMenu];
    [self initGenderMenu];
    [self initLanguageMenus];
    needsUpdate = YES;
    [retrieveButton setEnabled:[document isLoggedIn]];
}

// NSWindow delegate
- (void)windowWillClose:(NSNotification *)notification
{
    [document userDetailsControllerWillClose:self];
    [self autorelease];
}

- (void)windowDidUpdate:(NSNotification *)notification
{
    if (needsUpdate)
    {
        User *user = [document user];
        needsUpdate = NO;
        [homeCountryPopup selectItemAtIndex:[homeCountryPopup indexOfItemWithTag:[[user detailForKey:ICJHomeCountryCodeDetail] intValue]]];
        [genderPopup selectItemAtIndex:[genderPopup indexOfItemWithTag:[[user detailForKey:ICJSexCodeDetail] intValue]]];
        {
            NSArray *languageCodesArray = [user detailForKey:ICJLanguageCodesDetail];
            if (languageCodesArray)
            {
                [language1Popup selectItemAtIndex:[language1Popup indexOfItemWithTag:[[languageCodesArray objectAtIndex:0] intValue]]];
                [language2Popup selectItemAtIndex:[language2Popup indexOfItemWithTag:[[languageCodesArray objectAtIndex:1] intValue]]];
                [language3Popup selectItemAtIndex:[language3Popup indexOfItemWithTag:[[languageCodesArray objectAtIndex:2] intValue]]];
            }
        }
        [uinField setIntValue:[user uin]];
        [nicknameField setObjectValue:[user detailForKey:ICJNicknameDetail]];
        [aboutField setObjectValue:[user detailForKey:ICJAboutDetail]];
        [ageField setObjectValue:[user detailForKey:ICJStaticAgeDetail]];
        [birthdayField setObjectValue:[[user detailForKey:ICJBirthDateDetail] sameDateInTimezone:[NSTimeZone defaultTimeZone]]];
        [emailField setObjectValue:[user detailForKey:ICJEmailDetail]];
        [firstNameField setObjectValue:[user detailForKey:ICJFirstNameDetail]];
        [homeCellularField setObjectValue:[user detailForKey:ICJHomeCellularDetail]];
        [homeCityField setObjectValue:[user detailForKey:ICJHomeCityDetail]];
        [homeFaxField setObjectValue:[user detailForKey:ICJHomeFaxDetail]];
        [homepageField setObjectValue:[user detailForKey:ICJHomepageDetail]];
        [homePhoneField setObjectValue:[user detailForKey:ICJHomePhoneDetail]];
        [homeStateField setObjectValue:[user detailForKey:ICJHomeStateDetail]];
        [homeStreetField setObjectValue:[user detailForKey:ICJHomeStreetDetail]];
        [homeZipField setObjectValue:[user detailForKey:ICJHomeZipDetail]];
        [lastNameField setObjectValue:[user detailForKey:ICJLastNameDetail]];
        [[self window] makeFirstResponder:firstNameField];
        [self setDocumentEdited:NO];
    }
}

- (void)confirmCloseSheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode==NSAlertDefaultReturn)
    {
        [self saveAndUploadDetails];
        [[self window] close];
    }
    else if (returnCode==NSAlertAlternateReturn)
    {
        [[self window] close];
    }
    else if (returnCode==NSAlertOtherReturn)
    {
    }
}

- (BOOL)windowShouldClose:(id)sender
{
    if ([[self window] isDocumentEdited])
    {
        NSBeginAlertSheet(NSLocalizedString(@"Do you want to save the changes you made to your details?", @"Alert title"), NSLocalizedString(@"Save", @"Save button on unsaved details alert"), NSLocalizedString(@"Don't Save", @"Don't Save button on unsaved details alert"), NSLocalizedString(@"Cancel", @"Cancel button on unsaved details alert"), [self window], self, @selector(confirmCloseSheet:didEndAndReturned:contextInfo:), nil, nil, NSLocalizedString(@"Your changes will be lost if you don't save them.", @"Alert message"));
        return NO;
    }
    return YES;
}

// NSControl delegate
// Allow Enter to insert newline in the about field
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if (control==aboutField)
    {
        if (commandSelector==@selector(insertNewline:))
        {
            [textView doCommandBySelector:@selector(insertNewlineIgnoringFieldEditor:)];
            return YES;
        }
    }
    return NO;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self setDocumentEdited:YES];
}

@end
