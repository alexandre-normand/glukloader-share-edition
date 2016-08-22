//
//  GlukitTime.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/20/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import SwiftSerializer

class GlukitTime : Serializable {
    var timezone: String
    var timestamp: Int64
    
    init(timestamp: Int64, timezone: String) {
        self.timestamp = timestamp
        self.timezone = timezone
    }
}