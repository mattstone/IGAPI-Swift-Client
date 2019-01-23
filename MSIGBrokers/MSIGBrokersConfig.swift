//
//  IGApiConfig.swift
//  IGApi
//
//  Created by Matt Stone on 2/04/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

extension Double {
    var cleanValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}


// Singleton - replaced with..global variable as recommended by Apple..



struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

open class MSIGBrokersConfig : NSObject {
    
    
    public static let sharedInstance = MSIGBrokersConfig()
    // *** Start Notification Constants ***
    
    open let IG_SEND_TO_SIGNUP         = "IG_SEND_TO_SIGNUP"
    open let IG_VIDEO_1                = "IG_VIDEO_ONE"
    open let IG_HTTP_LOGIN             = "IG_HTTP_LOGIN"
    open let IG_HTTP_LOGOUT            = "IG_HTTP_LOGOUT"
    open let IG_OAUTH2_CONNECT         = "IG_OAUTH2_CONNECT"
    open let IG_SESSION_GET            = "IG_SESSION_GET"
    open let IG_ACCOUNTS               = "IG_ACCOUNTS"
    open let IG_ACCOUNT_SETTINGS       = "IG_ACCOUNT_SETTINGS"
    open let IG_ACCOUNT_SETTINGS_UPDATE = "IG_ACCOUNT_SETTINGS_UPDATE"
    open let IG_ACCOUNT_HISTORY        = "IG_ACCOUNT_HISTORY"
    open let IG_ACCOUNT_TRANSACTION_HISTORY = "IG_ACCOUNT_TRANSACTION_HISTORY"
    open let IG_ACCOUNT_ACTIVITY_HISTORY    = "IG_ACCOUNT_ACTIVITY_HISTORY"
    open let IG_ACCOUNT_PREFERENCES    = "IG_ACCOUNT_PREFERENCES"
    open let IG_APPLICATION_SETTINGS   = "IG_APPLICATION_SETTINGS"
    open let IG_APPLICATION_SETTINGS_UPDATE = "IG_APPLICATION_SETTINGS_UPDATE"
    open let IG_MARKET_NAVIGATION      = "IG_MARKET_NAVIGATION"
    open let IG_MARKET_NAVIGATION_HIERARCHY = "IG_MARKET_NAVIGATION_HIERARCHY"
    open let IG_MARKET_EPIC            = "IG_MARKET_EPIC"
    open let IG_MARKET_SEARCH          = "IG_MARKET_SEARCH"
    open let IG_PRICES                 = "IG_PRICES"
    
    open let IG_HISTORY                = "IG_HISTORY"
    open let IG_WATCHLISTS_SHOW        = "IG_WATCHLISTS_SHOW"
    open let IG_WATCHLIST_CREATE       = "IG_WATCHLIST_CREATE"
    open let IG_WATCHLIST_DELETE       = "IG_WATCHLIST_DELETE"
    open let IG_WATCHLIST_INSTRUMENT_CREATE = "IG_WATCHLIST_INSTRUMENT_CREATE"
    open let IG_WATCHLIST_INSTRUMENT_SHOW   = "IG_WATCHLIST_INSTRUMENT_SHOW"
    open let IG_WATCHLIST_INSTRUMENT_DELETE = "IG_WATCHLIST_INSTRUMENT_DELETE"
    open let IG_WATCHLIST_SUBSCRIBE_PRICES  = "IG_WATCHLIST_SUBSCRIBE_PRICES"
    open let IG_WATCHLIST_SUBSCRIBE_PRICES_CONVERSION  = "IG_WATCHLIST_SUBSCRIBE_PRICES_CONVERSION"
    open let IG_POSITIONS_SHOW         = "IG_POSITIONS_SHOW"
    open let IG_POSITION_CREATE        = "IG_POSITION_CREATE"
    open let IG_POSITION_UPDATE        = "IG_POSITION_UPDATE"
    open let IG_POSITION_DELETE        = "IG_POSITION_DELETE"
    open let IG_DEAL_CONFIRM           = "IG_DEAL_CONFIRM"
    
    open let IG_MARKET_SENTIMENT         = "IG_MARKET_SENTIMENT"
    open let IG_MARKET_SENTIMENT_RELATED = "IG_MARKET_SENTIMENT_RELATED"
    
    open let IG_NEWS_REQUEST           = "IG_NEWS_REQUEST"
    
    // IG Streaming
    
    open let IG_STREAMING_CONNECT      = "IG_STREAMING_CONNECT"
    open let IG_STREAMING_ACCOUNT      = "IG_STREAMING_ACCOUNT"
    open let IG_STREAMING_ACCOUNT_UI_UPDATE   = "IG_STREAMING_ACCOUNT_UI_UPDATE"
    open let IG_STREAMING_EPIC         = "IG_STREAMING_EPIC"
    open let IG_STREAMING_CHART_TICK   = "IG_STREAMING_CHART_TICK"
    open let IG_STREAMING_CHART_CANDLE = "IG_STREAMING_CHART_CANDLE"
    open let IG_STREAMING_TRADE_NOTIFICATIONS = "IG_STREAMING_TRADE_NOTIFICATIONS"
    
    open let IG_STREAMING_UNSUBSCRIBE         = "IG_STREAMING_UNSUBSCRIBE"
    open let IG_STREAMING_UNSUBSCRIBE_ALL     = "IG_STREAMING_UNSUBSCRIBE_ALL"
    open let IG_STREAMING_LOGOUT              = "IG_STREAMING_LOGOUT"
    open let IG_STREAMING_DISCONNECTED        = "IG_STREAMING_DISCONNECTED"
    
    open let IG_STREAMING_SUBSCRIPTION_ERROR  = "IG_STREAMING_SUBSCRIPTION_ERROR"
    
    open let TS_REAUTHENTICATE_USER_IG        = "TS_REAUTHENTICATE_USER_IG"
    
    // Error constants
    
    open let CouldNotUnderstandResponseFromServer = "CouldNotUnderstandResponseFromServer"
    open let NoConnectionMessage = "There was network problem. Please check your connection."
    open let UnknownError        = "An unknown problem was experienced. Please try again later."
    
    // Tests
    open var testStatus  = 0
    open var testsTotal  = 0
    open var testsPassed = 0
    open var testsFailed = 0
    
    // Network
    open var isNetwork = false
    open var isWan     = false
    open var isWiFi    = false
    
    open var nc        = NotificationCenter.default
    
    open var isDebug   = false
    
    // *** Start archive directory
    
    func fileDocumentDirURL(_ fileName: String) -> URL {
        let manager = FileManager.default
        let dirURL: URL?
        do {
            dirURL = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch _ {
            dirURL = nil
        }
        return dirURL!.appendingPathComponent(fileName)
    }
    
    // *** End archive directory
    
    open func tsDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }
}
