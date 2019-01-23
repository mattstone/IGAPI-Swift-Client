//
//  MSIGBrokerIGWatchlists.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 16/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

@objc open class MSIGBrokerIGWatchlist : NSObject {
    let config                       = MSIGBrokersConfig.sharedInstance
    let brokerIG                     = MSIGBrokerIG.sharedInstance
    
    open var defaultSystemWatchList  = false
    open var deleteable              = false
    open var editable                = false
    open var id                      = ""
    open var name                    = ""
    open var instruments             = [MSIGBrokerIGInstrument]()
    
    public override init() {}
    
    open func subscribePrices() -> LSSubscription {
        var epicArray = Array<String>()
        for instrument in instruments { epicArray.append(instrument.epic) }
        return brokerIG.ls.subscribeEpic(epicArray, notifier: config.IG_WATCHLIST_SUBSCRIBE_PRICES)
    }
    
    open func processSubscribePrices(_ updateInfo : LSItemUpdate) {
        
        let epic = brokerIG.ls.extractEpic(updateInfo.itemName!)
        
        for instrument in instruments {
            switch epic {
            case instrument.epic: instrument.snapshot.updateFromStreamingMarket(updateInfo)
            default: break
            }
        }
    }
}

public enum MSIGBrokerIGWatchlistsCreateStatus : String {
    case SUCCESS = "Success"
    case SUCCESS_NOT_ALL_INSTRUMENTS_ADDED = "Success not all instruments added"
}

public let TSSharedBrokerIGWatchlists = MSIGBrokerIGWatchlists()

open class MSIGBrokerIGWatchlists {
    
    let config          = MSIGBrokersConfig.sharedInstance
    let includes        = MSIGBrokersIncludes.sharedInstance
    open let brokerIG   = MSIGBrokerIG.sharedInstance
    open var watchlists = [MSIGBrokerIGWatchlist]()
    
    open var createStatus = MSIGBrokerIGWatchlistsCreateStatus.SUCCESS
    open var createId     = ""
    
    open func isError()            -> Bool   { return brokerIG.isError()            }
    open func simpleErrorMessage() -> String { return brokerIG.simpleErrorMessage() }
    
    public init() {}
    
    open func show() {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/watchlists" as Any?
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_WATCHLISTS_SHOW)
    }
    
    open func handleShowResponse(_ notification : Notification) {
        watchlists.removeAll()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let array = json["watchlists"] as? Array<Dictionary<String, Any>> {
                        for element in array {
                            let watchlist = MSIGBrokerIGWatchlist()
                            if let x = element["defaultSystemWatchlist"] as? Bool   { watchlist.defaultSystemWatchList = x }
                            if let x = element["deleteable"]             as? Bool   { watchlist.deleteable             = x }
                            if let x = element["editable"]               as? Bool   { watchlist.editable               = x }
                            if let x = element["id"]                     as? String { watchlist.id                     = x }
                            if let x = element["name"]                   as? String { watchlist.name                   = x }
                            watchlists.append(watchlist)
                        }
                        return
                    }
                }
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    open func create(_ name : String, epics : Array<String> = []) {
        
        let param = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/watchlists" as Any?

        dict["parameters"] = ["name"  : param!,
                              "epics" : epics]
        brokerIG.httpPost(dict, notification : brokerIG.config.IG_WATCHLIST_CREATE)
    }
    
    open func handleCreateResponse(_ notification : Notification) {
        createId = ""
        
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let x = json["status"] as? String {
                    switch x {
                    case "SUCCESS":                           createStatus = .SUCCESS
                    case "SUCCESS_NOT_ALL_INSTRUMENTS_ADDED": createStatus = .SUCCESS_NOT_ALL_INSTRUMENTS_ADDED
                    default: break
                    }
                }
                
                if let x = json["watchlistId"] as? String { createId = x }
                return
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    // Delete
    
    open func delete(_ id : String) {
        let param = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/watchlists/\(param!)" as Any?
        brokerIG.httpDeleteIG(dict, notification : brokerIG.config.IG_WATCHLIST_DELETE)
    }
    
    open func handleDeleteResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)

            if let json = dict["json"] as? Dictionary<String, Any> {
                if let _ = json["status"] as? String { return }  // Status is always "SUCCESS"
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    // Instruments
    
    open func createInstrument(_ id : String, epic : String) {
        
        let param = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/watchlists/\(param!)" as Any?
        dict["parameters"] = ["epic" : epic]
        brokerIG.httpPut(dict, notification : brokerIG.config.IG_WATCHLIST_INSTRUMENT_CREATE)
    }
    
    open func handleCreateInstrumentResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let _ = json["status"] as? String {
                    return }  // Status is always "SUCCESS"
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    
    // TODO: move to watchlist model
    open func showInstruments(_ id : String) {

        let param = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)

        var dict    =  Dictionary<String, Any>()
        dict["url"] = "\(brokerIG.apiUrl)/watchlists/\(param!)" as Any?
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_WATCHLIST_INSTRUMENT_SHOW, version: 1)
    }
    
    open func handleShowInstrumentsResponse(_ id : String, notification : Notification) {
        
        // Note: Popular Markets is a hard coded IG watchlist
        
        switch id == "Popular Markets" {
        case true:
            
            let watchlist = MSIGBrokerIGWatchlist()
            
            if let dict = notification.object as? Dictionary<String, Any> {
                brokerIG.processResponseForErrors(dict)
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let markets = json["markets"] as? Array<Dictionary<String, Any>> {
                        for market in markets {
                            let instrument      = brokerIG.extractInstrument(market)
                            instrument.snapshot = brokerIG.extractSnapshot(market)
                            watchlist.instruments.append(instrument)
                        }
                        watchlist.id = id
                        self.setWatchlist(watchlist)
                        return
                    }
                }
            }
            if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
            
        case false:
            let watchlist = getWatchlist(id)
            
            if watchlist == nil {
                brokerIG.addErrorObject("", description : "Unknown watchlist", code : "")
            } else {
                watchlist?.instruments.removeAll()
                
                if let dict = notification.object as? Dictionary<String, Any> {
                    brokerIG.processResponseForErrors(dict)
                    if let json = dict["json"] as? Dictionary<String, Any> {
                        
                        if let array = json["markets"] as? Array<Dictionary<String, Any>> {
                            for element in array {
                                let instrument      = brokerIG.extractInstrument(element)
                                instrument.snapshot = brokerIG.extractSnapshot(element)
                                watchlist?.instruments.append(instrument)
                            }
                            setWatchlist(watchlist!)
                            return
                        }
                    }
                }
            }
            if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
        }
    }
    
    
    open func getWatchlist(_ id : String) -> MSIGBrokerIGWatchlist! {
        includes.debugPrint(any: "brokerIG.getWatchlist: \(id)")
        includes.debugPrint(any: "brokerIG.getWatchlist: \(watchlists)")
        
        for watchlist in watchlists {
            includes.debugPrint(any: "  \(watchlist.id) : \(id)")
            if watchlist.id == id { return watchlist }
        }
        return nil
    }

    open func setWatchlist(_ watchlist : MSIGBrokerIGWatchlist) {
        var index = 0
        for element in watchlists {
            if watchlist.id == element.id { watchlists.remove(at: index) }
            index += 1
        }
        watchlists.append(watchlist)
    }
    
    open func deleteInstrument(_ id : String, epic : String) {
        
        let param = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(brokerIG.apiUrl)/watchlists/\(param!)/\(epic)" as Any?
        brokerIG.httpDeleteIG(dict, notification : brokerIG.config.IG_WATCHLIST_INSTRUMENT_DELETE)
    }
    
    open func handleDeleteInstrumentResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            brokerIG.processResponseForErrors(dict)
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let _ = json["status"] { return }   // status is always Success, errors returned as API errors.
            }
        }
        if !isError() { brokerIG.addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
}
