/** <title>NSTextContainer</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2002-11-23

   Author: Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <AppKit/GSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSNotification.h>

@interface NSTextContainer (TextViewObserver)
- (void) _textViewFrameChanged: (NSNotification*)aNotification;
@end

@implementation NSTextContainer (TextViewObserver)

- (void) _textViewFrameChanged: (NSNotification*)aNotification
{
  if (_observingFrameChanges)
    {
      id	textView;
      NSSize	newTextViewSize;
      NSSize	size;
      NSSize	inset;

      textView = [aNotification object];
      if (textView != _textView)
        {
	    NSDebugLog (@"NSTextContainer got notification for wrong View %@",
			textView);
	    return;
	}
      newTextViewSize = [textView frame].size;
      size = _containerRect.size;
      inset = [textView textContainerInset];

      if (_widthTracksTextView)
	{
	  size.width = MAX (newTextViewSize.width - (inset.width * 2.0), 0.0);
	}
      if (_heightTracksTextView)
	{
	  size.height = MAX (newTextViewSize.height - (inset.height * 2.0), 
			     0.0);
	}

      [self setContainerSize: size];
    }
}

@end /* NSTextContainer (TextViewObserver) */

@implementation NSTextContainer

+ (void) initialize
{
  if (self == [NSTextContainer class])
    {
      [self setVersion: 1];
    }
}

- (id) initWithContainerSize: (NSSize)aSize
{
  NSDebugLLog (@"NSText", @"NSTextContainer initWithContainerSize");
  _layoutManager = nil;
  _textView = nil;
  _containerRect.size = aSize;
  _lineFragmentPadding = 0.0;
  _observingFrameChanges = NO;
  _widthTracksTextView = NO;
  _heightTracksTextView = NO;

  return self;
}

- (void) dealloc
{
  if (_textView != nil)
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc removeObserver: self
	  name: NSViewFrameDidChangeNotification
	  object: _textView];
      
      RELEASE (_textView);
    }
  [super dealloc];
}

- (void) setLayoutManager: (GSLayoutManager*)aLayoutManager
{
  /* The layout manager owns us - so he retains us and we don't retain 
     him. */
  _layoutManager = aLayoutManager;
}

- (GSLayoutManager*) layoutManager
{
  return _layoutManager;
}

/**
 * Replaces the layout manager while maintaining the text object
 * framework intact.
 */
- (void) replaceLayoutManager: (GSLayoutManager*)aLayoutManager
{
  if (aLayoutManager != _layoutManager)
    {
      id	textStorage = [_layoutManager textStorage];
      NSArray	*textContainers = [_layoutManager textContainers]; 
      unsigned	i, count = [textContainers count];
      id oldLayoutManager = _layoutManager;

      RETAIN (oldLayoutManager);
      [textStorage removeLayoutManager: _layoutManager];
      [textStorage addLayoutManager: aLayoutManager];

      for (i = 0; i < count; i++)
	{
	  NSTextContainer *container;

	  container = RETAIN ([textContainers objectAtIndex: i]);
	  [_layoutManager removeTextContainerAtIndex: i];
	  [aLayoutManager addTextContainer: container];
	  /* The textview is caching the layout manager; refresh the
	   * cache with this do-nothing call.  */
	  [[container textView] setTextContainer: container];
	  RELEASE (container);
	}
      RELEASE (oldLayoutManager);
    }
}

- (void) setTextView: (NSTextView*)aTextView
{
  NSNotificationCenter *nc;

  nc = [NSNotificationCenter defaultCenter];
	  
  if (_textView)
    {
      [_textView setTextContainer: nil];
      [nc removeObserver: self  name: NSViewFrameDidChangeNotification 
	  object: _textView];
      /* NB: We do not set posts frame change notifications for the
	 text view to NO because there could be other observers for
	 the frame change notifications. */
    }

  ASSIGN (_textView, aTextView);

  if (aTextView != nil)
    {
      [_textView setTextContainer: self];
      if (_observingFrameChanges)
	{
	  [_textView setPostsFrameChangedNotifications: YES];
	  [nc addObserver: self
	      selector: @selector(_textViewFrameChanged:)
	      name: NSViewFrameDidChangeNotification
	      object: _textView];
	}
    }

  [_layoutManager textContainerChangedTextView: self];
}

- (NSTextView*) textView
{
  return _textView;
}

- (void) setContainerSize: (NSSize)aSize
{
  if (NSEqualSizes (_containerRect.size, aSize))
    {
      return;
    }

  _containerRect = NSMakeRect (0, 0, aSize.width, aSize.height);

  if (_layoutManager)
    {
      [_layoutManager textContainerChangedGeometry: self];
    }
}

- (NSSize) containerSize
{
  return _containerRect.size;
}

- (void) setWidthTracksTextView: (BOOL)flag
{
  NSNotificationCenter *nc;
  BOOL old_observing = _observingFrameChanges;

  _widthTracksTextView = flag;
  _observingFrameChanges = _widthTracksTextView | _heightTracksTextView;

  if (_textView == nil)
    return;

  if (_observingFrameChanges == old_observing)
    return;

  nc = [NSNotificationCenter defaultCenter];

  if (_observingFrameChanges)
    {      
      [_textView setPostsFrameChangedNotifications: YES];
      [nc addObserver: self
	  selector: @selector(_textViewFrameChanged:)
	  name: NSViewFrameDidChangeNotification
	  object: _textView];
    }
  else
    {
      [nc removeObserver: self name: NSViewFrameDidChangeNotification 
	  object: _textView];
    }
}

- (BOOL) widthTracksTextView
{
  return _widthTracksTextView;
}

- (void) setHeightTracksTextView: (BOOL)flag
{
  NSNotificationCenter *nc;
  BOOL old_observing = _observingFrameChanges;

  _heightTracksTextView = flag;
  _observingFrameChanges = _widthTracksTextView | _heightTracksTextView;
  if (_textView == nil)
    return;

  if (_observingFrameChanges == old_observing)
    return;

  nc = [NSNotificationCenter defaultCenter];

  if (_observingFrameChanges)
    {      
      [_textView setPostsFrameChangedNotifications: YES];
      [nc addObserver: self
	  selector: @selector(_textViewFrameChanged:)
	  name: NSViewFrameDidChangeNotification
	  object: _textView];
    }
  else
    {
      [nc removeObserver: self name: NSViewFrameDidChangeNotification 
	  object: _textView];
    }
}

- (BOOL) heightTracksTextView
{
  return _heightTracksTextView;
}

- (void) setLineFragmentPadding: (float)aFloat
{
  _lineFragmentPadding = aFloat;

  if (_layoutManager)
    [_layoutManager textContainerChangedGeometry: self];
}

- (float) lineFragmentPadding
{
  return _lineFragmentPadding;
}

-(NSRect) lineFragmentRectForProposedRect: (NSRect)proposed
	sweepDirection: (NSLineSweepDirection)sweep
	movementDirection: (NSLineMovementDirection)move
	remainingRect: (NSRect *)remain
{
  float minx, maxx, miny, maxy;
  float cminx, cmaxx, cminy, cmaxy;

  minx = NSMinX(proposed);
  maxx = NSMaxX(proposed);
  miny = NSMinY(proposed);
  maxy = NSMaxY(proposed);

  cminx = NSMinX(_containerRect);
  cmaxx = NSMaxX(_containerRect);
  cminy = NSMinY(_containerRect);
  cmaxy = NSMaxY(_containerRect);

  *remain = NSZeroRect;

  if (minx >= cminx && maxx <= cmaxx &&
      miny >= cminy && maxy <= cmaxy)
    {
      return proposed;
    }

  switch (move)
    {
      case NSLineMoveLeft:
	if (maxx < cminx)
	  return NSZeroRect;
	if (maxx > cmaxx)
	  {
	    minx -= maxx-cmaxx;
	    maxx = cmaxx;
	  }
	break;

      case NSLineMoveRight:
	if (minx > cmaxx)
	  return NSZeroRect;
	if (minx < cminx)
	  {
	    maxx += cminx-minx;
	    minx = cminx;
	  }
	break;

      case NSLineMoveDown:
	if (miny > cmaxy)
	  return NSZeroRect;
	if (miny < cminy)
	  {
	    maxy += cminy - miny;
	    miny = cminy;
	  }
	break;

      case NSLineMoveUp:
	if (maxy < cminy)
	  return NSZeroRect;
	if (maxy > cmaxy)
	  {
	    miny -= maxy - cmaxy;
	    maxy = cmaxy;
	  }
	break;

      case NSLineDoesntMove:
	break;
    }

  switch (sweep)
    {
      case NSLineSweepLeft:
      case NSLineSweepRight:
	if (minx < cminx)
	  minx = cminx;
	if (maxx > cmaxx)
	  maxx = cmaxx;
	break;

      case NSLineSweepDown:
      case NSLineSweepUp:
	if (miny < cminy)
	  miny = cminy;
	if (maxy > cmaxy)
	  maxy = cmaxy;
	break;
    }

  if (minx < cminx || maxx > cmaxx ||
      miny < cminy || maxy > cmaxy)
    {
      return NSZeroRect;
    }

  return NSMakeRect(minx, miny, maxx - minx, maxy - miny);
}

- (BOOL) isSimpleRectangularTextContainer
{
  // sub-classes may say no; this class always says yes
  return YES;
}

- (BOOL) containsPoint: (NSPoint)aPoint
{
  return NSPointInRect (aPoint, _containerRect);
}

@end /* NSTextContainer */

