//
//  AppDelegate.swift
//  glukloader
//
//  Created by Alexandre Normand on 8/19/16.
//  Copyright © 2016 Alexandre Normand. All rights reserved.
//

import Cocoa
import p2_OAuth2
import KeychainSwift
import Alamofire

//Example of GlukitSecrets (not to be committed):
//struct GlukitSecrets {
//    static let clientId = "id"
//    static let clientSecret = "secret"
//}

let oauth2Settings = [
    "client_id": GlukitSecrets.clientId,
    "client_secret": GlukitSecrets.clientSecret,
    "consumer_key": GlukitSecrets.clientId,
    "consumer_secret": GlukitSecrets.clientSecret,
    "authorize_uri": "https://glukit.appspot.com/authorize",
    "token_uri": "https://glukit.appspot.com/token",
    "scope": "",
    "redirect_uris": ["x-glukloader://oauth/callback"],   
    "keychain": true,
    ] as OAuth2JSON
let oauth2 = OAuth2CodeGrant(settings: oauth2Settings)

let KEYCHAIN_DEXCOM_SHARE_USERNAME_KEY = "dexcomShare-username"
let KEYCHAIN_DEXCOM_SHARE_PASSWORD_KEY = "dexcomShare-password"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let menuBarIcon = GlukloaderYosemite.imageOfGlukitIcon
    let keychain = KeychainSwift()
    
    @IBOutlet weak var settingsWindow: NSPanel!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet var autoStartMenuItem: NSMenuItem!
    @IBOutlet var saveSettingsButton: NSButton!
    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var validationMessageField: NSTextField!
    var statusBar: NSStatusItem!
    var syncTimer: NSTimer?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        self.statusBar = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
        
        self.statusBar.menu = self.statusMenu
        self.statusBar.image = menuBarIcon

        
        oauth2.onAuthorize = { parameters in
            print("Did authorize with parameters: \(parameters)")
        }
        oauth2.onFailure = { error in        // `error` is nil on cancel
            if let error = error {
                print("Authorization went wrong: \(error)")
            }
        }
        
        oauth2.authorize()
        
        startPeriodicSyncIfConfigured()
    }

    func startPeriodicSyncIfConfigured() {
        if let _ = keychain.get(KEYCHAIN_DEXCOM_SHARE_USERNAME_KEY), _ = keychain.get(KEYCHAIN_DEXCOM_SHARE_PASSWORD_KEY) {
            self.syncTimer = NSTimer.scheduledTimerWithTimeInterval(60.0 * 60.0, target: self, selector: #selector(AppDelegate.runSync), userInfo: nil, repeats: true)
            self.syncTimer!.fire()
        }
    }
    
    func runSync() {
        if let username = keychain.get(KEYCHAIN_DEXCOM_SHARE_USERNAME_KEY), password = keychain.get(KEYCHAIN_DEXCOM_SHARE_PASSWORD_KEY) {
            let fetcher = DexcomShareSyncManager(username: username, password: password, transmitter: GlukitTransmitter(oauth2: oauth2))
            fetcher.syncNewDataSince(GlukloaderUtils.loadSyncTagFromDisk())
        }
    }
    
    
    func applicationWillFinishLaunching(notification: NSNotification) {
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(self, andSelector:#selector(AppDelegate.handleGetURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "glukit.glukloader" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.URLByAppendingPathComponent("glukit.glukloader")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("glukloader", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CocoaAppCD.storedata")
            do {
                try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
            } catch {
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.sharedApplication().presentError(nserror)
            }
        }
    }
    
    @IBAction func quit(sender: AnyObject!) {
        NSApp.terminate(self)
    }
    
    @IBAction func toggleAutoStart(sender: AnyObject!) {
        
    }
    
    @IBAction func openSettings(sender: AnyObject!) {
        settingsWindow.setIsVisible(true)
    }
    
    @IBAction func validateAndSaveSettings(sender: AnyObject!) {
        // Disable save button to prevent user from initiating multiple validation requests
        saveSettingsButton.enabled = false
        
        let headers = [ "User-Agent": "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"]
        let parameters = [ "accountName": usernameField.stringValue,
                           "password": passwordField.stringValue,
                           "applicationId": "d89443d2-327c-4a6f-89e5-496bbb0317db"]
        
        Alamofire.request(.POST, "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName", parameters: parameters, headers: headers, encoding: .JSON)
            .validate()
            .responseString { response in
                switch response.result {
                case .Success:
                    print("Validation Successful")
                    self.validationMessageField.stringValue = "Login successful"
                    self.keychain.set(self.usernameField.stringValue, forKey: KEYCHAIN_DEXCOM_SHARE_USERNAME_KEY)
                    self.keychain.set(self.passwordField.stringValue, forKey: KEYCHAIN_DEXCOM_SHARE_PASSWORD_KEY)
                    self.saveSettingsButton.enabled = true
                    self.settingsWindow.setIsVisible(false)
                case .Failure(let error):
                    print("Error validating dexcom share credentials \(error.localizedDescription)")
                    self.validationMessageField.stringValue = "Invalid credentials, could not log in"
                    self.saveSettingsButton.enabled = true
                }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
            return .TerminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .TerminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .TerminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButtonWithTitle(quitButton)
            alert.addButtonWithTitle(cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertFirstButtonReturn {
                return .TerminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }
    
    func handleGetURLEvent(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue, url = NSURL(string: urlString) {
            if (url.host == "oauth") {
                oauth2.handleRedirectURL(url)
            } else {
                // Google provider is the only one wuth your.bundle.id url schema.
                oauth2.handleRedirectURL(url)
            }
        }
    }
    
}

