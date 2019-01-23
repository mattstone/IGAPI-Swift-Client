//
//  MSIGBrokerIGClientApplication.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 20/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGClientApplicationStatus {
    case disabled
    case enabled
    case revoked
}

open class MSIGBrokerIGClientApplication {
    open var allowEquities                  = false
    open var allowQuoteOrders               = false
    open var allowanceAccountHistoricalData = 0 as Double
    open var allowanceAccountOverall        = 0 as Double
    open var allowanceAccountTrading        = 0 as Double
    open var allowanceApplicationOverall    = 0 as Double
    open var apiKey                         = ""
    open var concurrentSubscriptionsLimit   = 0 as Double
    open var createdDate                    = ""
    open var name                           = ""
    open var status                         = MSIGBrokerIGClientApplicationStatus.disabled
    
    public init() {}    
}
