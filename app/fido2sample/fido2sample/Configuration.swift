//
//  Configuration.swift
//  fido2sample
//
//

import Foundation

// Fido2 Securelog public key
struct SecureLogPublicKey {
    //Replace this byte array with your own public key modulus.
     static let publicKeyModulus: [CUnsignedChar] = []
    //Replace this byte array with your own public key exponent.
    static let publicKeyExponent: [CUnsignedChar] = []
}

// Fido2 rpId, Replace this value to your own rpId
let rpId: String = ""
