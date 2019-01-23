//
//  Extensions.swift
//  MSIGBrokers
//
//  Created by Matt on 15/8/17.
//  Copyright © 2017 Matt Stone. All rights reserved.
//

import Foundation


extension Double {
    
    func doubleToDecimal(places: Int) -> String {
        let formatter : NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = places
        formatter.minimumFractionDigits = places
        return formatter.string(from: NSNumber(value: self))!
    }
    
}
