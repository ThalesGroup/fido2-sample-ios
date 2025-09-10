//
//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import UIKit
import Fido2
import Fido2Ui

class Authentication: NSObject {
    
    private let clientConformer: (ClientConformer & TGFPasscodeAuthenticatorDelegate)
    
    // Set up an instance variable of FIDO2 client
    private let fido2Client = try? TGFFido2ClientFactory.client()
    
    init( clientConformer: (ClientConformer & TGFPasscodeAuthenticatorDelegate)) {
        self.clientConformer = clientConformer
    }
    
    func execute(completion: @escaping (Error?) -> ()) {
        
        // Get authenticator registrations to include in allowCredentials
        let registrations = getAuthenticatorRegistrations()
        
        // Build allowCredentials array for the payload
        var allowCredentialsJson = ""
        
        if !registrations.isEmpty {
            var credentialItems = [String]()
            
            for registration in registrations {
                if let credentialId = registration.credentialId {
                    let base64Id = Base64.encode(data: credentialId as Data)
                    credentialItems.append("    {\n      \"type\" : \"public-key\",\n      \"id\" : \"\(base64Id)\"\n    }")
                }
            }
            
            if !credentialItems.isEmpty {
                allowCredentialsJson = "\"allowCredentials\" : [\n" + credentialItems.joined(separator: ",\n") + "\n  ],\n"
            }
        }
        
        // Fido2 authentication request json string
        let jsonString = """
        {
          \(allowCredentialsJson)"userVerification" : "required",
          "challenge" : "AAABcqFVwBmaMa534c9FKrv7163Penj7",
          "rpId" : "\(rpId)"
        }
        """
        
        // Log Authentication request json string into Log view.
        Logger.log(string: "Authentication Request:\n" + jsonString)
        
        do {
            // Create Authentication request providing the required credentials.
            /* 1 */
            ## Create Fido2 request with json String ##
            
            // Setup an instance of TGFFido2RespondArgsBuilder with registration request
            // Initialize all necessary UI delegates required by FIDO2 SDK.
            // Ensure that you conform to these corresponding delegates.
            // Required callbacks are essential to ensure a proper UX behaviour.
            // As a means of convenience, the FIDO2 UI SDK provides a ClientConformer class which conforms to all necessary delegates of FIDO2 SDK
            /* 2 */
            ## Setup TGFFido2RespondArgsBuilder with UI delegates ##
            
            
            // Retrieve the FIDO2 Registration response.
            // Handle on error or response
            /* 3 */
            ## Retrieve FIDO2 response ##
        } catch let error {
            completion(error)
            Logger.log(string: "Authentication Error:\n" + error.localizedDescription)
        }
    }
    
    // MARK: Helper function
    // get authenticator registrations
    private func getAuthenticatorRegistrations() -> [TGFFido2AuthenticatorRegistrationInfo] {
        do {
            return try fido2Client?.authenticatorRegistrations() ?? []
        } catch let error {
            Logger.log(string: "Error getting authenticator registrations: \(error.localizedDescription)")
            return []
        }
    }
}
