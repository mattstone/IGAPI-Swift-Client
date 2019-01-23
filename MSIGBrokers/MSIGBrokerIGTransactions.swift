//
//  MSIGBrokerIGTransactions.swift
//  MSIGBrokers
//
//  Created by Matt Stone on 5/09/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation


public enum MSIGBrokerIGTransactionsRequest : String {
    case ALL
    case ALL_DEAL
    case DEPOSIT
    case WITHDRAWAL
}

open class MSIGBrokerIGHistoryMetaData {
    open var size       = 0 as Int
    open var pageNumber = 0 as Int
    open var pageSize   = 0 as Int
    open var totalPages = 0 as Int
}

open class MSIGBrokerIGTransactions {
    
    open var meta         = MSIGBrokerIGHistoryMetaData()
    open var transactions = [MSIGBrokerIGTransaction]()
    
}
