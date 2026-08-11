//
//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import UIKit
import Fido2
import Fido2Ui

class Registration: NSObject {
    
    private let username: String
    private let clientConformer: ClientConformer & TGFPasscodeAuthenticatorDelegate
    
    // Set up an instance variable of FIDO2 client
    private let fido2Client =  try? TGFFido2ClientFactory.client()
    
    init(username: String, clientConformer: (ClientConformer & TGFPasscodeAuthenticatorDelegate)) {
        self.username = username
        self.clientConformer = clientConformer
    }
    
    func execute(completion: @escaping (Error?) -> ()) {
        
        // Fido2 registration request json string
        let jsonString = """
        {
          "authenticatorSelection" : {
            "userVerification" : "required",
            "authenticatorAttachment" : "platform",
            "requireResidentKey" : false
          },
          "user" : {
            "name" : "\(username)",
            "displayName" : "\(username)",
            "id" : "\(Base64.randomBase64StringWithoutPadding(bytesLength: 16))"
          },
          "attestation" : "direct",
          "challenge" : "AAABcqFVwBmaMa534c9FKrv7163Penj7",
          "rp" : {
            "id" : "\(rpId)",
            "name" : "\(rpId)"
          },
          "pubKeyCredParams" : [
            {
              "type" : "public-key",
              "alg" : -7
            }
          ]
        }
        """
        
        // Log Registration request json string into Log view.
        Logger.log(string: "Registration Request:\n" + jsonString)
        
        do {
            // Create Registration request providing the required credentials.
            /* 1 */
            ## Create Fido2 request with json String ##
            let fidoRequest = try TGFFido2RequestFactory.request(jsonString)
            
            
            // Setup an instance of TGFFido2RespondArgsBuilder with registration request
            // Initialize all necessary UI delegates required by FIDO2 SDK.
            // Ensure that you conform to these corresponding delegates.
            // Required callbacks are essential to ensure a proper UX behaviour.
            // As a means of convenience, the FIDO2 UI SDK provides a ClientConformer class which conforms to all necessary delegates of FIDO2 SDK
            /* 2 */
            ## Setup TGFFido2RespondArgsBuilder with UI delegates ##
            let respondArgsBuilder = TGFFido2RespondArgsBuilder(request: fidoRequest, uiDelegate: clientConformer)
            respondArgsBuilder.uiBiometricAuthenticatorDelegate = clientConformer
            respondArgsBuilder.uiPasscodeAuthenticatorDelegate = clientConformer
            respondArgsBuilder.passcodeAuthenticator = TGFPasscodeAuthenticator(delegate: clientConformer)
            let respondArgs = respondArgsBuilder.respondArgs()

            // Retrieve the FIDO2 Registration response.
            // Handle on error or response
            /* 3 */
            ## Retrieve FIDO2 response ##
            self.fido2Client?.respond(with: respondArgs) {(response, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        Logger.log(string: "Registration Error:\n" + error.localizedDescription)
                        completion(error)
                        return
                    } else {
                        let responseString: String = response!.raw()
                        Logger.log(string: "Registration Response:\n" + responseString)
                        completion(nil)
                    }
                }
            }
            
            
        } catch let error {
            DispatchQueue.main.async {
                completion(error)
                Logger.log(string: "Registration Error:\n" + error.localizedDescription)
            }
        }
    }
}
