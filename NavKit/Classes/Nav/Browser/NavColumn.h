//
//  NavColumn.h
//  Bitmarket
//
//  Created by Steve Dekorte on 2/5/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NavView.h"
#import "NavColoredView.h"
#import "NavSearchField.h"
#import "NavTableView.h"
#import "NavVerticalScrollView.h"

@interface NavColumn : NSView <NSTableViewDataSource, NSTableViewDelegate, NavSearchFieldDelegate>

@property (assign, nonatomic) NavView *navView;
@property (strong, nonatomic) NavNode *node;
@property (strong, nonatomic) NavSearchField *searchField;

@property (strong, nonatomic) NavVerticalScrollView *scrollView;
@property (strong, nonatomic) NavTableView *tableView;
@property (strong, nonatomic) NSTableColumn *tableColumn;
@property (strong, nonatomic) NavColoredView *documentView; // view within scrollview containing headerView and tableView

@property (strong, nonatomic) NavColoredView *headerView; // top of document view

@property (strong, nonatomic) NSView *contentView; // replaces scrollview

@property (strong, nonatomic) NSView *actionStrip;
@property (assign, nonatomic) BOOL isUpdating;

@property (strong, nonatomic) NavNode *lastSelectedChild;

@property (assign, nonatomic) BOOL isInlined;

+ (CGFloat)actionStripHeight;

- (void)didAddToNavView;
- (void)prepareToDisplay;
- (NavThemeDictionary  *)themeDict;

- (NavNode *)selectedNode;
- (NSInteger)columnIndex;
- (BOOL)selectNextRow;

- (BOOL)selectRowIndex:(NSInteger)rowIndex; // returns YES if there was another index to select
- (void)justSelectNode:(id)aNode;

- (void)setupHeaderView:(NSView *)aView;
- (void)setContentView:(NSView *)aView;

- (BOOL)selectItemNamed:(NSString *)aName;

- (void)searchForString:(NSString *)aString;

- (void)selectFirstResponder;

- (NavColumn *)previousColumn;
- (BOOL)selectPreviousColumn;
- (id)nextRowObject;


@end
