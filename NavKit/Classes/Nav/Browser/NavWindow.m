//
//  NavWindow.m
//  NavKit
//
//  Created by Steve Dekorte on 4/16/14.
//  Copyright (c) 2014 voluntary.net. All rights reserved.
//

#import "NavWindow.h"
#import "NSView+sizing.h"
#import "NavColumn.h"

@implementation NavWindow

+ (NavWindow *)newWindow
{
    NavWindow *instance = [[NavWindow alloc]
                           initWithContentRect:NSMakeRect(0, 0, 1600, 700)
                           styleMask:  NSTitledWindowMask |
                                       //NSClosableWindowMask |
                                       NSMiniaturizableWindowMask |
                                       NSResizableWindowMask |
                                       NSTexturedBackgroundWindowMask
                           backing:NSBackingStoreBuffered
                           defer:NO];
    [instance setReleasedWhenClosed:NO];
    
    
    return instance;
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:contentRect
                            styleMask:windowStyle
                              backing:bufferingType
                                defer:deferCreation];
    
    
    _backgroundView = [[NavColoredView alloc] initWithFrame:NSMakeRect(0, 0, contentRect.size.width, contentRect.size.height - [NavColumn actionStripHeight])];
    [_backgroundView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [_backgroundView setBackgroundColor:[NSColor blackColor]];
    [self.contentView addSubview:_backgroundView];
    
    [self setupBrowser];
    
    // add full screen support to window
    [[NSApplication sharedApplication] setPresentationOptions:NSFullScreenWindowMask];
    [self setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    [self setFrameUsingName:[self windowName]];
    [self setMinSize:NSMakeSize(300, 300)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTitleNotification:)
                                                 name:NavWindowSetTitle
                                               object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTitleNotification:(NSNotification *)aNote
{
    NSString *newTitle = [[aNote userInfo] objectForKey:@"windowTitle"];
    
    if (newTitle)
    {
        [self setTitle:newTitle];
    }
}

- (NSString *)windowName
{
    return @"NavMainWindow";
}

- (void)close
{
    [self saveFrameUsingName:self.windowName];
    [super close];
}

- (NSRect)contentFrame
{
    return ((NSView *)self.contentView).frame;
}

- (void)setupBrowser
{
    _scrollView = [[NSScrollView alloc] initWithFrame:self.contentFrame];
    [self.contentView addSubview:_scrollView];

    [_scrollView setDrawsBackground:NO];
    //[_scrollView setBackgroundColor:[NSColor redColor]];
    [_scrollView setBorderType:NSNoBorder];
    [_scrollView setAutohidesScrollers:NO];
    [_scrollView setAutoresizesSubviews:YES];
    [_scrollView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [_scrollView setHasHorizontalScroller:YES];
    [_scrollView setHasVerticalScroller:NO];
    [_scrollView setAllowsMagnification:NO];
    [_scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    [_scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
    
    // add main view
    _navView = [[NavView alloc] initWithFrame:self.contentFrame];
    //[self.contentView addSubview:_navView];
    [_scrollView setDocumentView:_navView];

    [self setupProgress];
}

- (void)setupProgress
{
    // setup progress indicator
    _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, ((NSView *)self.contentView).height - 28, 16, 16)];
    [self.contentView addSubview:_progressIndicator];

    
    self.progressController = [[NavProgressController alloc] init];
    [self.progressController setProgress:_progressIndicator];
    [NSNotificationCenter.defaultCenter postNotificationName:ProgressPushNotification object:self];
}

- (void)showSplashView
{
    [_navView removeFromSuperview];
    [_splashView setFrame:self.contentFrame];
    [self.contentView addSubview:_splashView];
    [_navView setHidden:YES];
    //[_progressIndicator setHidden:NO];
}

- (void)hideSplashView
{
    [_splashView removeFromSuperview];
    [_navView setHidden:NO];
    //[_progressIndicator setHidden:NO];
}

@end
