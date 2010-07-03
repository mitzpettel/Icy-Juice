/*
 * PreferencesWindowController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Fri Dec 07 2001.
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

#import "PreferencesWindowController.h"
#import "EnterTextView.h"
#import "MainController.h"

@implementation PreferencesWindowController

+ (id)sharedPreferencesWindowController {
    static PreferencesWindowController *sharedPreferencesObject = nil;
    
    if (!sharedPreferencesObject) {
        sharedPreferencesObject = [[self alloc] init];
    }
    return sharedPreferencesObject;
}

- (id)init {
    self = [self initWithWindowNibName:@"Preferences"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Preferences"];
    }
    return self;
}

- (IBAction)changeDefaultDocument:(id)sender
{
    id currentDefault = [[sender selectedItem] representedObject];
    if (currentDefault)
        [[NSUserDefaults standardUserDefaults] setObject:currentDefault forKey:ICJDefaultContactListUserDefault];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ICJDefaultContactListUserDefault];
}

- (void)selectItemWithCurrentDefault
{
    id currentDefault = [[NSUserDefaults standardUserDefaults] objectForKey:ICJDefaultContactListUserDefault];
    int itemIndex;
    if (currentDefault)
        itemIndex = [defaultDocumentPopup indexOfItemWithRepresentedObject:currentDefault];
    else
        itemIndex = 0;
    [defaultDocumentPopup selectItemAtIndex:itemIndex];
}

- (void)addItemWithCurrentDefault
{
    id currentDefault = [[NSUserDefaults standardUserDefaults] objectForKey:ICJDefaultContactListUserDefault];
    if (currentDefault && [defaultDocumentPopup indexOfItemWithRepresentedObject:currentDefault]==-1)
    {
        NSMenuItem *newItem = [[[NSMenuItem alloc] initWithTitle:[[NSFileManager defaultManager] displayNameAtPath:currentDefault] action:nil keyEquivalent:@""] autorelease];
        [newItem setRepresentedObject:currentDefault];
        [[defaultDocumentPopup menu] insertItem:newItem atIndex:1];
    }
}

- (IBAction)changeDockIconBehavior:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey:ICJDockIconBehaviorUserDefault];
}

- (IBAction)changeSendKey:(id)sender
{
    EnterTextViewKey selectedKey = [[sender selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setInteger:selectedKey forKey:ICJSendMessageKeyUserDefault];
    [[NSApp delegate] updateSendMessageMenuItem];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self addItemWithCurrentDefault];
    [self selectItemWithCurrentDefault];
    [dockIconBehaviorMatrix selectCellWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:ICJDockIconBehaviorUserDefault]];
    [sendKeyMatrix selectCellWithTag:[[NSUserDefaults standardUserDefaults] integerForKey:ICJSendMessageKeyUserDefault]];
}

- (void)selectPanelDidEnd:(NSOpenPanel *)selectPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode==NSOKButton)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[[selectPanel filenames] objectAtIndex:0] forKey:ICJDefaultContactListUserDefault];
        [self addItemWithCurrentDefault];
    }
    [self selectItemWithCurrentDefault];
}

- (IBAction)selectDefaultDocument:(id)sender
{
    NSOpenPanel *selectPanel = [NSOpenPanel openPanel];
    [selectPanel setPrompt:NSLocalizedString(@"Select", @"button title in the default contact list selection sheet of the preferences panel")];
    [selectPanel beginSheetForDirectory:nil file:nil types:[[NSDocumentController sharedDocumentController] fileExtensionsFromType:@"ICQ contact list"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(selectPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

@end
