//
//  MSIGBrokerIGCurrency.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGCurrency {
    open var code             = ""
    open var symbol           = ""
    open var baseExchangeRate = 0 as NSDecimalNumber
    open var exchangeRate     = 0 as NSDecimalNumber
    open var isDefault        = false
    
    public init() {}
}

