//
//  CredentialProviderViewController.swift
//  autofill
//

import AuthenticationServices
import Fido2Ui
import Fido2

class CredentialProviderViewController: TGFCredentialProviderViewController {
    
    let appGroup = ## fill the appGroup identifier here ##
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // call the config func to setup the securelog and appgroup
        setupConfigurations()
    }
    
    // MARK: - Fido2 Configuration
    private func setupConfigurations() {
        TGFFido2Config.setupSecureLog(nil)
        TGFFido2Config.setAppGroup(appGroup)
    }
}
