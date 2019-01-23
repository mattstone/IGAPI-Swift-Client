//
//  IGApiRestApi.swift
//  IGApi
//
//  Created by Matt Stone on 2/04/2016.
//  Copyright © 2016 Matt Stone. All rights reserved.
//

import Foundation


var MSIGBrokersRestAPISharedInstance = MSIGBrokersRestAPI()

enum restVerb {
    case show
    case create
    case update
    case delete
}

enum httpMethod {
    case get
    case put
    case post
    case delete
}

class MSIGBrokersRestAPI : NSObject {
    
    public static let sharedInstance = MSIGBrokersRestAPI()
    
    let config   = MSIGBrokersConfig.sharedInstance
    let includes = MSIGBrokersIncludes.sharedInstance
    
    func buildNSMutableURLRequest(_ httpMethod: String, url : String, parameters : Dictionary<String, Any>, access_token : String = "") -> NSMutableURLRequest {
        
        // Create request
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        do {
            // JSON serialize parameters
            
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            request.httpMethod = httpMethod
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Accept")
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            
            request.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
            
            switch request.httpMethod {
            case "GET": break
            default:    request.httpBody = jsonData
            }
            
            //            includes.debugPrint(any: "access_token: \(access_token) **********************************")
            //            includes.debugPrint(any: request.allHTTPHeaderFields!)
            //            includes.debugPrint(any: request.HTTPMethod)
            //            includes.debugPrint(any: request.HTTPBody)
            //            includes.debugPrint(any: "-------------------------------------------------------")
            
        } catch { includes.debugPrint(any: "TSRestAPI.buildNSMutableURLRequest : \(error)") }
        
        return request
    }
    
    func httpRequest(_ method : httpMethod, urlDict: Dictionary<String, Any>, delegate: Any) -> NSMutableURLRequest {
        
        var url        = ""
        var parameters = Dictionary<String, Any>()
        
        if let temp = urlDict["url"] as? String { url = temp } // Swift safe typing malarkey..
        if let temp = urlDict["parameters"] as? Dictionary<String, Any> { parameters = temp }
        
        switch method {
        case .get:
            // Build & encode url
            var parametersString = ""
            for (key, value) in parameters { parametersString += "\(key)=\(value)&" }
            parameters.removeAll()
            return buildNSMutableURLRequest("GET", url : url, parameters : parameters)
            
        case .post, .put:
            let httpMethod = method == .post ? "POST" : "PUT"
            return buildNSMutableURLRequest(httpMethod, url : url, parameters : parameters)
            
        case .delete: break
        }
        
        return NSMutableURLRequest() // return empty request if we get here.. :-(
    }
    
    func httpResponse(_ data: Data?, response : URLResponse, error : NSError?) -> Dictionary<String, Any> {
        var httpResponse = Dictionary<String, Any>()
        
        if error != nil {
            httpResponse["error"] = error!
        } else {
            do {

                if let http = response as? HTTPURLResponse {
                    
                    httpResponse["httpStatusCode"] = http.statusCode as Any?

                    switch http.statusCode {
                    case 200:
                        
                        if data != nil {
                            switch String(describing: data!) {
                            case "<>": httpResponse["json"] = Dictionary<String, Any>() as Any? // IG empty json..
                            default:
                                
                                httpResponse["json"] = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                                
                                if let dict = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary {
                                    httpResponse["json"] = dict
                                }
                                
                                if let array = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? Array<Any> {
                                    httpResponse["json"] = array
                                }
                                
                            }
                        }
                        
                    default:
                        
                        /* 
                         
                         TODO: This is IG Specific.. 
                         
                        
                         If IG has provided an error message, pass this back to the calling routine
                         
                        */
                        
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                            
                            if json != nil {
                                if let error = json!["errorCode"] as? String {
                                    httpResponse["error"] = error as Any?
                                    return httpResponse
                                }
                            }
                        } catch { // ignore error.. this catch just means that we will not crash!
                            includes.debugPrint(any: "We crashed.... :=-( -- invalid JSON returned..")
                            let datastring = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                            includes.debugPrint(any: "***: data: \(String(datastring!))")

                        }
                        
                        // If we get here.. there is an
                        switch http.statusCode {
                        case 400: httpResponse["error"] = "Bad Request"         as Any?
                        case 401: httpResponse["error"] = "Unauthorised"        as Any?
                        case 402: httpResponse["error"] = "Payment Required"    as Any?
                        case 403: httpResponse["error"] = "Forbidden"           as Any?
                        case 404: httpResponse["error"] = "Not Found"           as Any?
                        case 405: httpResponse["error"] = "Method Not Allowed"  as Any?
                        case 406: httpResponse["error"] = "Not Acceptable"      as Any?
                        case 407: httpResponse["error"] = "Proxy Authentication requried" as Any?
                        case 408: httpResponse["error"] = "Request Timeout"     as Any?
                        case 409: httpResponse["error"] = "Conflict"            as Any?
                        case 408: httpResponse["error"] = "Gone"                as Any?
                        case 503: httpResponse["error"] = "Service Unavailable" as Any?
                        default:
                            httpResponse["error"] = "Unknown" as Any?
                        }
                    }
                }
            } catch {
                httpResponse["error"] = "Invalid response from server" as Any?
            }
        }
        return httpResponse
    }
    
    
    // Handle JSON Response..
    
    func jsonResponse(_ _responseData: NSMutableData) -> NSDictionary {
        var dictionary = NSDictionary()
        
        do {
            let responseString = NSString(data:_responseData as Data, encoding:String.Encoding.utf8.rawValue)
            let jsonData       = responseString!.data(using: String.Encoding.utf8.rawValue)
            dictionary = try JSONSerialization.jsonObject(with: jsonData!, options: []) as! NSDictionary
            
        } catch { includes.debugPrint(any: "TSRestAPI.jsonResponse: \(error)") }
        
        return dictionary
    }
}
