//
//  HomeViewController.swift
//  fido2sample
//

import UIKit
import Fido2Ui
import Fido2

class HomeViewController: UIViewController {
    private let registerButton: UIButton = UIButton(type: .system)
    private let authenticateButton: UIButton = UIButton(type: .system)
    private var showLogsButton: UIBarButtonItem!
    private let textView = UITextView()
    
    private var registraterObj: Registration!
    private var authenticateObj: Authentication!

    // FIDO2 UI SDK provides a conformer to the necessary delegates of FIDO2 SDK
    // providing integrators with a convenient way of exploring the use-cases available.
    let clientConformer = ClientConformer()
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        initNavBar()
        
        navigationItem.title = NSLocalizedString("home_title", comment: "")
        
        view.backgroundColor = UIColor.extBackground
        let bgColor = UIColor(white: 0.9, alpha: 1.0)
        
        registerButton.setTitle(NSLocalizedString("register_button_title", comment: ""), for: .normal)
        registerButton.setTitleColor(UIColor.black, for: .normal)
        registerButton.backgroundColor = bgColor
        registerButton.addTarget(self, action: #selector(register(_:)), for: .touchUpInside)

        authenticateButton.setTitle(NSLocalizedString("authenticate_button_title", comment: ""), for: .normal)
        authenticateButton.setTitleColor(UIColor.black, for: .normal)
        authenticateButton.backgroundColor = bgColor
        authenticateButton.addTarget(self, action: #selector(authenticate(_:)), for: .touchUpInside)
 
        setupLayout()
        
        textView.isHidden = true
        textView.isEditable = false
        textView.text = Logger.logs()
        textViewScrollToBottom()

        // Set up the present View Closures. This is required to enable a proper management
        // of the view hierarchy.
        setupPresentViewClosure()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogs(notification:)), name: Logger.logNotification, object: nil)
    }

    private func setupPresentViewClosure() {
        clientConformer.presentViewClosure = { [weak self] (presentViewController: UIViewController) in
            if presentViewController is UIAlertController {
                self?.navigationController?.present(presentViewController, animated: true, completion: nil)
            } else {
                self?.navigationController?.pushViewController(presentViewController, animated: true)
            }
        }
        clientConformer.popViewClosure = { [unowned self] in
            self.navigationController?.popToViewController(self, animated: true)
        }
    }
    
    private func textViewScrollToBottom() {
        let range = NSMakeRange((textView.text as NSString).length - 1, 1);
        textView.scrollRangeToVisible(range)
    }
    
    // MARK: Notification Observers
    
    @objc internal func updateLogs(notification: Notification) {
        if let newLogs: String = notification.userInfo?[Logger.updateStringKey] as? String {
            textView.insertText(newLogs)
            textViewScrollToBottom()
        }
    }
    
    // MARK: IBActions

    @objc internal func register(_ button: UIButton) {
        textView.text = nil
        
        // Execute the Registration use-case.
        self.showInputUserNameAlertWindow()
    }

    @objc internal func authenticate(_ button: UIButton) {
        textView.text = nil
        
        // Show Alert if no authenticators registered.
        let registeredAuthenticatorsInfos: [TGFFido2AuthenticatorRegistrationInfo] = TGFFido2ClientFactory.client().authenticatorRegistrations()
        if registeredAuthenticatorsInfos.isEmpty {
            self.showAlert(withTitle: NSLocalizedString("alert_error_title", comment: ""), message: NSLocalizedString("authenticate_alert_message_no_registration", comment: ""), okAction: nil)
            return
        }
        
        // Execute the Authentication use-case.
  
        // Initialize an instance of the Authentication use-case, providing
        // (1) the clientConformer
        authenticateObj = Authentication(clientConformer: clientConformer)
        authenticateObj.execute { [weak self] (error) in
            // Remove all views displayed by the FIDO2 UI SDK.
            self?.navigationController?.popToRootViewController(animated: true)
            if ( error != nil) {
                // Display the result of the use-case and proceed accoridngly.
                let errorCode = (error! as NSError).code
                if(errorCode == TGFError.userLockout.rawValue) {
                    let userInfo = ((error! as NSError).userInfo[NSUnderlyingErrorKey] as! NSError).userInfo
                    // Show Lockout count down page in case of user lockout.
                    if (userInfo[NSLocalizedFailureReasonErrorKey] != nil) {
                        self?.showLockoutControllerWithLockoutTimeInterval()
                    }
                } else {
                    self?.showAlert(withTitle: NSLocalizedString("alert_error_title", comment: ""), message: error!.localizedDescription, okAction: nil)
                }
            } else {
                self?.showAlert(withTitle: NSLocalizedString("authenticate_alert_title", comment: ""), message: NSLocalizedString("authenticate_alert_message", comment: ""), okAction: nil)
            }
        }
    }
    
    @objc internal func initNavBar() {
        showLogsButton = UIBarButtonItem(title: NSLocalizedString("navbar_showlogs_title", comment: ""), style: .plain, target: self, action: #selector(showOrHideLogs))
        self.navigationItem.rightBarButtonItem  = showLogsButton
    }
    
    @objc private func showOrHideLogs() {
        if textView.isHidden == true {
            textView.isHidden = false
            showLogsButton.title = NSLocalizedString("navbar_hidelogs_title", comment: "")
        } else {
            textView.isHidden = true
            showLogsButton.title = NSLocalizedString("navbar_showlogs_title", comment: "")
        }
    }
    
    private func showLockoutControllerWithLockoutTimeInterval() {
        do {
            let lockoutInterval =  try TGFPasscodeAuthenticator.lockoutExpiryTimestamp().intValue
            if (lockoutInterval > 0){
                let lockoutVC = LockoutViewController()
                lockoutVC.lockoutTimeInterval = TimeInterval(lockoutInterval)

                lockoutVC.cancelHandler = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
                lockoutVC.completeHandler = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
                self.navigationController?.pushViewController(lockoutVC, animated: true)
            }
        } catch let error {
            Logger.log(string: error.localizedDescription)
        }
    }
    
    // MARK: Private Methods
    
    private func showInputUserNameAlertWindow() {
        let alertController = UIAlertController(title: NSLocalizedString("register_input_alert_title", comment: ""), message: NSLocalizedString("register_input_alert_message", comment: ""), preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = ""
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler:  {(action) in
            self.doRegister(username: alertController.textFields!.first!.text!)
        }))
        let cancelAction = UIAlertAction(title: NSLocalizedString("alert_cancel", comment: ""), style: .cancel, handler: { (alert: UIAlertAction!) -> Void in
        })
        alertController.addAction(cancelAction)
        self.parent?.present(alertController, animated: true, completion: nil)
    }
    
    private func doRegister(username: String) {
        // Initialize an instance of the Registration use-case, providing
        // (1) the username input from user
        // (2) the clientConformer
        registraterObj = Registration(username: username, clientConformer: clientConformer)
        registraterObj.execute { [weak self] (error) in
            // Remove all views displayed by the FIDO2 UI SDK.
            self?.navigationController?.popToRootViewController(animated: true)
            if ( error != nil) {
                // Display the result of the use-case and proceed accoridngly.
                self?.showAlert(withTitle: NSLocalizedString("alert_error_title", comment: ""), message: error!.localizedDescription, okAction: nil)
            } else {
                self?.showAlert(withTitle: NSLocalizedString("register_alert_title", comment: ""), message: NSLocalizedString("register_alert_message", comment: ""), okAction: nil)
            }
        }
    }

    // MARK: Convenience Methods

    private func showAlert(withTitle title: String, message: String, okAction: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: okAction))
        navigationController?.present(alertController, animated: true, completion: nil)
    }


    // MARK: Layout

    private func setupLayout() {
        guard registerButton.translatesAutoresizingMaskIntoConstraints,
              authenticateButton.translatesAutoresizingMaskIntoConstraints else {
                return
        }

        view.addSubview(registerButton)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            registerButton.heightAnchor.constraint(equalToConstant: 48),
            registerButton.topAnchor.constraint(equalTo: view.topAnchor, constant: self.view.frame.size.height / 4),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0)
        ])

        view.addSubview(authenticateButton)
        authenticateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            authenticateButton.heightAnchor.constraint(equalTo: registerButton.heightAnchor),
            authenticateButton.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -16.0),
            authenticateButton.leadingAnchor.constraint(equalTo: registerButton.leadingAnchor),
            authenticateButton.trailingAnchor.constraint(equalTo: registerButton.trailingAnchor),
        ])
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo:view.layoutMarginsGuide.centerYAnchor),
            textView.bottomAnchor.constraint(equalTo:view.layoutMarginsGuide.bottomAnchor, constant: -16.0),
            textView.leadingAnchor.constraint(equalTo:view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo:view.layoutMarginsGuide.trailingAnchor)
        ])
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.extLabel.cgColor
        textView.layer.cornerRadius = 8.0
    }
}

extension HomeViewController {
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textView.layer.borderColor = UIColor.extLabel.cgColor
    }
}
