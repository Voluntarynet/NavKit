//
//  NavView.m
//  Bitmarket
//
//  Created by Steve Dekorte on 2/5/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "NavView.h"
#import "NavColumn.h"
#import "NSView+sizing.h"
#import "NSWindow+positioning.h"
#import "NavSearchField.h"

@implementation NavView

- (BOOL)isOpaque
{
    return NO;
//    return self.alphaValue != 1.0;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    self.navColumns = [NSMutableArray array];
    self.actionStripHeight = 40.0;
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectNodeNotification:)
                                                 name:NavNodeSelectedNotification
                                               object:nil];
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)selectNodeNotification:(NSNotification *)aNote
{
    NavNode *node = aNote.object;

    if (node.nodeRememberedChildTitlePath)
    {
        // ugly - change the path convention to clean this up?
        
        NSMutableArray *path = [NSMutableArray arrayWithArray:node.nodeRememberedChildTitlePath];
        [path removeFirstObject];
        
        NSArray *titlePath = [self.rootNode nodeMaxTitlePath:path];
        NSMutableArray *nodes = [NSMutableArray arrayWithArray:titlePath];
        [nodes insertObject:self.rootNode atIndex:0];
        
        if (nodes.count > 1)
        {
            [self selectNodePath:nodes];
        }
    }
}

- (void)setRootNode:(NavNode *)rootNode
{
    _rootNode = rootNode;
    [self reload];
}

- (void)reload
{
    for (NavColumn *column in self.navColumns)
    {
        [column removeFromSuperview];
    }
    
    self.navColumns = [NSMutableArray array];
    
    [self addColumnForNode:self.rootNode];
}

- (NavColumn *)addColumnForNode:(NavNode *)node
{
    NavColumn *column = [[NavColumn alloc] initWithFrame:NSMakeRect(0, 0, 100, self.height)];
    [column setNode:node];

    NSView *lastColumn = self.navColumns.lastObject;
    [self.navColumns addObject:column];
    [self addSubview:column];

    [column setNavView:self];
    
    [column setHeight:self.height];
    
    if (lastColumn)
    {
        [column setX:lastColumn.x + lastColumn.width];
    }
    else
    {
        [column setX:0];
    }

    [column didAddToNavView];
    [self fitToColumns];
    
    return column;
}

- (void)setFrame:(NSRect)frameRect
{
    frameRect.size.width = ((NSView *)self.window.contentView).width;
    [super setFrame:frameRect];
    
    for (id view in self.subviews)
    {
        if ([view respondsToSelector:@selector(layout)])
        {
            [view layout];
        }
    }
}

- (void)fitToColumns
{
    self.width = self.columnsWidth;
    [self.window setMinWidth:self.totalSuggestedWidth];
    
    if (self.width < self.totalSuggestedWidth)
    {
        NSRect f = self.window.frame;
        f.size.width = self.totalSuggestedWidth;
        [self.window setFrame:f display:YES animate:YES];
    }
}

- (CGFloat)columnsWidth
{
    NSView *lastColumn = self.navColumns.lastObject;
    
    if (lastColumn)
    {
        CGFloat w = ((NSInteger)(lastColumn.x + lastColumn.width));
        return w;
    }
    
    return 0;
}

- (BOOL)shouldSelectNode:(NavNode *)node inColumn:inColumn
{
    NSMutableArray *toRemove = [NSMutableArray array];
    
    {
        BOOL hitColumn = NO;

        for (NavColumn *column in self.navColumns)
        {
            if (hitColumn)
            {
                [toRemove addObject:column];
                [column removeFromSuperview];
            }
            
            if (inColumn == column)
            {
                hitColumn = YES;
            }
        }
    }
    
    // remove old columns
    [self.navColumns removeObjectsInArray:toRemove];
    
    if (node)
    {
        NavColumn *newColumn = [self addColumnForNode:node];
        [newColumn prepareToDisplay];
    }
    
    //[self.window makeFirstResponder:inColumn];
    [node nodePostSelected];
    
    return YES;
}

- (CGFloat)totalSuggestedWidth
{
    NSUInteger w = 0;
    
    for (NavColumn *column in self.navColumns)
    {
        w += [column node].nodeSuggestedWidth.floatValue;
    }
    
    return w;
    
    //[self.window setWidth:totalWidth];
    //[self setWidth:totalWidth];
}

- (void)clearColumns
{
    for (NavColumn *column in self.navColumns)
    {
        [column removeFromSuperview];
    }
    
    [self.navColumns removeAllObjects];
}

- (void)selectPath:(NSArray *)pathComponents
{
    NSArray *nodes = [self.rootNode nodeTitlePath:pathComponents];
    [self selectNodePath:nodes];
}

- (void)selectNodePath:(NSArray *)nodes
{
    [self clearColumns];
    
    NavColumn *column = nil;
    
    {
        NavColumn *lastColumn = nil;
        
        for (NavNode *node in nodes)
        {
            column = [self addColumnForNode:node];
            
            if (lastColumn)
            {
                [lastColumn justSelectNode:node];
            }
            
            lastColumn = column;
        }
    }
    
    if ([column respondsToSelector:@selector(prepareToDisplay)])
    {
        [column prepareToDisplay];
    }
}

- (NSColor *)bgColor
{
    return [NavTheme.sharedNavTheme formBackgroundColor];
}

- (NSRect)drawFrame
{
    NSRect frame = self.frame;
    frame.size.height -= self.actionStripHeight;
    return frame;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect f = self.drawFrame;
    [[self bgColor] set];
    //[[NSColor blueColor] set];
    NSRectFill(f);
    //[super drawRect:f];
}

// --- actions ---------------------------------------------------

- (BOOL)canHandleAction:(SEL)aSel
{
    id lastColumn = [self.navColumns lastObject];
    return [lastColumn canHandleAction:aSel];
}

- (void)handleAction:(SEL)aSel
{
    id lastColumn = [self.navColumns lastObject];
    [lastColumn handleAction:aSel];
}

- (NavNode *)lastNode
{
    NSEnumerator *e = [self.navColumns reverseObjectEnumerator];
    id column = nil;
    
    while (column = [e nextObject])
    {
        if ([column respondsToSelector:@selector(node)])
        {
            NavNode *node = [column node];
            return node;
        }
    }
    
    return nil;
}

/*
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSLog(@"class %@ got key down", NSStringFromClass([self class]));
}
*/

- (NavColumn *)columnBeforeColumn:(NavColumn *)aColumn
{
    NSInteger index = [self.navColumns indexOfObject:aColumn];
    
    if (index == -1 || index == 0)
    {
        return nil;
    }
    
    NavColumn *inColumn = [self.navColumns objectAtIndex:index - 1];
    return inColumn;
}

- (void)leftArrowFrom:aColumn
{
    /*
    NSInteger index = [self.navColumns indexOfObject:aColumn];
    
    if (index == -1 || index == 0)
    {
        return;
    }
    
    NavColumn *inColumn = [self.navColumns objectAtIndex:index - 1];
    */
    
    NavColumn *inColumn = [self columnBeforeColumn:aColumn];
    
    [self shouldSelectNode:[inColumn selectedNode] inColumn:inColumn];
    [inColumn.window makeFirstResponder:inColumn.tableView];
}

- (void)rightArrowFrom:aColumn
{
    NSInteger index = [self.navColumns indexOfObject:aColumn];

    if (index == self.navColumns.count - 1)
    {
        return;
    }
    
    NavColumn *inColumn = [self.navColumns objectAtIndex:index + 1];
    
    if ([inColumn respondsToSelector:@selector(selectRowIndex:)])
    {
        [inColumn selectRowIndex:0];
        [inColumn.window makeFirstResponder:inColumn.tableView];
    }
    else
    {
        [inColumn selectFirstResponder];
    }
}

- (NSInteger)indexOfColumn:(NavColumn *)aColumn
{
    return [self.navColumns indexOfObject:aColumn];
}

- (NavColumn *)columnForNode:(id)node
{
    for (NavColumn *column in self.navColumns)
    {
        if (column.node == node)
        {
            return column;
        }
    }
    
    return nil;
}

@end
