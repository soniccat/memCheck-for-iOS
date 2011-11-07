//
//  NSMemCheckParser.h
//  News360Core
//
//  Created by ALEXEY GLUSHKOV on 31.10.11.
//  Copyright (c) 2011 News360. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NSMemCheckParseItem <NSObject>

//input - strings
//ouput - index of last parsed string + 1
- (NSInteger)parse:(NSArray*)strings;
- (BOOL)canParse:(NSArray*)strings;

@end

@protocol NSMemCheckParseArgument <NSMemCheckParseItem>

@property(nonatomic,readonly) NSArray* memCheckObjects;

@end

@protocol NSMemCheckParseFilter <NSMemCheckParseItem>

@property(nonatomic,retain) NSArray* inputMemCheckObjects;
@property(nonatomic,readonly) NSArray* outputMemCheckObjects;

@end

@protocol NSMemCheckParseCommand <NSMemCheckParseItem>

@property(nonatomic,retain) NSArray* inputMemCheckObjects;

- (void)run;

@end

@interface NSMemCheckParser : NSObject
{
    //parsers
    NSMutableArray* argumentParsers;
    NSMutableArray* filterParsers;
    NSMutableArray* commandParsers;
}

- (id)init;
- (void)parse:(NSString*)command;

+ (void)run:(NSString*)command;

@end
