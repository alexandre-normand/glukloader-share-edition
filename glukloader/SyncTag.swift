//
//  SyncTag.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/31/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import SwiftSerializer

class SyncTag : Serializable {
    var lastGlucoseReadTimestamp: Int64?
    
    init(lastGlucoseReadTimestamp: Int64?) {
        self.lastGlucoseReadTimestamp = lastGlucoseReadTimestamp
    }
}