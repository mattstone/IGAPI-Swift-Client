//
//  MSIGBrokerIGInstrument.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGClientSentiment {
    open var longPositionPercentage  = 0 as Double
    open var shortPositionPercentage = 0 as Double
    open var marketId                = ""
}

open class MSIGBrokerIGLimitedRiskPremium {
    open var value : Double = 0
    open var unit  : MSIGBrokerIGDealingRuleUnit = .NONE
}

open class MSIGBrokerIGExpiryDetails {
    var lastDealingDate = ""
    var settlementInfo  = ""
}

public enum MSIGBrokerIGInstrumentUnit : String {
    case CONTRACTS = "Contracts"
    case AMOUNT    = "Amount"
    case SHARES    = "Shares"
}

public enum MSIGBrokerIGInstrumentMarginFactorUnit : String {
    case PERCENTAGE = "Percentage"
    case POINTS     = "Points"
}

public enum MSIGBrokerIGInstrumentType : String {
    case BINARY             = "Binaries"
    case BUNGEE_CAPPED      = "Capped bungees"
    case BUNGEE_COMMODITIES	= "Commodity bungees"
    case BUNGEE_CURRENCIES	= "Currency bungees"
    case BUNGEE_INDICES	    = "Index bungees"
    case COMMODITIES	    = "Commodities"
    case CURRENCIES	        = "Currencies"
    case INDICES	        = "Indices"
    case OPT_COMMODITIES	= "Commodity options"
    case OPT_CURRENCIES  	= "Currency options"
    case OPT_INDICES	    = "Index options"
    case OPT_RATES	        = "FX options"
    case OPT_SHARES	        = "Share options"
    case RATES	            = "Rates"
    case SECTORS	        = "Sectors"
    case SHARES	            = "Shares"
    case SPRINT_MARKET	    = "Sprint Market"
    case TEST_MARKET	    = "Test market"
    case UNKNOWN	        = "Unknown"
}


public enum MSIGBrokerIGInstrumentStatus : String {
    case CLOSED	             = "Closed"
    case EDITS_ONLY	         = "Open for edits"
    case OFFLINE	         = "Offline"
    case ON_AUCTION	         = "In auction mode"
    case ON_AUCTION_NO_EDITS = "In no-edits mode"
    case SUSPENDED	         = "Suspended"
    case TRADEABLE	         = "Open for trades"
    case UNKNOWN             = "Unknown"
}

open class MSIGBrokerIGInstrument {
    
    let brokerIG           = MSIGBrokerIG.sharedInstance

    open var name          = ""
    open var type          = MSIGBrokerIGInstrumentType.UNKNOWN
    open var status        = MSIGBrokerIGInstrumentStatus.UNKNOWN
    
    open var snapshot      = MSIGBrokerIGSnapshot()
    let includes           = MSIGBrokersIncludes.sharedInstance
    
    open var chartCode     = ""
    open var contractSize  = 0 as Int
    open var country       = ""
    
    open var epic          = ""
    open var expiry        = ""
    open var expiryDetails = MSIGBrokerIGExpiryDetails()
    open var marketId      = ""
    open var newsCode      = ""
    open var onePipMeans   = ""
    open var valueOfOnePip = ""
    
    open var forceOpenAllowed   = false
    open var stopsLimitsAllowed = false
    
    open var lotSize    = 0 as Double
    open var unit       = MSIGBrokerIGInstrumentUnit.CONTRACTS
    
    open var controlledRiskAllowed    = true
    open var streamingPricesAvailable = false
    
    open var currencies         = Array<MSIGBrokerIGCurrency>()
    
    open var marginDepositBands = Array<MSIGBrokerIGMarginDepositBand>()
    open var marginFactor       = 0 as Double
    open var marginFactorUnit   = MSIGBrokerIGInstrumentMarginFactorUnit.PERCENTAGE
    open var limitedRiskPremium = MSIGBrokerIGLimitedRiskPremium()
    open var openingHours       = Array<Dictionary<String, Any>>()
    open var rolloverDetails    = Array<MSIGBrokerIGRolloverDetail>()
    open var slippageFactor     = MSIGBrokerIGSlippageFactor()
    open var specialInfo        = Array<String>()
    open var sprintMarketsMaximumExpiryTime = 0 as Double
    open var sprintMarketsMinimumExpiryTime = 0 as Double
    open var otcTradeable       = false // True if OTC tradeable tradeable & client holds the necessary access permissions
    
    open var marketSentiment    : MSIGBrokerIGClientSentiment!

    public init() {}
    
    open func extractSymbolFromEpic() -> String {
        if epic.isEmpty { return "" }
        let array       = epic.components(separatedBy: ".")
        if array.count != 5 { return "" }
        
//        switch array[3].uppercaseString {
//        case "MINI": return "\(array[2]) \(array[3])"
//        default:     return array[2]
//        }
        return array[2]
    }
    
    open func isEpicMini() -> Bool {
        if epic.isEmpty { return false }
        if epic.range(of: ".MINI.") != nil { return true }
        return false
    }
    
    open func displayPrice(_ price : NSDecimalNumber) -> String {
        switch type {
        case .CURRENCIES:
            let symbol = extractSymbolFromEpic().uppercased()
            
            switch symbol.range(of: "JPY") {
            case nil: return price.rounding(accordingToBehavior: includes.decimalNumberHandler(6)).stringValue
            //default:  return price.decimalNumberByRoundingAccordingToBehavior(includes.decimalNumberHandler(4)).stringValue
            default:  return price.rounding(accordingToBehavior: includes.decimalNumberHandler(6)).stringValue
            }
        default:      return price.rounding(accordingToBehavior: includes.decimalNumberHandler(4)).stringValue
        }
    }
    
//    open func currencyCode() -> String {
//        for currency in currencies { return currency.code }
//        return ""
//    }
    
    open func defaultCurrencyCode() -> String {
        for currency in currencies {
            includes.debugPrint("CURRENCY IS DEFAULT: \(currency.isDefault)")
            includes.debugPrint("CURRENCY CODE IS: \(currency.code)")
            if currency.isDefault { return currency.code }
        }
        return ""
    }
    
    open func isCurrencyJPY() -> Bool {
        for currency in currencies {
            if currency.code.uppercased() == "JPY" { return true }
        }
        return false
    }
    
    open func displayMargin() -> String {
        for marginDepositBand in marginDepositBands { return "\(marginDepositBand.margin) %" }
        return ""
    }
    
    open func calcFaceValue(_ position : MSIGBrokerIGPosition) -> Double {
        if position.order.size.isNaN              {
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: ORDER SIZE IS NAN")
            return 0 }
        if position.order.level.doubleValue.isNaN {
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: ORDER LEVEL IS NAN")
            return 0 }
        if snapshot.bid.doubleValue.isNaN         {
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: SNAP BID IS NAN")
            return 0 }
        if snapshot.offer.doubleValue.isNaN       {
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: SNAP OFFER IS NAN")
            return 0 }
        
        //includes.debugPrint(any: "THE DEAL TYPE IS: \(position.order.dealingType)")
        switch position.order.dealingType {
        case .otc:
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: ORDER SIZE:          \(position.order.size)")
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: CHART CONTRACT SIZE: \(contractSize)")
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcFaceValue: SNAP BID:            \(snapshot.bid.doubleValue)")
            
            switch position.direction {
            case .buy:  return Double(position.order.size) * Double(contractSize) * snapshot.bid.doubleValue
            case .sell: return Double(position.order.size) * Double(contractSize) * snapshot.offer.doubleValue
            }
            
        case .workingOrder:  return Double(position.order.size) * Double(contractSize) * Double(position.order.level.doubleValue)
        }
    }
    
    
    
//    open func calcTradeMargin(_ position: MSIGBrokerIGPosition) -> String {
//        
////        public var currency = "" // The currency for this currency band factor calculation
////        public var margin   = 0 as Double // Margin Percentage
////        public var max      = 0 as Double // Band maximum
////        public var min      = 0 as Double // Band minimum
//        
//        let faceValue = calcFaceValue(position)
//        includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: 1: faceValue: \(faceValue)")
//        var tradeMargin         = 0 as Double
//        let numberOfContracts   = Double(position.order.size)
//        let valuePerPoint       = NSDecimalNumber(string: valueOfOnePip).doubleValue
//        if position.order.guaranteedStop {
//            includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: 2: ITS A GUARANTEED STOP")
//            // This is still incorrect as we need to add the varying points premium
//            var toLevel : Double = 0
//            switch position.order.dealingType {
//            case .otc:
//                if position.order.stopDistance.doubleValue > 0 {
//                    return numberOfContracts * valuePerPoint * position.order.stopDistance.doubleValue
//                }
//                else {
//                    toLevel = Double(position.order.stopLevel)
//                }
//                includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: 3: toLevel: \(toLevel)")
//            case .workingOrder:
//                switch position.order.direction {
//                case .buy:
//                    toLevel = Double(position.order.level) - Double(position.order.stopDistance) * onePoint()
//                    
//                case .sell:
//                    toLevel = Double(position.order.stopDistance) - Double(position.order.level) * onePoint()
//
//                }
//            }
//            tradeMargin = numberOfContracts * valuePerPoint * (Double(convertLevelToDistance(Double(position.order.level), toLevel: toLevel)) + limitedRiskPremium.value)
//            includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: tradeMargin: \(tradeMargin)")
//        } else {
//            for band in marginDepositBands {
//                switch numberOfContracts > band.min {
//                case true:
//                    let marginPercent = (numberOfContracts - band.min) / numberOfContracts
//                    includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: marginPercent: \(marginPercent)")
//                    includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: band.margin: \(band.margin)")
//                    tradeMargin      += (faceValue * marginPercent) * (band.margin/100)
//                case false: break
//                }
//            }
//        }
//        includes.debugPrint(any: "MSIGBrokerIGInstrumen.calcTradeMargin: tradeMargin: \(tradeMargin)")
//        var marginString : String!
//        if isCurrencyJPY() { marginString = tradeMargin.doubleToDecimal(places: 0) }
//        else               { marginString = tradeMargin.doubleToDecimal(places: 2) }
//        return marginString
//    }
    
    open func calcLeverage(_ position : MSIGBrokerIGPosition) -> Double! {
        includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 1:")
        
        var leverage  : Double!
        var contracts = Double(position.order.size)
        
        //This defaults number of contracts to 0, if the position hasnt been given an order size yet.
        if contracts == 0 { contracts = 1 }
        
        includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 2: contacts: \(contracts)")
        
        includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 3: marginDepositBands.count: \(marginDepositBands.count)")
        
        for band in marginDepositBands {
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 4: band.min: \(band.min)")
            includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 5: band.max: \(band.max)")
            if contracts > band.min && contracts < band.max {
                //includes.debugPrint(any: "THE BAND MARGIN IS: \(band.margin)")
                leverage = 100 / band.margin
            }
        }
        if leverage != nil { return Double(leverage) }
        includes.debugPrint(any: "MSIGBrokerIGInstrument.calcLeverage: 6")
        return nil
    }
    
    open func avgTradeMargin(_ position : MSIGBrokerIGPosition) -> Double {
        var marginPercent = 0 as Double
        var bands       = 0 as Int
        let contracts   = Double(position.order.size)
        
        for band in marginDepositBands {
            switch contracts > band.min {
            case true:
                bands         += 1
                marginPercent += band.margin
//                marginPercent += (contracts - band.min) / contracts
                includes.debugPrint(any: "band: \(bands): \(marginPercent)")
            case false: break
            }
        }
        
//        includes.debugPrint(any: "avgTradeMargin")
//        includes.debugPrint(any: "  marginPercent: \(marginPercent)")
//        includes.debugPrint(any: "  bands: \(bands)")
        
        return marginPercent / Double(bands)
    }
    
    open func convertLevelToDistance(_ fromLevel : Double, toLevel : Double) -> Double {
        let distance = abs(fromLevel - toLevel)
        return distance / onePoint()
    }
    
    open func convertDistanceToLevel(_ distance: Double) -> Double {
        return distance * onePoint()
    }
    
    // TODO: this may not be right
    open func onePoint() -> Double {
        includes.debugPrint(any: "BROKERS: ONE POINT: ONE PIP MEANS: \(onePipMeans)")
        return NSDecimalNumber(string: onePipMeans).doubleValue
    }
    
    open func getMarketSentiment() {
        brokerIG.clientSentimentMarket(marketId)
    }
    
    open func handleMarketSentimentResponse(_ notification : Notification) {
        marketSentiment = brokerIG.handleClientSentimentMarketResponse(notification)
    }
    
    // isStatus
    open func isStatusClosed()           -> Bool { return status == .CLOSED        }
    open func isStatusEditsOnly()        -> Bool { return status == .EDITS_ONLY    }
    open func isStatusOffline()          -> Bool { return status == .OFFLINE       }
    open func isStatusOnAuction()        -> Bool { return status == .ON_AUCTION    }
    open func isStatusOnAuctionNoEdits() -> Bool { return status == .ON_AUCTION_NO_EDITS }
    open func isStatusSuspended()        -> Bool { return status == .SUSPENDED     }
    open func isStatusTradeble()         -> Bool { return status == .TRADEABLE     }
    open func isStatusUnknown()          -> Bool { return status == .UNKNOWN       }
    
    // isType
    open func isTypeBinary()             -> Bool { return type == .BINARY          }
    open func isTypeBungyCapped()        -> Bool { return type == .BUNGEE_CAPPED   }
    open func isTypeBungyCommodities()   -> Bool { return type == .BUNGEE_COMMODITIES }
    open func isTypeBungyCurrencies()    -> Bool { return type == .BUNGEE_CURRENCIES  }
    open func isTypeBungyIndicies()      -> Bool { return type == .BUNGEE_INDICES  }
    open func isTypeCommodities()        -> Bool { return type == .COMMODITIES     }
    open func isTypeCurrencies()         -> Bool { return type == .CURRENCIES      }
    open func isTypeIndicies()           -> Bool { return type == .INDICES         }
    open func isTypeOptionCommodities()  -> Bool { return type == .OPT_COMMODITIES }
    open func isTypeOptionCurrencies()   -> Bool { return type == .OPT_CURRENCIES  }
    open func isTypeOptionIndicies()     -> Bool { return type == .OPT_INDICES     }
    open func isTypeOptionRates()        -> Bool { return type == .OPT_RATES       }
    open func isTypeOptionShares()       -> Bool { return type == .OPT_SHARES      }
    open func isTypeRates()              -> Bool { return type == .RATES           }
    open func isTypeSectors()            -> Bool { return type == .SECTORS         }
    open func isTypeShares()             -> Bool { return type == .SHARES          }
    open func isTypeSprintMarket()       -> Bool { return type == .SPRINT_MARKET   }
    open func isTypeTestMarket()         -> Bool { return type == .TEST_MARKET     }
    open func isTypeUnknown()            -> Bool { return type == .UNKNOWN         }
    
}
