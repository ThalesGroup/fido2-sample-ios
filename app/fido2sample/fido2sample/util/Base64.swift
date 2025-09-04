//
//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import Foundation

struct Base64 {
    static func decode(string: String) -> Data? {
         let nonUrlEncoded = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
         let length = Float(nonUrlEncoded.lengthOfBytes(using: .utf8))
         let ceilx = ceil(length/4.0)
         let paddingLength = Int(ceilx*4.0)
         let addPadding = nonUrlEncoded.padding(toLength: paddingLength, withPad: "=", startingAt: 0)
         
         return Data(base64Encoded: addPadding)
     }
    
    static func encode(data: Data) -> String {
        let original = data.base64EncodedString()
        let urlEncoded = original.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        let removePadding = urlEncoded.replacingOccurrences(of: "=", with: "")
        return removePadding
    }
    
    static func encode(string: String) -> String {
        return encode(data: string.data(using: .utf8)!)
    }
    
    static func encode(dict: [String: Any]) -> String? {
        guard var data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else { return nil }
        let output = encode(data: data)
        data.resetBytes(in: 0..<data.count)
        return output
    }
    
    static func randomBase64StringWithoutPadding(bytesLength: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: bytesLength)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytesLength, &bytes)
        
        guard result == errSecSuccess else {
            fatalError("Unable to generate random bytes")
        }
        
        let data = Data(bytes: bytes, count: bytesLength)
        let string = data.base64EncodedString().replacingOccurrences(of: "=", with: "")

        return string.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
    }
}
