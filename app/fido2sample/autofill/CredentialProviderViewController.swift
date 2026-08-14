//
//  CredentialProviderViewController.swift
//  autofill
//

import AuthenticationServices
import Fido2Ui
import Fido2

class CredentialProviderViewController: TGFCredentialProviderViewController {
    
    let appgroupIdentifier: String = ## fill your appgroupIdentifier here ##
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConfigurations()
    }
    
    // MARK: - Fido2 Configuration
    private func setupConfigurations() {
        TGFFido2Config.setupSecureLog(nil)
        TGFFido2Config.setAppGroup(appgroupIdentifier)
    }
}
