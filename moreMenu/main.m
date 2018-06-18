//
//  main.m
//  moreMenu
//
//  Created by Wolfgang Baird on 6/17/18.
//Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#import "main.h"

BOOL dispatched = false;
NSArray *theOne;
NSMenu *expanderMenu;
NSMenuItem *expanderItem;
moreMenu *controlla;

void loadPlugin() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZKSwizzle(wb_NSMenuHook, NSMenu);
        controlla = [moreMenu sharedInstance];
        theOne = [[NSArray alloc] initWithArray:NSApp.mainMenu.itemArray];
        [controlla setupOurButton];
        [[NSApp mainMenu] addItem:expanderItem];
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

+ (moreMenu*) sharedInstance {
    static moreMenu* plugin = nil;
    if (plugin == nil)
        plugin = [[moreMenu alloc] init];
    return plugin;
}

- (void)setupOurButton {
    expanderItem = [[NSMenuItem alloc] initWithTitle:@"🚀" action:@selector(toggleMenu:) keyEquivalent:@""];
    [expanderItem setTarget:controlla];
    expanderMenu = [[NSMenu alloc] initWithTitle:@"🚀"];
    [[expanderMenu addItemWithTitle:@"👈" action:@selector(toggleMenu:) keyEquivalent:@""] setTarget:controlla];
    [expanderItem setSubmenu:expanderMenu];
}

- (void)toggleMenu:(id)sender {
    dispatched = !dispatched;
    if (dispatched == true) {
        [NSApp.mainMenu removeAllItems];
        [expanderMenu removeAllItems];
        for (NSMenuItem *i in theOne)
            [expanderMenu addItem:i];
        [[expanderMenu addItemWithTitle:@"👉" action:@selector(toggleMenu:) keyEquivalent:@""] setTarget:controlla];
        [expanderItem setSubmenu:expanderMenu];
        [[NSApp mainMenu] addItem:expanderItem];
    } else {
        [NSApp.mainMenu removeAllItems];
        [expanderMenu removeAllItems];
        for (NSMenuItem *i in theOne)
            [NSApp.mainMenu addItem:i];
        [self setupOurButton];
        [[NSApp mainMenu] addItem:expanderItem];
        
    }
    
    
//    NSMenuItem *i = sender;
//    if ([i.title isEqualToString:@"👈"]) {
//        [i setTitle:@"👉"];
//    } else {
//        [i setTitle:@"👈"];
//    }
//    for (NSMenuItem* i in NSApp.mainMenu.itemArray) {
//        wb_NSMenuHook* b = (wb_NSMenuHook*)i.submenu;
//        [b _itemArray];
//    }
}

@end



@implementation wb_NSMenuHook

- (void)addItem:(NSMenuItem *)newItem {
    ZKOrig(void, newItem);
}

- (id)_itemArray {
//    if (dispatched) {
//        if (![self.title isEqualToString:@""])
//            _oldTitle = self.title;
//        if (![self.title isEqualToString:@"🐳"])
//            [self setTitle:@""];
//    }
//    if (!dispatched) {
//        if (_oldTitle != nil)
//            [self setTitle:_oldTitle];
//    }
    return ZKOrig(id);
}

//- (BOOL)_isInMainMenu {
//    NSLog(@"Testing drugs _isInMainMenu");
//    return ZKOrig(BOOL);
//}

- (void)dumb {
}

- (void)update {
    ZKOrig(void);
}

@end
