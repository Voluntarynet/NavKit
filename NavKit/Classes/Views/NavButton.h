//
//  NavButton.h
//  Bitmessage
//
//  Created by Steve Dekorte on 3/4/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NavButton : NSButton

@property (strong, nonatomic) NSColor *textColor;

- (void)setActionTitle:(NSString *)anAction;
- (void)setTextColor:(NSColor *)aColor;
- (void)setFontSize:(CGFloat)pointSize;
- (void)updateTitle;

@end
