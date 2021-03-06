//
//  NavColumn.m
//  Bitmarket
//
//  Created by Steve Dekorte on 2/5/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "NavColumn.h"
#import "NavTableCell.h"
#import "NSView+sizing.h"
#import "NSEvent+keys.h"
#import "NavSearchField.h"
#import "NavTheme.h"
//#import <BitMessageKit/BitMessageKit.h>
#import <objc/runtime.h> // for associations on button to set action - should we switch to custom button?
#import <FoundationCategoriesKit/FoundationCategoriesKit.h>

@implementation NavColumn

+ (CGFloat)actionStripHeight
{
    return 40.0;
}

- (BOOL)isOpaque
{
    return NO;
//    return self.alphaValue != 1.0;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:NSViewHeightSizable /* | NSViewWidthSizable*/];
    //[self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [self setupSubviews];
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setupSubviews
{
    CGFloat h = self.class.actionStripHeight;
    self.actionStrip = [[NSView alloc] initWithFrame:NSMakeRect(0, self.height - h, self.width, h)];
    [self.actionStrip setAutoresizingMask:NSViewMinYMargin];
    [self addSubview:self.actionStrip];
    
    // scrollview
    
    self.scrollView = [[NavVerticalScrollView alloc] initWithFrame:self.scollFrameSansStrip];
    [self addSubview:self.scrollView];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalRuler:NO];
    [self.scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    
    [self.scrollView setAutoresizesSubviews:YES];
    [self.scrollView setAutoresizingMask:NSViewHeightSizable];
    
    // table
    
    self.tableView = [[NavTableView alloc] initWithFrame:self.scrollView.bounds];
    self.tableView.eventDelegate = self;
    [self.tableView setIntercellSpacing:NSMakeSize(0, 1)];
    
    [self.tableView setAutoresizesSubviews:YES];
    [self.tableView setAutoresizingMask:NSViewHeightSizable];
    
    self.tableColumn = [[NSTableColumn alloc] init];
    [self.tableColumn setDataCell:[[NavTableCell alloc] init]];
    [self.tableView addTableColumn:self.tableColumn];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView setDoubleAction:@selector(doubleClickedCell:)];
    [self.tableView setTarget:self];
    
    [self.tableView setHeaderView:nil];
    [self.tableView setFocusRingType:NSFocusRingTypeNone];
    
    if (NO)
    {
        self.documentView = [[NavColoredView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
        [self.scrollView setDocumentView:self.documentView];
        [self.documentView setFrame:NSMakeRect(0, 0, 1000, 1000)];
        
        
         self.headerView = [[NavColoredView alloc] initWithFrame:NSMakeRect(0, 0, self.width, 150)];
         if (self.headerView)
         {
             [self.documentView addSubview:self.headerView];
         }
        
        [self.documentView addSubview:self.tableView];
        [NSNotificationCenter.defaultCenter addObserver:self
                                                 selector:@selector(updateDocumentView:)
                                                     name:@"NSViewFrameDidChangeNotification"
                                                   object:self.tableView];
    }
    else
    {
        [self.scrollView setDocumentView:self.tableView];
    }
    
    [self setRowHeight:60];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
//    [self layoutActionStrip];
}

- (NSRect)scollFrameSansStrip
{
    NSRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.height -= self.class.actionStripHeight;
    return frame;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self prepareToDisplay];
    /*
     NSRect f = self.drawFrame;
     [[self bgColor] set];
     NSRectFill(f);
     [super drawRect:f];
     */
    [self setNeedsDisplay:NO];
    
    /*
    [self lockFocus];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    [self drawVerticalLineAtX:0];
    [self drawVerticalLineAtX:self.width];
    [self unlockFocus];
    */
}

- (NSArray *)allChildren
{
    if (self.node.shouldInlineChildren)
    {
        return self.node.inlinedChildren;
    }
    /*else
    {
        return self.node.children;
    }
    */
    
    if (_searchField && _searchField.stringValue.length)
    {
        return self.node.nodeSearchResults;
    }
    
    return self.node.children;

}

// ----------------------------------------

- (BOOL)selectedNodeWasRemoved
{
    return ![self.allChildren containsObject:[self selectedNode]];
}

- (void)reloadData
{
    BOOL needsNavUpdate = NO;
    
    NSInteger row = self.tableView.selectedRow;
    NSInteger maxRow = self.allChildren.count - 1;
    
    if (row > maxRow)
    {
        row = maxRow;
    }
    
    [self.tableView reloadData];
    
    if (_lastSelectedChild)
    {
        NSInteger nodeRow = [self rowForNode:_lastSelectedChild];
        //NSLog(@"get _lastSelectedChild %@ row %i", _lastSelectedChild, (int)nodeRow);
        
        if (nodeRow == -1)
        {
            needsNavUpdate = YES;
        }
        else
        {
            row = nodeRow;
        }
    }

    if (needsNavUpdate && row != -1)
    {
        [self tableView:self.tableView shouldSelectRow:row];
    }
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    _lastSelectedChild = self.selectedNode;
    
    //[self setNeedsDisplay:YES]; // new March 11 2015
    //[self selectRowIndex:row];
}

- (void)nodeRemovedChild:(NSNotification *)note
{
    BOOL needToUpdateNav = [self selectedNodeWasRemoved];
    
    [self reloadData];

    if (needToUpdateNav)
    {
        [self.navView shouldSelectNode:self.selectedNode inColumn:self];
    }
}

- (void)nodeAddedChild:(NSNotification *)note
{
    NavNode * node = self.node;
    
    if (node)
    {
        if ([node nodeShouldSelectChildOnAdd].boolValue)
        {
            id child = [[note userInfo] objectForKey:@"child"];
            [self.tableView reloadData];
            NSInteger row = [self rowForNode:child];
            [self selectRowIndex:row];
            return;
        }
        else
        {
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            //[self reloadData];
        }
    }
}

- (void)nodeChanged:(NSNotification *)note
{
    [self reloadData];
}

- (id)nextRowObject
{
    NSInteger nextRow = [self.tableView selectedRow] + 1;
    
    if (nextRow < self.allChildren.count)
    {
        return [self.allChildren objectAtIndex:nextRow];
    }
    
    return nil;
}

- (BOOL)selectNextRow
{
    NSInteger nextRow = [self.tableView selectedRow] + 1;
    return [self selectRowIndex:nextRow];
}

- (NavColumn *)previousColumn
{
    NavColumn *prev = [self.navView columnBeforeColumn:self];
    return prev;
}

- (BOOL)selectPreviousColumn
{
    NavColumn *prev = self.previousColumn;
    
    if (prev)
    {
        [self.window makeFirstResponder:prev];
        return YES;
    }
    
    return NO;
}

- (BOOL)selectRowIndex:(NSInteger)rowIndex
{
    NSInteger count = [self numberOfRowsInTableView:self.tableView];

    if (rowIndex != -1 && rowIndex < count)
    {
        [self tableView:self.tableView shouldSelectRow:rowIndex];
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [self.tableView scrollRowToVisible:rowIndex];
        _lastSelectedChild = self.selectedNode;
        return YES;
    }
    
    return NO;
}

- (void)justSelectNode:(id)aNode
{
    NSInteger rowIndex = [self rowForNode:aNode];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
    [self.tableView scrollRowToVisible:rowIndex];
    _lastSelectedChild = aNode;
}

- (BOOL)selectItemNamed:(NSString *)aName
{
    NSInteger rowIndex = 0;
    
    for (NavNode * child in self.allChildren)
    {
        if ([[child nodeTitle] isEqualToString:aName])
        {
            [self selectRowIndex:rowIndex];
            return YES;
        }
        
        rowIndex ++;
    }
    
    return NO;
}

- (void)setRowHeight:(CGFloat)height
{
    [self.tableView setRowHeight:height];
}

- (void)setMaxWidth:(CGFloat)w
{
    [self.tableColumn setMaxWidth:w];
    [self.scrollView setWidth:w];
    [self.tableView setWidth:w];
    [self setWidth:w];
}

- (void)setNode:(NavNode *)node
{
    if (_node != node)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self];

        _node = node;
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                                 selector:@selector(nodeChanged:)
                                                     name:NavNodeChangedNotification
                                                   object:_node];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                                 selector:@selector(nodeRemovedChild:)
                                                     name:NavNodeRemovedChildNotification
                                                   object:_node];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                                 selector:@selector(nodeAddedChild:)
                                                     name:NavNodeAddedChildNotification
                                                   object:_node];
        
        
        [self updateActionStrip];

        if (![node nodeView])
        {
            CGFloat w = node.nodeSuggestedWidth.floatValue;
            
            if (w)
            {
                [self setMaxWidth:w];
            }
            else
            {
                [self setMaxWidth:1000];
            }
        }
        
        [self.tableView reloadData];
        
        
        [self setRowHeight:self.node.nodeSuggestedRowHeight];
    }
}

- (void)fitWidthToRemainingSpace
{
    if (YES)
    {
        CGFloat w = fabs(((NSView *)self.navView.window.contentView).width - self.x);
        
        [self setWidth:w];
        [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    }
    /*
    else
    {
        //[self setWidth:850];
        //self.contentView.width = self.width;
        
        CGFloat minWidth = 850; //self.node.nodeSuggestedWidth.floatValue;
        
        if (minWidth == 0)
        {
            minWidth = 850;
        }
        
        CGFloat w = fabs(((NSView *)self.navView.window.contentView).width - self.x);
        
        if (w < minWidth)
        {
            w = minWidth;
        }
        
        [self setWidth:w];
        self.contentView.width = self.width;
    }
    */
}

- (void)layout
{
    [self updateWidth];
}

- (void)updateWidth
{
    NSView *nodeView = [self.node nodeView];
    
    if (nodeView && ![self.node nodeForceDisplayChildren].boolValue)
    {
        [self fitWidthToRemainingSpace];
        [nodeView setFrameSize:self.frame.size];
        [self setContentView:nodeView];
    }
    else if (self.node.nodeSuggestedWidth.floatValue == 0)
    {
        [self fitWidthToRemainingSpace];
    }
    else
    {
        self.width = self.node.nodeSuggestedWidth.floatValue;
        self.contentView.width = self.width;
    }
}

- (void)didAddToNavView
{
    [self updateWidth];
    
    [self.tableView setBackgroundColor:self.themeDict.unselectedBgColor];
    // if using document view
    [self.documentView setBackgroundColor:self.tableView.backgroundColor];
}

- (void)updateDocumentView:(NSNotification *)note
{
    //NSLog(@"tableFrameDidChangeNotification");
    
    if (!self.isUpdating &&
        //[note object] == self.tableView &&
        !NSEqualRects(self.documentView.bounds, self.tableView.bounds))
    {
        CGFloat fullHeight = [self.documentView sumOfSubviewHeights];
        
        if (fullHeight < self.scrollView.height)
        {
            fullHeight = self.scrollView.height;
        }
        
        NSRect newFrame = self.tableView.bounds;
        newFrame.size.height = fullHeight;
        
        self.isUpdating = YES;
        [self.documentView setFrame:newFrame];
        
        [self.documentView stackSubviewsTopToBottom];
        
        //[self.tableView setY:newFrame.size.height - self.tableView.height];
        self.isUpdating = NO;
    }
}

- (NSInteger)columnIndex
{
    return [self.navView indexOfColumn:self];
}

- (void)prepareToDisplay
{
    if (self.scrollView.superview)
    {
        BOOL useSuggestedWidth = self.node.nodeSuggestedWidth.floatValue > 0;
        
        if (useSuggestedWidth)
        {
            [self setMaxWidth:self.node.nodeSuggestedWidth.floatValue];
        }
        else
        {
            [self fitWidthToRemainingSpace];
        }
    }
    else if (self.contentView)
    {
        [self setMaxWidth:self.contentView.width];
    }
    
    [self layoutActionStrip];
}

- (NavThemeDictionary  *)themeDict
{
    return [NavTheme.sharedNavTheme themeForColumn:self.columnIndex];
}

/*
- (void)makeScrollViewFill
{
    [self.scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    //self.scrollView.frame = self.scollFrameSansStrip;
}
*/


- (void)setContentView:(NSView *)aView
{
    [(NavColumn *)aView setNavView:self.navView];
    
    //aView = [[NavColoredView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    //[(NavColoredView *)aView setBackgroundColor:[NSColor redColor]];
    [self setAutoresizesSubviews:YES];
    //[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self setAutoresizingMask:NSViewHeightSizable];
    [aView setAutoresizingMask:aView.autoresizingMask | NSViewWidthSizable];
    
    [self.scrollView removeFromSuperview];
    [self.contentView removeFromSuperview];
    _contentView = aView;
    
    self.contentView.frame = self.scollFrameSansStrip;
    [self addSubview:self.contentView];
    
    [self setNeedsDisplay:YES];
    
}

- (void)setupHeaderView:(NSView *)aView
{
    [self.tableView removeFromSuperview]; // so views are in correct order

    if (self.headerView)
    {
        [self.headerView removeFromSuperview];
    }
    
    //[self setMaxWidth:aView.i];
    self.headerView = (NavColoredView *)aView;
    [self.documentView addSubview:aView];
    [self.documentView addSubview:self.tableView];
    [self updateDocumentView:nil];
}

- (NavNode *)nodeForRow:(NSInteger)rowIndex
{
    if (rowIndex < self.allChildren.count)
    {
        return [self.allChildren objectAtIndex:rowIndex];
    }
    
    return nil;
}

- (NSInteger)rowForNode:(NavNode *)aNode
{
    NSInteger rowIndex = 0;
    
    for (id childNode in self.allChildren)
    {
        if (childNode == aNode)
        {
            return rowIndex;
        }
        
        rowIndex ++;
    }
    
    return -1;
}

// table data source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self.allChildren count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
    if (rowIndex < self.allChildren.count)
    {
        return [[self.allChildren objectAtIndex:rowIndex] nodeTitle];
    }
    else
    {
        NSLog(@"NavColumn: found bug in table!");
        return nil;
    }
}

// table delegate

// --- methods to deal with header ---

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)rowIndex
{
    return self.tableView.rowHeight;
}

// --- normal delegate methods ---

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    NavNode *node = [self nodeForRow:rowIndex];

    if (node.nodeParentInlines)
    {
        return NO;
    }
    
    //if (_lastSelectedChild != node)
    {
        _lastSelectedChild = node;
        [self.navView shouldSelectNode:node inColumn:self];
        [node nodeWillSelect];
    }
    
    return YES;
}

/*
// This was slow and choppy. Why?
 
- (NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    NavRowView *rowView = [aTableView makeViewWithIdentifier:@"NavRowView" owner:self];
    //NavRowView *rowView = [[NavRowView alloc] initWithFrame:NSMakeRect(0, 0, self.width, aTableView.rowHeight)];
    //NavRowView *rowView = [[NavRowView alloc] initWithFrame:NSMakeRect(0, 0, self.width, aTableView.rowHeight)];
    if (!rowView)
    {
        rowView = [[NavRowView alloc] initWithFrame:NSZeroRect];
    }
    ///[rowView setIsSelected:[aTableView selectedRow] == rowIndex];
    [rowView setNode:[self nodeForRow:rowIndex]];
    rowView.tableView = aTableView;
    rowView.rowIndex = rowIndex;
    return rowView;
}
*/


- (void)tableView:(NSTableView *)aTableView
    willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    [aCell setIsSelected:[aTableView selectedRow] == rowIndex];
    [aCell setNode:[self nodeForRow:rowIndex]];
    [aCell setNavColumn:self];
}

- (NavNode *)selectedNode
{
    NSInteger selectedRow = [self.tableView selectedRow];
    
    if (selectedRow >= 0)
    {
        return [self nodeForRow:selectedRow];
    }
    
    return nil;
}

// --- actions ---

- (BOOL)canHandleAction:(SEL)aSel
{
    return [self.node respondsToSelector:aSel];
}

- (void)handleAction:(SEL)aSel
{
    if ([self.node respondsToSelector:aSel])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(NSObject *)self.node performSelector:aSel withObject:nil];
#pragma clang diagnostic pop
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    //NSLog(@"column %@ got key down", NSStringFromClass(self.node.class));
    
    if ([event isDeleteDown])
    {
        //NSLog(@"delete action for event");
        [self delete];
    }
    else if ([event isLeftArrow])
    {
        //NSLog(@"isLeftArrow action for event");
        [self leftArrow];
    }
    else if ([event isRightArrow])
    {
        //NSLog(@"rightArrow action for event");
        [self rightArrow];
    }
    /*
    else if ([event isUpArrow])
    {
        NSLog(@"isUpArrow action for event");
        [self upArrow];
    }
    else if ([event isDownArrow])
    {
        NSLog(@"isDownArrow action for event");
        [self downArrow];
    }
    */
    else
    {
        //NSLog(@"no action for event");
        NSView *selectedNodeView = [self selectedNode].nodeView;
        
        if (selectedNodeView)
        {
            
            [selectedNodeView keyDown:event];
        }
    }
}

- (void)delete
{
    NavNode * node = [self selectedNode];

    [self sendAction:@"delete" toNode:node];
}

- (void)leftArrow
{
    [self.navView leftArrowFrom:self];
}

- (void)rightArrow
{
    [self.navView rightArrowFrom:self];
}

- (void)downArrow
{
    
}

- (void)upArrow
{
    
}

// --- action strip ----------------------------------------

- (void)updateActionStrip
{
    if ([self.node.nodeView respondsToSelector:@selector(handlesNodeActions)])
    {
        if ([(id)(self.node.nodeView) handlesNodeActions])
        {
            return;
        }
    }
    
    [_actionStrip setWidth:self.width];
    //[_actionStrip setBackgroundColor:[NSColor redColor]];
    
    CGFloat buttonHeight = 40;
    
    /*
    NSLog(@"updateActionStrip w %i for node %@ %@", (int)_actionStrip.width, NSStringFromClass(self.node.class), self.node.nodeTitle);
    NSLog(@"self.width %i", (int)self.width);
    NSLog(@"self.tableView.width %i", (int)self.tableView.width);
    */
    
    for (NSView *view in [NSArray arrayWithArray:[self.actionStrip subviews]])
    {
        [view removeFromSuperview];
    }
    
    [self setAutoresizesSubviews:YES];
    
    for (NSString *action in self.node.actions)
    {
        //CGFloat y = self.actionStrip.height/2 - buttonHeight/2;
        NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 50, buttonHeight)];
        [button setButtonType:NSMomentaryChangeButton];
        [button setBordered:NO];
        [button setFont:[NSFont fontWithName:[NavTheme.sharedNavTheme lightFontName] size:14.0]];
        [button setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
        
         NSString *imageName = [NSString stringWithFormat:@"%@_active", action];
         NSImage *image = [NSImage imageNamed:imageName];
        
         if (image && YES)
         {
             [button setImage:image];
             [button setWidth:image.size.width*2.5];
         }
         else
        {
            NSDictionary *att = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [button font], NSFontAttributeName,
                                 nil];
            CGFloat width = [[[NSAttributedString alloc] initWithString:action attributes:att] size].width + 15;
            [button setTitle:action];
            [button setWidth:width];
            //NSLog(@"button width %i", (int)width);
        }
        
        [button setToolTip:action];
        
        [button setTarget:self];
        [button setAction:@selector(hitActionButton:)];
        [self.actionStrip addSubview:button];
        
        objc_setAssociatedObject(button, @"action", action, OBJC_ASSOCIATION_RETAIN);
    }
 
    BOOL osxSearchFieldUIIsHosed = NO; //[[NSProcessInfo processInfo] majorMinorOSXVersionNumber].floatValue > 10.09;
    
    if (!osxSearchFieldUIIsHosed && [self.node canSearch])
    {
        Class searchFieldClass = NavSearchField.class;
        
        _searchField = [[searchFieldClass alloc] initWithFrame:NSMakeRect(0, 0, 20, buttonHeight)];
        [_searchField setSearchDelegate:self];
        [self.actionStrip addSubview:_searchField];
        //[_searchField setupExpanded];
        [_searchField setupCollapsed];
        [_searchField setToolTip:@"search"];
        [_searchField setSearchOnReturn:[self.node nodeSearchOnReturn]];
    }
    else
    {
        _searchField = nil;
    }
    
    [self layoutActionStrip];
}

- (void)layoutActionStrip
{
    if (self.actionStrip.width != self.width)
    {
        [self.actionStrip setWidth:self.width];
        [self.actionStrip stackSubviewsRightToLeftWithMargin:10.0];
        [self.actionStrip adjustSubviewsX:-10];
        [self.actionStrip centerSubviewsY];
    }
}

- (void)hitActionButton:(id)aButton
{
    NSString *action = objc_getAssociatedObject(aButton, @"action");
    //NSLog(@"hit action %@", action);
    [self sendAction:action toNode:self.node];
}
    
- (void)sendAction:(NSString *)action toNode:(NavNode *)aNode
{
    NavActionSlot *actionSlot = [aNode.navMirror actionSlotNamed:action];

    //if (![[aNode actions] containsObject:action])
    if (!actionSlot)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:[NSString stringWithFormat:@"%@ action not implemented", action]];
        [alert setInformativeText:@""];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        [alert runModal];
        return;
    }
    
    if (!actionSlot.isActive)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:[NSString stringWithFormat:@"%@ action disabled", action]];
        [alert setInformativeText:@""];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        return;
    }
        
    NSString *verifyMessage = [aNode verifyActionMessage:action];

        
    if (verifyMessage)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:[action capitalizedString]];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:[NSString stringWithFormat:@"%@ \"%@\"?", [action capitalizedString], aNode.nodeTitle]];
        [alert setInformativeText:verifyMessage];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertSecondButtonReturn)
        {
            // cancel
            return;
        }
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [aNode performSelector:NSSelectorFromString(action) withObject:nil];
#pragma clang diagnostic pop    
}

- (void)searchForString:(NSString *)aString
{
    //NSLog(@"searchForString '%@'", aString);
    [self.node search:aString];
    
    BOOL hasLastSelection = [self.node.children containsObject:self.self.lastSelectedChild];
    if (!hasLastSelection)
    {
        self.lastSelectedChild = nil;
        [self reloadData];
        [self.navView shouldSelectNode:nil inColumn:self];
    }
    else
    {
        [self reloadData];
        NSUInteger row = [self.tableView selectedRow];
        [self.tableView scrollRowToVisible:row];
        //[self.navView shouldSelectNode:self.lastSelectedChild inColumn:self];
    }
}

- (void)selectFirstResponder
{
    
}

- (void)doubleClickedCell:(id)anObject
{
    NSUInteger rowIndex = self.tableView.clickedRow;
    NavNode *rowNode = [self.node.children objectAtIndex:rowIndex];
    
    if ([rowNode respondsToSelector:@selector(nodeDoubleClick)])
    {
        [rowNode nodeDoubleClick];
    }
}

@end
