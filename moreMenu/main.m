//
//  main.m
//  moreMenu
//
//  Created by Wolfgang Baird on 6/17/18.
// Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#import "main.h"
#import <carbon/carbon.h>

BOOL hideMenu = false;
NSArray *customEmoji;
NSArray *originalMenuArray;

NSMenu *expanderMenu;
NSMenu *mainMenu;

NSMenuItem *expanderItem;
NSMenuItem *mainItem;

moreMenu *controlla;
NSUserDefaults *defaults;

// Initial setup of the plugin, do this only once
// SIMBL & mach_inject
__attribute__((constructor)) void moreMenuEntry() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controlla = [moreMenu sharedInstance];
        ZKSwizzle(wb_NSMenuHook, NSMenu);
        ZKSwizzle(wb_NSMenuItemHook, NSMenuItem);
        
        defaults = [NSUserDefaults standardUserDefaults];
        hideMenu = [defaults boolForKey:@"wb_moreMenu_hide"];
        
        // Support for custom emoji / strings
        NSArray *defEmoji = [[NSArray alloc] initWithObjects:@"moreMenu", @"👈", @"👉", nil];
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
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [controlla establishMenu];
            if (hideMenu) {
                [controlla hideMenu:nil];
            } else {
                Boolean addItem = true;
                for (NSMenuItem *i in NSApp.mainMenu.itemArray)
                    if (i.tag == 3015)
                        addItem = false;
                if (addItem)
                    [controlla addMenu:nil];
            }
        });
        
        NSLog(@"moreMenu loaded...");
    });
}

@implementation moreMenu

+ (void)load {
    moreMenuEntry();
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
    [expanderItem setTag:3015];
    [expanderItem setTarget:controlla];
    if (pointLeft) {
        expanderMenu = [[NSMenu alloc] initWithTitle:customEmoji[1]];
        [expanderItem setSubmenu:expanderMenu];
    } else {
        expanderMenu = [[NSMenu alloc] initWithTitle:customEmoji[2]];
        [expanderItem setTitle:customEmoji[2]];
    }
//    [[expanderMenu addItemWithTitle:@"" action:@selector(toggleMenu:) keyEquivalent:@""] setTarget:controlla];
//    [expanderItem setSubmenu:expanderMenu];
}

- (void)setupOurMenu {
    mainMenu = [[NSMenu alloc] initWithTitle:customEmoji[0]];
    mainItem = [[NSMenuItem alloc] initWithTitle:customEmoji[0] action:nil keyEquivalent:@""];
    [mainItem setTag:3016];
    [mainItem setTarget:controlla];
    for (NSMenuItem *i in originalMenuArray) {
        // Fix for first menuitem often not being named
        if (i == originalMenuArray.firstObject)
            if ([i.title isEqualToString:@""] || [i.title isEqualToString:@"Apple"])
                if (i.submenu.title.length > 0)
                    [i setTitle:i.submenu.title];
//                [i setTitle:[NSBundle mainBundle].bundlePath.stringByDeletingPathExtension.lastPathComponent];
        
        // Fix for a crash probably could do this without the try catch
        @try {
            [mainMenu addItem:i];
        } @catch (NSException *exception) {
            [i.menu removeItem:i];
            [mainMenu addItem:i];
        } @finally {
        }
    }
    [self setupOurButton:false];
    [mainMenu addItem:expanderItem];
    [mainItem setSubmenu:mainMenu];
}

/*
Hide the menu by removing everything from the mainmenu and our epanderMenu then resetup our expanderMenu and add it to the mainmenu
Interesting enough regardless of what the item is named the first menuitem in an applications mainMenu seems to always display
The applications name so that makes things easy on us
*/
- (void)hide {
    [NSApp.mainMenu removeAllItems];
    [expanderMenu removeAllItems];
    [mainMenu removeAllItems];
    [self setupOurMenu];
    [NSApp.mainMenu setItemArray:[NSArray arrayWithObject:mainItem]];
}

// Prevent adding duplicates of our expander item to the mainMenu
- (void)checkAndAdd {
    if (![NSApp.mainMenu.itemArray containsObject:expanderItem])
        [NSApp.mainMenu addItem:expanderItem];
}

// SHow the original menu by removing everything then setup the original menu array and add our hiding button
- (void)show {
    [NSApp.mainMenu removeAllItems];
    [expanderMenu removeAllItems];
    [mainMenu removeAllItems];
    [self setupOurButton:true];
    [NSApp.mainMenu setItemArray:originalMenuArray];
    [self checkAndAdd];
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

// Add menu
- (void)addMenu:(id)sender {
    [self setupOurButton:!hideMenu];
    [self checkAndAdd];
}

// Toggle the mainMenu state
- (void)toggleMenu:(id)sender {
    hideMenu = !hideMenu;
    [self writeDefaults];
    if (hideMenu == true) {
        [self hide];
    } else {
        [self show];
    }
}

// Update the `originalMenu` but only do this if out menu is not currently hidden
- (void)establishMenu {
    if (NSApp.mainMenu.itemArray.count > 0) {
        NSMutableArray *newMenuArray = [[NSMutableArray alloc] initWithArray:NSApp.mainMenu.itemArray];
        if (![newMenuArray[0] isEqualTo:mainItem]) {
            if ([[(NSMenuItem*)[newMenuArray lastObject] title] isEqualToString:customEmoji[0]])
                [newMenuArray removeLastObject];
            originalMenuArray = newMenuArray.copy;
//            NSLog(@"zzz establishMenu %@", originalMenuArray);
        }
    }
}

@end

extern MenuRef _NSGetCarbonMenu(NSMenu *);

@implementation wb_NSMenuHook

- (MenuRef) menuReference {
    MenuRef theMenuReference = _NSGetCarbonMenu(self);
    if (theMenuReference==0) {
        // this is necessary to make cocoa actually create the underlying carbon menu
        NSMenu *theMainMenu = [NSApp mainMenu];
        NSMenuItem *theDummyMenuItem = [theMainMenu addItemWithTitle: @"sub"
                                                              action: NULL keyEquivalent: @""];
        [theDummyMenuItem setSubmenu: self];
        [theDummyMenuItem setSubmenu: nil];
        [theMainMenu removeItem: theDummyMenuItem];
        return _NSGetCarbonMenu(self);
    }
    return theMenuReference;
}

// Check if we clicked out mainmenu item
- (void)_updateForTracking {
    ZKOrig(void);
    if ([self isEqualTo:expanderMenu]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            MenuTrackingData theMenuTrackingData;
            if (GetMenuTrackingData([self menuReference], &theMenuTrackingData)==noErr) {
                // Clicker the mainMenu menu
                [controlla toggleMenu:nil];
            }
        });
    }
}

// Prevent crashing if you try to add an item beyond index range
- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)index {
    // Fix for crash when menu is hidden and an application tries to insert an item at an expected index that no longer exists
    if (index <= self.itemArray.count)
        ZKOrig(void, newItem, index);
    else {
        if (hideMenu) {
            // Fix for items not being added when menu is hidden
            NSMenu *menu = NSApp.mainMenu.itemArray.firstObject.submenu;
            [menu insertItem:newItem atIndex:menu.itemArray.count - 1];
            NSMutableArray *muta = [NSMutableArray arrayWithArray:originalMenuArray];
            [muta insertObject:newItem atIndex:muta.count - 1];
            originalMenuArray = muta.copy;
        } else {
            if (self.itemArray.count > 0)
                ZKOrig(void, newItem, self.itemArray.count - 1);
        }
    }
}

// Hook this to make sure we stay hidden
- (void)addItem:(NSMenuItem *)newItem {
    // use Spotify+ (https://github.com/w0lfschild/spotifyPlus) to fix empty items in dock menu
    ZKOrig(void, newItem);
    
    // Fix to avoid Safari crash
    Boolean update = true;
    if ([self.className isEqualToString:@"WebsiteIconMenu"]) update = false;
    
    if (update == true) {
        if (hideMenu) {
            if (NSApp.mainMenu.itemArray.count > 1) {
//                NSLog(@"zzz, we need our mainItem");
                [controlla establishMenu];
                [controlla hide];
            }
        } else {
            if (![NSApp.mainMenu.itemArray containsObject:expanderItem]) {
//                NSLog(@"zzz, we need our expanderItem");
//                [controlla establishMenu];
                [controlla addMenu:nil];
            }
        }
    }
}

@end

@implementation wb_NSMenuItemHook

// Fix for Spotify crash with menu hidden
- (id)initWithTitle:(NSString *)string action:(SEL)selector keyEquivalent:(NSString *)charCode {
    // Avoid crash with nil string value
    if (string == nil) string = @"";
    return ZKOrig(id, string, selector, charCode);
}

@end
