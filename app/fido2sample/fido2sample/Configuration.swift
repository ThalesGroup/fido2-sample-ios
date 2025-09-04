//
//
// Copyright © 2021 THALES. All rights reserved.
//

//
//  Configuration.swift
//  fido2sample
//
//

import Foundation

// Fido2 Securelog public key
struct SecureLogPublicKey {
    //Replace this byte array with your own public key modulus.
    static let publicKeyModulus: [CUnsignedChar] = []  ## update your publicKeyModulus domain here ##
    //Replace this byte array with your own public key exponent.
    static let publicKeyExponent: [CUnsignedChar] = []  ## update your publicKeyExponent domain here ##
}

// Fido2 rpId, Replace this value to your own rpId
let rpId: String = ## fill your rp domain here ##

// 
let appgroupIdentifier: String = ## fill your appgroupIdentifier here ##


