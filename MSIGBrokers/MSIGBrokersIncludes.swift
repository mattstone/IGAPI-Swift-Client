//
//  IGApiIncludes.swift
//  IGApi
//
//  Created by Matt Stone on 2/04/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

import SystemConfiguration



open class MSIGBrokersIncludes : NSObject {
    
    
    public static let sharedInstance = MSIGBrokersIncludes()
    
    let config           = MSIGBrokersConfig.sharedInstance
    
    // Start - User progress  TODO: move to user model
    
    // delay
    func delay(_ delay: Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
        )
    }
    
    // General stuff
    
    func urlEncode(_ string : String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    func trimWhiteSpace(_ string: String) -> String {
        return string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func removeWhiteSpaces(_ string: String) -> String {
        //return string.replacingOccurrences(of: " ", with: "")
        return string.components(separatedBy: .whitespaces).joined(separator: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func stringWithOnlyNumber(_ string: String) -> String {
        var result : String = "" as String
        let digits = CharacterSet.decimalDigits
        
        for char in string.unicodeScalars {
            if digits.contains(UnicodeScalar(char.value)!) { result = "\(result)\(char)" }
        }
        return result
    }
    
    func doubleFromAnyObject(_ anyObject : Any) -> Double {
        var double = 0.00 as Double
        
        if let s = anyObject as? NSString {
            double = s.doubleValue
        } else if let f = anyObject as? Float {
            double = Double(f)
        }
        
        return double
    }
    
    func stringFromAnyObject(_ anyObject : Any) -> String {
        var string = ""
        if let s = anyObject as? String { string = s }
        return string
    }
    
    // Date conversion
    func dateStringToUTC(_ string : String) -> Date {
        let dateFormater : DateFormatter = DateFormatter()
        dateFormater.dateFormat = "yyyy:MM:dd-HH:mm:ss"      // date is in this format
        let date : Date? = dateFormater.date(from: string)
        return dateToUTC(date!)
    }
    
    func igDateToNSDate(_ dateString: String) -> (Date) {
        let dateString = "\(dateString) UTC"                   // IG dates always UTC
        let dateFormater : DateFormatter = DateFormatter()
        dateFormater.dateFormat = "yyyy:MM:dd-HH:mm:ss z"      // date is in this format
        return dateFormater.date(from: dateString)!
    }
    
    func dateNow() -> Date { return Date() }
    
    func dateAsString(_ date : Date) -> String {
        let dateFormatter        = DateFormatter()
        dateFormatter.timeZone   = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss z"
        return dateFormatter.string(from: date)
    }
    
    func dateFromStringIG(_ string : String) -> Date {
        let dateFormater : DateFormatter = DateFormatter()
        dateFormater.dateFormat = "yyyy:MM:dd-HH:mm:ss"      // date is in this format
        return dateFormater.date(from: string)!
    }
    
    func dateFromMongoISODate(_ date : String) -> Date {
        //let date = "2015-06-11T14:16:56.643Z"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"  // Date is in this format
        return formatter.date(from: date)!
    }
    
    func dateNowGMT() -> Date { return dateToUTC(Date()) }
    
    func dateToUTC(_ date : Date) -> Date {
        let timeZoneOffset  : Int = NSTimeZone.default.secondsFromGMT()
        let foo             : Double = round(date.timeIntervalSinceReferenceDate)
        let gmtTimeInterval : Double = foo - Double(timeZoneOffset)
        return Date(timeIntervalSinceReferenceDate: gmtTimeInterval)
    }
    
    // Date comparison
    
    func isDateInFuture(_ date : Date) -> Bool {
        return Date().compare(date) == ComparisonResult.orderedAscending
    }
    
    func isDateInPast(_ date : Date) -> Bool {
        return Date().compare(date) == ComparisonResult.orderedDescending
    }
    
    
    // IG Specific
    func isIGSymbol(_ symbol: String, igSymbol: String) -> Bool {
        return  "CS.D.\(removeWhiteSpaces(symbol)).CFD.IP" == igSymbol
    }
    
    func symbolToIG(_ symbol: String) -> String {
        return "CS.D.\(removeWhiteSpaces(symbol)).CFD.IP"
    }
    
    func displayCurrency(_ currency : String, amount : Double) -> String{
        switch currency {
        case "AUD": return String(format: "$%.2f", amount)
        default:    return String(format: "$%.2f", amount)
        }
    }
    
    func displayPrice(_ currency : String, amount : Double) -> String{
        return String(format: "$%.4f", amount)
    }
    
    func debugPrint(_ any : Any) {
        if config.isDebug { print(any) }
    }
    
    
//    func doubleTo4DecimalPlacesAsString(double : Double) -> String {
//        return NSString(format: "%.4f", double) as String
//    }
    
    
    // Decimal number
    
    open func decimalNumberHandler(_ decimalPoints : Int16) -> NSDecimalNumberHandler {
        return NSDecimalNumberHandler(
            roundingMode: NSDecimalNumber.RoundingMode.plain,
            scale: decimalPoints,
            raiseOnExactness:    false,
            raiseOnOverflow:     false,
            raiseOnUnderflow:    false,
            raiseOnDivideByZero: false)
    }
    
//        switch currency {
//        case "JPY":
//            return NSDecimalNumberHandler(
//                roundingMode: NSRoundingMode.RoundPlain,
//                scale: 2,
//                raiseOnExactness:    false,
//                raiseOnOverflow:     false,
//                raiseOnUnderflow:    false,
//                raiseOnDivideByZero: false)
//        default:
//            return NSDecimalNumberHandler(
//                roundingMode: NSRoundingMode.RoundPlain,
//                scale: 5,
//                raiseOnExactness:    false,
//                raiseOnOverflow:     false,
//                raiseOnUnderflow:    false,
//                raiseOnDivideByZero: false)
//        }
//    }
    
    // Test routines
    
    func startTest (_ name : String) {
        NSLog("-------------------------------------------------------")
        NSLog("\(name) - Start Tests")
        NSLog("-------------------------------------------------------")
    }
    
    func finishedTest(_ name: String) {
        NSLog("-------------------------------------------------------")
        NSLog("\(name) - Finished Tests")
        NSLog("-------------------------------------------------------")
    }
    
    func finishedTests() {
        NSLog("=======================================================")
        NSLog("Finished Testing")
        NSLog("    Total Tests: \(config.testsTotal)")
        NSLog("    👍: \(config.testsPassed)")
        NSLog("    ❌: \(config.testsFailed)")
        NSLog("=======================================================")
        
    }
    
    func logNormal(_ text: String) {
        config.testsTotal  += 1
        config.testsPassed += 1
        NSLog("👍: \(config.testsPassed): \(text)")
    }
    
    func logError(_ text:  String) {
        config.testsTotal  += 1
        config.testsFailed += 1
        NSLog("❌: \(config.testsFailed): \(text)")
    }
    
}
