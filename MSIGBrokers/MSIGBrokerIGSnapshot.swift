//
//  MSIGBrokerIGSnapshot.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGSnapshotChartScale {
    case second
    case minute_1
    case minute_5
    case hour
}


open class MSIGBrokerIGSnapshot {
    
    let includes   = MSIGBrokersIncludes.sharedInstance
    
    open var marketStatus = MSIGBrokerIGInstrumentStatus.UNKNOWN
    
    open var bid     = 0 as NSDecimalNumber
    open var offer   = 0 as NSDecimalNumber
    open var high    = 0 as NSDecimalNumber
    open var low     = 0 as NSDecimalNumber
    
    open var midOpen = 0 as NSDecimalNumber

    open var netChange           = 0 as NSDecimalNumber
    open var percentageChange    = 0 as Double
    open var delayTime           = 0 as Int
    open var updateTime          = ""
    open var updateTimeUTC       = ""
    
    open var binaryOdds          = 0 as Double
    open var decimalPlacesFactor = 0 as Double
    open var scalingFactor       = 0 as Double
    open var controlledRiskExtraSpread = 0 as Double
    
    // Chart tick fields
    open var lastTradedPrice     = 0 as NSDecimalNumber
    open var lastTradedVolume    = 0 as NSDecimalNumber
    open var incrementalTradingVolume = 0 as NSDecimalNumber
    open var tickUpdateTime      = 0 as TimeInterval
    open var dayOpenMid          = 0 as NSDecimalNumber
    open var dayNetChangeMid     = 0 as NSDecimalNumber
    open var dayPercChangeMid    = 0 as NSDecimalNumber
    open var dayHigh             = 0 as NSDecimalNumber
    open var dayLow              = 0 as NSDecimalNumber
    
    // Chart tick candle - as above plus..
    open var chartTickScale      = MSIGBrokerIGSnapshotChartScale.minute_5
    open var candleOfferOpen     = 0 as NSDecimalNumber
    open var candleOfferHigh     = 0 as NSDecimalNumber
    open var candleOfferLow      = 0 as NSDecimalNumber
    open var candleOfferClose    = 0 as NSDecimalNumber
    open var candleBidOpen       = 0 as NSDecimalNumber
    open var candleBidHigh       = 0 as NSDecimalNumber
    open var candleBidLow        = 0 as NSDecimalNumber
    open var candleBidClose      = 0 as NSDecimalNumber

    open var candleLTPOpen       = 0 as NSDecimalNumber // LTP = Last Traded Price
    open var candleLTPHigh       = 0 as NSDecimalNumber
    open var candleLTPLow        = 0 as NSDecimalNumber
    open var candleLTPClose      = 0 as NSDecimalNumber
    
    open var isLastTick          = false
    open var candleNumTicks      = 0 as Int
    
    public init() {}
    
    open func updateFromStreamingMarket(_ updateInfo : LSItemUpdate) {
        
        bid              = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID")      as Double)
        offer            = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFFER")    as Double)
        high             = NSDecimalNumber(value: extractDouble(updateInfo, field: "HIGH")     as Double)
        low              = NSDecimalNumber(value: extractDouble(updateInfo, field: "LOW")      as Double)
        midOpen          = NSDecimalNumber(value: extractDouble(updateInfo, field: "MID_OPEN") as Double)
    
//        includes.debugPrint(any: "***************************************************************")
//        includes.debugPrint(any: "MSIGBrokerIGSnapshot.updateFromStreamingMarket")
//        includes.debugPrint(any: "bid: \(bid)")
//        includes.debugPrint(any: "offer: \(offer)")
//        includes.debugPrint(any: "high: \(high)")
//        includes.debugPrint(any: "low: \(low)")
//        includes.debugPrint(any: "midOpen: \(midOpen)")
//        includes.debugPrint(any: "---------------------------------------------------------------")
        
        
        if updateInfo.value(withFieldName: "UPDATE_TIME") != nil {
            updateTime = updateInfo.value(withFieldName: "UPDATE_TIME")!
        }
        
        if updateInfo.value(withFieldName: "MARKET_DELAY") != nil {
            let x = updateInfo.value(withFieldName: "MARKET_DELAY")!
            if !x.isEmpty { delayTime = Int(x)! }
        }
        
        percentageChange = extractDouble(updateInfo, field: "CHANGE_PCT")
        
//        includes.debugPrint(any: "percentageChange: \(percentageChange)")
//        includes.debugPrint(any: "MARKET_STATE: " + updateInfo.currentValueOfFieldName("MARKET_STATE"))
        
        switch updateInfo.value(withFieldName: "MARKET_STATE")! {
        case "CLOSED":              marketStatus = .CLOSED
        case "EDITS_ONLY":          marketStatus = .EDITS_ONLY
        case "OFFLINE":             marketStatus = .OFFLINE
        case "ON_AUCTION":          marketStatus = .ON_AUCTION
        case "ON_AUCTION_NO_EDITS": marketStatus = .ON_AUCTION_NO_EDITS
        case "SUSPENDED":           marketStatus = .SUSPENDED
        case "TRADEABLE":           marketStatus = .TRADEABLE
        default:                    marketStatus = .UNKNOWN
        }
//        includes.debugPrint(any: "---------------------------------------------------------------")
    }
    
    open func updateFromStreamingTick(_ updateInfo : LSItemUpdate) {
        bid              = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID") as Double)
        offer            = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFR") as Double)
        lastTradedPrice  = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTP") as Double)
        lastTradedVolume = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTV") as Double)
        incrementalTradingVolume = NSDecimalNumber(value: extractDouble(updateInfo, field: "TTV") as Double)

       
        // Once in a while UTM will be nil - This is an IG error.
        
        if updateInfo.value(withFieldName: "UTM") != nil {
            let string = updateInfo.value(withFieldName: "UTM")
            
            switch string!.isEmpty {
            case true: break
            default: tickUpdateTime = Double(string!)! as TimeInterval
            }
        }
        
        dayOpenMid       = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_OPEN_MID")     as Double)
        dayNetChangeMid  = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_NET_CHG_MID")  as Double)
        dayPercChangeMid = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_PERC_CHG_MID") as Double)
        dayHigh          = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_HIGH")         as Double)
        dayLow           = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_LOW")          as Double)
    }
    
    open func updateFromStreamingCandle(_ updateInfo : LSItemUpdate) {
        
        lastTradedVolume         = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTV") as Double)
        incrementalTradingVolume = NSDecimalNumber(value: extractDouble(updateInfo, field: "TTV") as Double)
        
        if updateInfo.value(withFieldName: "UTM") != nil {
            updateTime = updateInfo.value(withFieldName: "UTM")!
        }
        
        dayOpenMid       = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_OPEN_MID")     as Double)
        dayNetChangeMid  = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_NET_CHG_MID")  as Double)
        dayPercChangeMid = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_PERC_CHG_MID") as Double)
        dayHigh          = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_HIGH")  as Double)
        dayLow           = NSDecimalNumber(value: extractDouble(updateInfo, field: "DAY_LOW")   as Double)
        candleOfferOpen  = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFR_OPEN")  as Double)
        candleOfferHigh  = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFR_HIGH")  as Double)
        candleOfferLow   = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFR_LOW")   as Double)
        candleOfferClose = NSDecimalNumber(value: extractDouble(updateInfo, field: "OFR_CLOSE") as Double)
        candleBidOpen    = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID_OPEN")  as Double)
        candleBidHigh    = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID_HIGH")  as Double)
        candleBidLow     = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID_LOW")   as Double)
        candleBidClose   = NSDecimalNumber(value: extractDouble(updateInfo, field: "BID_CLOSE") as Double)
        candleLTPOpen    = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTP_OPEN")  as Double)
        candleLTPHigh    = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTP_HIGH")  as Double)
        candleLTPLow     = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTP_LOW")   as Double)
        candleLTPClose   = NSDecimalNumber(value: extractDouble(updateInfo, field: "LTP_CLOSE") as Double)
        
        switch updateInfo.value(withFieldName: "CONS_END") == nil {
        case true: isLastTick = false
        case false:
            switch updateInfo.value(withFieldName: "CONS_END")!.isEmpty {
            case true: isLastTick = false
            case false:
                switch updateInfo.value(withFieldName: "CONS_END")! {
                case "1": isLastTick = true
                default:  isLastTick = false
                }
            }
        }

        switch updateInfo.value(withFieldName: "LTP_CLOSE")!.isEmpty {
        case true: candleNumTicks = 0
        default:
            switch updateInfo.value(withFieldName: "LTP_CLOSE")!.isEmpty {
            case true:  candleNumTicks = 0
            case false:
                
                if !updateInfo.value(withFieldName: "LTP_CLOSE")!.isEmpty {
                    let x = updateInfo.value(withFieldName: "LTP_CLOSE")!
                    candleNumTicks = Int(x)!
                }
            }
        }
        
    }
    
    open func tickUpdateTimeToDate() -> Date {
        return Date(timeIntervalSince1970: tickUpdateTime / 1000)
    }
    
    // handle nils (there are quite a few of them :-(
    open func extractDouble(_ updateInfo : LSItemUpdate, field : String) -> Double {
        if updateInfo.value(withFieldName: field) == nil   { return 0 }
        if updateInfo.value(withFieldName: field)!.isEmpty { return 0 }
         return Double(updateInfo.value(withFieldName: field)!)!
    }
    
}
