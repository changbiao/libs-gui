/** <title>NSTabView</title>

   <abstract>The tabular view class</abstract>

   Copyright (C) 1999,2000 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSForm.h"
#include "AppKit/NSMatrix.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSTabView.h"
#include "AppKit/NSTabViewItem.h"
#include "AppKit/PSOperators.h"

@implementation NSTabView

- (id) initWithFrame: (NSRect)rect
{
  [super initWithFrame: rect];

  // setup variables  

  ASSIGN (_items, [NSMutableArray array]);
  ASSIGN (_font, [NSFont systemFontOfSize: 0]);
  _selected = nil;

  return self;
}

- (void) dealloc
{
  RELEASE(_items);
  RELEASE(_font);
  [super dealloc];
}

// tab management.

- (void) addTabViewItem: (NSTabViewItem*)tabViewItem
{
  [self insertTabViewItem: tabViewItem atIndex: [_items count]];
}

- (void) insertTabViewItem: (NSTabViewItem*)tabViewItem
		   atIndex: (int)index
{
  [tabViewItem _setTabView: self];
  [_items insertObject: tabViewItem atIndex: index];

  if ([_delegate respondsToSelector: 
    @selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [_delegate tabViewDidChangeNumberOfTabViewItems: self];
    }
}

- (void) removeTabViewItem: (NSTabViewItem*)tabViewItem
{
  unsigned i = [_items indexOfObject: tabViewItem];
  
  if (i == NSNotFound)
    return;

  if ([tabViewItem isEqual: _selected])
    {
      _selected = nil;
    }

  [_items removeObjectAtIndex: i];

  if ([_delegate respondsToSelector: 
    @selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [_delegate tabViewDidChangeNumberOfTabViewItems: self];
    }
}

- (int) indexOfTabViewItem: (NSTabViewItem*)tabViewItem
{
  return [_items indexOfObject: tabViewItem];
}

- (int) indexOfTabViewItemWithIdentifier: (id)identifier
{
  unsigned	howMany = [_items count];
  unsigned	i;

  for (i = 0; i < howMany; i++)
    {
      id anItem = [_items objectAtIndex: i];

      if ([[anItem identifier] isEqual: identifier])
        return i;
    }

  return NSNotFound;
}

- (int) numberOfTabViewItems
{
  return [_items count];
}

- (NSTabViewItem*) tabViewItemAtIndex: (int)index
{
  return [_items objectAtIndex: index];
}

- (NSArray*) tabViewItems
{
  return (NSArray*)_items;
}

- (void) selectFirstTabViewItem: (id)sender
{
  [self selectTabViewItemAtIndex: 0];
}

- (void) selectLastTabViewItem: (id)sender
{
  [self selectTabViewItem: [_items lastObject]];
}

- (void) selectNextTabViewItem: (id)sender
{
  if ((unsigned)(_selected_item + 1) < [_items count])
    [self selectTabViewItemAtIndex: _selected_item+1];
}

- (void) selectPreviousTabViewItem: (id)sender
{
  if (_selected_item > 0)
    [self selectTabViewItemAtIndex: _selected_item-1];
}

- (NSTabViewItem*) selectedTabViewItem
{
  if (_selected_item == NSNotFound || [_items count] == 0)
    return nil;
  return [_items objectAtIndex: _selected_item];
}

- (void) selectTabViewItem: (NSTabViewItem*)tabViewItem
{
  BOOL canSelect = YES;

  if ([_delegate respondsToSelector: 
    @selector(tabView: shouldSelectTabViewItem:)])
    {
      canSelect = [_delegate tabView: self
		shouldSelectTabViewItem: tabViewItem];
    }

  if (canSelect)
    {
      NSView *selectedView;

      if (_selected != nil)
        {
          [_selected _setTabState: NSBackgroundTab];

	  /* NB: If [_selected view] is nil this does nothing, which
             is fine.  */
	  [[_selected view] removeFromSuperview];
	}

      _selected = tabViewItem;

      if ([_delegate respondsToSelector: 
	@selector(tabView: willSelectTabViewItem:)])
	{
	  [_delegate tabView: self willSelectTabViewItem: _selected];
	}

      _selected_item = [_items indexOfObject: _selected];
      [_selected _setTabState: NSSelectedTab];

      selectedView = [_selected view];

      if (selectedView != nil)
	{
	  [self addSubview: selectedView];
	  [selectedView setFrame: [self contentRect]];
	  [_window makeFirstResponder: [_selected initialFirstResponder]];
	}
      
      /* FIXME - only mark the contentRect as needing redisplay! */
      [self setNeedsDisplay: YES];
      
      if ([_delegate respondsToSelector: 
	@selector(tabView: didSelectTabViewItem:)])
	{
	  [_delegate tabView: self didSelectTabViewItem: _selected];
	}
    }
}

- (void) selectTabViewItemAtIndex: (int)index
{
  if (index < 0)
    [self selectTabViewItem: nil];
  else
    [self selectTabViewItem: [_items objectAtIndex: index]];
}

- (void) selectTabViewItemWithIdentifier:(id)identifier 
{
  int index = [self indexOfTabViewItemWithIdentifier: identifier];
  [self selectTabViewItemAtIndex: index];
}

- (void) takeSelectedTabViewItemFromSender: (id)sender
{
  int	index = -1;

  if ([sender respondsToSelector: @selector(indexOfSelectedItem)] == YES)
    {
      index = [sender indexOfSelectedItem];
    }
  else if ([sender isKindOfClass: [NSMatrix class]] == YES)
    {
      int	cols = [sender numberOfColumns];
      int	row = [sender selectedRow];
      int	col = [sender selectedColumn];

      if (row >= 0 && col >= 0)
	{
	  index = row * cols + col;
	}
    }
  [self selectTabViewItemAtIndex: index];
}

- (void) setFont: (NSFont*)font
{
  ASSIGN(_font, font);
}

- (NSFont*) font
{
  return _font;
}

- (void) setTabViewType: (NSTabViewType)tabViewType
{
  _type = tabViewType;
}

- (NSTabViewType) tabViewType
{
  return _type;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _draws_background = flag;
}

- (BOOL) drawsBackground
{
  return _draws_background;
}

- (void) setAllowsTruncatedLabels: (BOOL)allowTruncatedLabels
{
  _truncated_label = allowTruncatedLabels;
}

- (BOOL) allowsTruncatedLabels
{
  return _truncated_label;
}

- (void) setDelegate: (id)anObject
{
  _delegate = anObject;
}

- (id) delegate
{
  return _delegate;
}

// content and size

- (NSSize) minimumSize
{
  return NSZeroSize;
}

- (NSRect) contentRect
{
  NSRect cRect = _bounds;

  if (_type == NSTopTabsBezelBorder)
    {
      cRect.origin.y += 1; 
      cRect.origin.x += 0.5; 
      cRect.size.width -= 2;
      cRect.size.height -= 18.5;
    }
  
  if (_type == NSNoTabsBezelBorder)
    {
      cRect.origin.y += 1; 
      cRect.origin.x += 0.5; 
      cRect.size.width -= 2;
      cRect.size.height -= 2;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      cRect.size.height -= 8;
      cRect.origin.y = 8;
    }

  return cRect;
}

// Drawing.

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  float			borderThickness;
  int			howMany = [_items count];
  int			i;
  NSRect		previousRect;
  int			previousState = 0;
  NSRect		aRect = _bounds;

  DPSgsave(ctxt);

  switch (_type)
    {
      default:
      case NSTopTabsBezelBorder: 
	aRect.size.height -= 16;
	NSDrawButton(aRect, NSZeroRect);
	borderThickness = 2;
	break;

      case NSBottomTabsBezelBorder: 
	aRect.size.height -= 16;
	aRect.origin.y += 16;
	NSDrawButton(aRect, rect);
	aRect.origin.y -= 16;
	borderThickness = 2;
	break;

      case NSNoTabsBezelBorder: 
	NSDrawButton(aRect, rect);
	borderThickness = 2;
	break;

      case NSNoTabsLineBorder: 
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(aRect);
	borderThickness = 1;
	break;

      case NSNoTabsNoBorder: 
	borderThickness = 0;
	break;
    }

  if (!_selected)
    [self selectFirstTabViewItem: nil];

  if (_type == NSNoTabsBezelBorder || _type == NSNoTabsLineBorder)
    {
      DPSgrestore(ctxt);
      return;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize	s;
	  NSRect	r;
	  NSPoint	iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState	itemState;

	  itemState = [anItem tabState];

	  s = [anItem sizeOfLabel: NO];

	  if (i == 0)
	    {
	      int iFlex = 0;
	      iP.x = aRect.origin.x;
	      iP.y = aRect.origin.y;

	      if (itemState == NSSelectedTab)
		{
		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		  iFlex = 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownUnSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = aRect.origin.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt,1);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y-1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];

	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      int	iFlex = 0;

	      iP.x = previousRect.origin.x + previousRect.size.width;
	      iP.y = aRect.origin.y;

	      if (itemState == NSSelectedTab) 
		{
		  iP.y += 1;
		  iFlex = 1;
		  [[NSImage imageNamed:
		    @"common_TabDownUnSelectedToSelectedJunction.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y += 1;
		      [[NSImage imageNamed:
			@"common_TabDownSelectedToUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y -= 1;
		      iFlex = -1;
		    }
		  else
		    {
		      //		    iP.y += 1;
		      [[NSImage imageNamed:
			@"common_TabDownUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      //iP.y -= 1;
		      iFlex = -1;
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	      
	      r.origin.x = iP.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex; // was 15

	      iFlex = 0;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt,1);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y - 1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      iP.x += s.width + 13;

	      if ([anItem tabState] == NSSelectedTab)
		[[NSImage imageNamed: @"common_TabDownSelectedRight.tiff"]
		  compositeToPoint: iP operation: NSCompositeSourceOver];
	      else if ([anItem tabState] == NSBackgroundTab)
		{
		  //		  iP.y += 1;
		  [[NSImage imageNamed: @"common_TabDownUnSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  //		  iP.y -= 1;
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }
  else if (_type == NSTopTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize s;
	  NSRect r;
	  NSPoint iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState itemState;
	  
	  itemState = [anItem tabState];
	  
	  s = [anItem sizeOfLabel: NO];
	  
	  if (i == 0)
	    {
	      iP.x = aRect.origin.x;
	      iP.y = aRect.size.height;
	      
	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
		  [[NSImage imageNamed: @"common_TabSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else if (itemState == NSBackgroundTab)
		[[NSImage imageNamed: @"common_TabUnSelectedLeft.tiff"]
		  compositeToPoint: iP operation: NSCompositeSourceOver];
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = aRect.origin.x + 13;
	      r.origin.y = aRect.size.height;
	      r.size.width = s.width;
	      r.size.height = 15;
	      
	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt,1);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      iP.x = previousRect.origin.x + previousRect.size.width;
	      iP.y = aRect.size.height;

	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
		  [[NSImage imageNamed:
		    @"common_TabUnSelectToSelectedJunction.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y -= 1;
		      [[NSImage imageNamed:
			@"common_TabSelectedToUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y += 1;
		    }
		  else
		    {
		      [[NSImage imageNamed:
			@"common_TabUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = iP.x + 13;
	      r.origin.y = aRect.size.height;
	      r.size.width = s.width;
	      r.size.height = 15;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt,1);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      iP.x += s.width + 13;
	    
	      if ([anItem tabState] == NSSelectedTab)
		[[NSImage imageNamed: @"common_TabSelectedRight.tiff"]
		compositeToPoint: iP operation: NSCompositeSourceOver];
	      else if ([anItem tabState] == NSBackgroundTab)
		[[NSImage imageNamed: @"common_TabUnSelectedRight.tiff"]
		compositeToPoint: iP operation: NSCompositeSourceOver];
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }

  DPSgrestore(ctxt);
}

- (BOOL) isOpaque
{
  return NO;
}

// Event handling.

- (NSTabViewItem*) tabViewItemAtPoint: (NSPoint)point
{
  int		howMany = [_items count];
  int		i;

  point = [self convertPoint: point fromView: nil];

  for (i = 0; i < howMany; i++)
    {
      NSTabViewItem *anItem = [_items objectAtIndex: i];

      if(NSPointInRect(point,[anItem _tabRect]))
	return anItem;
    }

  return nil;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTabViewItem *anItem = [self tabViewItemAtPoint: location];
  
  if (anItem != nil  &&  ![anItem isEqual: _selected])
    {
      [self selectTabViewItem: anItem];
    }
}


- (NSControlSize) controlSize
{
  // FIXME
  return NSRegularControlSize;
}

/**
 * Not implemented.
 */
- (void) setControlSize: (NSControlSize)controlSize
{
  // FIXME 
}

- (NSControlTint) controlTint
{
  // FIXME
  return NSDefaultControlTint;
}

/**
 * Not implemented.
 */
- (void) setControlTint: (NSControlTint)controlTint
{
  // FIXME 
}

// Coding.

- (void) encodeWithCoder: (NSCoder*)aCoder
{ 
  [super encodeWithCoder: aCoder];
           
  [aCoder encodeObject: _items];
  [aCoder encodeObject: _font];
  [aCoder encodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeValueOfObjCType: "i" at: &_selected_item];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_items];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_font];
  [aDecoder decodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
  _delegate = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: "i" at: &_selected_item];
  _selected = [_items objectAtIndex: _selected_item];

  return self;
}
@end
