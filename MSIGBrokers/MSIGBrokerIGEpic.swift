//
//  MSIGBrokerIGEpic.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 14/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBrokerIGEpicOrderPointType {
    case level
    case distance
}

open class MSIGBrokerIGEpic  {
    open var dealingRules = MSIGBrokerIGDealingRules()
    open var instrument   = MSIGBrokerIGInstrument()
    open var snapshot     = MSIGBrokerIGSnapshot()
    
    public init() {}

    // Minimums
    
    open func minStopLevel(_ position : MSIGBrokerIGPosition) -> Double {
        
        let direction                    = position.direction
        let minNormalStopOrLimitDistance = dealingRules.minNormalStopOrLimitDistance
        
        switch position.order.stopType {
        case .NONE, .NORMAL:
            switch minNormalStopOrLimitDistance.unit {
            case .PERCENTAGE: return stopPercentageLevel(direction, percent: dealingRules.minNormalStopOrLimitDistance.value)
            case .POINTS:     return stopPointsLevel(direction,     points:  dealingRules.minNormalStopOrLimitDistance.value)
            case .NONE:       return 0
            }
            
        case .GUARANTEED:
            switch dealingRules.minControlledRiskStopDistance.unit {
            case .PERCENTAGE: return stopPercentageLevel(direction, percent: dealingRules.minControlledRiskStopDistance.value)
            case .POINTS:     return stopPointsLevel(direction, points: dealingRules.minControlledRiskStopDistance.value / instrument.lotSize)
            case .NONE:       return 0
            }
        }
    }
    
    open func minLimitLevel(_ direction : MSIGBrokerIGPositionDirection) -> Double {
        let minNormalStopOrLimitDistance = dealingRules.minNormalStopOrLimitDistance
        
        switch minNormalStopOrLimitDistance.unit {
        case .PERCENTAGE: return limitPercentageLevel(direction, percent: dealingRules.minNormalStopOrLimitDistance.value)
        case .POINTS:     return limitPointsLevel(direction,     points:  dealingRules.minNormalStopOrLimitDistance.value)
        case .NONE:       return 0
        }
    }
    
    // Percentage calculations
    
    open func stopPercentageLevel(_ direction : MSIGBrokerIGPositionDirection, percent : Double) -> Double {
        let snapshot       = instrument.snapshot
        
        let buyPercentage  = (100 - percent)/100 as Double
        let sellPercentage = (100 + percent)/100 as Double
        
        switch direction {
        case .buy:  return snapshot.offer.doubleValue * buyPercentage
        case .sell: return snapshot.bid.doubleValue   * sellPercentage
        }
    }
    
    open func limitPercentageLevel(_ direction : MSIGBrokerIGPositionDirection, percent : Double) -> Double {
        let snapshot       = instrument.snapshot
        
        let buyPercentage  = (100 + percent)/100 as Double
        let sellPercentage = (100 - percent)/100 as Double
        
        switch direction {
        case .buy:  return snapshot.offer.doubleValue * buyPercentage
        case .sell: return snapshot.bid.doubleValue   * sellPercentage
        }
    }
    
    // Points calculations
    
    open func stopPointsLevel(_ direction : MSIGBrokerIGPositionDirection, points : Double) -> Double {
        let snapshot  = instrument.snapshot

        switch direction {
        case .buy:  return snapshot.offer.doubleValue - (instrument.onePoint() * points)
        case .sell: return snapshot.bid.doubleValue   + (instrument.onePoint() * points)
        }
    }
    
    open func limitPointsLevel(_ direction : MSIGBrokerIGPositionDirection, points : Double) -> Double {
        let snapshot = instrument.snapshot
        
        switch direction {
        case .buy:  return snapshot.bid.doubleValue   + (instrument.onePoint() * points)
        case .sell: return snapshot.offer.doubleValue - (instrument.onePoint() * points)
        }
    }
    
    // Stop Distance
    
    open func plusPointStop(_ position  : MSIGBrokerIGPosition,
                              pointType : MSIGBrokerIGEpicOrderPointType) -> MSIGBrokerIGPosition {
//        print("*** TODO: plusPointStopLevel: handle maxStopOrLimitDistance")
        
        switch pointType {
        case .level:
            switch position.order.stopLevel == 0 {
            case true:
                switch position.order.direction {
                case .buy:  break
                case .sell: position.order.stopLevel = NSDecimalNumber(value: minStopLevel(position) + (10 * instrument.onePoint()) as Double)
                }
                
            case false:  position.order.stopLevel = NSDecimalNumber(value: position.order.stopLevel.doubleValue + instrument.onePoint() as Double)
            }
        case .distance:
            switch position.order.stopDistance == 0 {
            case true:  position.order.stopDistance = NSDecimalNumber(value: max(dealingRules.minNormalStopOrLimitDistance.value, 10.0) as Double)
            case false: position.order.stopDistance = NSDecimalNumber(value: position.order.stopDistance.doubleValue + 1 as Double)
            }
        }
        
        return applyIGTradingRulesToStopAndLimit(position)
    }
    
    
    open func minusPointStop(_ position  : MSIGBrokerIGPosition,
                               pointType : MSIGBrokerIGEpicOrderPointType) -> MSIGBrokerIGPosition {
        switch pointType {
        case .level:
            switch position.order.stopLevel == 0 {
            case true:
                switch position.order.direction {
                case .buy:  position.order.stopLevel = NSDecimalNumber(value: minStopLevel(position) - (10 * instrument.onePoint()) as Double)
                case .sell: break
                }
            case false: position.order.stopLevel = NSDecimalNumber(value: position.order.stopLevel.doubleValue - instrument.onePoint() as Double)
            }
        case .distance:
            switch position.order.stopDistance == 0 {
            case true:  break
            case false: position.order.stopDistance = NSDecimalNumber(value: position.order.stopDistance.doubleValue - 1 as Double)
            }
        }
        
        return applyIGTradingRulesToStopAndLimit(position)
    }
    
    // LimitLevel
    
    open func plusPointLimit(_ position  : MSIGBrokerIGPosition,
                               pointType : MSIGBrokerIGEpicOrderPointType) -> MSIGBrokerIGPosition {
        switch pointType {
        case .level:
            switch position.order.limitLevel == 0 {
            case true:
                switch position.order.direction {
                case .buy:  position.order.limitLevel = NSDecimalNumber(value: minLimitLevel(position.order.direction) + (10 * instrument.onePoint()) as Double)
                case .sell: break
                }
            case false: position.order.limitLevel = NSDecimalNumber(value: position.order.limitLevel.doubleValue + instrument.onePoint() as Double)
            }
        case .distance:
            switch position.order.limitDistance == 0 {
            case true:  position.order.limitDistance = NSDecimalNumber(value: max(dealingRules.minNormalStopOrLimitDistance.value, 10.0) as Double)
            case false: position.order.limitDistance = NSDecimalNumber(value: position.order.limitDistance.doubleValue + 1 as Double)
            }
        }

        return applyIGTradingRulesToStopAndLimit(position)
    }
    
    open func minusPointLimit(_ position  : MSIGBrokerIGPosition,
                                pointType : MSIGBrokerIGEpicOrderPointType) -> MSIGBrokerIGPosition {
        switch pointType {
        case .level:
            switch position.order.limitLevel == 0 {
            case true:
                switch position.order.direction {
                case .buy:  break
                case .sell: position.order.limitLevel = NSDecimalNumber(value: minLimitLevel(position.order.direction) - (10 * instrument.onePoint()) as Double)
                }
            case false:
                 position.order.limitLevel = NSDecimalNumber(value: position.order.limitLevel.doubleValue - instrument.onePoint() as Double)
            }
            
        //                return dealingRules.minNormalStopOrLimitDistance.value - 10
        case .distance:
            switch position.order.limitDistance == 0 {
            case true:  break
            case false: position.order.limitDistance = NSDecimalNumber(value: position.order.limitDistance.doubleValue - 1 as Double)
            }
        }
        
        return applyIGTradingRulesToStopAndLimit(position)
    }
    
    open func convertLevelToDistance(_ fromLevel : Double, toLevel : Double) -> Int {
//        print("    convertLevelToDistance: 1: \(fromLevel) : \(toLevel)")
        
        let distance = abs(fromLevel - toLevel)
//        print("    convertLevelToDistance: 2: \(distance)")
//        print("    convertLevelToDistance: 3: \(onePoint())")
//        let x = Int(distance / onePoint())
//        let y = Int(distance * onePoint())
//        print("    convertLevelToDistance: 4: \(x)")
//        print("    convertLevelToDistance: 5: \(y)")
        return Int(distance / instrument.onePoint())
    }
    
    open func convertDistanceToStopLevel(_ position : MSIGBrokerIGPosition, level : Double, distance : Int) -> Double {
        let points = Double(distance) * instrument.onePoint()
        
        switch position.order.direction {
        case .buy:  return level - points
        case .sell: return level + points
        }
    }

    open func convertDistanceToLimitLevel(_ position : MSIGBrokerIGPosition, level : Double, distance : Int) -> Double {
        let points = Double(distance) * instrument.onePoint()
        
        switch position.order.direction {
        case .buy:  return level + points
        case .sell: return level - points
        }
    }
    
    open func applyIGTradingRulesToStopAndLimit(_ position : MSIGBrokerIGPosition) -> MSIGBrokerIGPosition {
        let minStop  = minStopLevel(position)
        let minLimit = minLimitLevel(position.order.direction)

//        print("*** TODO cater for max limit & distance")
        
        // *** Stop Level
        
        switch position.order.stopLevel.doubleValue > 0 {
        case true:
            position.order.stopDistance = 0  // Can only have stopLevel or stopDistance
            
            switch position.order.direction {
            case .buy:
                switch position.order.stopLevel.doubleValue > minStop {
                case true:  position.order.stopLevel = 0
                case false: break
                }
            case .sell:
                switch position.order.stopLevel.doubleValue < minStop {
                case true:  position.order.stopLevel = 0
                case false: break
                }
            }
        case false: break
        }
        
        // *** Stop Distance
        
        switch position.order.stopDistance.doubleValue > 0 {
        case true:
            position.order.stopLevel = 0 // Can only have stopLevel or stopDistance
            
            switch position.order.stopType {
            case .NONE, .NORMAL:
                switch Int(position.order.stopDistance) < Int(dealingRules.minNormalStopOrLimitDistance.value) {
                case true: position.order.stopDistance = 0
                case false: break
                }
                
            case .GUARANTEED:
                switch Int(position.order.stopDistance) < Int(dealingRules.minControlledRiskStopDistance.value) {
                case true: position.order.stopDistance = 0
                case false: break
                }
            }
        case false: break
        }
        
        // *** Limit Level
        
        switch position.order.limitLevel.doubleValue > 0 {
        case true:
            position.order.limitDistance = 0 // Can only have one limitLevel or limitDistance
            
            switch position.order.direction {
            case .buy:
                switch position.order.limitLevel.doubleValue < minLimit {
                case true:  position.order.limitLevel = 0
                case false: break
                }
            case .sell:
                switch position.order.limitLevel.doubleValue > minLimit {
                case true:  position.order.limitLevel = 0
                case false: break
                }
            }
        case false: break
        }
        
        // *** Limit Distance
        
        switch position.order.limitDistance.doubleValue > 0 {
        case true:
            position.order.limitLevel = 0 // Can only have one limitLevel or limitDistance
            
            let diff = Int((minLimit - position.instrument.snapshot.bid.doubleValue) * position.instrument.lotSize)
            
            switch Int(position.order.limitDistance.int32Value) < diff {
            case true:  position.order.limitDistance = 0
            case false: break
            }
        case false: break
        }
    
        return position
    }
    
// Only one version of this 
//    open func onePoint() -> Double {
//        
//        switch instrument.type {
//        case .CURRENCIES:
//            switch instrument.currencyCode() {
//            case "JPY": return 0.001
//            default: break
//            }
//        default: break
//        }
//        
//        return Double(1.0 / Double(instrument.contractSize))
//    }

}
