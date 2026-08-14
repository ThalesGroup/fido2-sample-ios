//
//
// Copyright © 2020 THALES. All rights reserved
//  SamplePersistence.swift
//  fido2sample
//
//

import Foundation

struct SamplePersistence {
    private static let IsEulaAccepted: String = "IsEulaAcceptedKey"

    static var isEulaAccepted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: self.IsEulaAccepted)
        }
    }
    
    static func setEulaAccepted(_ isEulaAccepted: Bool) {
        UserDefaults.standard.set(isEulaAccepted, forKey: self.IsEulaAccepted)
    }
}

