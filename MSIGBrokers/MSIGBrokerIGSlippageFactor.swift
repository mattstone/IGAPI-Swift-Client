//
//  MSIGBrokerIGSlippageFactor.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGSlippageFactorUnit : String {
    case PERCENT = "Percent"
    case POINT   = "Point"
}

open class MSIGBrokerIGSlippageFactor {
    open var unit  = MSIGBrokerIGSlippageFactorUnit.PERCENT
    open var value = 0 as Double
    
    public init() {}
    
    open func display() -> String {
        switch unit {
        case .POINT:   return "\(value) pts"
        case .PERCENT: return "\(value) %"
        }
    }
}
