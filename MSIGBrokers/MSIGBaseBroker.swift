//
//  MSIGBaseBroker.swift
//  TradeSamuraiBooks
//
//  Created by Matt Stone on 13/03/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation

public enum MSIGBaseBrokerBroker {
    case ig
}

public enum MSIGBaseBrokerEnvironment {
    case debug
    case production
}

open class MSIGBaseBroker {
    
    open var config   = MSIGBrokersConfig.sharedInstance
    let includes = MSIGBrokersIncludes.sharedInstance
    let restAPI  = MSIGBrokersRestAPI.sharedInstance
    
    var broker   = MSIGBaseBrokerBroker.ig
    
    var request  : NSMutableURLRequest!
    let session  = URLSession(configuration: URLSessionConfiguration.default)
    
    var responseObject = Dictionary<String, Any>()
    var responseString = ""
    open var errors  = [Dictionary<String, String>]()
    
    open var apiUrl = ""
    open var apiKey = ""
    
    open var environment = MSIGBaseBrokerEnvironment.debug
    open var isLoggedIn  = false
    
    var headerCST            = "" // IG
    var headerXSecurityToken = "" // IG
    var isIGOAuth2   = false      // IG
    var igOauth2Dict = Dictionary<String, Any>() // IG
    
    open func httpLogin(_ username : String, password : String) {}
    
    // Handle errors
    open func isError() -> Bool { return !errors.isEmpty }
    open func clearErrors()     { errors.removeAll()    }

    func addErrorObject(_ field: String, description : String, code : String) {
        errors.append(["field" : field, "description" : description, "code" : code])
    }
    
    open func simpleErrorMessage() -> String {
        if errors.first != nil {
            if let element = errors.first { return element["description"]! }
        }
        return ""
    }
    
    func processResponseForErrors(_ dict : Dictionary<String, Any>) {}
    
    
    open func handleLoginResponse(_ notification : Notification) {
    }
    
    // Http
    
    
    func addIGOauth2Headers(_ request : NSMutableURLRequest) -> NSMutableURLRequest {
        if let clientId = igOauth2Dict["clientId"] as? String {
            if let OauthToken = igOauth2Dict["OauthToken"] as? String {
                if let apiKey = igOauth2Dict["apiKey"] as? String {
                    request.addValue (clientId,   forHTTPHeaderField: "IG-ACCOUNT-ID")
                    request.addValue (OauthToken, forHTTPHeaderField: "X-IG-OAUTH-TOKEN")
                    request.addValue (apiKey,     forHTTPHeaderField: "X-IG-API-KEY")
                }
            }
        }
        return request
    }
    
    
    func httpGet(_ urlDict : Dictionary<String, Any>, notification : String, version : Int = 1) {
        
        var request          = NSMutableURLRequest()
        var url              = ""
        
        if let nonOptionalString = urlDict["url"] as? String {
            url = nonOptionalString
        }
        
        var parametersString = ""
        if let parametersDict = urlDict["parameters"] as? Dictionary<String, Any> {
            for (key, value) in parametersDict {
                
                if let string = value as? String {
                    let param = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    parametersString = "\(parametersString)&\(key)=\(String(describing: param))"
                }
            }
        }
        
        if !parametersString.isEmpty { url = "\(url)?\(parametersString)" }
        includes.debugPrint(any: "HTTP GET URL: \(url)")
        request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
//        let sReq = NSMutableURLRequest()
//        sReq.url = url as URL
//        request = sReq
//        request.httpMethod = "GET"
        
        // Configure request as per required by each broker
        
        switch broker {
        case .ig:
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Accept")
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
//            request.addValue("\(version)",                      forHTTPHeaderField: "VERSION")
            request.addValue("\(version)",                      forHTTPHeaderField: "Version")
            
            switch isIGOAuth2 {
            case true:
                switch isLoggedIn {
                case true:  request = addIGOauth2Headers(request)
                case false:
                    if let x = urlDict["OauthToken"] as? String {
                        print("THE X OAUTH TOKEN IS: \(x)")
                        request.addValue ("Bearer \(x)", forHTTPHeaderField: "Authorization")
                    }
                }
                
            case false:
//                print("THE HEADER CST IS: \(headerCST)")
//                print("THE X SEC TOKEN IS: \(headerXSecurityToken)")
//                print("THE API KEY IS: \(apiKey)")
                request.addValue(headerCST,            forHTTPHeaderField: "CST")
                request.addValue(headerXSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
                request.addValue(apiKey,               forHTTPHeaderField: "X-IG-API-KEY")
            }
        }
        
//        print(urlDict)
//        print(request.url)
//        print(request.allHTTPHeaderFields)
        
        let session = URLSession.shared
        let task    = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
//            print("------------------------------------------------")
//            print("HTTP GET RESPONSE")
//            print("------------------------------------------------")
//            print("data: \(data)")
//            print("response: \(response)")
//            print("error: \(error)")
//            print("------------------------------------------------")
            
            if error != nil {
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: error)
            } else {
                
                // Keep for debugging - shows raw http body from response
//                let datastring = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//                print("***: data: \(String(datastring!))")
                
                let httpResponse = self.restAPI.httpResponse(data, response: response!, error: error as NSError?)
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: httpResponse)
            }
        })
        task.resume()
    }
    
    func httpPost(_ urlDict : Dictionary<String, Any>, notification : String, version : Int = 1, isIGLogin : Bool = false) {
        var request = restAPI.httpRequest(httpMethod.post, urlDict: urlDict, delegate: self)
        
        // Configure request as per required by each broker
        switch broker {
        case .ig:
            request.addValue("\(version)", forHTTPHeaderField: "version")
            
            switch isIGOAuth2 {
            case true: request = addIGOauth2Headers(request)
            case false:
                request.addValue(apiKey,       forHTTPHeaderField: "X-IG-API-KEY")
            
                if !isIGLogin {
                    request.addValue(headerCST,            forHTTPHeaderField: "CST")
                    request.addValue(headerXSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
                }
            }
        }
        
//        print(request.allHTTPHeaderFields)
        
        let task    = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: error)
            } else {
                //                 Keep for debugging - shows raw http body from response
                let datastring = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("***: data: \(String(datastring!))")
                
                let httpResponse = self.restAPI.httpResponse(data, response: response!, error: error as NSError?)
                
                if isIGLogin {
                    if let http = response as? HTTPURLResponse {
                        if let x = http.allHeaderFields["CST"]              as? String { self.headerCST = x }
                        if let x = http.allHeaderFields["X-SECURITY-TOKEN"] as? String { self.headerXSecurityToken = x }
                    }
                }
                
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: httpResponse)
            }
        })
        task.resume()
    }
    
    func httpPut(_ urlDict : Dictionary<String, Any>, notification : String, version : Int = 1) {
        var request = restAPI.httpRequest(httpMethod.put, urlDict: urlDict, delegate: self)
        
        // Configure request as per required by each broker
        switch broker {
        case .ig:
            request.addValue("\(version)",         forHTTPHeaderField: "version")
            
            switch isIGOAuth2 {
            case true: request = addIGOauth2Headers(request)
            case false:
                request.addValue(apiKey,               forHTTPHeaderField: "X-IG-API-KEY")
                request.addValue(headerCST,            forHTTPHeaderField: "CST")
                request.addValue(headerXSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
            }
        }
        
        let task    = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            if (error != nil) {
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: error)
            } else {
//                 Keep for debugging - shows raw http body from response
                let datastring = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("***: data: \(String(datastring!))")
                
                let httpResponse = self.restAPI.httpResponse(data, response: response!, error: error as NSError?)
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: httpResponse)
            }
        })
        task.resume()
    }
    
    open func cleanUp() {}
    
    /*
    
    This is a valid HTTP DELETE = IG's is borked..
    
    func httpDelete(urlDict : Dictionary<String, Any>, notification : String, version : Int = 1) {
        httpMethod.DELETE
        
        var request          = NSMutableURLRequest()
        var url              = ""
        if let nonOptionalString = urlDict["url"] as? String { url = nonOptionalString }
        
        var parametersString = ""
        if let parametersDict = urlDict["parameters"] as? Dictionary<String, Any> {
            for (key, value) in parametersDict {
                parametersString = "\(parametersString)&\(key)=\(value)"
            }
        }
        
        if !parametersString.isEmpty { url = "\(url)?\(parametersString)" }
        
        request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        
        request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        // Configure request as per required by each broker
        switch broker {
        case .IG:
            request.addValue(headerCST,            forHTTPHeaderField: "CST")
            request.addValue(headerXSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
            request.addValue(apiKey,               forHTTPHeaderField: "X-IG-API-KEY")
            request.addValue("\(version)",         forHTTPHeaderField: "version")
        }
        
        let session = NSURLSession.sharedSession()
        let task    = session.dataTaskWithRequest(request, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                self.config.nc.postNotificationName(notification, object: error)
            } else {
                let httpResponse = self.restAPI.httpResponse(data, response: response!, error: error)
                self.config.nc.postNotificationName(notification, object: httpResponse)
            }
        })
        task.resume()
    }
*/
    
    func httpDeleteIG(_ urlDict : Dictionary<String, Any>, notification : String, version : Int = 1, isIGLogin : Bool = false) {
        var request = restAPI.httpRequest(httpMethod.post, urlDict: urlDict, delegate: self)
        
        // Configure request as per required by each broker
        switch broker {
        case .ig:
            request.addValue("\(version)", forHTTPHeaderField: "version")
            request.addValue("DELETE",             forHTTPHeaderField: "_method")
            
            switch isIGOAuth2 {
            case true: request = addIGOauth2Headers(request)
            case false:
                request.addValue(apiKey,       forHTTPHeaderField: "X-IG-API-KEY")
            
                if !isIGLogin {
                    request.addValue(headerCST,            forHTTPHeaderField: "CST")
                    request.addValue(headerXSecurityToken, forHTTPHeaderField: "X-SECURITY-TOKEN")
                }
            }
        }
        
//        print(request.allHTTPHeaderFields)
        
        let task    = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: error)
            } else {
                let httpResponse = self.restAPI.httpResponse(data, response: response!, error: error as NSError?)
                
                if isIGLogin {
                    if let http = response as? HTTPURLResponse {
                        if let x = http.allHeaderFields["CST"]              as? String { self.headerCST = x }
                        if let x = http.allHeaderFields["X-SECURITY-TOKEN"] as? String { self.headerXSecurityToken = x }
                    }
                }
                
                self.config.nc.post(name: Notification.Name(rawValue: notification), object: httpResponse)
            }
        })
        task.resume()
    }
    
}
