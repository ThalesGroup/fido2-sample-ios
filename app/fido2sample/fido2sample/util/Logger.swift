//
//  Logger.swift
//  fido2sample
//
//  Copyright © 2020 Thales Group. All rights reserved.
//

import UIKit

class Logger {
    static let logNotification: Notification.Name = Notification.Name(rawValue: "LogNotification")
    static let updateStringKey: String = "UpdateStringKey"
    
    private static var logString: String = ""
    static let nextLine = "\n"

    static func logs() -> String {
        return logString
    }
    
    static func log(string: String) {
        let newString: String = currentTime() + nextLine + string + nextLine
        logString += newString
        
        NotificationCenter.default.post(name: logNotification, object: nil, userInfo: [updateStringKey: newString])
        print(newString)
    }
    
    static func reset() {
        logString = ""
    }
    
    private static func currentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
        return dateFormatter.string(from: Date())
    }
}
