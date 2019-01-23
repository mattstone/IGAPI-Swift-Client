//
//  MSIGBrokerIG.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 13/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//


import Foundation

public enum MSIGBrokerIGPriceResolution : String {
    case SECOND    = "Second"
    case MINUTE    = "Minute"
    case MINUTE_2  = "2 Minute"
    case MINUTE_3  = "3 Minute"
    case MINUTE_5  = "5 Minute"
    case MINUTE_10 = "10 Minute"
    case MINUTE_15 = "15 Minute"
    case MINUTE_30 = "30 Minute"
    case HOUR      = "Hour"
    case HOUR_2    = "2 Hour"
    case HOUR_3    = "3 Hour"
    case HOUR_4    = "4 Hour"
    case DAY       = "Day"
    case WEEK      = "Week"
    case MONTH     = "Month"
}



open class MSIGBrokerIG : MSIGBaseBroker {
    
    public static let sharedInstance = MSIGBrokerIG()
    
    open var account            : MSIGBrokerIGAccount!
    open var clientApplications : [MSIGBrokerIGClientApplication] = []

    open var marketNodes = Array<Dictionary<String, Any>>()
    open var markets     = Array<MSIGBrokerIGInstrument>()
    open var ls          = MSIGBrokerIGSharedLightStreamerClient
    
    open var tokenUrl    = ""
    open var b2bApiKey   = "68ee4eef86d612491bd2d1f373392c42c7b97c9b"
    open var OauthToken  = ""
    open var OauthUserInfo = Dictionary<String, Any>()
    
    open var subscribeAccountNotificationsKey : LSSubscription!
    open var subscribeTradeNotificationsKey   : LSSubscription!
    
    var httpUrl = ""
    
    fileprivate override init() {
        super.init()
        
        broker  = MSIGBaseBrokerBroker.ig
        
        switch environment {
        case .debug:
            apiUrl = "https://demo-api.ig.com/gateway/deal"
            apiKey = "ff2d222f7f9dd93f7272"
//            apiUrl = "https://api.ig.com/gateway/deal"
//            apiKey = "377be2b4596de5e915129bc6517b598fb9a49ee1"
            tokenUrl = "https://demo-as.ig.com/openam"
        case .production:
            apiUrl = "https://api.ig.com/gateway/deal"
            apiKey = "377be2b4596de5e915129bc6517b598fb9a49ee1"
            tokenUrl = "https://as.ig.com/openam"
        }
        
        httpUrl = apiUrl
        setupObservers()
    }
 
//    baseURL: "https://demo-as.ig.com/openam"
//    authorizationPath: '/oauth2/authorize'
//    tokenPath: 'https://demo-as.ig.com/openam/oauth2/access_token'
//    refreshTokenPath: 'https://demo-as.ig.com/openam/oauth2/refresh/access-token'
//    clientID: "TradeSamurai"
//    clientSecret: "TradeSamurai!"
//    callbackURL: "http://dev.tradesamurai.com"
//    realm: "external"
    
    func setupObservers() {
        config.nc.addObserver(self,
                              selector: #selector(streamingAccountsNotification),
                              name: NSNotification.Name(rawValue: config.IG_STREAMING_ACCOUNT),
                              object: nil)
        
    }
    
    override func processResponseForErrors(_ dict : Dictionary<String, Any>) {
        clearErrors()
        if let errorMsg = dict["error"] as? String {
            addErrorObject("", description : errorMsg, code : "")
        }
    }
    
    open func isTokenTimeOutError() -> Bool {
        for error in errors {
            if error.description.lowercased() == "error.security.oauth-token-invalid" { return true }
        }
        return false
    }

    open func symbolFromEpic(_ string : String) -> String {
        if string.isEmpty { return "" }
        let array = string.components(separatedBy: ":")
        if array.count < 2 { return "" }
        return array[1]
    }

    // Login
    open override func httpLogin(_ username: String, password: String) {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/session" as Any?
        dict["parameters"] = [ "identifier" : username, "password" : password]
        httpPost(dict, notification : config.IG_HTTP_LOGIN, version: 2, isIGLogin: true)
    }
    
    open func oauth2Setup(_ token : String, cst : String, securityToken : String) {
        updateIGOauthToken(token, cst: cst, securityToken: securityToken)
        oauth2Connect()
    }
    
    // use to get user's details if logged in via OAuth2
    open func getSession() {
        var dict    = Dictionary<String, Any>()
        dict["url"] = "\(apiUrl)/session" as Any?
        httpGet(dict, notification: config.IG_SESSION_GET, version: 1)
    }
    
    open func handleGetSession(notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            
            if let statusCode = dict["httpStatusCode"] as? Int {
                switch statusCode {
                case 200:
                    if let json = dict["json"] as? Dictionary<String, Any> {
                        
                        isLoggedIn = true
                        account    = MSIGBrokerIGAccount()
                        
                        if let x = json["accountId"] as? String { account.currentAccountId = x }
                        if let x = json["clientId"]  as? String { account.clientId         = x }
                        if let x = json["currency"]  as? String { account.currencyIsoCode  = x }
                        if let x = json["lightstreamerEndpoint"]  as? String { account.lightstreamerEndpoint  = x }
                        if let x = json["locale"]         as? String { account.locale          = x }
                        if let x = json["timezoneOffset"] as? Double { account.timezoneOffset  = x }
                    }
                default: break
                }
            }
        }
    }
    
    open func updateIGOauthToken(_ token : String, cst : String, securityToken : String) {
        OauthToken           = token
        headerCST            = cst
        headerXSecurityToken = securityToken
        isIGOAuth2           = true
//        includes.debugPrint(any: "THE HEADER CST IS: \(headerCST)")
//        includes.debugPrint(any: "THE HEADER X SECURITY TOKEN IS: \(headerXSecurityToken)")
//        includes.debugPrint(any: "THE OAUTH TOKEN IS: \(OauthToken)")
        igOauth2Dict["OauthToken"] = OauthToken
    }
    
    open func oauth2Disconnect() {
        OauthToken = ""
        isIGOAuth2 = false
        isLoggedIn = false
        igOauth2Dict.removeAll()
        
        //apiUrl = httpUrl
    }
    
    open func isOauth2() -> Bool { return !OauthToken.isEmpty }
    
    open func oauth2Connect() {
        includes.debugPrint(any: "MSIGBrokerIG.oauth2Connect")
        
        var dict =  Dictionary<String, Any>()
        
        dict["url"]        = "\(tokenUrl)/oauth2/userinfo"
        dict["parameters"] = []
        dict["OauthToken"] = OauthToken
        dict["isOauth2"]   = isOauth2()
        
         includes.debugPrint(any: "  dict: \(dict)")
        
        httpGet(dict, notification : config.IG_OAUTH2_CONNECT)
    }
    
    open func handleOauth2ConnectResponse(_ notification : Notification) {
         includes.debugPrint(any: "MSIGBrokerIG.handleOauth2ConnectResponse")
         includes.debugPrint(any: notification)
        
//        includes.debugPrint(any: "********************************")
//        includes.debugPrint(any: "handleOauth2ConnectResponse : 1")
        
        //            json =     {
        //                "family_name" = 100001320;
        //                name = 100001320;
        //                sub = 100001320;
        //                "updated_at" = 1466655472;
        //            };
        
        let json = extractJson(notification)
        
        switch isError() {
        case true: break
        case false:
             includes.debugPrint(any: "handleOauth2ConnectResponse : 2: \(json)")
            
            self.isLoggedIn    = true
            OauthUserInfo = json
            
//            includes.debugPrint(any: "handleOauth2ConnectResponse : 3: \(OauthUserInfo)")
//            includes.debugPrint(any: "handleOauth2ConnectResponse : 4: \(oauth2Sub())")
//            includes.debugPrint(any: "handleOauth2ConnectResponse : 5: \(OauthToken)")
//            includes.debugPrint(any: "handleOauth2ConnectResponse : 6: \(b2bApiKey)")
            
            igOauth2Dict["clientId"]   = oauth2Sub() as Any?  // Set the baseBrokers dictionary
            igOauth2Dict["OauthToken"] = OauthToken  as Any?
            igOauth2Dict["apiKey"]     = b2bApiKey   as Any?
        }
    }
    
    open func oauth2Sub() -> String {
        // TODO: temp hard coded whilst IG works on the the API
        
        return "X7OXY"
        
//        if let sub = OauthUserInfo["sub"] as? String { return sub }
//        return ""
    }

    
    open override func handleLoginResponse(_ notification: Notification) {
        
        let json = extractJson(notification)
        
        if !isError() {
            isLoggedIn = true
            account    = MSIGBrokerIGAccount()
            
            if let x = json["accountType"] as? String {
                switch x {
                case "CFD":       account.type = .CFD
                case "PHYSICAL":  account.type = .PHYSICAL
                case "SPREADBET": account.type = .SPREADBET
                default: break
                }
            }
            
            if let x = json["dealingEnabled"]        as? Bool   { account.dealingEnabled        = x }
            if let x = json["trailingStopsEnabled"]  as? Bool   { account.trailingStopsEnabled  = x }
            if let x = json["hasActiveLiveAccounts"] as? Bool   { account.hasActiveLiveAccounts = x }
            if let x = json["currencySymbol"]        as? String { account.currencySymbol        = x }
            
            if let x = json["reroutingEnvironment"]  as? String {
                switch x {
                case "DEMO": account.reroutingEnvironment = .demo
                case "LIVE": account.reroutingEnvironment = .live
                case "TEST": account.reroutingEnvironment = .test
                case "UAT":  account.reroutingEnvironment = .demo
                default:     account.reroutingEnvironment = .null
                }
            }
            
            if let x = json["currentAccountId"]      as? String { account.currentAccountId      = x }
            if let x = json["currencyIsoCode"]       as? String { account.currencyIsoCode       = x }
            if let x = json["lightstreamerEndpoint"] as? String { account.lightstreamerEndpoint = x }
            if let x = json["timezoneOffset"]        as? Double { account.timezoneOffset        = x }
            if let x = json["clientId"]              as? String { account.clientId              = x }
            if let x = json["hasActiveDemoAccounts"] as? Bool   { account.hasActiveDemoAccounts = x }
            
            if let x = json["accountInfo"] as? Dictionary<String, Any> {
                if let y = x["available"]  as? Double { account.availableFunds = NSDecimalNumber(value: y as Double) }
                if let y = x["balance"]    as? Double { account.balance        = NSDecimalNumber(value: y as Double) }
                if let y = x["deposit"]    as? Double { account.deposit        = NSDecimalNumber(value: y as Double) }
                if let y = x["profitLoss"] as? Double { account.profitLoss     = NSDecimalNumber(value: y as Double) }
            }
            
            if let array = json["accounts"] as? Array<Dictionary<String, Any>> {
                //for x in array { account.accounts.append(x) }
                for element in array { account.accounts.append(extractAccount(element)) }
            }
            return
        }
        
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    // Accounts
    
    open func accounts() {
        
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/accounts" as Any?
        httpGet(dict, notification : config.IG_ACCOUNTS, version: 1)
    }
    
    open func handleAccountsResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {

                    if account == nil { account = MSIGBrokerIGAccount() }

                    account.accounts.removeAll()
                    if let array = json["accounts"] as? Array<Dictionary<String, Any>> {
                        for element in array {
                            account.accounts.append(extractAccount(element))
                        }
                    }
                    return
                }
            }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    open func extractAccount(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGAccountDetails {
        let accountDetails = MSIGBrokerIGAccountDetails()
        
        if let x = dict["accountId"]   as? String { accountDetails.id   = x }
        if let x = dict["accountName"] as? String { accountDetails.name = x }
        if let x = dict["preferred"]   as? Bool   { accountDetails.preferred = x }
        
        if let x = dict["accountType"] as? String {
            switch x {
            case "CFD":       accountDetails.type = .CFD
            case "PHYSICAL":  accountDetails.type = .PHYSICAL
            case "SPREADBET": accountDetails.type = .SPREADBET
            default: break
            }
        }
        return accountDetails
    }
    
    open func accountHistory() {
        
    }
    
    
    open func accountSettings() {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/accounts/preferences" as Any?
        httpGet(dict, notification : config.IG_ACCOUNT_SETTINGS)
    }
    
    open func handleAccountSettingsResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let x = json["trailingStopsEnabled"] as? Bool { account.trailingStopsEnabled = x }
                    return
                }
            }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    open func accountSettingsUpdate() {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/accounts/preferences" as Any?
        let trailingStopsEnabled = account.trailingStopsEnabled ? "true" : "false"
        dict["parameters"] = [ "trailingStopsEnabled" : trailingStopsEnabled]
        httpPut(dict, notification : config.IG_ACCOUNT_SETTINGS_UPDATE)
    }
    
    open func handleAccountSettingsUpdateResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let x = json["errorCode"] as? String { addErrorObject("", description : x, code : "") }
                    if let x = json["status"]    as? String { if x.uppercased() == "SUCCESS" { return } }
                }
            }
            
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    /* 
    
        Market Navigation
    
        marketNavigation() populates top level class var marketNodes
    
        marketNavigationHierarchy(id) re-populates  marketNodes and/or populates market array
    
        client side code should cache as needed

    */

    open func marketNavigation() {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/marketnavigation" as Any?
        httpGet(dict, notification : config.IG_MARKET_NAVIGATION)
    }
    
    open func handleMarketNavigationResponse(_ notification : Notification) {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let array = json["nodes"] as? Array<Dictionary<String, Any>> {
                        marketNodes.removeAll()
                        for element in array { marketNodes.append(element) }
                        return
                    }
                }
            }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    open func marketNavigationHierarchy(_ id : String) {
        
        let param = id.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/marketnavigation/\(param!)" as Any?
        httpGet(dict, notification : config.IG_MARKET_NAVIGATION_HIERARCHY)
    }
    
    open func handleMarketNavigationHierarchyResponse(_ notification : Notification)  {
        if let dict = notification.object as? Dictionary<String, Any> {
            
            processResponseForErrors(dict)
            
            if !isError() {
                marketNodes.removeAll()
                markets.removeAll()
                
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let array = json["nodes"] as? Array<Dictionary<String, Any>> {
                        for element in array { marketNodes.append(element) }
                    }
                    if let array = json["markets"] as? Array<Dictionary<String, Any>> {
                        for element in array {
                            let instrument      = extractInstrument(element)
                            instrument.snapshot = extractSnapshot(element)
                            markets.append(instrument)
                        }
                    }
                    return
                }
            }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    
    open func marketEpic(_ epic : String ) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/markets/\(epic)" as Any?
        httpGet(dict, notification : config.IG_MARKET_EPIC, version: 3)
    }
    
    open func handleMarketEpicResponse(_ notification : Notification) -> MSIGBrokerIGEpic {
        var epic = MSIGBrokerIGEpic()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            if !isError() {
                //includes.debugPrint(any: "THE DICT IS: \(dict["json"])")
                if let json = dict["json"] as? Dictionary<String, Any> {
                    //includes.debugPrint(any: "THE JSON IS: \(json)")
                    epic = extractEpic(json)
                    return epic
                }
            }
            else {
                config.nc.post(name: NSNotification.Name(rawValue: config.TS_REAUTHENTICATE_USER_IG), object: nil)
            }
        }
        
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        return epic
    }

    open func marketSearch(_ query : String) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/markets?searchTerm=\(query)" as Any?
        httpGet(dict, notification : config.IG_MARKET_SEARCH, version: 1)
    }

    // To be called called marketSearch(query)
    open func isMarketSearchNotFound() -> Bool { return simpleErrorMessage() == "Not Found" }
    
    open func handleMarketSearchResponse(_ notification : Notification) -> [MSIGBrokerIGInstrument] {
        markets.removeAll()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    if let array = json["markets"] as? Array<Dictionary<String, Any>> {
                        for element in array { markets.append(extractInstrument(element)) }
                    }
                }
            }
        }
        
        if markets.count == 0 {
            if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        }
        return markets
    }
    
    
    // Prices

    open func prices(_ epic : String,
        resolution : MSIGBrokerIGPriceResolution = .MINUTE,
        startDate  : String = "",
        toDate     : String = "",
        max        : Int    = 10,
        pageSize   : Int    = 0,
        pageNumber : Int    = 1 ) {
            
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/prices/\(epic)?resolution=\(resolution)" as  String as Any?
            if !startDate.isEmpty { dict["url"] = dict["url"] as! String + "&startDate=\(startDate)"   }
            if !toDate.isEmpty    { dict["url"] = dict["url"] as! String + "&toDate=\(toDate)"         }
            if max > 0            { dict["url"] = dict["url"] as! String + "&max=\(max)"               }
            if pageSize > 0       { dict["url"] = dict["url"] as! String + "&pageSize=\(pageSize)"     }
            if pageNumber > 0     { dict["url"] = dict["url"] as! String + "&pageNumber=\(pageNumber)" }
            
//        includes.debugPrint(any: dict)
        httpGet(dict, notification : config.IG_HISTORY, version: 3)
            
//https://demo-api.ig.com/gateway/deal/prices/CS.D.AUDCHF.MINI.IP?resolution=MINUTE&pageSize=3
        
    }
    
    open func pricesNumPoints(_ epic: String, resolution: MSIGBrokerIGPriceResolution, numPoints : Int) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/prices/\(epic)/\(resolution)/\(numPoints)" as String as Any?
        httpGet(dict, notification : config.IG_HISTORY, version: 2)
    }

    open func pricesDate(_ epic: String, resolution: MSIGBrokerIGPriceResolution, startDate : String, endDate : String) {
        var dict             = Dictionary<String, Any>()
        let encodedStartDate = startDate.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let encodedEndDate   = endDate.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
//        dict["url"]        = "\(apiUrl)/prices/\(epic)/\(resolution)/\(startDate)/\(endDate)" as String
        dict["url"]        = "\(apiUrl)/prices/\(epic)/\(resolution)/\(encodedStartDate)/\(encodedEndDate)" as String as Any?
        httpGet(dict, notification : config.IG_HISTORY, version: 2)
    }
    
    
    open func handlePricesResponse(_ notification : Notification) -> MSIGBrokerIGPrices {
        
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let json = dict["json"] as? Dictionary<String, Any> {
                    let prices = MSIGBrokerIGPrices()
                    
                    if let x = json["instrumentType"] as? String { prices.instrumentType = extractInstrumentType(x) }
                    
                    if let metadata = json["metadata"] as? Dictionary<String, Any> {
                        if let x = metadata["size"] as? Int { prices.metadata.size = x }
                        if let allowance = metadata["allowance"] as? Dictionary<String, Any> {
                            if let x = allowance["allowanceExpiry"]    as? Int { prices.metadata.allowance.allowanceExpiry = x }
                            if let x = allowance["remainingAllowance"] as? Int { prices.metadata.allowance.remainingAllowance = x }
                            if let x = allowance["totalAllowance"]     as? Int { prices.metadata.allowance.totalAllowance = x }
                        }
                        
                        if let pageData = metadata["pageData"] as? Dictionary<String, Any> {
                            if let x = pageData["pageSize"]    as? Int { prices.metadata.pageData.pageSize   = x }
                            if let x = pageData["pageNumber"]  as? Int { prices.metadata.pageData.pageNumber = x }
                            if let x = pageData["totalPages"]  as? Int { prices.metadata.pageData.totalPages = x }
                        }
                    }
                    
                    if let array = json["prices"] as? Array<Dictionary<String, Any>> {
                        for element in array {
                            let price = MSIGBrokerIGPrice()
                            
                            
                            if let x = element["snapshotTime"]     as? String { price.snapshotTime     = x }
                            if let x = element["snapshotTimeUTC"]  as? String { price.snapshotTimeUTC  = x }
                            if let x = element["lastTradedVolume"] as? Double { price.lastTradedVolume = x }
                            
                            if let x = element["openPrice"] as? Dictionary<String, Any> {
                                price.openPrice = extractBidAskPrice(x)
                            }
                            
                            if let x = element["highPrice"] as? Dictionary<String, Any> {
                                price.highPrice = extractBidAskPrice(x)
                            }
                            
                            if let x = element["lowPrice"] as? Dictionary<String, Any> {
                                price.lowPrice = extractBidAskPrice(x)
                            }
                            if let x = element["closePrice"] as? Dictionary<String, Any> {
                                price.closePrice = extractBidAskPrice(x)
                            }
                            prices.prices.append(price)
                        }
                    }
                    return prices
                }
            }
        }
        
        if markets.count == 0 {
            if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        }
        return MSIGBrokerIGPrices()
    }
    
    @objc open func streamingAccountsNotification(_ notification : Notification) {
        //includes.debugPrint(any: "RECEIVED ACCOUNT NOTIFICATION")
        if let updateInfo = notification.object as? LSItemUpdate {
            //includes.debugPrint(any: "THE PREFFERED ACCOUNT IS: \(account.preferredAccountDetails())")
            if account.preferredAccountDetails() != nil {
                account.profitLoss      = NSDecimalNumber(value: ls.extractDouble(updateInfo, field: "PNL") as Double)
                account.availableFunds  = NSDecimalNumber(value: ls.extractDouble(updateInfo, field: "AVAILABLE_CASH") as Double)
                account.deposit         = NSDecimalNumber(value: ls.extractDouble(updateInfo, field: "DEPOSIT") as Double)
                account.balance         = NSDecimalNumber(value: ls.extractDouble(updateInfo, field: "FUNDS") as Double)
                config.nc.post(name: Notification.Name(rawValue: config.IG_STREAMING_ACCOUNT_UI_UPDATE), object: nil)
            }
            else {
                includes.debugPrint(any: "THERE WAS AN ERROR WITH GETTING THE ACCOUNT NOTIFICATION")
            }
        }
    }
    
    open func extractBidAskPrice(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGPriceBidAsk {
        let price = MSIGBrokerIGPriceBidAsk()
        if let x = dict["bid"]        as? Double { price.bid        = NSDecimalNumber(value: x as Double) }
        if let x = dict["ask"]        as? Double { price.ask        = NSDecimalNumber(value: x as Double) }
        if let x = dict["lastTraded"] as? Double { price.lastTraded = NSDecimalNumber(value: x as Double) }
        return price
    }
    
    open func isPriceResponseEmpty() -> Bool { return simpleErrorMessage() == "Unknown" }
    
    // Client sentiment
    
    open func clientSentimentMarket(_ marketId : String) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/clientsentiment/\(marketId)" as Any?
        httpGet(dict, notification : config.IG_MARKET_SENTIMENT)
    }
    
    open func handleClientSentimentMarketResponse(_ notification : Notification) -> MSIGBrokerIGClientSentiment {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            if let json = dict["json"] as? Dictionary<String, Any> { return extractClientSentiment(json) }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        return MSIGBrokerIGClientSentiment()
    }

    open func clientSentimentMarketRelated(_ marketId : String) {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/clientsentiment/related/\(marketId)" as Any?
        httpGet(dict, notification : config.IG_MARKET_SENTIMENT_RELATED)
    }
    
    open func handleClientSentimentMarketRelatedResponse(_ notification : Notification) -> [MSIGBrokerIGClientSentiment] {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> {
                if let array = json["clientSentiments"] as? Array<Dictionary<String, Any>> {
                    var clientSentiments = [MSIGBrokerIGClientSentiment]()
                    for element in array { clientSentiments.append(extractClientSentiment(element)) }
                    return clientSentiments
                }
            }
            
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        return [MSIGBrokerIGClientSentiment]()
    }
    
    open func extractClientSentiment(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGClientSentiment {
        let clientSentiment = MSIGBrokerIGClientSentiment()
        if let x = dict["longPositionPercentage"]  as? Double { clientSentiment.longPositionPercentage  = x }
        if let x = dict["shortPositionPercentage"] as? Double { clientSentiment.shortPositionPercentage = x }
        if let x = dict["marketId"]                as? String { clientSentiment.marketId                = x }
        return clientSentiment
    }
    
    // Client application settings

    // TODO: this returns nothing.. may not be being used..??
    open func getClientApplications() {
        var dict           =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/operations/application" as Any?
        httpGet(dict, notification : config.IG_APPLICATION_SETTINGS, version: 1)
    }
    
    open func handleClientApplications(notification : Notification) {
        clientApplications.removeAll()
        
        if let dict = notification.object as? Dictionary<String, Any> {
            
            if let array = dict["json"] as? Array<Dictionary<String, Any>> {
                
                for element in array {
                    let ca = MSIGBrokerIGClientApplication()
                    
                    if let x = element["allowEquities"]    as? Bool { ca.allowEquities    = x }
                    if let x = element["allowQuoteOrders"] as? Bool { ca.allowQuoteOrders = x }
                    if let x = element["allowanceAccountHistoricalData"] as? Double { ca.allowanceAccountHistoricalData = x }
                    if let x = element["allowanceAccountOverall"] as? Double { ca.allowanceAccountOverall = x }
                    if let x = element["allowanceAccountTrading"] as? Double { ca.allowanceAccountTrading = x }
                    if let x = element["allowanceApplicationOverall"] as? Double { ca.allowanceApplicationOverall = x }
                    if let x = element["apiKey"] as? String { ca.apiKey = x }
                    if let x = element["concurrentSubscriptionsLimit"] as? Double { ca.concurrentSubscriptionsLimit = x }
                    if let x = element["createdDate"] as? String { ca.createdDate = x }
                    if let x = element["name"] as? String { ca.name = x }
                    
                    if let x = element["status"] as? String {
                        switch x.lowercased() {
                        case "enabled":  ca.status = .enabled
                        case "disabled": ca.status = .disabled
                        case "revoked":  ca.status = .revoked
                        default: break
                        }
                    }
                    
                    clientApplications.append(ca)
                }
            }
        }
        
        
    }


//    open func clientApplicationSettings() {
//        var dict           =  Dictionary<String, Any>()
//        dict["url"]        = "\(apiUrl)/operations/application" as Any?
//        
//        includes.debugPrint(any: "MSIGBrokers.clientApplicationSettings(): \(dict)")
//        
//        httpGet(dict, notification : config.IG_APPLICATION_SETTINGS)
//    }
//    
//    open func handleClientApplicationSettingsResponse(_ notification : Notification) -> MSIGBrokerIGClientApplication {
//        let json = extractJson(notification)
//    
//        if !isError() { return extractClientSettings(json) }
//        //if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
//        return MSIGBrokerIGClientApplication()
//    }
//    
//    open func clientApplicationSettingsUpdate(_ clientSettings : MSIGBrokerIGClientApplication) {
//        var dict    =  Dictionary<String, Any>()
//        dict["url"] = "\(apiUrl)/operations/application" as Any?
//    
//        var params  = Dictionary<String, Any>()
//    
//        params["allowanceAccountOverall"] = clientSettings.allowanceAccountOverall as Any?
//        params["allowanceAccountTrading"] = clientSettings.allowanceAccountTrading as Any?
//        params["apiKey"]                  = clientSettings.apiKey as Any?
//    
//        switch clientSettings.status {
//        case .disabled: params["status"] = "DISABLED" as Any?
//        case .enabled:  params["status"] = "ENABLED" as Any?
//        case .revoked:  params["status"] = "REVOKED" as Any?
//        }
//    
//        dict["params"] = params as Any?
//        httpPut(dict, notification : config.IG_APPLICATION_SETTINGS_UPDATE)
//    }
//    
//    open func handleClientApplicationSettingsUpdateResponse(_ notification : Notification) -> MSIGBrokerIGClientApplication {
//        let json = extractJson(notification)
//    
//        if !isError() { return extractClientSettings(json) }
//        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
//        return MSIGBrokerIGClientApplication()
//    }
    
    open func extractClientSettings(_ json : Dictionary<String, Any>) -> MSIGBrokerIGClientApplication {
        let clientSettings = MSIGBrokerIGClientApplication()
        
        if let x = json["allowEquities"] as? Bool { clientSettings.allowEquities = x }
        if let x = json["allowQuoteOrders"] as? Bool { clientSettings.allowQuoteOrders = x }
        if let x = json["allowanceAccountHistoricalData"] as? Double { clientSettings.allowanceAccountHistoricalData = x }
        if let x = json["allowanceAccountOverall"]        as? Double { clientSettings.allowanceAccountOverall = x }
        if let x = json["allowanceAccountTrading"]        as? Double { clientSettings.allowanceAccountTrading = x }
        if let x = json["allowanceApplicationOverall"]    as? Double { clientSettings.allowanceApplicationOverall = x }
        if let x = json["apiKey"]      as? String { clientSettings.apiKey = x }
        if let x = json["concurrentSubscriptionsLimit"]   as? Double { clientSettings.concurrentSubscriptionsLimit = x }
        if let x = json["createdDate"] as? String { clientSettings.createdDate = x }
        if let x = json["name"]        as? String { clientSettings.name = x }
        if let x = json["status"]      as? String {
            switch x {
            case "ENABLED": clientSettings.status = .enabled
            case "REVOKED": clientSettings.status = .revoked
            default:        clientSettings.status = .disabled
            }
        }
        return clientSettings
    }
    
    // Logout
    
    open func logout() {
        var dict =  Dictionary<String, Any>()
        dict["url"]        = "\(apiUrl)/session" as Any?
//includes.debugPrint(any: "logout: \(dict)")
        httpDeleteIG(dict, notification : config.IG_HTTP_LOGOUT, version: 1)
    }
    
    open func handleLogoutResponse(_ notification : Notification) {
//        includes.debugPrint(any: "handleLogoutResponse: \(notification)")
        
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if !isError() {
                if let _ = dict["json"] as? Dictionary<String, Any> {
                    isLoggedIn = false
                    return
                }
            }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
    }
    
    // Epic / Instrument
    
    open func extractJson(_ notification : Notification) -> Dictionary<String, Any> {
        if let dict = notification.object as? Dictionary<String, Any> {
            processResponseForErrors(dict)
            
            if let json = dict["json"] as? Dictionary<String, Any> { return json }
        }
        if !isError() { addErrorObject("", description : simpleErrorMessage(), code : "") }
        return Dictionary<String, Any>()
    }
    
    open func extractEpic(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGEpic {
        let epic = MSIGBrokerIGEpic()
        if let x = dict["dealingRules"] as? Dictionary<String, Any> { epic.dealingRules = extractDealingRules(x) }
        if let d = dict["instrument"] as? Dictionary<AnyHashable, Any> {
            includes.debugPrint(any: "THE EPIC DICT IS: \(d)")
        }
        if let x = dict["instrument"]   as? Dictionary<String, Any> { epic.instrument   = extractInstrument(x) }
        if let x = dict["snapshot"]     as? Dictionary<String, Any> {
            epic.snapshot            = extractSnapshot(x)
            epic.instrument.snapshot = epic.snapshot
        }
        return epic
    }
    
    open func extractDealingRules(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGDealingRules {
        let dealingRules = MSIGBrokerIGDealingRules()
        
        if let x = dict["marketOrderPreference"] as? String {
            switch x {
            case "AVAILABLE_DEFAULT_OFF": dealingRules.marketOrderPreference = .AVAILABLE_DEFAULT_OFF
            case "AVAILABLE_DEFAULT_ON":  dealingRules.marketOrderPreference = .AVAILABLE_DEFAULT_ON
            case "NOT_AVAILABLE":         dealingRules.marketOrderPreference = .NOT_AVAILABLE
            default: break
            }
        }
        
        if let x = dict["maxStopOrLimitDistance"] as? Dictionary<String, Any> {
            dealingRules.maxStopOrLimitDistance = extractDealingRule(x)
        }
        if let x = dict["minControlledRiskStopDistance"] as? Dictionary<String, Any> {
            dealingRules.minControlledRiskStopDistance = extractDealingRule(x)
        }

        if let x = dict["minDealSize"] as? Dictionary<String, Any> {
            dealingRules.minDealSize = extractDealingRule(x)
        }

        if let x = dict["minNormalStopOrLimitDistance"] as? Dictionary<String, Any> {
            dealingRules.minNormalStopOrLimitDistance = extractDealingRule(x)
        }

        if let x = dict["minStepDistance"] as? Dictionary<String, Any> {
            dealingRules.minStepDistance = extractDealingRule(x)
        }
        
        if let x = dict["trailingStopsPreference"] as? String {
            switch x {
            case "AVAILABLE":     dealingRules.trailingStopsPreference = .AVAILABLE
            case "NOT_AVAILABLE": dealingRules.trailingStopsPreference = .NOT_AVAILABLE
            default: break
            }
        }
        
        return dealingRules
    }
    
    open func extractDealingRule(_ dict : Dictionary<String, Any>) ->  MSIGBrokerIGDealingRule {
        let dealingRule = MSIGBrokerIGDealingRule()
        
        if let unit = dict["unit"] as? String {
            switch unit {
            case "PERCENTAGE": dealingRule.unit = .PERCENTAGE
            case "POINTS":     dealingRule.unit = .POINTS
            default: break
            }
        }
        
        if let value = dict["value"] as? Double { dealingRule.value = value }
        return dealingRule
    }
    
    open func extractInstrumentType(_ string : String) -> MSIGBrokerIGInstrumentType {
        switch string {
        case "BINARY":             return .BINARY
        case "BUNGEE_CAPPED":      return .BUNGEE_CAPPED
        case "BUNGEE_COMMODITIES": return .BUNGEE_COMMODITIES
        case "BUNGEE_CURRENCIES":  return .BUNGEE_CURRENCIES
        case "BUNGEE_INDICES":     return .BUNGEE_INDICES
        case "COMMODITIES":        return .COMMODITIES
        case "CURRENCIES":         return .CURRENCIES
        case "INDICES":            return .INDICES
        case "OPT_COMMODITIES":    return .OPT_COMMODITIES
        case "OPT_CURRENCIES":     return .OPT_CURRENCIES
        case "OPT_INDICES":        return .OPT_INDICES
        case "OPT_RATES":          return .OPT_RATES
        case "OPT_SHARES":         return .OPT_SHARES
        case "RATES":              return .RATES
        case "SECTORS":            return .SECTORS
        case "SHARES":             return .SHARES
        case "SPRINT_MARKET":      return .SPRINT_MARKET
        case "TEST_MARKET":        return .TEST_MARKET
        default:                   return .UNKNOWN
        }
    }
    
    open func extractInstrument(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGInstrument {
        let instrument = MSIGBrokerIGInstrument()
        includes.debugPrint(dict)
        if let x = dict["epic"]            as? String { instrument.epic   = x }
        if let x = dict["expiry"]          as? String { instrument.expiry = x }
        if let x = dict["expiryDetails"]   as? Dictionary<String, Any> { instrument.expiryDetails = MSIGBrokerIGExpiryDetails()
            if let lastDealingDate = x["lastDealingDate"] as? String { instrument.expiryDetails.lastDealingDate = lastDealingDate }
            if let settlementInfo = x["settlementInfo"] as? String { instrument.expiryDetails.settlementInfo = settlementInfo }
        }
    
        if let x = dict["chartCode"]       as? String { instrument.chartCode     = x }
        if let x = dict["newsCode"]        as? String { instrument.newsCode      = x }
        if let x = dict["country"]         as? String { instrument.country       = x }

        // Note: market will send name, instrument will send instrumentName
        
        if let x = dict["marketId"]                 as? String { instrument.marketId = x }
        
        if let x = dict["name"]                     as? String { instrument.name     = x }
        if let x = dict["type"]                     as? String { instrument.type     = extractInstrumentType(x) }
        if let x = dict["name"]                     as? String { instrument.name     = x }
        if let x = dict["type"]                     as? String { instrument.type     = extractInstrumentType(x) }
        if let x = dict["instrumentName"]           as? String { instrument.name     = x }
        if let x = dict["instrumentType"]           as? String { instrument.type     = extractInstrumentType(x) }
        if let x = dict["onePipMeans"]              as? String { instrument.onePipMeans    = x }
        if let x = dict["valueOfOnePip"]            as? String { instrument.valueOfOnePip  = x }
        if let x = dict["otcTradeable"]             as? Bool   { instrument.otcTradeable   = x }
        if let x = dict["marketStatus"]             as? String { instrument.status = extractInstrumentStatus(x) }
        if let x = dict["forceOpenAllowed"]         as? Bool   { instrument.forceOpenAllowed   = x }
        if let x = dict["stopsLimitsAllowed"]       as? Bool   { instrument.stopsLimitsAllowed = x }
        if let x = dict["lotSize"]                  as? Double { instrument.lotSize            = x }
        
        if let x = dict["contractSize"]             as? String {
            let floatX = Float(x)
            if !x.isEmpty { instrument.contractSize = Int(floatX!) }
        }
        
        if let array = dict["openingHours"]         as? Array<Dictionary<String, Any>> {
            for element in array { instrument.openingHours.append(element) }
        }
        
        if let array = dict["rolloverDetails"]      as? Array<Dictionary<String, Any>> {
            for element in array {
                let rolloverDetail = MSIGBrokerIGRolloverDetail()
                if let x = element["lastRolloverTime"] as? String { rolloverDetail.lastRolloverTime = x }
                if let x = element["rolloverInfo "]    as? String { rolloverDetail.rolloverInfo     = x }
                instrument.rolloverDetails.append(rolloverDetail)
            }
        }
        
        if let dic = dict["limitedRiskPremium"]   as? Dictionary<String, Any> {
            if let x = dic["unit"]  as? String {
                switch x {
                case "PERCENTAGE"   : instrument.limitedRiskPremium.unit = .PERCENTAGE
                case "POINTS"       : instrument.limitedRiskPremium.unit = .POINTS
                default: break
                }
            }
            if let x = dic["value"] as? Double { instrument.limitedRiskPremium.value = x }
        }
        
        if let x = dict["marginFactor"]             as? Double { instrument.marginFactor = x }
        if let x = dict["marginFactorUnit"]         as? String {
            switch x {
            case "PERCENTAGE": instrument.marginFactorUnit = .PERCENTAGE
            case "POINTS":     instrument.marginFactorUnit = .POINTS
            default: break
            }
        }
        
        if let x = dict["slippageFactor"]           as? Dictionary<String, Any> {
            let slippageFactor = MSIGBrokerIGSlippageFactor()
            
            if let unit = x["unit"]     as? String {
                switch unit.uppercased() {
                case "PERCENT", "PCT": slippageFactor.unit = .PERCENT
                default:               slippageFactor.unit = .POINT
                }
            }
            
            if let value = x["value"]   as? Double { slippageFactor.value = value }
            
            instrument.slippageFactor = slippageFactor
        }
        
        if let array = dict["specialInfo"]          as? Array<String> {
            for element in array { instrument.specialInfo.append(element) }
        }
        
        if let x = dict["unit"] as? String {
            switch x {
            case "CONTRACTS": instrument.unit = .CONTRACTS
            case "AMOUNT":    instrument.unit = .AMOUNT
            case "SHARES":    instrument.unit = .SHARES
            default: break
            }
        }
        
        if let x = dict["controlledRiskAllowed"]    as? Bool   { instrument.controlledRiskAllowed    = x }
        if let x = dict["streamingPricesAvailable"] as? Bool   { instrument.streamingPricesAvailable = x }
        if let x = dict["marketId"]                 as? String { instrument.marketId = x }
        
        includes.debugPrint(any: "MSIGBrokerIG.extractInstrument.currencies: 1: dict[currencies]: \(String(describing: dict["currencies"]))")
        
        if let array = dict["currencies"]           as? Array<Dictionary<String, Any>> {
            includes.debugPrint(any: "MSIGBrokerIG.extractInstrument.currencies: 2: \(array)")
            for element in array {
                includes.debugPrint(any: "MSIGBrokerIG.extractInstrument.currencies: 3: \(element)")
                let currency = MSIGBrokerIGCurrency()
                if let x = element["code"]             as? String { currency.code      = x }
                if let x = element["symbol"]           as? String { currency.symbol    = x }

                includes.debugPrint(any: "MSIGBrokerIG.extractInstrument.currencies: 4: \(String(describing: element["isDefault"] ))")
                if let x = element["isDefault"]        as? Bool   {
                    includes.debugPrint(any: "MSIGBrokerIG.extractInstrument.currencies: 5: \(x)")
                    currency.isDefault = x
                }
                if let x = element["baseExchangeRate"] as? Double { currency.baseExchangeRate = NSDecimalNumber(value: x as Double) }
                if let x = element["exchangeRate"]     as? Double { currency.exchangeRate     = NSDecimalNumber(value: x as Double) }
                
                instrument.currencies.append(currency)
            }
        }
        
        if let array = dict["marginDepositBands"]   as? Array<Dictionary<String, Any>> {
            for element in array {
                let marginDepositBand = MSIGBrokerIGMarginDepositBand()
                if let x = element["currency"] as? String { marginDepositBand.currency = x }
                if let x = element["margin"]   as? Double { marginDepositBand.margin   = x }
                if let x = element["max"]      as? Double { marginDepositBand.max      = x }
                if let x = element["min"]      as? Double { marginDepositBand.min      = x }
                instrument.marginDepositBands.append(marginDepositBand)
            }
         }
        
        //instrument.snapshot = extractSnapshot(dict)
        
        return instrument
    }

    
    open func extractSnapshot(_ dict : Dictionary<String, Any>) -> MSIGBrokerIGSnapshot {
        let snapshot = MSIGBrokerIGSnapshot()
        
        if let x = dict["bid"]                       as? Double { snapshot.bid = NSDecimalNumber(value: x as Double) }
        if let x = dict["binaryOdds"]                as? Double { snapshot.binaryOdds                = x }
        if let x = dict["controlledRiskExtraSpread"] as? Double { snapshot.controlledRiskExtraSpread = x }
        if let x = dict["decimalPlacesFactor"]       as? Double { snapshot.decimalPlacesFactor       = x }
        if let x = dict["delayTime"]                 as? Int    { snapshot.delayTime                 = x }
        if let x = dict["high"]                      as? Double { snapshot.high  = NSDecimalNumber(value: x as Double) }
        if let x = dict["low"]                       as? Double { snapshot.low   = NSDecimalNumber(value: x as Double) }
        if let x = dict["netChange"]                 as? Double { snapshot.netChange = NSDecimalNumber(value: x as Double) }
        if let x = dict["offer"]                     as? Double { snapshot.offer     = NSDecimalNumber(value: x as Double) }
        if let x = dict["percentageChange"]          as? Double { snapshot.percentageChange          = x }
        if let x = dict["scalingFactor"]             as? Double { snapshot.scalingFactor             = x }
        if let x = dict["updateTime"]                as? String { snapshot.updateTime                = x }
        if let x = dict["updateTimeUTC"]             as? String { snapshot.updateTimeUTC             = x }
        
        // Note: epic sends as marketStatus and market sent as status..
        if let x = dict["marketStatus"]     as? String { snapshot.marketStatus = extractInstrumentStatus(x) }
        if let x = dict["status"]           as? String { snapshot.marketStatus = extractInstrumentStatus(x) }
        return snapshot
    }
    
    open func extractInstrumentStatus(_ string : String) -> MSIGBrokerIGInstrumentStatus {
        switch string {
        case "CLOSED":	           return .CLOSED
        case "EDITS_ONLY":	       return .EDITS_ONLY
        case "OFFLINE":	           return .OFFLINE
        case "ON_AUCTION":	       return .ON_AUCTION
        case "ON_AUCTION_NO_EDIT": return .ON_AUCTION_NO_EDITS
        case "SUSPENDED":	       return .SUSPENDED
        case "TRADEABLE":	       return .TRADEABLE
        default:                   return .UNKNOWN
        }
    }
    
    // Streaming
    
    open func streamingConnect() {
        switch account != nil {
        case true:
            ls.open(
                headerCST,
                securityToken: headerXSecurityToken,
                endPoint: account.lightstreamerEndpoint,
                clientId: account.clientId)
        case false: break
        }
    }
    
    open func streamingDisconnect() { ls.close() }
    
    open override func cleanUp() {
        account?.cleanUp()
        account = nil
        
        marketNodes.removeAll()
    }
    
    func tearDownObservers() {
        config.nc.removeObserver(self)
    }
    
    deinit {
        includes.debugPrint(any: "MSIGBrokerIG: deinit")
        tearDownObservers()
    }
}
