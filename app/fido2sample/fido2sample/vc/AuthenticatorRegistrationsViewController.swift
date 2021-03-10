//
//  AuthenticatorRegistrationsViewController.swift
//  fido2sample
//
//  Copyright © 2020 Thales Group. All rights reserved.
//

import UIKit
import Fido2
import LocalAuthentication

class AuthenticatorRegistrationsViewController: UIViewController {
    
    var authenticatorRegistrationInfos: [TGFFido2AuthenticatorRegistrationInfo] = []

    fileprivate let tableView = UITableView()
    private let reuseIdentifier = "registeredAuthenticators_reuseIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        title = NSLocalizedString("RegisteredAuthenticators_title", comment: "")
        view.backgroundColor = UIColor.extBackground
        
        toggleRightBarButton(isEdit: true)
        setUpLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadData()
    }
    
    // MARK: SelectableUi

    func reloadData() {
        self.authenticatorRegistrationInfos = TGFFido2ClientFactory.client().authenticatorRegistrations()
        self.tableView.reloadData()
    }
    
    // MARK: Setup
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = false
    }
    
    func setUpLayout() {
        guard tableView.translatesAutoresizingMaskIntoConstraints
            else {
                return
        }
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
    
    private func toggleRightBarButton(isEdit: Bool) {
        var button: UIBarButtonItem
        if isEdit {
            button = UIBarButtonItem(title: NSLocalizedString("edit_button_title", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(edit(_:)))
        } else {
            button = UIBarButtonItem(title: NSLocalizedString("cancel_button_title", comment: ""),
                                     style: .plain,
                                     target: self,
                                     action: #selector(cancel(_:)))
        }
        navigationItem.rightBarButtonItem = button
    }
    
    @objc internal func edit(_ button: UIBarButtonItem) {
        toggleRightBarButton(isEdit: false)
        tableView.setEditing(true, animated: true)
    }
    
    @objc internal func cancel(_ button: UIBarButtonItem) {
        toggleRightBarButton(isEdit: true)
        tableView.setEditing(false, animated: true)
    }
    
    private func showAlert(withTitle title: String, message: String, okAction: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: okAction))
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

extension AuthenticatorRegistrationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Execute remove registered authenticator and row deletion
            let authInfo = authenticatorRegistrationInfos[indexPath.row]
            let client = TGFFido2ClientFactory.client()
            client.deleteAuthenticatorRegistration(authInfo)
            authInfo.wipe()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.tableView.setEditing(false, animated: true)
                self?.toggleRightBarButton(isEdit: true)
                self?.authenticatorRegistrationInfos.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

extension AuthenticatorRegistrationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return authenticatorRegistrationInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if (cell == nil) {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        cell.selectionStyle = .none
        let authInfo = authenticatorRegistrationInfos[indexPath.row]
        cell?.textLabel?.text = Base64.encode(data: authInfo.credentialId! as Data)
        cell?.detailTextLabel?.text = Base64.encode(data: authInfo.rpIdHash! as Data)
        
        var image: UIImage
        switch authInfo.verifyMethod {
        case .proprietaryBiometric:
            let context = LAContext()
            let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            if canEvaluate {
                switch context.biometryType {
                case .none:
                    fatalError("Device not registered with TouchID/FaceID")
                case .touchID:
                    image = #imageLiteral(resourceName: "authenticator_biometric")
                case .faceID:
                    image = #imageLiteral(resourceName: "authenticator_facial")
                default:
                    fatalError("Unsupported biometricType")
                }
            } else {
                fatalError("Error on evaluate biometricType")
            }
        case .passcode:
            image = #imageLiteral(resourceName: "authenticator_pin")
        default:
            fatalError("Unsupported verifyMethod")
        }
        cell.imageView?.image = image
        
        return cell
    }
}




