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
        
        //Configure RASP, to crash app in case of hook/debugger/jailbreak detected.
//#if DEBUG
//        TGFRaspUiConfigure(TGF_RASP_TYPE_DEBUGGER ,TGF_RASP_MODE_DISABLE)
//        TGFRaspUiConfigure(TGF_RASP_TYPE_HOOK | TGF_RASP_TYPE_JAILBREAK ,TGF_RASP_MODE_CRASH)
//#else
//        TGFRaspUiConfigure(TGF_RASP_TYPE_DEBUGGER | TGF_RASP_TYPE_HOOK | TGF_RASP_TYPE_JAILBREAK,TGF_RASP_MODE_CRASH)
//#endif
        
        //Initialise SecureLog, to log necessary retrievable information.
        initializeSecureLog()
        
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
        
        self.window!.rootViewController = tabBarController
        
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: Private Methods
    
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

