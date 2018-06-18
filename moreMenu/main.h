//
//  main.h
//  moreMenu
//
//  Created by Wolfgang Baird on 6/17/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#ifndef main_h
#define main_h
#endif /* main_h */

@import AppKit;

@interface moreMenu : NSObject
+ (moreMenu*) sharedInstance;
- (void)toggleMenu:(id)sender;
- (void)hideMenu:(id)sender;
- (void)setupOurButton:(BOOL)pointLeft;
@end

@interface wb_NSMenuHook : NSMenu
@property NSString* oldTitle;
@property NSArray* itemz;
@end
