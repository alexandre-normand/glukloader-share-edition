//
//  DexcomShareFetcher.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/19/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import SwiftSerializer

class DexcomShareSyncManager {
    var username: String
    var password: String
    var sessionId: String?
    
    init(username: String, password: String, sessionId: String?) {
        self.username = username
        self.password = password
        self.sessionId = sessionId
    }
    
    func syncNewDataSince(sinceExclusive: NSDate) -> String? {
        let headers = [ "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        let parameters = [ "accountName": self.username,
                           "password": self.password,
                           "applicationId": "d89443d2-327c-4a6f-89e5-496bbb0317db"]
        
        Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName", parameters: parameters, headers: headers, encoding: .JSON)
            .responseString { response in
                if let result = response.result.value {
                    let sessionId = result.stringByTrimmingCharactersInSet(NSCharacterSet.init(charactersInString: "\""))
                    print("session id is \(sessionId)")
                    
                    let glucoseRequestParams = [ "sessionId": sessionId, "minutes": "60", "maxCount": "100"]
                    let glucoseReq = Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues", parameters: glucoseRequestParams, headers: headers, encoding: .URLEncodedInURL)
                        .responseJSON { response in
                            if let glucoseResult = response.result.value {
                                let json = JSON(glucoseResult)
                                
                                var reads: [GlucoseRead] = []
                                for (_, read):(String, JSON) in json {
                                    let value = Double(read["Value"].rawString()!)
                                    let timestampString = String(read["WT"].rawString()!.characters.dropFirst(6).dropLast(2))
                                    let timestamp = Double(timestampString)
                                    let localTimeZone = NSTimeZone.localTimeZone()
                                    reads.append(GlucoseRead(value: value!, unit: "mgPerDL", time: GlukitTime(timestamp: Int64(timestamp!), timezone: localTimeZone.name)))
                                }
                                
                                print("reads json: \(reads.toJsonString()!)")
                            }
                    }
                    debugPrint(glucoseReq)
                }
        }
        
        return self.sessionId
    }
}