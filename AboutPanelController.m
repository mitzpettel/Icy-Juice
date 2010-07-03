/*
 * AboutPanelController.m
 * Icy Juice
 *
 * Created by Mitz Pettel on Sat Nov 29 2003.
 *
 * Copyright (c) 2003-2004 Mitz Pettel <source@mitzpettel.com>. All rights reserved.
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

#import "AboutPanelController.h"

@implementation AboutPanelController

+ (id)sharedAboutPanelController {
    static AboutPanelController *sharedInstance = nil;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    NSBundle	*bundle;
    
    self = [super init];
    if (self) {
        [NSBundle loadNibNamed:@"AboutPanel" owner:self];
    }
    bundle = [NSBundle mainBundle];
    [appNameField setStringValue:[bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey]];
    [legalTextField setStringValue:[bundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];
    [versionField
        setStringValue:[NSString
            stringWithFormat:@"%@ (v%@)",
            [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]
        ]
    ];
	[localizationCreditsTextView setEditable:NO];
	[localizationCreditsTextView setDrawsBackground:NO];
	if ( [bundle objectForInfoDictionaryKey:@"ICJLocalizationCredit"] )
		[[localizationCreditsTextView textStorage]
			setAttributedString:[[[NSAttributedString alloc] autorelease]
				initWithHTML:[[NSString
					stringWithFormat:@"<FONT size=\"2\" face=\"Lucida Grande\">%@</FONT>",
					[bundle objectForInfoDictionaryKey:@"ICJLocalizationCredit"]
				] dataUsingEncoding:NSUnicodeStringEncoding]
				documentAttributes:nil
			]
		];
	[localizationCreditsTextView setAlignment:NSCenterTextAlignment];

	[acknowledgmentsTextView setEditable:NO];
	[acknowledgmentsTextView setDrawsBackground:NO];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:[bundle pathForResource:@"acknowledgments" ofType:@"html"]] )
		[[acknowledgmentsTextView textStorage]
			setAttributedString:[[[NSAttributedString alloc] autorelease]
				initWithHTML:[NSData dataWithContentsOfFile:[bundle pathForResource:@"acknowledgments" ofType:@"html"]]
				documentAttributes:nil
			]
		];

    return self;
}

- (void)dealloc
{
    [infoPanel release];
    [super dealloc];
}

- (IBAction)showPanel:(id)sender
{
    if ( ![infoPanel isVisible] )
        [infoPanel center];
    [infoPanel makeKeyAndOrderFront:nil];
}

- (IBAction)logoClicked:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender title]]];
}

@end
