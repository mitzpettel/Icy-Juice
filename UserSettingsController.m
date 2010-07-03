/*
 * UserSettingsController.m
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

#import "UserSettingsController.h"
#import "ICQUserDocument.h"
#import "MainController.h"
#import "ICJMessage.h"


@implementation UserSettingsController

- (id)init
{
    self = [self initWithWindowNibName:@"UserSettings"];
    return self;
}

- (id)initForWindow:(NSWindow *)theParentWindow document:(ICQUserDocument *)theDocument
{
    self = [self init];
    document = theDocument;
    statusMessages = [[[document settingWithName:ICJStatusMessagesSettingName] mutableCopy] retain];
    [NSApp beginSheet:[self window] modalForWindow:theParentWindow modalDelegate:self didEndSelector:@selector(settingsSheet:didEndAndReturned:contextInfo:) contextInfo:nil];
    return self;
}

- (void)dealloc
{
    [statusMessages release];
    [receivedFont release];
    [sentFont release];
    [super dealloc];
}

- (void)settingsSheet:(NSWindow *)sheet didEndAndReturned:(int)returnCode contextInfo:(void *)context
{
    if (sheet)
        [sheet close];
}

- (void)initStatusMenu
{
    NSEnumerator *statuses = [[[NSApp delegate] userStatuses] objectEnumerator];
    ContactStatus *status;
    NSString *statusKey;
    NSMenuItem *menuItem;
    while (statusKey = [statuses nextObject])
    {
        status = [[NSApp delegate] statusForKey:statusKey];
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:[status name]];
        [menuItem setRepresentedObject:statusKey];
        [[initialStatusPopup menu] addItem:menuItem];
    }
}

- (void)initSoundsMenu
{
    NSEnumerator *sounds = [[[NSSound librarySounds] sortedArrayUsingSelector:@selector(displayNameCompare:)] objectEnumerator];
    NSEnumerator *builtInSounds = [[[[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:nil] pathsMatchingExtensions:[NSSound soundUnfilteredFileTypes]] objectEnumerator];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *sound;
    NSMenuItem *menuItem;
        
    [[messageSoundPopup itemAtIndex:0] setRepresentedObject:@""];
        
    while (sound = [builtInSounds nextObject])
    {
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:[[manager displayNameAtPath:sound] stringByDeletingPathExtension]];
        [menuItem setRepresentedObject:[sound lastPathComponent]];
        [[messageSoundPopup menu] addItem:menuItem];
    }
    
    [[messageSoundPopup menu] addItem:[NSMenuItem separatorItem]];
    
    while (sound = [sounds nextObject])
    {
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:[[manager displayNameAtPath:sound] stringByDeletingPathExtension]];
        [menuItem setRepresentedObject:sound];
        [[messageSoundPopup menu] addItem:menuItem];
    }
}

- (void)initTextEncodingMenu
{
    NSMenuItem *menuItem;
    const CFStringEncoding *encodingList = CFStringGetListOfAvailableEncodings();
    int i = 0;
    [textEncodingPopup removeItemAtIndex:0];
    while (encodingList[i]!=kCFStringEncodingInvalidId)
    {
        menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:(NSString *)CFStringGetNameOfEncoding(encodingList[i])];
        [menuItem setTag:encodingList[i]];
        [[textEncodingPopup menu] addItem:menuItem];
        i++;
    }
}

- (void)showPane:(NSView *)pane animate:(BOOL)flag
{
    NSRect newRect;
    float delta;
    if ( [[paneView subviews] count] )
        [[[paneView subviews] objectAtIndex:0] removeFromSuperview];
    newRect = [[self window] frame];
    delta = ([pane frame].size.height - [paneView frame].size.height);
    newRect.size.height += delta;
    newRect.origin.y -= delta;
    [[self window] setFrame:newRect display:YES animate:flag];
    [paneView addSubview:pane];    
}

- (void)synchronizeSampleHistoryView
{
    [sampleHistoryView setAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [receivedBackgroundColorWell color],	ICJIncomingBackgroundAttributeName,
            [receivedTextColorWell color],		ICJIncomingColorAttributeName,
            [sentBackgroundColorWell color],		ICJOutgoingBackgroundAttributeName,
            [sentTextColorWell color],			ICJOutgoingColorAttributeName,
            receivedFont,				ICJIncomingFontAttributeName,
            sentFont,					ICJOutgoingFontAttributeName,
            nil
        ]
    ];
}

- (IBAction)tabChoiceChanged:(id)sender
{
    NSView *pane;
    switch ( [[sender selectedItem] tag] )
    {
        case 0:
            pane = generalPaneView;
            break;
        case 1:
            pane = messageWindowsPaneView;
            break;
        case 2:
            pane = statusPaneView;
            break;
        case 3:
            pane = networkPaneView;
            break;
        case 4:
            pane = notificationPaneView;
            break;
        case 5:
            pane = colorPaneView;
            break;
        default:
            pane = nil;
            break;
    }
    [self showPane:pane animate:YES];
}

- (IBAction)useDefaultICQServer:(id)sender
{
    [serverHostField setStringValue:[[NSApp delegate] settingWithName:ICJServerHostSettingName]];
    [serverPortField setStringValue:[[NSApp delegate] settingWithName:ICJServerPortSettingName]];
}

- (IBAction)OK:(id)sender
{
    NSString *selectedStatus;
    [document setAutoPopup:([autoPopupCheckbox state]==NSOnState)];
    [document setUsesDialogWindows:([[windowTypeMatrix selectedCell] tag]==0)];
    if (selectedStatus = [[initialStatusPopup selectedItem] representedObject])
    {
        [document setStartsWithPreviousStatus:NO];
        [document setInitialStatus:selectedStatus];
    }
    else
    {
        [document setStartsWithPreviousStatus:YES];
    }
        
    [document setTextEncoding:[[textEncodingPopup selectedItem] tag]];
    [document setObject:[NSNumber numberWithBool:([ignoreIfNotOnListCheckbox state]==NSOnState)] forSettingName:ICJIgnoreIfNotOnListSettingName];
    [document setObject:[NSNumber numberWithBool:([webAwareCheckbox state]==NSOnState)] forSettingName:ICJWebAwareSettingName];
    [document setObject:[NSNumber numberWithBool:([promptForStatusCheckbox state]==NSOnState)] forSettingName:ICJPromptForStatusMessageSettingName];
    [document setObject:[NSNumber numberWithBool:([hideWhenSendingCheckbox state]==NSOnState)] forSettingName:ICJHideWhenSendingSettingName];
    [document setObject:[NSNumber numberWithBool:([checkSpellingCheckbox state]==NSOnState)] forSettingName:ICJSpellCheckAsYouTypeSettingName];
    [document setObject:[NSNumber numberWithBool:([silentOccupiedDNDCheckbox state]==NSOnState)] forSettingName:ICJSilentOccupiedDNDSettingName];
    [document setObject:[NSNumber numberWithBool:([silentFrontmostConversationCheckbox state]==NSOnState)] forSettingName:ICJSilentFrontDialogSettingName];
    [document setObject:[NSNumber numberWithInt:[[timeToHideInactivePopup selectedItem] tag]] forSettingName:ICJTimeToHideInactiveSettingName];
    [statusMessages setObject:[[statusMessageField string] copy] forKey:selectedStatusKey];
    [document setObject:statusMessages forSettingName:ICJStatusMessagesSettingName];
    if (![[serverHostField stringValue] isEqual:[[NSApp delegate] settingWithName:ICJServerHostSettingName]] || ![[serverPortField stringValue] isEqual:[[NSApp delegate] settingWithName:ICJServerPortSettingName]])
    {
        [document setObject:[serverHostField stringValue] forSettingName:ICJServerHostSettingName];
        [document setObject:[serverPortField stringValue] forSettingName:ICJServerPortSettingName];
    }
    else
    {
        [document removeSettingWithName:ICJServerHostSettingName];
        [document removeSettingWithName:ICJServerPortSettingName];
    }
	{
		int		start = [portRangeStartTextField intValue];
		int		end = [portRangeEndTextField intValue];
		
		if ( ( start<=end || end==0 ) && ( start==0 || start>=1024 ) && ( end==0 || end>=1024 ) )
		{
			[document setObject:[NSNumber numberWithInt:start] forSettingName:ICJPortRangeStartSettingName];
			[document setObject:[NSNumber numberWithInt:end] forSettingName:ICJPortRangeEndSettingName];
		} 
	}
	[document setObject:[NSNumber numberWithBool:[displayNetworkAlertCheckbox state]] forSettingName:ICJDisplayNetworkAlertsSettingName];
	
    if ([[messageSoundPopup selectedItem] representedObject])
        [document setObject:[[messageSoundPopup selectedItem] representedObject] forSettingName:ICJIncomingSoundSettingName];
    else
        [document removeSettingWithName:ICJIncomingSoundSettingName];
    {
        int idleSeconds = [idleMinutesTextField intValue]*60;
        [document
            setObject: [NSNumber numberWithBool:(idleSeconds>0 && [idleMinutesCheckbox state])]
            forSettingName: ICJAutoAwayIdleSettingName
            ];
        if (idleSeconds<0)
            idleSeconds = 0;
        [document setObject:[NSNumber numberWithInt:idleSeconds] forSettingName:ICJAutoAwayIdleSecondsSettingName];
    }
    [document setObject:[NSNumber numberWithBool:[screenEffectCheckbox state]] forSettingName:ICJAutoAwayScreenSaverSettingName];
    [document setObject:[sentFont fontName] forSettingName:ICJOutgoingFontSettingName];
    [document setObject:[NSNumber numberWithFloat:[sentFont pointSize]] forSettingName:ICJOutgoingSizeSettingName];
    [document setObject:[receivedFont fontName] forSettingName:ICJIncomingFontSettingName];
    [document setObject:[NSNumber numberWithFloat:[receivedFont pointSize]] forSettingName:ICJIncomingSizeSettingName];
    [document setObject:[[sentBackgroundColorWell color] RGBComponents] forSettingName:ICJOutgoingBackgroundSettingName];
    [document setObject:[[sentTextColorWell color] RGBComponents] forSettingName:ICJOutgoingColorSettingName];
    [document setObject:[[receivedBackgroundColorWell color] RGBComponents] forSettingName:ICJIncomingBackgroundSettingName];
    [document setObject:[[receivedTextColorWell color] RGBComponents] forSettingName:ICJIncomingColorSettingName];
    [document setObject:[[filesDirectoryPopUp itemAtIndex:0] representedObject] forSettingName:ICJFilesDirectorySettingName];
    [NSApp endSheet:[self window]];
    [document settingsDidChange];
}

- (IBAction)cancel:(id)sender
{
    [NSApp endSheet:[self window]];
}

- (IBAction)messageSoundChanged:(id)sender
{
    NSString *sound = [[sender selectedItem] representedObject];
    if (sound)
    {
        [[[NSApp delegate] soundWithNameOrPath:sound refetch:YES] play];
    }
}

- (IBAction)idleMinutesCheckboxChanged:(id)sender
{
    [idleMinutesTextField setEnabled:[(NSButton *)sender state]];
}

- (IBAction)colorChanged:(id)sender
{
    [self synchronizeSampleHistoryView];
}

- (IBAction)fontButtonClicked:(id)button
{
    NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
    if (button==receivedFontButton)
    {
        [fontPanel setPanelFont:receivedFont isMultiple:NO];
        fontPanelAssociation = 1;
    }
    else if (button==sentFontButton)
    {
        [fontPanel setPanelFont:sentFont isMultiple:NO];
        fontPanelAssociation = 2;
    }
        
    [[NSFontManager sharedFontManager] orderFrontFontPanel:nil];
}

- (void)updateFontTextFields
{
    NSString *formatString = NSLocalizedString(@"%@ %.1f pt.", @"font name and size in points");
    [receivedFontTextField setStringValue:
        [NSString stringWithFormat:formatString, [receivedFont displayName], [receivedFont pointSize]]
    ];
    [sentFontTextField setStringValue:
        [NSString stringWithFormat:formatString, [sentFont displayName], [sentFont pointSize]]
    ];
}

// NSFontManagerResponderMethod
- (void)changeFont:(id)sender
{
    if (fontPanelAssociation==1)
    {
        [receivedFont autorelease];
        receivedFont = [[sender convertFont:receivedFont] retain];
    }
    else if (fontPanelAssociation==2)
    {
        [sentFont autorelease];
        sentFont = [[sender convertFont:sentFont] retain];
    }
    
    [self updateFontTextFields];

    [self synchronizeSampleHistoryView];

}

- (void)updateStatusMessageField
{
    NSString *message = [statusMessages objectForKey:selectedStatusKey];
    [statusMessageField setString:(message ? [message copy] : @"")];
}

- (void)prepareColorAndFonts
{
    ICQNormalMessage *sampleIncomingMessage, *sampleOutgoingMessage;
    ICJContact *sampleSender;
    sampleSender = [[ICJContact alloc] initWithNickname:@"" uin:0];
    sampleIncomingMessage = [ICQNormalMessage messageFrom:sampleSender date:[NSDate date]];
    [sampleIncomingMessage setText:NSLocalizedString(@"The little brown fox jumps over the lazy dog.", @"Sample incoming message text")];
    sampleOutgoingMessage = [ICQNormalMessage messageTo:sampleSender];
    [sampleOutgoingMessage setText:NSLocalizedString(@"Cozy lummox gives smart squid who asks for job pen.", @"Sample outgoing message text")];
    [sampleHistoryView setHistory:
        [NSArray arrayWithObjects:
            sampleIncomingMessage,
            sampleOutgoingMessage,
            nil
        ]
    ];
    [sentBackgroundColorWell setColor:
        [NSColor colorWithRGB:[document settingWithName:ICJOutgoingBackgroundSettingName]]];
    [receivedBackgroundColorWell setColor:
        [NSColor colorWithRGB:[document settingWithName:ICJIncomingBackgroundSettingName]]];
    [sentTextColorWell setColor:
        [NSColor colorWithRGB:[document settingWithName:ICJOutgoingColorSettingName]]];
    [receivedTextColorWell setColor:
        [NSColor colorWithRGB:[document settingWithName:ICJIncomingColorSettingName]]];
        
    receivedFont = [[NSFont
        fontWithName:[document settingWithName:ICJIncomingFontSettingName]
        size:[[document settingWithName:ICJIncomingSizeSettingName] floatValue]
        ] retain];
    sentFont = [[NSFont
        fontWithName:[document settingWithName:ICJOutgoingFontSettingName]
        size:[[document settingWithName:ICJOutgoingSizeSettingName] floatValue]
        ] retain];
    [self updateFontTextFields];
    [self synchronizeSampleHistoryView];
}

- (void)updateFilesDirectoryPopUp
{
    NSString	*path = [[filesDirectoryPopUp itemAtIndex:0] representedObject];
    NSImage	*icon;
    
    [[filesDirectoryPopUp itemAtIndex:0] setTitle:[path lastPathComponent]];
    icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [icon setScalesWhenResized:YES];
    [icon setSize:NSMakeSize(16, 16)];
    [[filesDirectoryPopUp itemAtIndex:0] setImage:icon];
}

- (IBAction)changedFilesDirectory:(id)sender
{
    NSOpenPanel		*panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setPrompt:NSLocalizedString( @"Select", @"prompt for received files folder selection panel" )];
    [panel setTitle:NSLocalizedString(
        @"Choose where to save received files",
        @"folder selection dialog title"
    )];
    if ( [panel
        runModalForDirectory:[[filesDirectoryPopUp itemAtIndex:0] representedObject]
        file:nil
        types:nil
        ]==NSOKButton )
    [[filesDirectoryPopUp itemAtIndex:0] setRepresentedObject:[panel filename]];
    [self updateFilesDirectoryPopUp];
    [filesDirectoryPopUp selectItemAtIndex:0];
}

//NSWindowController
- (void)windowDidLoad
{
    selectedStatusKey = [[[NSApp delegate] statusMessageStatuses] objectAtIndex:[statusTable selectedRow]];
    [self updateStatusMessageField];

    [autoPopupCheckbox setState:([document autoPopup] ? NSOnState : NSOffState)];
    [windowTypeMatrix selectCellWithTag:([document usesDialogWindows] ? 0 : 1)];
    [self initSoundsMenu];
    if ([document settingWithName:ICJIncomingSoundSettingName])
    {
        int i = [messageSoundPopup indexOfItemWithRepresentedObject:[document settingWithName:ICJIncomingSoundSettingName]];
        if (i!=-1)
            [messageSoundPopup selectItemAtIndex:i];
    }
    [self initStatusMenu];
    if (![document startsWithPreviousStatus])
        [initialStatusPopup selectItemAtIndex:[initialStatusPopup indexOfItemWithRepresentedObject:[document initialStatus]]];
    [self initTextEncodingMenu];
    [textEncodingPopup selectItemAtIndex:[textEncodingPopup indexOfItemWithTag:[document textEncoding]]];
    [ignoreIfNotOnListCheckbox setState:([[document settingWithName:ICJIgnoreIfNotOnListSettingName] boolValue])];
    [webAwareCheckbox setState:([[document settingWithName:ICJWebAwareSettingName] boolValue])];
    [promptForStatusCheckbox setState:([[document settingWithName:ICJPromptForStatusMessageSettingName] boolValue])];
    [hideWhenSendingCheckbox setState:([[document settingWithName:ICJHideWhenSendingSettingName] boolValue])];
    [checkSpellingCheckbox setState:([[document settingWithName:ICJSpellCheckAsYouTypeSettingName] boolValue])];
    [timeToHideInactivePopup selectItemAtIndex:[timeToHideInactivePopup indexOfItemWithTag:[[document settingWithName:ICJTimeToHideInactiveSettingName] intValue]]];
    [serverHostField setStringValue:[document settingWithName:ICJServerHostSettingName]];
    [serverPortField setStringValue:[document settingWithName:ICJServerPortSettingName]];
	[portRangeStartTextField setIntValue:[[document settingWithName:ICJPortRangeStartSettingName] intValue]];
	[portRangeEndTextField setIntValue:[[document settingWithName:ICJPortRangeEndSettingName] intValue]];
	[displayNetworkAlertCheckbox setState:[[document settingWithName:ICJDisplayNetworkAlertsSettingName] boolValue]];
    [silentOccupiedDNDCheckbox setState:[[document settingWithName:ICJSilentOccupiedDNDSettingName] boolValue]];
    [silentFrontmostConversationCheckbox setState:[[document settingWithName:ICJSilentFrontDialogSettingName] boolValue]];
    [idleMinutesCheckbox setState:[[document settingWithName:ICJAutoAwayIdleSettingName] boolValue]];
    [idleMinutesTextField setEnabled:[[document settingWithName:ICJAutoAwayIdleSettingName] boolValue]];
    [idleMinutesTextField setIntValue:[[document settingWithName:ICJAutoAwayIdleSecondsSettingName] intValue]/60];
    [screenEffectCheckbox setState:[[document settingWithName:ICJAutoAwayScreenSaverSettingName] boolValue]];
    [self prepareColorAndFonts];
    [[filesDirectoryPopUp itemAtIndex:0] setRepresentedObject:[document settingWithName:ICJFilesDirectorySettingName]];
    [self updateFilesDirectoryPopUp];
    [self showPane:generalPaneView animate:NO];
}

// NSTableView delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    id message;
    if (message = [statusMessageField string])
        [statusMessages setObject:[message copy] forKey:selectedStatusKey];
    else
        [statusMessages removeObjectForKey:selectedStatusKey];
    selectedStatusKey = [[[NSApp delegate] statusMessageStatuses] objectAtIndex:[[aNotification object] selectedRow]];
    [self updateStatusMessageField];
}

// NSContorlSubclassDelegate

- (BOOL)control:(NSControl *)control isValidObject:(id)obj
{
	int		val = [control intValue];
	
	if ( val==0 )
		return YES;
	if ( val<1024 )
	{
		NSBeep();
		return NO;
	}
	return YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	NSControl   *control = [notification object];
	int			val = [control intValue];
	
	if ( [control isEqual:portRangeStartTextField] )
	{
		if ( [portRangeEndTextField intValue]<val )
			[portRangeEndTextField setIntValue:val];
	}
	else if ( [control isEqual:portRangeEndTextField] )
	{
		if ( val!=0 && [portRangeStartTextField intValue]>val )
			[portRangeStartTextField setIntValue:val];
	}
}

// NSTableDataSource
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[[NSApp delegate] statusMessageStatuses] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return [[[NSApp delegate] statusForKey:[[[NSApp delegate] statusMessageStatuses] objectAtIndex:row]] name];
}

@end
