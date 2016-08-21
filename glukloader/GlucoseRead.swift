//
//  GlucoseRead.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/20/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation

class GlucoseRead : CustomStringConvertible {
    var value: Double
    var unit: String
    var time: GlukitTime
    
    init(value: Double, unit: String, time: GlukitTime) {
        self.value = value
        self.unit = unit
        self.time = time
    }
    
    var description:String {
        return "GlucoseRead[value=\(self.value), unit=\(self.unit), time=\(self.time)]"
    }
}