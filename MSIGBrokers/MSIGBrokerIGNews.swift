//
//  MSIGBrokerIGNews.swift
//  MSIGBrokers
//
//  Created by Matt Stone on 7/05/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGNews {
    let brokerIG   = MSIGBrokerIG.sharedInstance
    
    open var items = [Dictionary<String, Any>()]
    
    open var news  = [Dictionary<String, Any>]()
    open var blogs = [Dictionary<String, Any>]()
    
    public init() {}
    
    open func get(_ codes : [String] = []) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "https://query.yahooapis.com/v1/public/yql?q=select%20title,%20description%20from%20rss%20where%20url%3D%22https%3A%2F%2Ffinance.yahoo.com%2Frss%2Ftopstories%22&format=json&diagnostics=true&callback=" as Any?
        brokerIG.httpGet(dict, notification : brokerIG.config.IG_NEWS_REQUEST)
    }
    
    open func processNewsResponse(_ notification : Notification) {
        if let response = notification.object as? Dictionary<String, Any> {
            if let json = response["json"] as? Dictionary<String, Any> {
                if let query = json["query"] as? Dictionary<String, Any> {
                    if let results = query["results"] as? Dictionary<String, Any> {
                        if let items = results["item"] as? [Dictionary<String, Any>] {
                            self.items = items
                        }
                    }
                }
            }
        }
    }

    open func itemTitle(_ index : Int) -> String {
        if index >= items.count { return "" }
        
        let item = items[index]
        if let x = item["title"] as? String { return x }
        return ""
    }
    
    open func itemDescription(_ index : Int) -> String {
        if index >= items.count { return "" }
        
        let item = items[index]
        if let x = item["description"] as? String { return x }
        return ""
    }
}
