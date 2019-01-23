//
//  MSIGBrokerIGPosition.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 16/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

/*
 
Note:
 
1. Position reflects existing position
2. Position.order reflects create, update request
 
*/


import Foundation

public enum MSIGBrokerIGPositionDirection : String {
    case buy  = "Buy"
    case sell = "Sell"
}

public enum MSIGBrokerIGPositionDealStatus : String {
    case ACCEPTED     =	"Accepted"
    case FUND_ACCOUNT = "Account requires funding"
    case REJECTED     = "Rejected"
}

public enum MSIGBrokerIGPositionAffectedDealsStatus : String {
    case AMENDED          = "Amended"
    case DELETED          = "Deleted"
    case FULLY_CLOSED     = "Fully closed"
    case OPENED           = "Opened"
    case PARTIALLY_CLOSED = "Partially closed"
}

public enum MSIGBrokerIGPositionStatus : String {
    case AMENDED      = "Amended"
    case CLOSED	      = "Closed"
    case FULLY_CLOSED = "Fully Closed"
    case DELETED      = "Deleted"
    case OPEN	      = "Open"
    case PARTIALLY_CLOSED = "Partially Closed"
    case UNKNOWN      = "Unknown"
}

public enum MSIGBrokerIGPositionReason : String {
    case ACCOUNT_NOT_ENABLED_TO_TRADING	              = "Account not enabled for Trading"
    case ATTACHED_ORDER_LEVEL_ERROR	= "Attached order level error"
    case ATTACHED_ORDER_TRAILING_STOP_ERROR	          = "Attached order trailing stop error"
    case CANNOT_CHANGE_STOP_TYPE	= "Cannot change Stop type"
    case CANNOT_REMOVE_STOP	        = "Cannot remove Stop"
    case CLOSING_ONLY_TRADES_ACCEPTED_ON_THIS_MARKET  = "Closing only trades accepted on this market"
    case CONFLICTING_ORDER	        = "Conflicting order"
    case CR_SPACING	                = "CR Spacing"
    case DUPLICATE_ORDER_ERROR	    = "Duplicate order error"
    case EXCHANGE_MANUAL_OVERRIDE	= "Exchange manual override"
    case FINANCE_REPEAT_DEALING	    = "Finance repeat dealing"
    case FORCE_OPEN_ON_SAME_MARKET_DIFFERENT_CURRENCY = "Force open on same market, different currency"
    case GENERAL_ERROR	            = "General error"
    case GOOD_TILL_DATE_IN_THE_PAST	= "Good til date in the past"
    case INSTRUMENT_NOT_FOUND	    = "Instrument not found"
    case INSUFFICIENT_FUNDS	        = "Insufficient funds"
    case LEVEL_TOLERANCE_ERROR	    = "Level tolerance error"
    case MANUAL_ORDER_TIMEOUT	    = "Manual order timeout"
    case MARKET_CLOSED	            = "Market closed"
    case MARKET_CLOSED_WITH_EDITS	= "Market closed with edits"
    case MARKET_CLOSING	            = "Market closing"
    case MARKET_NOT_BORROWABLE	    = "Market not borrowable"
    case MARKET_OFFLINE	            = "Market offline"
    case MARKET_PHONE_ONLY	        = "Market phone only"
    case MARKET_ROLLED	            = "Market rolled"
    case MARKET_UNAVAILABLE_TO_CLIENT	         = "Market unavailable to client"
    case MAX_AUTO_SIZE_EXCEEDED	    = "Max auto size exceeded"
    case MINIMUM_ORDER_SIZE_ERROR	= "Minimum order size error"
    case MOVE_AWAY_ONLY_LIMIT	    = "Move away only limit"
    case MOVE_AWAY_ONLY_STOP	    = "Move away only stop"
    case MOVE_AWAY_ONLY_TRIGGER_LEVEL	         = "Move away only trigger lever"
    case OPPOSING_DIRECTION_ORDERS_NOT_ALLOWED	 = "Opposing direction orders not allowed"
    case OPPOSING_POSITIONS_NOT_ALLOWED	         = "Opposing positions not allowed"
    case ORDER_LOCKED	            = "Order locked"
    case ORDER_NOT_FOUND	        = "Order not found"
    case OVER_NORMAL_MARKET_SIZE	= "Over normal market size"
    case PARTIALY_CLOSED_POSITION_NOT_DELETED	 = "Partially closed position not deleted"
    case POSITION_NOT_AVAILABLE_TO_CLOSE	     = "Position not available to close"
    case POSITION_NOT_FOUND	        = "Position not found"
    case REJECT_SPREADBET_ORDER_ON_CFD_ACCOUNT	 = "Reject spreadbet order on CFD account"
    case SIZE_INCREMENT         	= "Size increment"
    case SPRINT_MARKET_EXPIRY_AFTER_MARKET_CLOSE = "Sprint market expiry after market close"
    case STOP_OR_LIMIT_NOT_ALLOWED	= "Stop or limit not allowed"
    case STOP_REQUIRED_ERROR	    = "Stop required error"
    case STRIKE_LEVEL_TOLERANCE	    = "Strike level tolerance"
    case SUCCESS	                = "Success"
    case TRAILING_STOP_NOT_ALLOWED	= "Trailing stop not allowed"
    case WRONG_SIDE_OF_MARKET       = "Wrong side of market"
    case CONTACT_SUPPORT_INSTRUMENT_ERROR = "Contact support instrument error"
    case UNKNOWN	                = "Unknown"
}

open class MSIGBrokerIGPositionAffectedDeal {
    open var dealId = ""
    open var status = MSIGBrokerIGPositionAffectedDealsStatus.OPENED
    
    public init() {}
}

open class MSIGBrokerIGPosition {
    
    
    let includes           = MSIGBrokersIncludes.sharedInstance
    
    open var brokerIG = MSIGBrokerIG.sharedInstance
    open var order    = MSIGBrokerIGPositionOrder()
    
    open var dealId         = ""
    open var dealReference  = ""
    open var dealStatus     = MSIGBrokerIGPositionDealStatus.REJECTED
    open var reason         = MSIGBrokerIGPositionReason.UNKNOWN
    open var status         = MSIGBrokerIGPositionStatus.UNKNOWN
    
    open var affectedDeals  = [MSIGBrokerIGPositionAffectedDeal]()
    
    open var instrument     = MSIGBrokerIGInstrument()
    open var contractSize   = 0 as Double
    open var controlledRisk = false
    open var createdDate    = ""
    open var createdDateUTC = ""
    open var currency       = ""
    open var direction      = MSIGBrokerIGPositionDirection.buy
    open var expiry         = ""
    open var guaranteedStop = false
    open var level          = 0 as NSDecimalNumber
    open var closeLevel     = 0 as NSDecimalNumber
    open var closeType      = MSIGBrokerIGPositionOrderType.MARKET
    open var limitDistance  = 0 as NSDecimalNumber
    open var limitLevel     = 0 as NSDecimalNumber
    open var size           = 0 as Double
    open var stopDistance   = 0 as NSDecimalNumber
    open var stopLevel      = 0 as NSDecimalNumber
    open var trailingStep         : NSDecimalNumber!
    open var trailingStopDistance : NSDecimalNumber!
    
    public init() {}
    
    open func closeParams() -> Dictionary<String, Any> {
        
        var params = Dictionary<String, Any>()
        
        switch order.dealingType {
        case .otc:
            switch dealId.isEmpty {
            case true:
                params["epic"]   = order.epic as Any?
                params["expiry"] = order.expiry as Any?
            case false:
                params["dealId"] = dealId as Any?
            }
            
            switch direction {
            case .buy:  params["direction"] = "SELL" as Any?
            case .sell: params["direction"] = "BUY" as Any?
            }
            
            switch closeType {
            case .MARKET:
                // [Constraint: If orderType equals MARKET, then DO NOT set level,quoteId]
                params["orderType"] = "MARKET" as Any?
            case .LIMIT:
                // [Constraint: If orderType equals LIMIT, then DO NOT set quoteId]
                // [Constraint: If orderType equals LIMIT, then set level]
                params["orderType"] = "LIMIT" as Any?
                params["level"]     = closeLevel.doubleValue as Any?
            case .QUOTE:
                // [Constraint: If orderType equals QUOTE, then set level,quoteId]
                params["orderType"] = "QUOTE" as Any?
                params["level"]     = closeLevel.doubleValue as Any?
                params["quoteId"]   = order.quoteId as Any?
            default: break
            }
            
            params["size"] = size as Any?
            
            switch order.timeInForce {
            case .EXECUTE_AND_ELIMINATE: params["timeInForce"] = "EXECUTE_AND_ELIMINATE" as Any?
            case .FILL_OR_KILL:          params["timeInForce"] = "FILL_OR_KILL" as Any?
            default: break
            }
            
        case .workingOrder: break // return empty params
        }

        //[Constraint: Set only one of {dealId,epic}]
        // [Constraint: If epic is defined, then set expiry]
        return params
    }
    
    open func convertLevelToDistance(level : Double) -> Double {
        return instrument.convertLevelToDistance(level, toLevel: currentPrice())
    }
    
    open func convertDistanceToLevel(distance : Double, isStopLevel : Bool) -> Double {
        switch order.direction {
        case .sell:
            if isStopLevel { return currentPrice() + distance * instrument.onePoint() }
            else           { return currentPrice() - distance * instrument.onePoint() }
        case .buy:
            if isStopLevel { return currentPrice() - distance * instrument.onePoint() }
            else           { return currentPrice() + distance * instrument.onePoint() }
        }
    }
    
    open func currentPrice() -> Double {
        switch order.direction {
        case .buy:  return instrument.snapshot.offer.doubleValue
        case .sell: return instrument.snapshot.bid.doubleValue
        }
    }
    
    open func calcTradeMargin(isOpen : Bool) -> Double! {
        var tradeMargin : Double = 0
        includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN: ORDER GUAR STOP \(order.guaranteedStop)")
        switch order.guaranteedStop {
        case false:
            tradeMargin = trailingStopTradeMargin()
        case true:
            tradeMargin = guaranteedStopTradeMargin(isOpen: isOpen)
        }
        includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN: FINAL TRADE MARGIN: \(tradeMargin)")
        return tradeMargin
    }
    
    func guaranteedStopTradeMargin(isOpen: Bool) -> Double {
        
        var tradeMargin         : Double = 0
        var toLevel             : Double = 0
        var fromLevel           : Double = 0
        var limitedRiskPremium  : Double = 0
        let valueOfOnePip       : Double = NSDecimalNumber(string: instrument.valueOfOnePip).doubleValue
        switch instrument.limitedRiskPremium.unit {
        case .POINTS:
            limitedRiskPremium = instrument.limitedRiskPremium.value
            includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: LIMITED RISK PREM: \(limitedRiskPremium)")
        default: break
        }
        includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: ORDER DEALING TYPE: \(order.dealingType)")
        switch order.dealingType {
        case .otc:
            if isOpen  {
                //HERE
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: STOP DISTANCE FIRST: \(order.stopDistance)")
                 includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: STOP DISTANCE FIRST CAST TO INT VALUE: \(order.stopDistance.intValue)")
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: STOP DISTANCE FIRST INT VALUE: \(Int(order.stopDistance.doubleValue))")
                if Int(order.stopDistance.doubleValue) > 0 {
                    includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: ORDER SIZE FIRST: \(order.size)")
                    
                    tradeMargin = order.size * (order.stopDistance.doubleValue + limitedRiskPremium) * valueOfOnePip
                    
                    includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: TRADE MARGIN FIRST: \(tradeMargin)")
                }
            }
            else {
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: ORDER SIZE SECOND: \(order.size)")
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: STOP DISTANCE SECOND: \(order.stopDistance)")
                let distance = instrument.convertLevelToDistance(Double(level), toLevel: Double(order.stopLevel))
                tradeMargin = order.size * (distance + limitedRiskPremium) * valueOfOnePip
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN GSTOP: TRADE MARGIN SECOND: \(tradeMargin)")
            }
        case .workingOrder:
            fromLevel = order.level.doubleValue
            switch order.direction {
            case .buy: toLevel = order.level.doubleValue - order.stopDistance.doubleValue * valueOfOnePip
            case .sell: toLevel = Double(order.stopDistance) - order.level.doubleValue * valueOfOnePip
            }
            let distance = instrument.convertLevelToDistance(fromLevel, toLevel: toLevel)
            tradeMargin = order.size * (distance + limitedRiskPremium)
        }
        //if instrument.isCurrencyJPY() { tradeMargin *= 100 }
        return tradeMargin
    }
    
    func trailingStopTradeMargin() -> Double {
        var tradeMargin : Double = 0
        for band in instrument.marginDepositBands {
            switch Double(order.size) > band.min {
            case false: break
            case true:
                let faceValue       = instrument.calcFaceValue(self)
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN TSTOP: FACE VALUE \(faceValue)")
                let marginPercent   = (Double(order.size) - band.min) / Double(order.size)
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN TSTOP: MARGIN PERCENT: \(marginPercent)")
                tradeMargin += (faceValue * marginPercent) * (band.margin/100)
                includes.debugPrint(any: "BROKERS POSITION: CALC TRADE MARGIN TSTOP: TRADE MARGIN: \(tradeMargin)")
            }
        }
        return tradeMargin
    }
    
    open func calcTradeMarginAUD(isOpen : Bool) -> String! {
        var marginString : String!
        if let currency = instrument.currencies.first {
            let convertedMargin =  calcTradeMargin(isOpen: isOpen) / Double(currency.baseExchangeRate)
            marginString = convertedMargin.doubleToDecimal(places: 2)
        }
        return marginString
    }
    
    open func isProfit() -> Bool {
        
        switch status {
        case .CLOSED:
            switch direction {
            case .buy:  return level.doubleValue <= closeLevel.doubleValue
            case .sell: return level.doubleValue >= closeLevel.doubleValue
            }
        default:
            switch direction {
            case .buy:  return level.doubleValue <= instrument.snapshot.bid.doubleValue
            case .sell: return level.doubleValue >= instrument.snapshot.offer.doubleValue
            }
        }
    }
    
    open func pAndL() -> Double {
        switch status {
        case .CLOSED:
            switch direction {
            case .buy:  return (level.doubleValue     - closeLevel.doubleValue) * contractSize * size
            case .sell: return (closeLevel.doubleValue - level.doubleValue)      * contractSize * size
            }
        default:
            switch direction {
            case .buy:  return (instrument.snapshot.bid.doubleValue - level.doubleValue)  * contractSize * size
            case .sell: return (level.doubleValue - instrument.snapshot.offer.doubleValue) * contractSize * size
            }
        }
    }
    
    open func setupForCreation() {
//        If a limitDistance is set, then forceOpen must be true]
//        If a limitLevel is set, then forceOpen must be true]
//        If a stopDistance is set, then forceOpen must be true]
//        If a stopLevel is set, then forceOpen must be true]
//        If guaranteedStop equals true, then set only one of stopLevel,stopDistance]
//        If orderType equals LIMIT, then DO NOT set quoteId]
//        If orderType equals LIMIT, then set level]
//        If orderType equals MARKET, then DO NOT set level,quoteId]
//        If orderType equals QUOTE, then set level,quoteId]
//        If trailingStop equals false, then DO NOT set trailingStopIncrement]
//        If trailingStop equals true, then DO NOT set stopLevel]
//        If trailingStop equals true, then guaranteedStop must be false]
//        If trailingStop equals true, then set stopDistance,trailingStopIncrement]
//        Set only one of {limitLevel,limitDistance}]
//        Set only one of {stopLevel,stopDistance}]
        
        order.forceOpen = true
        
        //Change this when WORKING ORDERS ARE IMPLEMENTED
        order.type = .MARKET
    }
    
    open func setupForUpdate() {
        // setup position.order for updating..
        //        position.order.dealingType = position.deal
        
        order.direction    = direction
        order.currencyCode = currency
        order.epic         = instrument.epic
        
//        switch order.dealingType {
//        case .otc:
//            order.level = level
//            order.size  = size
//            order.stopDistance  = stopDistance
//            order.stopLevel     = stopLevel
//            order.limitDistance = limitDistance
//            order.limitLevel    = limitLevel
//        case .workingOrder: break // already setup
//        }
        
        switch guaranteedStop {
        case true:  order.stopType = .GUARANTEED
        case false: break
        }
        
        
    }
    
    open func isJPYCurrency() -> Bool {
        if currency.uppercased() == "JPY" { return true }
        return false
    }
    
    open func debug() {
        print("*** position.debug ***")
        print("dealId: \(dealId)")
        print("dealReference: \(dealReference)")
        print("dealStatus: \(dealStatus)")
        print("reason: \(reason)")
        print("status: \(status)")
        print("affectedDeals: \(affectedDeals)")
        
        print("contractSize: \(contractSize)")
        print("controlledRisk: \(controlledRisk)")
        print("createdDate: \(createdDate)")
        print("createdDateUTC: \(createdDateUTC)")
        print("currency: \(currency)")
        print("direction: \(direction)")
        print("expiry: \(expiry)")
        print("guaranteedStop: \(guaranteedStop)")
        print("level: \(level)")
        print("closeLevel: \(closeLevel)")
        print("closeType: \(closeType)")
        print("stopLevel: \(stopLevel)")
        print("stopDistance: \(stopDistance)")
        print("limitLevel: \(limitLevel)")
        print("limitDistance: \(limitDistance)")
        print("size: \(size)")
        print("trailingStop: \(trailingStep)")
        print("trailingStopDistance: \(trailingStopDistance)")        
        
//        public var brokerIG = MSIGBrokerIGSharedInstance
//        public var order    = MSIGBrokerIGPositionOrder()
//        public var instrument     = MSIGBrokerIGInstrument()
        print("****************************")
        
        
    }
}


