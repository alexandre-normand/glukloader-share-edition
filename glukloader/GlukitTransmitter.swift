//
//  GlukitTransmitter.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/31/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import p2_OAuth2

let GLUCOSE_READ_ENDPOINT = "https://glukit.appspot.com/v1/glucosereads"

class GlukitTransmitter {
    var oauth2: OAuth2
    
    init(oauth2: OAuth2) {
        self.oauth2 = oauth2
    }
    
    func transmit(reads: [GlucoseRead]) {
        let request = self.oauth2.request(forURL: NSURL(string: GLUCOSE_READ_ENDPOINT)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = reads.toJson(true)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = oauth2.session.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                NSLog("Error sending \(reads.count) to glukit: \(error.localizedDescription)")
            }
            else {
                let syncTag = SyncTag(lastGlucoseReadTimestamp: reads.last?.time.timestamp)
                NSLog("Successfully sent \(reads.count) reads to glukit, saving sync tag \(syncTag)")
                GlukloaderUtils.saveSyncTagToDisk(syncTag)
            }
        }
        
        task.resume()
    }
}