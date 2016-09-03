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
    var transmitter: GlukitTransmitter
    
    init(username: String, password: String, transmitter: GlukitTransmitter) {
        self.username = username
        self.password = password
        self.transmitter = transmitter
    }
    
    func syncNewDataSince(syncTag: SyncTag) {
        let headers = [ "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        let parameters = [ "accountName": self.username,
                           "password": self.password,
                           "applicationId": "d89443d2-327c-4a6f-89e5-496bbb0317db"]
        
        Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName", parameters: parameters, headers: headers, encoding: .JSON)
            .responseString { response in
                if let result = response.result.value {
                    let sessionId = result.stringByTrimmingCharactersInSet(NSCharacterSet.init(charactersInString: "\""))
                    
                    let glucoseRequestParams = [ "sessionId": sessionId, "minutes": "2100", "maxCount": "420"]
                    Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues", parameters: glucoseRequestParams, headers: headers, encoding: .URLEncodedInURL)
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
                                
                                if (reads.count > 0) {
                                    let newReads = reads.filter { $0.time.timestamp > syncTag.lastGlucoseReadTimestamp }
                                    NSLog("filtered reads after \(syncTag.lastGlucoseReadTimestamp)")
                                    
                                    if (newReads.count > 0) {
                                        let sortedNewReads = newReads.sort { $1.time.timestamp > $0.time.timestamp }
                                        print("reads json: \(sortedNewReads.toJsonString(true)!)")
                                        
                                        GlukloaderUtils.saveGlucoseReadBatchToDisk(sortedNewReads)
                                        
                                        self.transmitter.transmit(sortedNewReads)
                                    } else {
                                        NSLog("No new records found")
                                    }
                                } else {
                                    NSLog("No records found")
                                }
                                
                            }
                    }
                }
        }
    }
}