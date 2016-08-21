//
//  GlukitTime.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/20/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation

class GlukitTime : CustomStringConvertible {
    var timezone: String
    var timestamp: Int64
    
    init(timestamp: Int64, timezone: String) {
        self.timestamp = timestamp
        self.timezone = timezone
    }
    
    var description:String {
        return "GlukitTime[timestamp=\(self.timestamp), timezone=\(self.timezone)]"
    }
}