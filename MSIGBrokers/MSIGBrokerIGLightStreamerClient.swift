//
//  TBrokerIGLightStreamerClient.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 20/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

open class MSIGBrokerIGLightStreamerClientSubscription {
    open var subscription = LSSubscription()
//    open var tableInfo  = LSExtendedTableInfo()
//    open var updateInfo = LSItemUpdate()
    open var notifier     = ""
}

open class MSIGBrokerIGLightStreamerClientSubscriptionError {
    open var subscription = LSSubscription()
    open var code : Int   = 0
    open var message      = ""
    
}

public let MSIGBrokerIGSharedLightStreamerClient = MSIGBrokerIGLightStreamerClient()

//open class MSIGBrokerIGLightStreamerClient : NSObject, LSConnectionDelegate, LSTableDelegate {
open class MSIGBrokerIGLightStreamerClient : NSObject, LSClientDelegate, LSSubscriptionDelegate {
    
    open let maxConn        = 40
    let config              = MSIGBrokersConfig.sharedInstance
    let includes            = MSIGBrokersIncludes.sharedInstance
    open var ls             = LSLightstreamerClient()
    open var subscriptions  = [MSIGBrokerIGLightStreamerClientSubscription]()
    
    open var isConnected    = false
    
    var showLog              = false
    
    public override init() {
        super.init()
    }
    
    open func isMaxConn() -> Bool { return subscriptions.count >= 40 }
    
    open func open(_ cst : String, securityToken : String, endPoint : String, clientId : String) {
        
        includes.debugPrint(any: "Lightstreamer: open: clientId: \(clientId) endPoint: \(endPoint)")

        ls = LSLightstreamerClient(serverAddress: endPoint, adapterSet: "DEFAULT")
        ls.connectionDetails.user        = clientId
        ls.connectionDetails.setPassword("CST-\(cst)|XST-\(securityToken)")
        ls.addDelegate (self)
        ls.connect()
    }
    
    open func subscribeEpic(_ epics : [String], notifier : String) -> LSSubscription {
        
        includes.debugPrint(any: "Lightstreamer: subscribeEpic: epics: \(epics)")
        
        var request = [String]()
        for epic in epics { request.append("MARKET:\(epic)") }
        
        return subscribe(request,
            mode: "MERGE",
            fields: ["BID",          "OFFER",     "HIGH",        "LOW",        "MID_OPEN",
                     "CHANGE",       "CHANGE_PCT","MARKET_DELAY","MARKET_STATE","UPDATE_TIME"],
//                     "STRIKE_PRICE", "ODDS"],
            dataAdapter: "DEFAULT",
            snapshot: false,
            notifier: notifier)
    }
    
    open func subscribeAccount(_ accountId : String, notifier : String) -> LSSubscription {
        #if DEBUG
            includes.debugPrint(any: "Lightstreamer: subscribeAccount: accountId: \(accountId)")
        #endif
        
        return subscribe(["ACCOUNT:\(accountId)"],
            mode: "MERGE",
            fields: ["PNL",    "DEPOSIT", "AVAILABLE_CASH", "PNL_LR",     "PNL_NLR",
                     "FUNDS",  "MARGIN",  "MARGIN_LR",      "MARGIN_NLR", "AVAILABLE_TO_DEAL",
                     "EQUITY", "EQUITY_USED"],
            dataAdapter: "DEFAULT",
            snapshot: true,
            notifier: notifier)
    }
    
    open func subscribeTrade(_ accountId : String, notifier : String) -> LSSubscription {
        #if DEBUG
            includes.debugPrint(any: "Lightstreamer: subscribeTrade: accountId: \(accountId)")
        #endif
        
        return subscribe(["TRADE:\(accountId)"],
            mode: "DISTINCT",
            fields: ["CONFIRMS", "OPU", "WOU"],
            dataAdapter: "DEFAULT",
            snapshot: true,
            notifier: notifier)
    }
    
    open func subscribeChartTick(_ epics : [String], notifier : String) -> LSSubscription {
        #if DEBUG
            includes.debugPrint(any: "Lightstreamer: subscribeChartTick: epics: \(epics)")
        #endif
        
        var request = [String]()
        for epic in epics { request.append("CHART:\(epic):TICK") }
        
        if showLog {
            includes.debugPrint(any: "Lightstreamer: subscribeChartTick: \(request)")
        }
        
        return subscribe(request,
            mode: "DISTINCT",
            fields: ["BID",   "OFR",           "LTP",             "LTV",              "TTV",
                     "UTM",   "DAY_OPEN_MID",  "DAY_NET_CHG_MID", "DAY_PERC_CHG_MID", "DAY_HIGH",
                     "DAY_LOW"],
            dataAdapter: "DEFAULT",
            snapshot: true,
            notifier: notifier)
    }

    open func subscribeChartCandle(_ epics : [String], scale : MSIGBrokerIGSnapshotChartScale, notifier : String) -> LSSubscription{
        
        #if DEBUG
            includes.debugPrint(any: "Lightstreamer: subscribeChartCandle: epics: \(epics)")
        #endif
        
        var chartScale = ""
        
        switch scale {
        case .second:   chartScale = "SECOND"
        case .minute_1: chartScale = "1MINUTE"
        case .minute_5: chartScale = "5MINUTE"
        case .hour:     chartScale = "HOUR"
        }
        
        var request = [String]()
        for epic in epics { request.append("CHART:\(epic):\(chartScale)") }
        
        return subscribe(request,
            mode: "MERGE",
            fields: ["LTV",      "TTV",       "UTM",      "DAY_OPEN_MID", "DAY_NET_CHG_MID", "DAY_PERC_CHG_MID",
                     "DAY_HIGH", "DAY_LOW",   "OFR_OPEN", "OFR_HIGH",     "OFR_LOW",         "OFR_CLOSE",
                     "BID_OPEN", "BID_HIGH",  "BID_LOW",  "BID_CLOSE",    "LTP_OPEN",        "LTP_HIGH",
                     "LTP_LOW",  "LTP_CLOSE", "CONS_END", "CONS_TICK_COUNT"],
            dataAdapter: "DEFAULT",
            snapshot: true,
            notifier: notifier)
    }
    
    func subscribe(_ items: Array<String>, mode: String, fields: Array<String>, dataAdapter: String = "DEFAULT", snapshot : Bool = true, notifier : String) -> LSSubscription {
        
//        includes.debugPrint(any: "Lightstream.subscribe mode:     \(mode)")
//        includes.debugPrint(any: "Lightstream.subscribe items:    \(items)")
//        includes.debugPrint(any: "Lightstream.subscribe fields:   \(fields)")
//        includes.debugPrint(any: "Lightstream.subscribe notifier: \(notifier)")

        var requestedSnapshot = ""
        switch snapshot {
        case true:  requestedSnapshot = "yes"
        case false: requestedSnapshot = "no"
        }
        
        var cleanedItems = [String]()
        
        for element in items {
            cleanedItems.append(includes.removeWhiteSpaces(element))
        }
        
        // Subscribe to Lightstreamer
        let subscription         = LSSubscription(subscriptionMode: mode)
        subscription.items       = cleanedItems
        subscription.fields      = fields
        subscription.dataAdapter = dataAdapter
        subscription.requestedSnapshot = requestedSnapshot
        subscription.addDelegate(self)
        ls.subscribe(subscription)

        // Save subscription so we can respond appropriately
        let x = MSIGBrokerIGLightStreamerClientSubscription()
        x.subscription = subscription
        x.notifier     = notifier
        subscriptions.append(x)
        
        return subscription
    }

    open func unsubscribeAllKeys() {

        includes.debugPrint(any: "Lightstreamer: unsubscribeAllKeys")
        
        for subscription in self.subscriptions { unsubscribe(subscription.subscription) }
        self.subscriptions.removeAll()
    }

    open func unsubscribe(_ subscription : LSSubscription) {

        #if DEBUG
            includes.debugPrint(any: "Lightstreamer: unsubscribe: subscription: \(subscription)")
        #endif

        do {

            /*
 
             // TODO: may not be needed anymore..
             
             
             Note:
             
             Lightstreamer throws NSException, which swift does not capture.
             
             Hence wrapping in objective C
             
            */
            
            try ObjC.catchException {
                var removeIndex = 0
                
                for x in self.subscriptions {
                    switch x.subscription {
                    case subscription:
                        self.subscriptions.remove(at: removeIndex)
                        self.ls.unsubscribe(subscription)
                        self.config.nc.post(name: Notification.Name(rawValue: self.config.IG_STREAMING_UNSUBSCRIBE),
                                            object: subscription)
                    default:  removeIndex = removeIndex + 1
                    }
                }
            }
                
        } catch let error as NSException {
            includes.debugPrint(any: "Error: Lightstreamer NSException: unsubscribe: \(subscription): \(error)")
        } catch let error as NSError {
            includes.debugPrint(any: "Error: Lightstreamer: unsubscribe: \(subscription): \(error.localizedDescription)")
        }
    }
    
    public func subscription(_ subscription: LSSubscription, didUpdateItem itemUpdate: LSItemUpdate) {
        //includes.debugPrint(any: "brokerIG.subscription : received data for subscription: subscription")
        
        for x in subscriptions {
            if x.subscription == subscription {
                config.nc.post(name: Notification.Name(rawValue: x.notifier), object: itemUpdate)
            }
        }
    }

    public func subscription(_ subscription: LSSubscription, didFailWithErrorCode code: Int, message: String?) {
        includes.debugPrint(any: "brokerIG.subscription: didFailWithErrorCode: \(code) : \(String(describing: message))")
        
        let error = MSIGBrokerIGLightStreamerClientSubscriptionError()
        error.subscription = subscription
        error.code         = code
        
        if message != nil {
            error.message = includes.trimWhiteSpace(message!)
        }
        
        config.nc.post(name: Notification.Name(rawValue: config.IG_STREAMING_SUBSCRIPTION_ERROR), object: error)
    }
    
/*
    open func tableDidUnsubscribeAllItems(_ tableKey: LSSubscription!) {
        if showLog {
            includes.debugPrint(any: "Lightstreamer: table: tableDidUnsubscribeAllItems")
        }
    }
*/
    // Connection
    
    public func client(_ client: LSLightstreamerClient, didChangeStatus status: String) {
        
        includes.debugPrint(any: "Lightstreamer: didChangeStatus: \(status)")
        

/*
        <li>"CONNECTING" the client is waiting for a Server's response in order to establish a connection;</li>
            <li>"CONNECTED:STREAM-SENSING" the client has received a preliminary response from the server and is currently verifying if a streaming connection is possible;</li>
        <li>"CONNECTED:WS-STREAMING" a streaming connection over WebSocket is active;</li>
        <li>"CONNECTED:HTTP-STREAMING" a streaming connection over HTTP is active;</li>
        <li>"CONNECTED:WS-POLLING" a polling connection over WebSocket is in progress;</li>
        <li>"CONNECTED:HTTP-POLLING" a polling connection over HTTP is in progress;</li>
        <li>"STALLED" the Server has not been sending data on an active streaming connection for longer than a configured time;</li>
        <li>"DISCONNECTED" no connection is currently active;</li>
        <li>"DISCONNECTED:WILL-RETRY" no connection is currently active but one will be open after a timeout.</li>
 */
        
        switch status {
        case "CONNECTING":               break
        case "CONNECTED:STREAM-SENSING": break
        case "CONNECTED:WS-STREAMING", "CONNECTED:HTTP-STREAMING",
             "CONNECTED:WS-POLLING",   "CONNECTED:HTTP-POLLING":
            isConnected = true
            config.nc.post(name: Notification.Name(rawValue: config.IG_STREAMING_CONNECT), object: nil)

            includes.debugPrint(any: "*******************************")
            includes.debugPrint(any: "*** ls.isConnected = true")
            includes.debugPrint(any: "*******************************")
        
        case "STALLED":   break
        case "DISCONNECTED", "DISCONNECTED:WILL-RETRY":
            isConnected = false
            config.nc.post(name: Notification.Name(rawValue: config.IG_STREAMING_DISCONNECTED), object: nil)
        default: break
        }
        
        
    }
    
/*
    open func clientConnectionDidSucceedResettingBadge(onServer client: LSClient!) {
        if showLog {
            includes.debugPrint(any: "Lightstreamer: clientConnectionDidSucceedResettingBadgeOnServer")
        }
    }
    
    open func clientConnectionDidEstablish(_ client: LSClient!) {
        if showLog {
            includes.debugPrint(any: "Lightstreamer: clientConnectionDidEstablish")
        }
    }
    
    open func clientConnection(_ client: LSClient!, willSendRequestFor challenge: URLAuthenticationChallenge!) {
        if showLog {
        includes.debugPrint(any: "Lightstreamer: clientConnection: willSendRequestForAuthenticationChallenge")
        
//        includes.debugPrint(any: "  *** challenge: \(challenge)")
//        includes.debugPrint(any: "  *** challenge: \(challenge.description)")
//        challenge.sender?.continueWithoutCredentialForAuthenticationChallenge(challenge)
        
        // TODO: it may be that this is only needed when connecting to IG's demo environment
        }

        challenge.sender?.performDefaultHandling!(for: challenge)
    }

    open func clientConnection(_ client: LSClient!, didSucceedChangingDeviceTokenOnServerWith info: LSMPNTokenChangeInfo!) {
//        includes.debugPrint(any: "clientConnection: didSucceedChangingDeviceTokenOnServerWithInfo")
    }
    
    open func clientConnection(_ client: LSClient!, didFailResettingBadgeOnServerWithError error: LSException!) {
//        includes.debugPrint(any: "clientConnection: didFailResettingBadgeOnServerWithError")
    }
    
    open func clientConnection(_ client: LSClient!, didReceiveServerFailure failure: LSPushServerException!) {
        if showLog {
          includes.debugPrint(any: "Lightstreamer: clientConnection: didReceiveServerFailure")
          includes.debugPrint(any: "  *** \(failure.reason!)")
        }
    }
    
    open func clientConnection(_ client: LSClient!, didFailChangingDeviceTokenOnServerWithError error: LSException!) {
        if showLog {
            includes.debugPrint(any: "Lightstreamer: clientConnection: didFailChangingDeviceTokenOnServerWithError: \(error)")
        }
    }
    
    open func clientConnection(_ client: LSClient!, didReceiveDataError error: LSPushUpdateException!) {
        if showLog {
            includes.debugPrint(any: "Lightstreamer: clientConnection: didReceiveDataError: \(error)")
        }
    }
    
*/
    
    // handle nils (there are quite a few of them :-(
    open func extractDouble(_ updateInfo : LSItemUpdate, field : String) -> Double {
        //includes.debugPrint(any: "extractDouble: \(field)")
        
        if updateInfo.value(withFieldName: field) == nil   { return 0 }
        if updateInfo.value(withFieldName: field)!.isEmpty { return 0 }
        return Double(updateInfo.value(withFieldName: field)!)!
    }
    
    // Process data
    
    open func extractEpic(_ string : String) -> String {
        if string.isEmpty { return "" }
        let array = string.components(separatedBy: ":")
        if array.count < 2 { return "" }
        return array[1]
    }

    open func close() {
        includes.debugPrint(any: "Lightstreamer close: 1")
        ls.disconnect()
        includes.debugPrint(any: "Lightstreamer close: 2")
    }
    
}
