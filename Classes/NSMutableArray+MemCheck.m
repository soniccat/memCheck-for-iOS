//
//  NSMutableArray+MemCheck.m
//  inFoundation
//
//  Created by Alexey Glushkov on 20.02.11.
//  Copyright 2011 Mobile Platforms. All rights reserved.
//

#ifdef MEMTEST_ON

#import "NSMutableArray+MemCheck.h"

@implementation NSMutableArray(MemCheck)

- (NSMemCheckObject*) memCheckObjectByPointer:(id)obj
{
	for(NSMemCheckObject* item in self)
		if( item.pointerValue == obj )
			return item;
	
	return nil;
}

- (NSString*) allMem
{
	return [NSString stringWithFormat:@"%d items\n%@", [self count], [self description]];
}

- (NSString*) top:(NSInteger)top
{
	NSInteger count = top;
	if( count > [self count] )
		count = [self count];
	
	NSMutableString* outString = [NSMutableString stringWithFormat:@"%d items\n",[self count]];
	for (int i=0;i<count;++i) 
		[outString appendFormat:@"%@\n",[[self objectAtIndex:i] description]];
	
	return outString;
}

@end

#endif
