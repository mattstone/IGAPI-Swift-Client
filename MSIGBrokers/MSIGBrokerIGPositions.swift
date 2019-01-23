//
//  MSIGBrokerIGPositions.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 16/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGPositions {
    let brokerIG   = MSIGBrokerIG.sharedInstance
    let includes   = MSIGBrokersIncludes.sharedInstance
    
    open var positions  = [MSIGBrokerIGPosition]()

    open func isError()            -> Bool   { return brokerIG.isError()            }
    open func simpleErrorMessage() -> String { return brokerIG.simpleErrorMessage() }

    public init() {}

    // Show OTC
    open func show() {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/positions" as Any?
        includes.debugPrint(any: "BROKERS: SHOW POSITIONS: \(dict)")
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_POSITIONS_SHOW)
    }
    
    open func handleShowPositions(_ notification : Notification) {
        positions.removeAll()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            includes.debugPrint(any: "BROKERS: HADNLE SHOW RESPONSE: \(dict)")
            brokerIG.processResponseForErrors(dict)

            if let json = dict["json"] as? Dictionary<String, Any> {
                if let array = json["positions"] as? Array<Dictionary<String, Any>> {
                    for element in array { positions.append(extractPosition(element)) }
                    return
                }
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    open func showWorking() {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/workingorders" as Any?
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_POSITIONS_SHOW, version: 2)
    }
    
    open func handleShowWorking(_ notification : Notification) -> Array<MSIGBrokerIGPosition> {
        var positions = Array<MSIGBrokerIGPosition>()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let array = json["workingOrders"] as? Array<Dictionary<String, Any>> {
                    
                    for element in array {
                        let position = extractPosition(element)
                        position.order.dealingType = .workingOrder
                        positions.append(position)
                    }
                    return positions
                }
            }
        }
        
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return positions
    }
    
    open func extractPosition(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGPosition {
        let position = MSIGBrokerIGPosition()
        
        if let p = dict["position"] as? Dictionary<String, Any> {
            
            if let x = p["contractSize"]   as? Double { position.contractSize   = x }
            if let x = p["createdDate"]    as? String { position.createdDate    = x }
            if let x = p["createdDateUTC"] as? String { position.createdDateUTC = x }
            if let x = p["dealId"]         as? String { position.dealId         = x }
            if let x = p["dealSize"]       as? Double { position.size           = x }
            if let x = p["size"]           as? Double { position.size           = x }
            
            if let x = p["direction"] as? String {
                switch x {
                case "SELL" : position.direction = .sell
                case "BUY"  : position.direction = .buy
                default: break
                }
            }
            
            if let x = p["openLevel"]   as? Double { position.level      = NSDecimalNumber(value: x as Double) }
            if let x = p["limitLevel"]  as? Double { position.limitLevel = NSDecimalNumber(value: x as Double) }
            if let x = p["currency"]    as? String { position.currency   = x }
            if let x = p["controlledRisk"]       as? Bool   { position.controlledRisk   = x }
            if let x = p["stopLevel"]            as? Double { position.stopLevel   = NSDecimalNumber(value: x as Double) }
            if let x = p["trailingStep"]         as? Double { position.trailingStep   = NSDecimalNumber(value: x as Double) }
            if let x = p["trailingStopDistance"] as? Double { position.trailingStopDistance = NSDecimalNumber(value: x as Double) }
        }
        
        if let wo = dict["workingOrderData"] as? Dictionary<String, Any> {
            
            position.order             = MSIGBrokerIGPositionOrder()
            position.order.dealingType = .workingOrder
            
            if let x = wo["createdDate"]    as? String { position.createdDate    = x }
            if let x = wo["createdDateUTC"] as? String { position.createdDateUTC = x }
            
            if let x = wo["currencyCode"]   as? String { position.currency       = x }
            if let x = wo["dealId"]         as? String { position.dealId         = x }
            
            if let x = wo["direction"]      as? String {
                switch x {
                case "BUY":  position.direction = .buy
                case "SELL": position.direction = .sell
                default: break
                }
            }
            
            if let x = wo["dma"]  as? Bool   { position.order.dma  = x }
            if let x = wo["epic"] as? String { position.order.epic = x }
            
            if let x = wo["goodTillDate"]    as? String {
                position.order.goodTillDate    = x
                
                switch x.isEmpty {
                case true:  break
                case false:
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
                    position.order.goodTillNSDate = dateFormatter.date(from: x)!
                }
            }
            
            if let x = wo["goodTillDateISO"] as? String { position.order.goodTillDateISO = x }
            if let x = wo["guaranteedStop"]  as? Bool   { position.order.guaranteedStop  = x }
            if let x = wo["limitDistance"]   as? Double { position.order.limitDistance = NSDecimalNumber(value: x as Double) }
            if let x = wo["orderLevel"]      as? Double { position.order.level = NSDecimalNumber(value: x as Double) }
            if let x = wo["orderSize"]       as? Double { position.order.size  = x }
            
            if let x = wo["orderType"] as? String {
                switch x {
                case "MARKET": position.order.type = .MARKET
                case "LIMIT":  position.order.type = .LIMIT
                case "QUOTE":  position.order.type = .QUOTE
                case "STOP":   position.order.type = .STOP
                default: break
                }
            }
            
            if let x = wo["stopDistance"] as? Double { position.order.stopDistance = NSDecimalNumber(value: x as Double) }
            
            if let x = wo["timeInForce"]  as? String {
                switch x {
                case "GOOD_TILL_CANCELLED": position.order.timeInForce = .GOOD_TILL_CANCELLED
                case "GOOD_TILL_DATE":      position.order.timeInForce = .GOOD_TILL_DATE
                default: break
                }
            }
        }
        
        for (key, _) in dict { includes.debugPrint(any: "THE DICT KEY IS: \(key)") }
        
        if let x = dict["market"] as? Dictionary<String, Any> {
            includes.debugPrint(any: "EXTRACT INSTRUMENT: KEY: MARKET: \(x)")
            position.instrument = brokerIG.extractInstrument(x)
        }

        if let x = dict["marketData"] as? Dictionary<String, Any> {
            includes.debugPrint(any: "EXTRACT INSTRUMENT: KEY: MARKET DATA: \(x)")
            position.instrument = brokerIG.extractInstrument(x)
        }
                
        return position
    }
    
    // Create
    open func create(_ position : MSIGBrokerIGPosition ) -> Bool {
//        if !position.order.isCreateValid() { return false }
        
        let version  = 2
        var dict     =  Dictionary<String, Any>()
        
        switch position.order.dealingType {
        case .otc:     dict["url"] = "\(brokerIG.apiUrl)/positions/otc" as Any?
        case .workingOrder: dict["url"] = "\(brokerIG.apiUrl)/workingorders/otc" as Any?
        }
        
        dict["parameters"] = position.order.createParams() as Any?

//        position.order.debug()

        includes.debugPrint(any: "positions.create: \(dict)")
        
        brokerIG.httpPost(dict, notification : brokerIG.config.IG_POSITION_CREATE, version: version)
        return true
    }
    
    open func grandTotalPandL() -> String! {
    
        if positions.isEmpty { return nil }
        
        //Return the sum of all positions Profit and Loss
        var x : Double = 0.0
        for position in positions {
            //CRASH: BUG HERE
            x += position.pAndL()
        }
        
       
        let formatter = NumberFormatter()
        formatter.locale = Locale.init(identifier: "en_AU")
        formatter.numberStyle = .currency
        let formattedValue = formatter.string(from: NSNumber(value: x))

        return formattedValue
    }
    
//    https://demo-api.ig.com/gateway/deal/confirms/PQ3UH7ETK7WTT8C
    
    open func confirm(_ position : MSIGBrokerIGPosition) {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/confirms/\(position.dealReference)" as Any?
        
        includes.debugPrint(any: "position.confirm: \(dict)")
        
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_DEAL_CONFIRM)
    }
    
    open func handleCreateResponse(_ notification : Notification, position : MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            if let json = dict["json"] as? Dictionary<String, Any> {
                return extractCreate(json, position: position)
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return  position
    }
    
    open func handleConfirmResponse(_ notification : Notification, position : MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        if let dict = notification.object as? Dictionary<String, Any> {
            includes.debugPrint(any: "BROKERS: HADNLE CONFIRM RESPONSE: \(dict)")
            brokerIG.processResponseForErrors(dict)
            if let json = dict["json"] as? Dictionary<String, Any> {
                return extractConfirm(json, position: position)
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return position
    }
    
    open func handleStreamingConfirm(_ string : String) -> MSIGBrokerIGPosition {
        var position = MSIGBrokerIGPosition()
        brokerIG.clearErrors()
        
        let data = string.data(using: String.Encoding.utf8)
        if data == nil  { brokerIG.addErrorObject("", description : "Invalid confirm received", code : "") }
        
        if !brokerIG.isError() {
            do {
                let obj = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                
                if let json = obj as? Dictionary<String, Any> {
//                    includes.debugPrint(any: "Streaming:json: \(json)")
                    position = extractConfirm(json, position: position)
                } else {
                    brokerIG.addErrorObject("", description : "Unable to read confirm received", code : "")
                }
            } catch let error {
                brokerIG.addErrorObject("", description : "Invalid confirm received: \(error)", code : "")
            }
        }
        
        return position
    }
    
    func extractCreate(_ json : Dictionary<String, Any>, position: MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        
        if let x = json["dealReference"] as? String { position.dealReference = x }
        return position
    }
    
    func extractConfirm(_ json : Dictionary<String, Any>, position: MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        if let array = json["affectedDeals"] as? Array<Dictionary<String, Any>> {
            position.affectedDeals.removeAll()
            
            for element in array {
                let affectedDeal = MSIGBrokerIGPositionAffectedDeal()
                if let x = element["dealId"] as? String { affectedDeal.dealId = x }
                if let x = element["status"] as? String {
                    switch x {
                    case "AMENDED":          affectedDeal.status = .AMENDED
                    case "DELETED":          affectedDeal.status = .DELETED
                    case "FULLY_CLOSED":     affectedDeal.status = .FULLY_CLOSED
                    case "OPENED":           affectedDeal.status = .OPENED
                    case "PARTIALLY_CLOSED": affectedDeal.status = .PARTIALLY_CLOSED
                    default: break
                    }
                }
                position.affectedDeals.append(affectedDeal)
            }
        }

        if let x = json["epic"]           as? String { position.instrument.epic = x } // Provided in confirm
        if let x = json["dealId"]         as? String { position.dealId          = x }
        if let x = json["dealReference"]  as? String { position.dealReference   = x }
        if let x = json["expiry"]         as? String { position.expiry          = x }
        if let x = json["guaranteedStop"] as? Bool   { position.guaranteedStop  = x }
        if let x = json["level"]          as? Double { position.level           = NSDecimalNumber(value: x as Double) }
        if let x = json["limitDistance"]  as? Double { position.limitDistance   = NSDecimalNumber(value: x as Double) }
        if let x = json["limitLevel"]     as? Double { position.limitLevel      = NSDecimalNumber(value: x as Double) }
        if let x = json["size"]           as? Double { position.size            = x }
        if let x = json["stopDistance"]   as? Double { position.stopDistance    = NSDecimalNumber(value: x as Double) }
        if let x = json["stopLevel"]      as? Double { position.stopLevel       = NSDecimalNumber(value: x as Double) }
        if let x = json["trailingStep"]   as? Double { position.trailingStep    = NSDecimalNumber(value: x as Double) }
        
        if let x = json["direction"] as? String {
            switch x {
            case "BUY":  position.direction = .buy
            case "SELL": position.direction = .sell
            default: break
            }
        }
        
        if let x = json["dealStatus"] as? String {
            switch x {
            case "ACCEPTED":     position.dealStatus = .ACCEPTED
            case "FUND_ACCOUNT": position.dealStatus = .FUND_ACCOUNT
            case "REJECTED":     position.dealStatus = .REJECTED
            default: break
            }
        }
        
        if let x = json["status"] as? String {
            switch x {
            case "AMENDED": position.status = .AMENDED
            case "CLOSED":  position.status = .CLOSED
            case "DELETED": position.status = .DELETED
            case "OPEN":    position.status = .OPEN
            case "PARTIALLY_CLOSED": position.status = .PARTIALLY_CLOSED
            default:        position.status = .UNKNOWN
            }
        }
        
        if let x = json["reason"] as? String {
            switch x {
            case "ACCOUNT_NOT_ENABLED_TO_TRADING": position.reason = .ACCOUNT_NOT_ENABLED_TO_TRADING
            case "ATTACHED_ORDER_LEVEL_ERROR":     position.reason = .ATTACHED_ORDER_LEVEL_ERROR
            case "ATTACHED_ORDER_TRAILING_STOP_ERROR": position.reason = .ATTACHED_ORDER_TRAILING_STOP_ERROR
            case "CANNOT_CHANGE_STOP_TYPE":        position.reason = .CANNOT_CHANGE_STOP_TYPE
            case "CANNOT_REMOVE_STOP":             position.reason = .CANNOT_REMOVE_STOP
                case "CONTACT_SUPPORT_INSTRUMENT_ERROR": position.reason = .CONTACT_SUPPORT_INSTRUMENT_ERROR
            case "CLOSING_ONLY_TRADES_ACCEPTED_ON_THIS_MARKET": position.reason = .CLOSING_ONLY_TRADES_ACCEPTED_ON_THIS_MARKET
            case "CONFLICTING_ORDER":              position.reason = .CONFLICTING_ORDER
            case "CR_SPACING":                     position.reason = .CR_SPACING
            case "DUPLICATE_ORDER_ERROR":          position.reason = .DUPLICATE_ORDER_ERROR
            case "EXCHANGE_MANUAL_OVERRIDE":       position.reason = .EXCHANGE_MANUAL_OVERRIDE
            case "FINANCE_REPEAT_DEALING":         position.reason = .FINANCE_REPEAT_DEALING
            case "FORCE_OPEN_ON_SAME_MARKET_DIFFERENT_CURRENCY": position.reason = .FORCE_OPEN_ON_SAME_MARKET_DIFFERENT_CURRENCY
            case "GENERAL_ERROR":                  position.reason = .GENERAL_ERROR
            case "GOOD_TILL_DATE_IN_THE_PAST":     position.reason = .GOOD_TILL_DATE_IN_THE_PAST
            case "INSTRUMENT_NOT_FOUND":           position.reason = .INSTRUMENT_NOT_FOUND
            case "INSUFFICIENT_FUNDS":             position.reason = .INSUFFICIENT_FUNDS
            case "LEVEL_TOLERANCE_ERROR":          position.reason = .LEVEL_TOLERANCE_ERROR
            case "MANUAL_ORDER_TIMEOUT":           position.reason = .MANUAL_ORDER_TIMEOUT
            case "MARKET_CLOSED":                  position.reason = .MARKET_CLOSED
            case "MARKET_CLOSED_WITH_EDITS":       position.reason = .MARKET_CLOSED_WITH_EDITS
            case "MARKET_CLOSING":                 position.reason = .MARKET_CLOSING
            case "MARKET_NOT_BORROWABLE":          position.reason = .MARKET_NOT_BORROWABLE
            case "MARKET_OFFLINE":                 position.reason = .MARKET_OFFLINE
            case "MARKET_PHONE_ONLY":              position.reason = .MARKET_PHONE_ONLY
            case "MARKET_ROLLED":                  position.reason = .MARKET_ROLLED
            case "MARKET_UNAVAILABLE_TO_CLIENT":   position.reason = .MARKET_UNAVAILABLE_TO_CLIENT
            case "MAX_AUTO_SIZE_EXCEEDED":         position.reason = .MINIMUM_ORDER_SIZE_ERROR
            case "MINIMUM_ORDER_SIZE_ERROR":       position.reason = .MINIMUM_ORDER_SIZE_ERROR
            case "MOVE_AWAY_ONLY_LIMIT":           position.reason = .MOVE_AWAY_ONLY_LIMIT
            case "MOVE_AWAY_ONLY_STOP":            position.reason = .MOVE_AWAY_ONLY_STOP
            case "MOVE_AWAY_ONLY_TRIGGER_LEVEL":   position.reason = .MOVE_AWAY_ONLY_TRIGGER_LEVEL
            case "OPPOSING_DIRECTION_ORDERS_NOT_ALLOWED":   position.reason = .OPPOSING_DIRECTION_ORDERS_NOT_ALLOWED
            case "OPPOSING_POSITIONS_NOT_ALLOWED": position.reason = .OPPOSING_POSITIONS_NOT_ALLOWED
            case "ORDER_LOCKED":                   position.reason = .ORDER_LOCKED
            case "ORDER_NOT_FOUND":                position.reason = .ORDER_NOT_FOUND
            case "OVER_NORMAL_MARKET_SIZE":        position.reason = .OVER_NORMAL_MARKET_SIZE
            case "PARTIALY_CLOSED_POSITION_NOT_DELETED":    position.reason = .PARTIALY_CLOSED_POSITION_NOT_DELETED
            case "POSITION_NOT_AVAILABLE_TO_CLOSE": position.reason = .POSITION_NOT_AVAILABLE_TO_CLOSE
            case "POSITION_NOT_FOUND":             position.reason = .POSITION_NOT_FOUND
            case "REJECT_SPREADBET_ORDER_ON_CFD_ACCOUNT":   position.reason = .REJECT_SPREADBET_ORDER_ON_CFD_ACCOUNT
            case "SIZE_INCREMENT":                 position.reason = .SIZE_INCREMENT
            case "SPRINT_MARKET_EXPIRY_AFTER_MARKET_CLOSE": position.reason = .SPRINT_MARKET_EXPIRY_AFTER_MARKET_CLOSE
            case "STOP_OR_LIMIT_NOT_ALLOWED":      position.reason = .STOP_OR_LIMIT_NOT_ALLOWED
            case "STOP_REQUIRED_ERROR":            position.reason = .STOP_REQUIRED_ERROR
            case "STRIKE_LEVEL_TOLERANCE":         position.reason = .STRIKE_LEVEL_TOLERANCE
            case "SUCCESS":                        position.reason = .SUCCESS
            case "TRAILING_STOP_NOT_ALLOWED":      position.reason = .TRAILING_STOP_NOT_ALLOWED
            case "WRONG_SIDE_OF_MARKET":           position.reason = .WRONG_SIDE_OF_MARKET
            default:                               position.reason = .UNKNOWN
            }
        }
        
        return position
    }
    
    // update
    open func update(_ position : MSIGBrokerIGPosition) {
        let version  = 2
        var dict     = Dictionary<String, Any>()
        
        switch position.order.dealingType {
        case .otc:     dict["url"] = "\(brokerIG.apiUrl)/positions/otc/\(position.dealId)" as Any?
        case .workingOrder: dict["url"] = "\(brokerIG.apiUrl)/workingorders/otc/\(position.dealId)" as Any?
        }
//        dict["parameters"] = position.order.updateParams()
        
        let params = position.order.updateParams()
//        includes.debugPrint(any: "THE EARLY PARAMS IS: \(params)")
//        includes.debugPrint(any: "*** TODO: position.order.. this is not good..")

        // 
//        if position.limitLevel    == position.order.limitLevel    { params.removeValueForKey("limitLevel") }
//        if position.limitDistance == position.order.limitDistance { params.removeValueForKey("limitDistance") }
//        if position.stopLevel     == position.order.stopLevel     { params.removeValueForKey("stopLevel") }
//        if position.stopDistance  == position.order.stopDistance  { params.removeValueForKey("stopDistance") }
        
//        switch position.guaranteedStop {
//        case true:
//            switch position.order.stopType {
//            case .NONE:   break
//            case .NORMAL: break
//            case .GUARANTEED: if position.stopLevel == position.order.stopLevel { params.removeValueForKey("stopLevel") }
//            }
//        case false:
//            if position.stopLevel == position.order.stopLevel { params.removeValueForKey("stopLevel") }
//        }
        
//        includes.debugPrint(any: "THE LATER PARAMS IS: \(params)")

        dict["parameters"] = params as Any?

includes.debugPrint(any: "brokerIG: position.update --------------------------------------")
includes.debugPrint(any: "position.update: dict: \(dict)")
        includes.debugPrint(any: ".....................................")
includes.debugPrint(any: position.order.debug())
        includes.debugPrint(any: "brokerIG: position.update --------------------------------------")
        
        brokerIG.httpPut(dict, notification : brokerIG.config.IG_POSITION_UPDATE, version: version)
    }
    
    open func handleUpdateResponse(_ notification : Notification, position : MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let x = json["dealReference"] as? String {
                    position.dealReference = x
                    return position
                }
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return position
    }
    
    // Close
    
    open func close(_ position : MSIGBrokerIGPosition) {
        let version  = 1
        var dict     =  Dictionary<String, Any>()
        
        switch position.order.dealingType {
        case .otc:     dict["url"] = "\(brokerIG.apiUrl)/positions/otc" as Any?
        case .workingOrder: dict["url"] = "\(brokerIG.apiUrl)/workingorders/otc/\(position.dealId)" as Any?
        }
        
        dict["parameters"] = position.closeParams() as Any?
        brokerIG.httpDeleteIG(dict, notification : brokerIG.config.IG_POSITION_DELETE, version: version)
    }
    
    open func handleCloseResponse(_ notification : Notification, position : MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let x = json["dealReference"] as? String {
                    position.dealReference = x
                    return position
                }
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return position
    }
    
    // handleDealReference
    
    open func handleDealReferenceResponse(_ notification : Notification) -> String {
        
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let x = json["dealReference"] as? String { return x }
            }
        }
        
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        return ""
    }
    
}

