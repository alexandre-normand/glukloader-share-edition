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

class DexcomShareFetcher {
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func getAllDataSince(sinceExclusive: NSDate) -> String {
        let headers = [ "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        let parameters = [ "accountName": self.username,
                           "password": self.password,
                           "applicationId": "d89443d2-327c-4a6f-89e5-496bbb0317db"]
        var sessionId = ""
        Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName", parameters: parameters, headers: headers, encoding: .JSON)
            .responseString { response in
                if let result = response.result.value {
                    sessionId = result
                    print("the session id is \(sessionId)")
                }
        }
        
        
        return sessionId
    }
}