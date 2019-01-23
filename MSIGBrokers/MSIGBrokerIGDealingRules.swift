//
//  MSIGBrokerIGDealingRules.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGDealingRuleUnit : String {
    case NONE       = "None"
    case PERCENTAGE = "Percentage"
    case POINTS     = "Points"
}

open class MSIGBrokerIGDealingRule {
    open var unit  = MSIGBrokerIGDealingRuleUnit.POINTS
    open var value = 0 as Double
    
    open func description() -> String {
        switch unit {
        case .POINTS:     return "\(value.cleanValue) pts"
        case .PERCENTAGE: return "\(value.cleanValue) %"
        case .NONE: return ""
        }
    }
    
    open func value(_ faceValue : Double) -> Double {
        switch unit {
        case .POINTS:     return value
        case .PERCENTAGE: return faceValue / value
        case .NONE: return 0
        }
    }
}

public enum MSIGBrokerIGDealingRulesMarketOrderPreference : String {
    case AVAILABLE_DEFAULT_OFF = "Available default off" //Market orders are allowed for the account type and instrument, and the user has enabled market orders in their preferences but decided the default state is off.
    case AVAILABLE_DEFAULT_ON  = "Available default on"	//Market orders are allowed for the account type and instrument, and the user has enabled market orders in their preferences and has decided the default state is on.
    case NOT_AVAILABLE	       = "Not available" //Market orders are not allowed for the current site and/or instrument
}

public enum MSIGBrokerIGDealingRulesTrailingStopsPreference : String {
    case AVAILABLE     = "Available"
    case NOT_AVAILABLE = "Not available"
}

open class MSIGBrokerIGDealingRules  {
    open var marketOrderPreference         = MSIGBrokerIGDealingRulesMarketOrderPreference.NOT_AVAILABLE
    open var maxStopOrLimitDistance        = MSIGBrokerIGDealingRule()
    open var minControlledRiskStopDistance = MSIGBrokerIGDealingRule()
    open var minDealSize                   = MSIGBrokerIGDealingRule()
    open var minNormalStopOrLimitDistance  = MSIGBrokerIGDealingRule()
    open var minStepDistance               = MSIGBrokerIGDealingRule()
    open var trailingStopsPreference       = MSIGBrokerIGDealingRulesTrailingStopsPreference.NOT_AVAILABLE
    
    public init() {}
}
