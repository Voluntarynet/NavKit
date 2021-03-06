//
//  NavAdvTextView.m
//
//  Created by Steve Dekorte on 4/23/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "NavAdvTextView.h"
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>
#import "NSView+sizing.h"

@implementation NavAdvTextView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _roundRect = [[NavRoundRect alloc] init];
        [_roundRect setFrame:self.bounds];
        [self setAutoresizesSubviews:NO];
        [self setAutoresizingMask:NSViewNotSizable];
        _isValid = YES;
    }
    
    return self;
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    [self.suffixView removeFromSuperview];
}

- (void)setSuffix:(NSString *)aString
{
    if (aString)
    {
        if (!self.suffixView)
        {
            self.suffixView = [[NavTextView alloc] initWithFrame:NSMakeRect(0, 0, 600, self.height)];
            [_suffixView setAutoresizesSubviews:NO];
            [_suffixView setAutoresizingMask:NSViewNotSizable];
            [self.suffixView setEditable:NO];
            [self.suffixView setSelectable:NO];
            [self.superview addSubview:self.suffixView];
        }
        
        self.suffixView.string = aString.strip;
        [self updateSuffixView];
        [self updateTheme];
    }
    else
    {
        [self.suffixView removeFromSuperview];
        self.suffixView = nil;
    }
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self updateSuffixView];
    [_roundRect setFrame:self.bounds];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [_roundRect draw];
    [super drawRect:dirtyRect];
}

- (void)updateSuffixView
{
    if (self.suffixView)
    {
        assert(self.suffixView.superview == self.superview);
        self.suffixView.x = self.x + self.textStorage.size.width;
        self.suffixView.y = self.y; // + self.height - self.suffixView.height;
        
        //NSLog(@"y %i suffixY %i", (int)self.y, (int)self.suffixView.y);
        
        //CGFloat w = self.suffixView.textStorage.size.width;
        //[self.suffixView setWidth:w];
        
        [self.suffixView setHidden:[self.string isEqualToString:self.uneditedTextString]];
        [self.suffixView setNeedsDisplay:YES];
    }
}


- (BOOL)isReady
{
    return ![self.string isEqualToString:self.uneditedTextString] &&
        ![self.string.strip isEqualToString:@""];
}

- (BOOL)isEmpty
{
    return [self.string.strip isEqualToString:@""];
}

- (void)textShouldBeginEditing
{
    if ([self.string isEqualToString:self.uneditedTextString])
    {
        self.string = @"";
    }
}

- (void)textDidBeginEditing
{
    [self useUneditedTextStringIfNeeded];
}

- (void)useUneditedTextStringIfNeeded
{
    if (self.uneditedTextString)
    {
        /*
        if ([self.string hasPrefix:self.uneditedTextString])
        {
            self.string = [self.string after:self.uneditedTextString];
            [self updateTheme];
        }
        */
        
        if ([self.string isEqualToString:@""] && self.window.firstResponder != self)
        {
            self.string = self.uneditedTextString;
            [self updateTheme];
        }
    }
}

- (void)setEditedThemePath:(NSString *)editedThemePath
{
    _editedThemePath = editedThemePath;
    [self updateTheme];
}

- (void)setIsValid:(BOOL)isValid
{
    if (_isValid != isValid)
    {
        _isValid = isValid;
        [self updateTheme];
    }
}

- (void)checkMaxStringLength
{
    if (self.maxStringLength)
    {
        NSUInteger max = self.maxStringLength.integerValue;
        
        if (self.string.length > max)
        {
            self.string = [self.string substringToIndex:max];
            //self.isValid = NO;
        }
    }
}

- (void)updateTheme
{
    NSString *themePath = nil;
    
    if ([self.string isEqualToString:self.uneditedTextString])
    {
        themePath = [_editedThemePath stringByAppendingString:@"-unedited"];
    }
    else
    {
        themePath = _editedThemePath;
    }
    
    if (!_isValid)
    {
        themePath = [_editedThemePath stringByAppendingString:@"-invalid"];
    }
    
    [self setThemePath:themePath];
    [self setNeedsDisplay:YES];
    
    // update suffix theme and fit to width
    if (self.suffixView)
    {
        [self.suffixView setThemePath:themePath];
        /*
        NSDictionary *att = [NavTheme.sharedNavTheme attributesDictForPath:themePath];
        CGFloat width = [[[NSAttributedString alloc] initWithString:self.suffixView.string
                                                         attributes:att] size].width;
        self.suffixView.width = width + 30;
        //NSLog(@"suffix '%@' %i %i", self.suffixView.string, (int)width, (int)self.suffixView.width);
        self.suffixView.backgroundColor = [NSColor blueColor];
        */
        [self.suffixView setNeedsDisplay:YES];
    }
    //[self.suffixView setHidden:!self.isReady];
}

/*
- (void)forceToBeNumber
{
    if (self.lastString && self.string.doubleValue == 0)
    {
        [self.string rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
        self.string = self.lastString;
        NSBeep();
    }
    
    self.lastString = self.string;
}
 */

- (void)setString:(NSString *)aString
{
    if (aString == nil)
    {
        aString = @"";
    }
    
    [super setString:aString];
    [self updateSuffixView];
}

- (void)textDidChange
{
    [self checkMaxStringLength];
    [self useUneditedTextStringIfNeeded];
    [self updateTheme];
    [self updateSuffixView];
}

- (void)textDidEndEditing
{
}

- (BOOL)becomeFirstResponder
{
    if ([self.string isEqualToString:self.uneditedTextString])
    {
        self.string = @"";
        [self updateTheme];
        [self setNeedsDisplay:YES];
    }

    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    //NSLog(@"resign");
    
    if ([self.string.strip isEqualToString:@""])
    {
        self.string = self.uneditedTextString;
        [self updateTheme];
        //NSLog(@"string on resign = '%@'", self.string);
    }
    
    return [super resignFirstResponder];
}

- (NSString *)stringSansUneditedString
{
    return [self.string stringByReplacingOccurrencesOfString:self.uneditedTextString withString:@""];
}

- (void)keyDown:(NSEvent *)theEvent
{
    // go to next keyView on return or tab instead of inserting
    
    unsigned int returnKeyCode = 36;
    unsigned int tabKeyCode    = 48;
    unsigned int deleteCode    = 51;
    
    
    unsigned int keyCode = [theEvent keyCode];
    
    if (keyCode == deleteCode) // hack
    {
        if (self.string.length == 1)
        {
            self.string = @"";
            [self setNeedsDisplay:YES];
            return;
        }
    }
    
    if (self.endsOnReturn)
    {
        if (keyCode == returnKeyCode ||
            keyCode == tabKeyCode)
        {
            [self.window makeFirstResponder:self.nextKeyView];
            return;
        }
    }
    
    [super keyDown:theEvent];
}

@end
