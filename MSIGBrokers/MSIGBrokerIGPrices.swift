//
//  MSIGBrokerIGPrices.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 15/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGPriceBidAsk {
    open var bid        = 0 as NSDecimalNumber
    open var ask        = 0 as NSDecimalNumber
    open var lastTraded = 0 as NSDecimalNumber
    
    public init() {}
}

open class MSIGBrokerIGPrice {
    open var openPrice  = MSIGBrokerIGPriceBidAsk()
    open var highPrice  = MSIGBrokerIGPriceBidAsk()
    open var lowPrice   = MSIGBrokerIGPriceBidAsk()
    open var closePrice = MSIGBrokerIGPriceBidAsk()
    
    open var lastTradedVolume = 0 as Double
    open var snapshotTime     = ""
    open var snapshotTimeUTC  = ""
    
    public init() {}
}

open class MSIGBrokerIGPrices {
    open var instrumentType = MSIGBrokerIGInstrumentType.UNKNOWN
    open var prices         = Array<MSIGBrokerIGPrice>()
    open var metadata       = MSIGBrokerIGMetaData()    
    
    public init() {}
    
    
    open func resolutions() -> [MSIGBrokerIGPriceResolution]  {
        return [
            MSIGBrokerIGPriceResolution.SECOND,
            MSIGBrokerIGPriceResolution.MINUTE,
            MSIGBrokerIGPriceResolution.MINUTE_2,
            MSIGBrokerIGPriceResolution.MINUTE_3,
            MSIGBrokerIGPriceResolution.MINUTE_5,
            MSIGBrokerIGPriceResolution.MINUTE_10,
            MSIGBrokerIGPriceResolution.MINUTE_15,
            MSIGBrokerIGPriceResolution.MINUTE_30,
            MSIGBrokerIGPriceResolution.HOUR,
            MSIGBrokerIGPriceResolution.HOUR_2,
            MSIGBrokerIGPriceResolution.HOUR_3,
            MSIGBrokerIGPriceResolution.HOUR_4,
            MSIGBrokerIGPriceResolution.DAY,
            MSIGBrokerIGPriceResolution.WEEK,
            MSIGBrokerIGPriceResolution.MONTH
        ]

    }
}
