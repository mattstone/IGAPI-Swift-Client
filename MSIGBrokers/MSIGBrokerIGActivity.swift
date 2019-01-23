//
//  MSIGBrokerIGActivity.swift
//  MSIGBrokers
//
//  Created by Matt Stone on 5/09/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGActivityChannel {
    case dealer
    case mobile
    case public_FIX_API
    case public_WEB_API
    case system
    case web
}

public enum MSIGBrokerIGActivityActionType {
    case limit_ORDER_AMENDED
    case limit_ORDER_DELETED
    case limit_ORDER_FILLED
    case limit_ORDER_OPENED
    case limit_ORDER_ROLLED
    case position_CLOSED
    case position_DELETED
    case position_OPENED
    case position_PARTIALLY_CLOSED
    case position_ROLLED
    case stop_LIMIT_AMENDED
    case stop_ORDER_AMENDED
    case stop_ORDER_DELETED
    case stop_ORDER_FILLED
    case stop_ORDER_OPENED
    case stop_ORDER_ROLLED
    case unknown
    case working_ORDER_DELETED
}

public enum MSIGBrokerIGActivityStatus {
    case accepted
    case rejected
    case unknown
}

public enum MSIGBrokerIGActivityType {
    case edit_STOP_AND_LIMIT
    case position
    case system
    case working_ORDER
}


open class MSIGBrokerIGActivityAction {
    open var actionType     = MSIGBrokerIGActivityActionType.unknown
    open var affectedDealId = ""
}

open class MSIGBrokerIGActivityDetails {
    open var actions        = [MSIGBrokerIGActivityAction]()
    open var currency       = ""
    open var dealReference  = ""
    open var direction      = MSIGBrokerIGPositionDirection.buy
    open var goodTillDate   = ""
    open var guaranteedStop = false
    open var level          = 0 as NSDecimalNumber
    open var limitDistance  = 0 as NSDecimalNumber
    open var limitLevel     = 0 as NSDecimalNumber
    open var marketName     = ""
    open var size           = 0 as Double
    open var stopDistance   = 0 as NSDecimalNumber
    open var stopLevel      = 0 as NSDecimalNumber
    open var trailingStep   = 0 as NSDecimalNumber
    open var trailingStopDistance = 0 as NSDecimalNumber
}


open class MSIGBrokerIGActivity {
    
    open var channel     = MSIGBrokerIGActivityChannel.public_WEB_API
    open var date        = ""
    open var dealId      = ""
    open var description = ""
    open var details     = [MSIGBrokerIGActivityDetails]()
    open var epic        = ""
    open var period      = ""
    open var status      = MSIGBrokerIGActivityStatus.unknown
    open var type        = MSIGBrokerIGActivityType.system
    
    
}
