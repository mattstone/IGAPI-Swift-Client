//
//  MSIGBrokerIGMetaData.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 15/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGMetaDataPage {
    open var pageNumber = 0 as Int
    open var pageSize   = 0 as Int
    open var totalPages = 0 as Int
    
    public init() {}
}

open class MSIGBrokerIGMetaDataAllowance {
    open var allowanceExpiry    = 0 as Int
    open var remainingAllowance = 0 as Int
    open var totalAllowance     = 0 as Int
    
    public init() {}
}


open class MSIGBrokerIGMetaData {
    open var pageData  = MSIGBrokerIGMetaDataPage()
    open var size      = 0 as Int
    open var allowance = MSIGBrokerIGMetaDataAllowance()
    
    public init() {}
}
 
