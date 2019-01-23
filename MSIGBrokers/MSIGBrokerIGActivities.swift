//
//  MSIGBrokerIGActivities.swift
//  MSIGBrokers
//
//  Created by Matt Stone on 5/09/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGActivitiesMeta {
    open var next = ""
    open var size = 0 as Int
}


open class MSIGBrokerIGActivities {
    
    open var meta       = MSIGBrokerIGActivitiesMeta()
    open var activities = [MSIGBrokerIGActivity]()
    
}
