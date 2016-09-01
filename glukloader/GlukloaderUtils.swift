//
//  GlukloaderUtils.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/31/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftSerializer


class GlukloaderUtils {
    static func pathForFilename(filename: String) -> String {
        let fileManager = NSFileManager.defaultManager()
        let folder = self.glukitRoot()
        
        if (!fileManager.fileExistsAtPath(folder)) {
            do {
                try fileManager.createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError {
                print("Error creating directory to hold data and state: \(error.localizedDescription)");
            }
        }
        
        return (folder as NSString).stringByAppendingPathComponent(filename)
    }
    
    static func glukitRoot() -> String {
        let folder: NSString = "~/Library/Application Support/Glukloader-Share/"
        return folder.stringByExpandingTildeInPath
    }
    
    static func loadSyncTagFromDisk() -> SyncTag {
        let path = self.pathForStateFile()
        do {
            let contents = try NSString(contentsOfFile: path, usedEncoding: nil) as String
            let json = JSON(contents)
            return SyncTag(lastGlucoseReadTimestamp: json["lastGlucoseReadTimestamp"].int64)
        } catch let error as NSError {
            print("Could not load SyncTag from file \(path), defaulting to initial sync: \(error.localizedDescription)")
            return SyncTag(lastGlucoseReadTimestamp: nil)
        }
    }
    
    static func saveSyncTagToDisk(syncTag: SyncTag) {
        let path = self.pathForStateFile()
        let serializedSyncTag = syncTag.toJsonString(true)
        do {
          try serializedSyncTag!.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Could not save SyncTag to file \(path), will reload from previous state next time: \(error.localizedDescription)")
        }
    }
    
    static func pathForStateFile() -> String {
        return self.pathForFilename("Glukloader.state")
    }
    
    static func fileNameForGlucoseReads(firstRecordDate: NSDate) -> String {
        let filenameDateFormatter = NSDateFormatter()
        filenameDateFormatter.dateFormat = "dd-MM-yyyy'T'hh:mm:ssZ"
        
        return "glucoseReads-" + filenameDateFormatter.stringFromDate(firstRecordDate) + ".json"
    }
    
    static func saveGlucoseReadBatchToDisk(reads: [GlucoseRead]) {
        let oldestRecord = NSDate(timeIntervalSince1970: Double(reads.first!.time.timestamp) / 1000)
        let recordFilename = self.fileNameForGlucoseReads(oldestRecord)
        let recordFullPath = self.pathForFilename(recordFilename)
        
        do {
            try reads.toJsonString(true)?.writeToFile(recordFullPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print("Could not save records to file \(recordFullPath): \(error.localizedDescription)")
        }
    }
}