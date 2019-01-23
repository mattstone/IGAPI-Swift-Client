//
//  MSIGBrokerIGPositionOrder.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 16/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGPositionOrderStopType : String {
    case NONE       = "None"
    case NORMAL     = "Normal"
    case GUARANTEED = "Guaranteed"
}

public enum MSIGBrokerIGPositionOrderType : String {
    case LIMIT  = "LIMIT"
    case STOP   = "STOP"
    case MARKET = "MARKET"
    case QUOTE  = "QUOTE"
}

public enum MSIGBrokerIGPositionDealingType : String {
    case otc            = "Over the Counter"
    case workingOrder   = "Working Order"
}

public enum MSIGBrokerIGPositionDealingTimeInForce : String {
    case NULL                      = "Null"
    case EXECUTE_AND_ELIMINATE     = "Execute and eliminate"
    case FILL_OR_KILL              = "Fill or kill"
    case GOOD_TILL_CANCELLED       = "Good Till Cancelled"
    case GOOD_TILL_DATE            = "Good Till Date"
}

open class MSIGBrokerIGPositionOrder {
    
    let includes       = MSIGBrokersIncludes.sharedInstance
    
    open var dealingType    = MSIGBrokerIGPositionDealingType.otc

    open var currencyCode   = ""
    open var direction      = MSIGBrokerIGPositionDirection.buy
    open var dma            = false
    open var epic           = ""
    open var expiry         = "-"
    open var forceOpen      = false
    
    open var goodTillDate    = ""
    open var goodTillDateISO = ""
    open var stopType       = MSIGBrokerIGPositionOrderStopType.NONE
    
    open var goodTillNSDate = Date()
    
    open var guaranteedStop = false
    open var level          = 0 as NSDecimalNumber
    open var limitDistance  = 0 as NSDecimalNumber
    open var limitLevel     = 0 as NSDecimalNumber
    open var type           = MSIGBrokerIGPositionOrderType.LIMIT
    open var quoteId        = ""
    open var size           = 0 as Double
    open var stopDistance   = 0 as NSDecimalNumber
    open var stopLevel      = 0 as NSDecimalNumber
    open var timeInForce    = MSIGBrokerIGPositionDealingTimeInForce.NULL
    open var trailingStop   = false
    open var trailingStopIncrement = 0 as NSDecimalNumber
    
    public init() {}
    
    open func isCreateValid() -> Bool {
        
        switch dealingType {
        case .otc:

//             constraints as per http://labs.ig.com/rest-trading-api-reference/service-detail?id=208
//            [Constraint: If guaranteedStop equals true, then set only one of stopLevel,stopDistance]
//            [Constraint: If orderType equals LIMIT,    then set level]
//            [Constraint: If orderType equals LIMIT,    then DO NOT set quoteId]
//            [Constraint: If orderType equals MARKET,   then DO NOT set level, quoteId]
//            [Constraint: If orderType equals QUOTE,    then set level,quoteId]
//            [Constraint: If trailingStop equals true,  then DO NOT set stopLevel]
//            [Constraint: If trailingStop equals true,  then set stopDistance,trailingStopIncrement]
//            [Constraint: If trailingStop equals false, then DO NOT set trailingStopIncrement]
//            [Constraint: Set only one of {limitLevel,limitDistance}]
//            [Constraint: Set only one of {stopLevel,stopDistance}]
            
            switch guaranteedStop {
            case true:
                
                if stopLevel.doubleValue > 0 && stopDistance.doubleValue > 0 { return false }
                if trailingStop                                              { return false }
            default:   break
            }
            
            switch type {
            case .LIMIT:
                if level.doubleValue == 0 { return false }
                if !quoteId.isEmpty       { return false }
                
                timeInForce = .FILL_OR_KILL
                
//            case .MARKET:
//                if level.doubleValue != 0 { return false }
//                if !quoteId.isEmpty       { return false }
                
            case .QUOTE: if level.doubleValue == 0 || quoteId.isEmpty { return false }
            default: break
            }
            
            switch trailingStop {
            case true:
                if guaranteedStop                         { return false }
                if stopLevel.doubleValue              > 0 { return false }
                if stopDistance.doubleValue          == 0 { return false }
                if trailingStopIncrement.doubleValue == 0 { return false }
                
            case false:
                if trailingStopIncrement.doubleValue  > 0 { return false }
            }
            
            if limitLevel.doubleValue > 0 && limitDistance.doubleValue > 0 { return false }
            if stopLevel.doubleValue  > 0 && stopDistance.doubleValue  > 0 { return false }
            
        case .workingOrder:
            
            switch type {
            case .LIMIT: return true
            case .STOP:  return true
            default:     return true
            }
            
        }
        
        return true
    }
    
    open func pointsForPrice(level : Double, price : Double) -> Double {
        let difference = abs(level - price)
        return difference * conversionScalar()
    }
    
    
    open func priceForPoints(level : Double, points : Double, isPointsGreaterThanPrice : Bool) -> Double {
        
        let convertedPoints = points / conversionScalar()
        var price : Double!
        if isPointsGreaterThanPrice { price = level + convertedPoints }
        else                        { price = level - convertedPoints }
        return price
    }
    
    func conversionScalar() -> Double {
        //includes.debugPrint(any: "THE CURRENCY CODE IS: \(currencyCode)")
        if currencyCode == "JPY" { return 100 }
        return 10000
    }
    
    open func createParams() -> Dictionary<String, Any> {
        var decimalPoints = 0 as Int16
        
        switch currencyCode.uppercased() {
//        case "JPY": decimalPoints = 4
        case "JPY": decimalPoints = 6
        default:    decimalPoints = 6
        }
        
        var params = Dictionary<String, Any>()
        
        params["currencyCode"] = currencyCode as Any?
        params["epic"]         = epic   as Any?
        params["size"]         = size   as Any?
        params["expiry"]       = expiry as Any?
        
        switch direction {
        case .buy:  params["direction"] = "BUY"  as Any?
        case .sell: params["direction"] = "SELL" as Any?
        }
        
//        params["type"] = type.rawValue  // Internal variable.. not an IG one..
        
        switch forceOpen {
        case true:  params["forceOpen"] = "true"  as Any?
        case false: params["forceOpen"] = "false" as Any?
        }
        
        // [Constraint: If guaranteedStop equals true, then set only one of stopLevel,stopDistance]
        // [Constraint: Set only one of {stopLevel,stopDistance}]
        includes.debugPrint(any: "BROKERS: POSITIONS CREATE: GUARANTEED STOP: \(guaranteedStop)")
        switch guaranteedStop {
        case true:  params["guaranteedStop"] = "true"  as Any?
        case false: params["guaranteedStop"] = "false" as Any?
        }
        
        if stopLevel.doubleValue > 0 {
            params["stopLevel"]    = stopLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
        } else if stopDistance.doubleValue > 0 {
            // MODIFIED
            includes.debugPrint(any: "BROKERS: POSITIONS CREATE: STOP DISTANCE: \(stopDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints)))")
            params["stopDistance"] = stopDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
        }
        
        switch dealingType {
        case .otc:
            
            // constraints as per http://labs.ig.com/rest-trading-api-reference/service-detail?id=208
            
            // [Constraint: If orderType equals LIMIT,    then set level]
            // [Constraint: If orderType equals LIMIT,    then DO NOT set quoteId]
            // [Constraint: If orderType equals MARKET,   then DO NOT set level, quoteId]
            // [Constraint: If orderType equals QUOTE,    then set level,quoteId]
            timeInForce = .NULL
            switch type {
            case .LIMIT:
                params["orderType"] = "LIMIT" as Any?
                params["level"]     = level.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
                
                timeInForce         = .FILL_OR_KILL
            case .MARKET:
                params["orderType"] = "MARKET" as Any?
            case .QUOTE:
                params["orderType"] = "QUOTE" as Any?
                params["quoteId"]   = quoteId as Any?
                params["level"]     = level.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            default: break
            }
            
            includes.debugPrint(any: "LIMIT LEVEL: \(limitLevel)")
            // [Constraint: Set only one of {limitLevel,limitDistance}]
            switch limitLevel.doubleValue > 0 {
            case true:  params["limitLevel"]     = limitLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false:
                switch limitDistance.doubleValue > 0 {
                case true:
                    includes.debugPrint(any: "BROKERS: POSITIONS CREATE: LIMIT DISTANCE: \(limitDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints)))")
                    params["limitDistance"]  = limitDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
                case false: break
                }
            }
            
            
            switch timeInForce {
            case .EXECUTE_AND_ELIMINATE: params["timeInForce"] = "EXECUTE_AND_ELIMINATE" as Any?
            case .FILL_OR_KILL:          params["timeInForce"] = "FILL_OR_KILL" as Any?
            default: break
            }
            
            // [Constraint: If trailingStop equals true,  then DO NOT set stopLevel]
            // [Constraint: If trailingStop equals true,  then set stopDistance,trailingStopIncrement]
            // [Constraint: If trailingStop equals false, then DO NOT set trailingStopIncrement]
            switch trailingStop {
            case true:
                params.removeValue(forKey: "stopLevel")
                params["trailingStop"]          = trailingStop as Any?
                
                var decimalPoints = 0 as Int16
                
                switch currencyCode.uppercased() {
//                case "JPY": decimalPoints = 4
                case "JPY": decimalPoints = 6
                default:    decimalPoints = 6
                }
                
                params["trailingStopIncrement"] = trailingStopIncrement.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false: break
            }
            
        case .workingOrder:
//            [Constraint: If guaranteedStop equals true, then set only one of stopDistance, stopLevel]
//            [Constraint: If timeInForce equals GOOD_TILL_DATE, then set goodTillDate]

            params["type"]   = type.rawValue as Any?
            params["level"]  = level.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            
            //.WORKING accepts either DISTANCE or LEVEL - (limitDistance preffered)
            switch limitDistance.doubleValue > 0 {
            case true:  params["limitDistance"]  = limitDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false:
                switch limitLevel.doubleValue > 0 {
                case true:  params["limitLevel"]     = limitLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
                case false: break
                }
            }
            
            //.WORKING accepts ONLY STOP DISTANCE
            if stopDistance.doubleValue > 0 {
                params["stopDistance"] = Int(stopDistance.int32Value) as Any?
            }

            switch timeInForce {
            case .GOOD_TILL_CANCELLED: params["timeInForce"] = "GOOD_TILL_CANCELLED" as Any?
            case .GOOD_TILL_DATE:
                params["timeInForce"]  = "GOOD_TILL_DATE" as Any?
                params["goodTillDate"] = goodTillDate as Any?
            default: break
            }
        }
        return params
    }
    
    open func updateParams() -> Dictionary<String, Any> {
        var params = Dictionary<String, Any>()
        
        var decimalPoints = 0 as Int16
        
        switch currencyCode.uppercased() {  // Settings for decimalNumberHandler
//        case "JPY": decimalPoints = 4
        case "JPY": decimalPoints = 6
        default:    decimalPoints = 6
        }
        
        switch dealingType {
        case .otc:
            
            switch trailingStop {
            case true:
                // [Constraint: If trailingStop equals true, then set trailingStopDistance,trailingStopIncrement,stopLevel]
                params["trailingStop"]          = "true" as Any?
                params["trailingStopDistance"]  = stopDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
                params["trailingStopIncrement"] = trailingStopIncrement.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false:
                // [Constraint: If trailingStop equals false, then DO NOT set trailingStopDistance,trailingStopIncrement]
                params["trailingStop"]          = "false" as Any?
            }
            
            if limitLevel.doubleValue > 0 {
                params["limitLevel"] = limitLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            }
            
            if stopLevel.doubleValue > 0 {
                params["stopLevel"] = stopLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            }
        case .workingOrder:
            
            params["level"]     = level
            params["type"]      = type.rawValue.uppercased() as Any?
            
//            switch guaranteedStop {
//            case true:  params["guaranteedStop"] = "true"
//            case false: params["guaranteedStop"] = "false"
//            }
            
            switch timeInForce {
            case .GOOD_TILL_CANCELLED:
                params["timeInForce"] = "GOOD_TILL_CANCELLED" as Any?
            case .GOOD_TILL_DATE:
                params["timeInForce"]  = "GOOD_TILL_DATE"
                params["goodTillDate"] = goodTillDate //formatDateForOrder(goodTillNSDate)
            default: break
            }
            
            switch limitDistance.doubleValue > 0 {
            case true:
                params["limitDistance"] = limitDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false: break
            }

            switch stopDistance.doubleValue > 0 {
            case true:
                params["stopDistance"] = stopDistance.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            case false: break
            }
            
            if stopLevel.doubleValue > 0 {
                params["stopLevel"] = stopLevel.rounding(accordingToBehavior: includes.decimalNumberHandler(decimalPoints))
            }
            
        }
        return params
    }
    
    open func toggleLimitLevelDistance(_ price : Double) {
        
        switch limitLevel.doubleValue > 0 {
        case true:
            limitDistance = NSDecimalNumber(value: abs(limitLevel.doubleValue - price) as Double)
            limitLevel    = 0
            
        case false:
            switch direction {
            case .buy:  limitLevel = NSDecimalNumber(value: price + limitDistance.doubleValue as Double)
            case .sell: limitLevel = NSDecimalNumber(value: price - limitDistance.doubleValue as Double)
            }
            
            limitDistance = 0
        }
        
    }
    
    // Note date should in UTC Time
    func formatDateForOrder(_ date : Date) -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.timeZone   = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    open func debug() {
        
        includes.debugPrint(any: "*** position.order.debug ***")
        includes.debugPrint(any: "dealingType: \(dealingType)")
        includes.debugPrint(any: "currencyCode: \(currencyCode)")
        includes.debugPrint(any: "direction: \(direction)")
        includes.debugPrint(any: "dma: \(dma)")
        includes.debugPrint(any: "epic: \(epic)")
        includes.debugPrint(any: "expiry: \(expiry)")
        includes.debugPrint(any: "forceOpen: \(forceOpen)")
        includes.debugPrint(any: "goodTillDate: \(goodTillDate)")
        includes.debugPrint(any: "goodTillDateISO: \(goodTillDateISO)")
        includes.debugPrint(any: "stopType: \(stopType)")
        includes.debugPrint(any: "goodTillNSDate: \(goodTillNSDate)")
        includes.debugPrint(any: "guaranteedStop: \(guaranteedStop)")
        includes.debugPrint(any: "level: \(level)")
        includes.debugPrint(any: "limitDistance: \(limitDistance)")
        includes.debugPrint(any: "limitLevel: \(limitLevel)")
        includes.debugPrint(any: "type: \(type)")
        includes.debugPrint(any: "quoteId: \(quoteId)")
        includes.debugPrint(any: "size: \(size)")
        includes.debugPrint(any: "stopDistance: \(stopDistance)")
        includes.debugPrint(any: "stopLevel: \(stopLevel)")
        includes.debugPrint(any: "timeInForce: \(timeInForce)")
        includes.debugPrint(any: "trailingStop: \(trailingStop)")
        includes.debugPrint(any: "****************************")
    }
}

