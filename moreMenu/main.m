//
//  main.m
//  moreMenu
//
//  Created by Wolfgang Baird on 6/17/18.
// Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#import "main.h"

BOOL hideMenu = false;
NSArray *customEmoji;
NSArray *originalMenuArray;
NSMenu *expanderMenu;
NSMenuItem *expanderItem;
moreMenu *controlla;
NSUserDefaults *defaults;

// Initial setup of the plugin, do this only once.
void loadPlugin() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaults = [NSUserDefaults standardUserDefaults];
        hideMenu = [defaults boolForKey:@"wb_moreMenu_hide"];
        
        // Support for custom emoji / strings
        NSArray *defEmoji = [[NSArray alloc] initWithObjects:@"🚀", @"👈", @"👉", nil];
        NSArray *newEmoji = [defaults arrayForKey:@"wb_moreMenu_emoji"];
        NSMutableArray *emojiBuild = [[NSMutableArray alloc] init];
        if (newEmoji.count > 0) {
            NSUInteger count = newEmoji.count;
            if (count > 2) count = 2;
            for (int i = 0; i < count; i++) {
                NSString *emoji = newEmoji[i];
                if (emoji.length > 0)
                    [emojiBuild addObject:emoji];
                else
                    [emojiBuild addObject:defEmoji[i]];
            }
        } else {
            emojiBuild = defEmoji.mutableCopy;
        }
        customEmoji = emojiBuild.copy;
        //
        
        controlla = [moreMenu sharedInstance];
        originalMenuArray = [[NSArray alloc] initWithArray:NSApp.mainMenu.itemArray];
        [controlla setupOurButton:true];
        [[NSApp mainMenu] addItem:expanderItem];
        if (hideMenu == true)
            [controlla hideMenu:nil];
    });
}

// mach_inject
__attribute__((constructor)) void moreMenuEntry() {
    loadPlugin();
}

@implementation moreMenu

// SIMBL
+ (void)load {
    loadPlugin();
}

// Get a shared instance of moreMenu
+ (moreMenu*) sharedInstance {
    static moreMenu* plugin = nil;
    if (plugin == nil)
        plugin = [[moreMenu alloc] init];
    return plugin;
}

// Setup the hide/show menu/button
- (void)setupOurButton:(BOOL)pointLeft {
    expanderItem = [[NSMenuItem alloc] initWithTitle:customEmoji[0] action:@selector(toggleMenu:) keyEquivalent:@""];
    [expanderItem setTarget:controlla];
    expanderMenu = [[NSMenu alloc] initWithTitle:customEmoji[0]];
    if (pointLeft) {
        // Point left is an item at the end of the existing menu that will compact it
        [[expanderMenu addItemWithTitle:customEmoji[1] action:@selector(toggleMenu:) keyEquivalent:@""] setTarget:controlla];
    } else {
        // Point right we make the menu contain all of the original menu array items
        // Then add out pointy finger at the end of the list to expand the menu
        for (NSMenuItem *i in originalMenuArray)
            [expanderMenu addItem:i];
        [[expanderMenu addItemWithTitle:customEmoji[2] action:@selector(toggleMenu:) keyEquivalent:@""] setTarget:controlla];
    }
    [expanderItem setSubmenu:expanderMenu];
}

/*
Hide the menu by removing everything from the mainmenu and our epanderMenu then resetup our expanderMenu and add it to the mainmenu
Interesting enough regardless of what the item is named the first menuitem in an applications mainMenu seems to always display
The applications name so that makes things easy on us
*/
- (void)hide {
    [NSApp.mainMenu removeAllItems];
    [expanderMenu removeAllItems];
    [self setupOurButton:false];
    [[NSApp mainMenu] addItem:expanderItem];
}

// Write out our current state of hideMenu to the application preferences
- (void)writeDefaults {
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:hideMenu forKey:@"wb_moreMenu_hide"];
    [defaults synchronize];
}

// Specifically hide the mainMenu, this is called on load if the preferences tell us to
- (void)hideMenu:(id)sender {
    hideMenu = true;
    [self writeDefaults];
    [self hide];
}

// Toggle the mainMenu state
- (void)toggleMenu:(id)sender {
    hideMenu = !hideMenu;
    [self writeDefaults];
    if (hideMenu == true) {
        [self hide];
    } else {
        [NSApp.mainMenu removeAllItems];
        [expanderMenu removeAllItems];
        for (NSMenuItem *i in originalMenuArray)
            [NSApp.mainMenu addItem:i];
        [self setupOurButton:true];
        [[NSApp mainMenu] addItem:expanderItem];
    }
}

@end
