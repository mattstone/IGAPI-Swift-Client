//
//  MSIGBrokerIGMarginDepositBand.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGMarginDepositBand {
    open var currency = "" // The currency for this currency band factor calculation
    open var margin   = 0 as Double // Margin Percentage
    open var max      = 0 as Double // Band maximum
    open var min      = 0 as Double // Band minimum

    public init() {}
}
