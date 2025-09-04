//
//
// Copyright © 2021 THALES. All rights reserved.
//

//
//  SecureLogArchive.swift
//  fido2sample
//

import Foundation
import SSZipArchive

class SecureLogArchive : NSObject {
    
    let logFilesFolderName : String = "LogFiles"

    override init() {
    }

    // Zip all secure log files and return the archived URL path.
    func execute() -> URL {
        let documentDirectory = Foundation.URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])!
        let archivePath = documentDirectory.absoluteString.appending("/\(logFilesFolderName).zip")

        // Get array of log files that logged by secure log
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let logFileURLs = delegate.secureLog.files()
        var logFilesPaths = [String]()
        for fileUrl in logFileURLs {
            logFilesPaths.append(fileUrl.path)
        }
        // Zip files
        SSZipArchive.createZipFile(atPath: archivePath, withFilesAtPaths: logFilesPaths)

        let zipFilePath = Foundation.URL(fileURLWithPath: archivePath)
        return zipFilePath
    }
}
