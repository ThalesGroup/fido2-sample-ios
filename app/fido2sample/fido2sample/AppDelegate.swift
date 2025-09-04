//
//
// Copyright © 2021 THALES. All rights reserved.
//

//
//  AppDelegate.swift
//  fido2sample
//

import UIKit
import CoreData
import Fido2

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var secureLog : SecureLog!
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Initialise SecureLog, to log necessary retrievable information.
        initializeSecureLog()
        
        // config the AppGroups
        TGFFido2Config.setAppGroup(appgroupIdentifier)
        
        // cert pinning
        setupCertPinning()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
      
        let tabBarController = UITabBarController()
        tabBarController.tabBar.isTranslucent = false

        let mainNVC = UINavigationController(rootViewController: HomeViewController())
        mainNVC.navigationBar.isTranslucent = false
        tabBarController.addChild(mainNVC)
        mainNVC.tabBarItem.image = #imageLiteral(resourceName: "home")
        mainNVC.tabBarItem.title = NSLocalizedString("tabbar_home_title", comment: "")
        
        let settingsNVC = UINavigationController(rootViewController: SettingsViewController())
        settingsNVC.navigationBar.isTranslucent = false
        tabBarController.addChild(settingsNVC)
        settingsNVC.tabBarItem.image = #imageLiteral(resourceName: "settings")
        settingsNVC.tabBarItem.title = NSLocalizedString("tabbar_settings_title", comment: "")
        
        self.window?.rootViewController = tabBarController
        
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: Private Methods
    
    private func setupCertPinning() {
        if let certPath = Bundle.main.path(forResource: ## fill your certificate name ##, ofType: "cer"),
           let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) {
            TGFFido2Config.setTlsCertificates([certData])
        }
    }
    
    private func initializeSecureLog() {
        
        //Configure SecureLog
        let config = SecureLogConfig { (slComps) in
            slComps.fileID = "fido2samp"

            //Set Mandatory parameters
            slComps.publicKeyModulus = NSData(bytes: SecureLogPublicKey.publicKeyModulus, length:SecureLogPublicKey.publicKeyModulus.count) as Data
            slComps.publicKeyExponent = NSData(bytes: SecureLogPublicKey.publicKeyExponent, length: SecureLogPublicKey.publicKeyExponent.count) as Data
        }
        //create instance of secure logger with configuration, only 1 instance is allowed to be created.
        secureLog = TGFFido2Config.setupSecureLog(config)
    }

}
