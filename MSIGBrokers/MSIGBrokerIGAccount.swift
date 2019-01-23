//
//  MSIGBrokerIGAccount.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 13/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation


public enum MSIGBrokerIGAccountType : String {
    case CFD
    case PHYSICAL
    case SPREADBET
}

public enum MSIGBrokerIGAccountReroutingEnvironment {
    case null
    case demo
    case live
    case test
    case uat
}

public enum MSIGBrokerIGAccountAuthenticationStatus {
    case unauthorised
    case authenticated
    case authenticated_MISSING_CREDENTIALS
    case change_ENVIRONMENT
    case disabled_PREFERRED_ACCOUNT
    case missing_PREFERRED_ACCOUNT
    case rejected_INVALID_CLIENT_VERSION
}

open class MSIGBrokerAccountPreferences {
    open var trailingStopsEnabled : Bool = false
}

open class MSIGBrokerIGAccountDetails {
    open var id   = ""
    open var name = ""
    open var type = MSIGBrokerIGAccountType.CFD
    open var preferred   = false
    
    public init() {}
}

//public class MSIGBrokerHistoryMetaPageData {
//    public var pageNumber = 0
//    public var pageSize   = 0
//    public var totalPages = 0
//}
//
//public class MSIGBrokerHistoryMetaData {
//    public var pageData = MSIGBrokerHistoryMetaPageData()
//    public var size     = 0
//}


//public class MSIGBrokerIGAccountTransactionHistory {
//    public var cashTransaction = false
//    public var closeLevel      = ""
//    public var currency        = ""
//    public var date            = ""
//    public var dateUTC         = ""
//    public var instrumentName  = ""
//    public var openLevel       = ""
//    public var period          = ""
//    public var profitAndLoss   = ""
//    public var reference       = ""
//    public var size            = ""
//    public var transactionType = ""
//}

public enum MSIGBrokerIGAccountTransactionHistoryType : String {
    case ALL
    case ALL_DEAL
    case DEPOSIT
    case WITHDRAWAL
}

open class MSIGBrokerIGAccount {
    let brokerIG   = MSIGBrokerIG.sharedInstance
    
    open var type                 = MSIGBrokerIGAccountType.CFD
    open var reroutingEnvironment = MSIGBrokerIGAccountReroutingEnvironment.null
    
    open var transactionHistory   = MSIGBrokerIGTransactions()
    open var activityHistory      = MSIGBrokerIGActivities()
    open var preferences          = MSIGBrokerAccountPreferences()
    
//    public var histories            = [MSIGBrokerIGHistory]()
//    public var historyMetaData      = MSIGBrokerHistoryMetaData()
    
//    public var transactionHistories = [MSIGBrokerIGAccountTransactionHistory]()
//    public var transactionHistoryMetaData = MSIGBrokerHistoryMetaData()
    
    open var availableFunds   = 0 as NSDecimalNumber
    open var balance          = 0 as NSDecimalNumber
    open var deposit          = 0 as NSDecimalNumber
    open var profitLoss       = 0 as NSDecimalNumber
    
    open var accounts         = Array<MSIGBrokerIGAccountDetails>()
    
    open var clientId         = "" as String
    open var currencyIsoCode  = "" as String
    open var currencySymbol   = "" as String
    open var currentAccountId = "" as String
    open var dealingEnabled   = false as Bool
    open var encrypted        = false as Bool
    open var timezoneOffset   = 0 as Double
    
    open var formDetails      = Array<Dictionary<String, Any>>()  // Not used at the moment
    
    open var hasActiveDemoAccounts = false 	      // Whether the Client has active demo accounts.
    open var hasActiveLiveAccounts = false        // Whether the Client has active live accounts.
    open var trailingStopsEnabled  = false
    open var igCompany             = "" as String //The ig company that this client belongs to
    open var lightstreamerEndpoint = "" as String
    open var locale                = "" as String
    
    public init() {}
    
    open func cleanUp() {
        accounts.removeAll()
        formDetails.removeAll()
    }
    
    open func preferredAccountDetails() -> MSIGBrokerIGAccountDetails! {
        if accounts.count == 0 { return nil }
        
        for account in accounts {
            switch account.preferred {
            case true:  return account
            case false: break
            }
        }
        
        return accounts.first!
    }
    
    open func transactionHistories(_ type : MSIGBrokerIGTransactionsRequest = .ALL,
                        from           : Date = Date().addingTimeInterval(-30*24*60*60),
                        to             : Date = Date(),
                        maxSpanSeconds : Int!    = nil,
                        pageSize       : Int = 20,   // pageSize = 0 disables paging
                        pageNumber     : Int = 1) {
        
        //        var url                  = "\(brokerIG.apiUrl)/history/activity"
        var url = "\(brokerIG.apiUrl)/history/transactions"
        url    += "?type=\(type.rawValue)&"
        url    += "from=\(parseDateForIgQuery(from))&"
        url    += "to=\(parseDateForIgQuery(to))&"
        if maxSpanSeconds != nil { url += "to=\(maxSpanSeconds)&" }
        url    += "pageSize=\(pageSize)&"
        url    += "pageNumber=\(pageNumber)"
        
        var dict    =  Dictionary<String, Any>()
        dict["url"] = url as Any?

//        print(dict)
        
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_ACCOUNT_TRANSACTION_HISTORY, version: 2)
    }
    
    open func handleTransactionHistories(_ notification : Notification) {
        transactionHistory.transactions.removeAll()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                
                if let m = json["metadata"] as? Dictionary<String, Any> {
                    transactionHistory.meta = updateMetadata(m)
                }
                
                if let array = json["transactions"] as? Array<Dictionary<String, Any>> {
                    
                    for element in array {
                        
                        let t = MSIGBrokerIGTransaction()
                        
                        if let x = element["cashTransaction"] as? Bool   { t.cashTransaction = x }
                        if let x = element["closeLevel"]      as? String { t.closeLevel      = x }
                        if let x = element["currency"]        as? String { t.currency        = x }
                        if let x = element["date"]            as? String { t.date            = x }
                        if let x = element["dateUtc"]         as? String { t.dateUTC         = x }
                        if let x = element["instrumentName"]  as? String { t.instrumentName  = x }
                        if let x = element["openLevel"]       as? String { t.openLevel       = x }
                        if let x = element["period"]          as? String { t.period          = x }
                        if let x = element["profitAndLoss"]   as? String { t.profitAndLoss   = x }
                        if let x = element["reference"]       as? String { t.reference       = x }
                        if let x = element["size"]            as? String { t.size            = x }
                        if let x = element["transactionType"] as? String { t.transactionType = x }

                        transactionHistory.transactions.append(t)
                    }
                }
            }
        }        
    }
    
    
    open func activityHistories(_ from     : Date  = Date().addingTimeInterval(-30*24*60*60),
                                  to       : Date  = Date(),
                                  detailed : Bool    = true,
                                  dealId   : String! = nil,
                                  filter   : String! = nil,
                                  pageSize : Int = 50)    { // pageSize = 0 disables paging
    
        var url = "\(brokerIG.apiUrl)/history/activity"
        url    += "?from=\(parseDateForIgQuery(from))&"
        url    += "to=\(parseDateForIgQuery(to))&"
        url    += "detailed=\(detailed)&"
        if dealId != nil { url += "dealId=\(dealId)" }
        if filter != nil { url += "filter=\(filter)" }
        url    += "pageSize=\(pageSize)"
        
        var dict    =  Dictionary<String, Any>()
        dict["url"] = url as Any?
        
//        print(dict)
        
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_ACCOUNT_ACTIVITY_HISTORY, version: 3)
    }
    

    open func handleActvityHistories(_ notification : Notification) {
        activityHistory.activities.removeAll()
    
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
        
            if let json = dict["json"] as? Dictionary<String, Any> {
            
                if let m = json["metadata"] as? Dictionary<String, Any> {
                    
                    if let p = m["paging"] as? Dictionary<String, Any> {
                        if let x = p["next"] as? String { activityHistory.meta.next = x }
                        if let x = p["size"] as? Int    { activityHistory.meta.size = x }
                    }
                }
                
                if let array = json["activities"] as? Array<Dictionary<String, Any>> {
                    
                    for element in array {
                        
                        let a = MSIGBrokerIGActivity()
                        
                        if let x = element["channel"] as? String {
                            switch x {
                            case "DEALER":         a.channel = .dealer
                            case "MOBILE":         a.channel = .mobile
                            case "PUBLIC_FIX_API": a.channel = .public_FIX_API
                            case "PUBLIC_WEB_API": a.channel = .public_WEB_API
                            case "SYSTEM":         a.channel = .system
                            case "WEB":            a.channel = .web
                            default: break
                            }
                        }
                        
                        if let x = element["date"]        as? String { a.date        = x }
                        if let x = element["dealId"]      as? String { a.dealId      = x }
                        if let x = element["description"] as? String { a.description = x }
                        
                        
                        if let dict = element["details"] as? Dictionary<String, Any> {
                            let detail = MSIGBrokerIGActivityDetails()
                            
                            if let array = dict["actions"] as? Array<Dictionary<String, Any>> {
                                
                                for e in array {
                                    
                                    let action = MSIGBrokerIGActivityAction()
                                    
                                    if let x = e["actionType"] as? String {
                                        switch x {
                                        case "LIMIT_ORDER_AMENDED"   : action.actionType = .limit_ORDER_AMENDED
                                        case "LIMIT_ORDER_DELETED"   : action.actionType = .limit_ORDER_DELETED
                                        case "LIMIT_ORDER_FILLED"    : action.actionType = .limit_ORDER_FILLED
                                        case "LIMIT_ORDER_OPENED"    : action.actionType = .limit_ORDER_OPENED
                                        case "LIMIT_ORDER_ROLLED"    : action.actionType = .limit_ORDER_ROLLED
                                        case "POSITION_CLOSED"       : action.actionType = .position_CLOSED
                                        case "POSITION_DELETED"      : action.actionType = .position_DELETED
                                        case "POSITION_OPENED"       : action.actionType = .position_OPENED
                                        case "POSITION_PARTIALLY_CLOSED" : action.actionType = .position_PARTIALLY_CLOSED
                                        case "POSITION_ROLLED"       : action.actionType = .position_ROLLED
                                        case "STOP_LIMIT_AMENDED"    : action.actionType = .stop_LIMIT_AMENDED
                                        case "STOP_ORDER_AMENDED"    : action.actionType = .stop_ORDER_AMENDED
                                        case "STOP_ORDER_DELETED"    : action.actionType = .stop_ORDER_DELETED
                                        case "STOP_ORDER_FILLED"     : action.actionType = .stop_ORDER_FILLED
                                        case "STOP_ORDER_OPENED"     : action.actionType = .stop_ORDER_OPENED
                                        case "STOP_ORDER_ROLLED"     : action.actionType = .stop_ORDER_ROLLED
                                        case "WORKING_ORDER_DELETED" : action.actionType = .working_ORDER_DELETED
                                        default: action.actionType = .unknown
                                        }
                                    }
                                    
                                    if let x = e["affectedDealId"] as? String { action.affectedDealId = x }
                                        
                                    detail.actions.append(action)
                                }
                            }
                            
                            if let x = dict["currency"]      as? String { detail.currency      = x }
                            if let x = dict["dealReference"] as? String { detail.dealReference = x }
                            
                            if let x = dict["direction"]     as? String {
                                switch x {
                                case "BUY":  detail.direction = .buy
                                case "SELL": detail.direction = .sell
                                default: break
                                }
                            }
                            
                            if let x = dict["goodTillDate"]   as? String { detail.goodTillDate   = x }
                            if let x = dict["guaranteedStop"] as? Bool   { detail.guaranteedStop = x }
                            if let x = dict["level"]          as? Double { detail.level          = NSDecimalNumber(value: x as Double) }
                            if let x = dict["limitDistance"]  as? Double { detail.limitDistance  = NSDecimalNumber(value: x as Double) }
                            if let x = dict["limitLevel"]     as? Double { detail.limitLevel     = NSDecimalNumber(value: x as Double) }
                            if let x = dict["marketName"]     as? String { detail.marketName     = x }
                            if let x = dict["size"]           as? Double { detail.size           = x }
                            if let x = dict["stopDistance"]   as? Double { detail.stopDistance   = NSDecimalNumber(value: x as Double) }
                            if let x = dict["stopLevel"]      as? Double { detail.stopLevel      = NSDecimalNumber(value: x as Double) }
                            if let x = dict["trailingStep"]   as? Double { detail.trailingStep   = NSDecimalNumber(value: x as Double) }
                            if let x = dict["trailingStopDistance"] as? Double { detail.trailingStopDistance = NSDecimalNumber(value: x as Double) }
                            
                            a.details.append(detail)
                        }
                        
                        if let x = element["epic"]   as? String { a.epic   = x }
                        if let x = element["period"] as? String { a.period = x }
                        
                        if let x = element["status"] as? String {
                            switch x {
                            case "ACCEPTED": a.status = .accepted
                            case "REJECTED": a.status = .rejected
                            default:         a.status = .unknown
                            }
                        }
                        
                        if let x = element["type"] as? String {
                            switch x {
                            case "EDIT_STOP_AND_LIMIT": a.type = .edit_STOP_AND_LIMIT
                            case "POSITION":            a.type = .position
                            case "SYSTEM":              a.type = .system
                            case "WORKING_ORDER":       a.type = .working_ORDER
                            default: break
                            }
                        }
                        activityHistory.activities.append(a)
                    }
                }
            }
        }
    }
    
    
    func updateMetadata(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGHistoryMetaData {
        let metaData = MSIGBrokerIGHistoryMetaData()
        
        if let x = dict["size"] as? Int { metaData.size = x }
        
        if let p = dict["pageData"] as? Dictionary<String, Any> {
            if let x = p["pageNumber"] as? Int { metaData.pageNumber = x }
            if let x = p["pageSize"]   as? Int { metaData.pageSize   = x }
            if let x = p["totalPages"] as? Int { metaData.totalPages = x }
        }

        return metaData
    }
    
    open func getPreferences() {
        var dict    =  Dictionary<String, Any>()
        dict["url"] = "\(brokerIG.apiUrl)/accounts/preferences" as Any?
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_ACCOUNT_PREFERENCES, version: 1)
    }
    
    open func handleGetPreferences(notification : Notification) {
        preferences = MSIGBrokerAccountPreferences()  // Initialise preferences
        
        let json = brokerIG.extractJson(notification)
        
        switch brokerIG.isError() {
        case true: break
        case false:
            if let x = json["trailingStopsEnabled"] as? Bool {  preferences.trailingStopsEnabled = x  }
        }
    }
    
    func parseDateForIgQuery(_ date : Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date) + "T00:00:00"
    }
    
}
