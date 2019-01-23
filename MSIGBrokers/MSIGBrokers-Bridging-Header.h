//
//  MSIGBroker-Bridging-header.h
//  MSIGBrokers
//
//  Created by Matt Stone on 2/04/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

#ifndef MSIGBroker_Bridging_header_h
#define MSIGBroker_Bridging_header_h


#endif /* MSIGBroker_Bridging_header_h */

//#import "LightstreamerClient.h"
//#import "Lightstreamer_IOS_Client.h"
#import <Lightstreamer_iOS_Client/Lightstreamer_iOS_Client.h>


/*
 
 Note: Lightstreamer throws Obj C style NSException - which causes Swift to crash.
 
 ObjC captures these and stops them from crashing Lightstreamer.. :-(
 
*/

#import "ObjC.h"

