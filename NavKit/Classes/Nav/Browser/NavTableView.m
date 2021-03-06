//
//  NavTableView.m
//  Bitmessage
//
//  Created by Steve Dekorte on 4/14/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "NavTableView.h"
#import "NSEvent+keys.h"

@implementation NavTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        //[self setIntercellSpacing:NSMakeSize(10, 10)];
    }
    
    [[self enclosingScrollView] setScrollerStyle:NSScrollerStyleOverlay];
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)event
{
    //NSLog(@"TableView keyDown");
    
    if ([event isUpArrow])
    {
        //NSLog(@"isUpArrow action for event");
        [super keyDown:event];
    }
    else if ([event isDownArrow])
    {
        //NSLog(@"isDownArrow action for event");
        [super keyDown:event];
    }
    else
    {
        [self.eventDelegate keyDown:event];
    }
}

/*
- (BOOL)acceptsFirstResponder
{
    return NO;
}
*/

@end
