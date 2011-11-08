//
//  NSMemCheckParser.m
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 31.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import "NSMemCheckParser.h"

#import "NSMemArgAll.h"
#import "NSMemArgDead.h"
#import "NSMemArgHeap.h"
#import "NSMemArgLeaks.h"

#import "NSMemFilterHeap.h"
#import "NSMemFilterWithLiveOwners.h"
#import "NSMemFilterWithoutLiveOwners.h"
#import "NSMemFilterWithoutOwners.h"
#import "NSMemFilterWithOwners.h"
#import "NSMemFilterWithOwnersLessThan.h"
#import "NSMemFilterWithout.h"

#import "NSMemCommandPrint.h"
#import "NSMemCommandMarkHeap.h"
#import "NSMemCommandMarkHeapWithName.h"
#import "NSMemCommandSaveGraph.h"
#import "NSMemCommandShowHeaps.h"

NSMemCheckParser* parser;

@interface NSMemCheckParser ()

@property(nonatomic,retain) NSMutableArray* arguments;
@property(nonatomic,retain) NSMutableArray* filters;
@property(nonatomic,retain) NSMutableArray* commands;

@end

@implementation NSMemCheckParser

@synthesize arguments;
@synthesize filters;
@synthesize commands;

- (id)init
{
    self = [super init];
    if(self)
    {
        self.arguments = [NSMutableArray arrayWithObjects: [[[NSMemArgAll alloc] init] autorelease],
                          [[[NSMemArgDead alloc] init] autorelease],
                          [[[NSMemArgHeap alloc] init] autorelease],
                          [[[NSMemArgLeaks alloc] init] autorelease],nil];
        
        self.filters = [NSMutableArray arrayWithObjects: [[[NSMemFilterHeap alloc] init] autorelease],
                        [[[NSMemFilterWithLiveOwners alloc] init] autorelease],
                        [[[NSMemFilterWithoutLiveOwners alloc] init] autorelease],
                        [[[NSMemFilterWithoutOwners alloc] init] autorelease],
                        [[[NSMemFilterWithOwners alloc] init] autorelease],
                        [[[NSMemFilterWithOwnersLessThan alloc] init] autorelease],
                        [[[NSMemFilterWithout alloc] init] autorelease],nil];
        
        self.commands = [NSMutableArray arrayWithObjects: [[[NSMemCommandPrint alloc] init] autorelease],
                         [[[NSMemCommandMarkHeap alloc] init] autorelease],
                         [[[NSMemCommandMarkHeapWithName alloc] init] autorelease],
                         [[[NSMemCommandSaveGraph alloc] init] autorelease],
                         [[[NSMemCommandShowHeaps alloc] init] autorelease],nil];
        
    }
    
    return self;
}

- (void)dealloc
{
    self.arguments = nil;
    self.filters = nil;
    self.commands = nil;
    
    [super dealloc];
}

- (void)run:(NSString*)command
{
    [parser performSelector:@selector(parse:) withObject:command afterDelay:1];
}

- (NSMutableArray*)wordsFromCommand:(NSString*)command
{
    NSMutableArray* strings = [NSMutableArray array];
    
    //divide string on words where word is set of characters without spaces or string with \" at start and end
    //Expamle: abc def "rty ugf"
    NSInteger stringPos = 0;
    while( stringPos < [command length] )
    {
        if( [command characterAtIndex:stringPos] == ' ' )
            stringPos++;
        
        else if( [command characterAtIndex:stringPos] == '"')
        {
            NSInteger endPos = [command rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] options:0 range:NSMakeRange(stringPos+1, [command length]-stringPos-1)].location;
            
            if(endPos == NSNotFound)
            {
                NSLog(@"Error: end of string isn't found %@", command);
                return nil;
            }else
                endPos +=  1;
            
            NSString* word = [command substringWithRange:NSMakeRange(stringPos+1, endPos - stringPos-2)];
            [strings addObject: word ];
            
            stringPos = endPos;
            
            //read word
        }else
        {
            NSInteger endPos = [command rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "] options:0 range:NSMakeRange(stringPos+1, [command length]-stringPos-1)].location;
            
            if(endPos == NSNotFound)
                endPos = [command length];
            
            NSString* word = [command substringWithRange:NSMakeRange(stringPos, endPos - stringPos)];
            [strings addObject: word ];
            
            stringPos = endPos;
        }
    }
    
    return strings;
}

- (void)parse:(NSString*)command
{
    @try
    {
    
    NSMutableArray* strings = [self wordsFromCommand:command];
    if(!strings)
        return;
        
    NSInteger startIndex = 0;
    NSArray* memObjects = nil;
    
    //detect input array
    for( id<NSMemCheckParseArgument> argument in self.arguments )
    {
        if( [argument canParse:strings] )
        {
            startIndex = [argument parse:strings];
            memObjects = argument.memCheckObjects;
            
            [strings removeObjectsInRange:NSMakeRange(0, startIndex)];
            break;
        }
    }
    
    //use filters
    BOOL canParse = YES;
    
    if(memObjects)
    while(canParse)
    {
        canParse = NO;
        for( id<NSMemCheckParseFilter> filter in self.filters )
        {
            if( [filter canParse:strings] )
            {
                filter.inputMemCheckObjects = memObjects;
                startIndex = [filter parse:strings];
                memObjects = filter.outputMemCheckObjects;
                
                [strings removeObjectsInRange:NSMakeRange(0, startIndex)];
                canParse = YES;
            }
        }
    }
    
    //run commands
    canParse = YES;
    while(canParse)
    {
        canParse = NO;
        for( id<NSMemCheckParseCommand> command in self.commands )
        {
            if( [command canParse:strings] )
            {
                command.inputMemCheckObjects = memObjects;
                startIndex = [command parse:strings];
                [command run];
                
                [strings removeObjectsInRange:NSMakeRange(0, startIndex)];
                canParse = YES;
            }
        }
    }
        
    if( [strings count] )
    {
        NSMutableString* str = [NSMutableString string];
        
        for(NSString* a in strings)
        {
            [str appendString:a];
            [str appendString:@" "];
        }
        
        NSLog(@"Warning: parsing was stopped at %@", str);
    
    }else
        NSLog(@"parse is finised");
        
    }@catch (NSException* ex) 
    {
        NSLog(@"Exception: %@",[ex description]);
    }
    
}

@end
