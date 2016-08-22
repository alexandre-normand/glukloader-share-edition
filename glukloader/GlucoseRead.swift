//
//  GlucoseRead.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/20/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import SwiftSerializer

class GlucoseRead : Serializable {
    var value: Double
    var unit: String
    var time: GlukitTime
    
    init(value: Double, unit: String, time: GlukitTime) {
        self.value = value
        self.unit = unit
        self.time = time
    }
}