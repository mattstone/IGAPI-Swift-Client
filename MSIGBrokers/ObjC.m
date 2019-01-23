//
//  ObjC.m
//  MSIGBrokers
//
//  Created by Matt Stone on 29/07/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//
#import "ObjC.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
    }
}

@end
