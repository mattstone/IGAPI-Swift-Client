//
//  ObjC.h
//  MSIGBrokers
//
//  Created by Matt Stone on 29/07/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end
