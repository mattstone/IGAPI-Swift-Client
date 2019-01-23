//
//  MSIGBrokerIGHistory.swift
//  MSIGBrokers
//
//  Created by Matt Stone on 19/05/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGHistoryActionStatus : String {
    case ACCEPT
    case REJECT
    case MANUAL
    case NOT_SET
}

open class MSIGBrokerIGHistory {

    open var actionStatus      = MSIGBrokerIGHistoryActionStatus.NOT_SET
    open var activity          = ""
    open var activityHistoryId = ""
    open var channel           = ""
    open var currency          = ""
    open var dealId            = ""
    open var date              = ""
    open var epic              = ""
    open var level             = ""
    open var limit             = ""
    open var marketName        = ""
    open var period            = ""
    open var result            = ""
    open var size              = ""
    open var stop              = ""
    open var stopType          = ""

    public init() {}
}
