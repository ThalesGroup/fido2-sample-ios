//
//
// Copyright 2021 THALES. All rights reserved.
//

//
//  SettingsViewController.swift
//  fido2sample
//

import UIKit
import Fido2Ui
import Fido2

fileprivate let settingsDataSource: [Section] = [
    Section(sectionType: .authenticators, rows: [
        Row(rowType: .registeredAuthenticators, reuseIdentifier: "", inputValue: nil, accessoryType: .disclosureIndicator),
    ]),
    Section(sectionType: .passcodeManagement, rows: [
        Row(rowType: .createPasscode, reuseIdentifier: "", inputValue: nil , accessoryType: .disclosureIndicator),
        Row(rowType: .changePasscode, reuseIdentifier: "", inputValue: nil, accessoryType: .disclosureIndicator),
        Row(rowType: .deletePasscode, reuseIdentifier: "", inputValue: nil, accessoryType: .disclosureIndicator),
        Row(rowType: .passcodeRules, reuseIdentifier: "", inputValue: nil, accessoryType: .disclosureIndicator),
        Row(rowType: .maxRetryCount, reuseIdentifier: "", inputValue: NSLocalizedString("maxRetryCount_subtitle", comment: "") , accessoryType: .none),
        Row(rowType: .baseLockoutDuration, reuseIdentifier: "", inputValue: NSLocalizedString("baseLockoutDuration_subtitle", comment: "") , accessoryType: .none),
    ]),
    Section(sectionType: .sdk, rows: [
        Row(rowType: .shareSecureLogs, reuseIdentifier: "", inputValue: nil, accessoryType: .none),
        Row(rowType: .reset, reuseIdentifier: "", inputValue: nil, accessoryType: .none),
    ])
]

class SettingsViewController: UIViewController {
    fileprivate let tableView = UITableView()
    fileprivate var dataSource = settingsDataSource
    private var secureLogObj : SecureLogArchive!
    
    private var passcodeAuthenticator: TGFPasscodeAuthenticator
    private let clientConformer: ClientConformer & TGFPasscodeAuthenticatorDelegate = PasscodePadClientConformer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = NSLocalizedString("settings_title", comment: "")
        setupTableView()
        
        view.backgroundColor = UIColor.extBackground
        setupLayout()
        
        setupPresentViewClosure()
    }
    
    init() {
        self.passcodeAuthenticator = TGFPasscodeAuthenticator(delegate: clientConformer)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    private func setupLayout() {
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

    private func shareLogFiles() {

        //Set up an instance of the SecureLogArchive to prepare archiving logfiles
        secureLogObj = SecureLogArchive.init()
        // Retreive archivePath
        let archivePath = secureLogObj.execute()

        //User press this button to send logfiles.
        let activityVC = UIActivityViewController(activityItems: [archivePath], applicationActivities: nil)
        //Support share files through airdrop & mail
        activityVC.excludedActivityTypes = [.addToReadingList,
                                            .assignToContact,
                                            .copyToPasteboard,
                                            .message,
                                            .openInIBooks,
                                            .postToFacebook,
                                            .postToFlickr,
                                            .postToTencentWeibo,
                                            .postToTwitter,
                                            .postToVimeo,
                                            .postToWeibo,
                                            .print,
                                            .saveToCameraRoll,
                                            .markupAsPDF]

        self.present(activityVC, animated: true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = dataSource[indexPath.section]
        let row = section.rows[indexPath.row]
        switch (section.sectionType, row.rowType) {
        
        case (.authenticators, .registeredAuthenticators):
            let authenticatorRegistrationsVC = AuthenticatorRegistrationsViewController()
            navigationController?.pushViewController(authenticatorRegistrationsVC, animated: true)

        case (.passcodeManagement, .maxRetryCount):
            let alertController = UIAlertController(title: NSLocalizedString("maxRetryCount_cell_title", comment: ""), message: nil, preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.keyboardType = .numberPad
            }
            alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: { (action) in
                if let value = alertController.textFields?.first?.text,
                    let intValue = UInt(value) {
                    // Execute to set Maximum retry count
                    TGFFido2Config.setMaximumRetryCount(intValue)
                }
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_cancel", comment: ""), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        case (.passcodeManagement, .baseLockoutDuration):
            let alertController = UIAlertController(title: NSLocalizedString("baseLockoutDuration_cell_title", comment: ""), message: nil, preferredStyle: .alert)
             alertController.addTextField { (textField) in
                 textField.keyboardType = .numberPad
             }
             alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", comment: ""), style: .default, handler: { (action) in
                 if let value = alertController.textFields?.first?.text,
                     let timeInterval = TimeInterval(value) {
                    // Execute to set base lockout duration
                     TGFFido2Config.setBaseLockoutDuration(timeInterval)
                 }
             }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_cancel", comment: ""), style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
            
        case (.passcodeManagement, .createPasscode):
            // Execute to Create passcode
            passcodeAuthenticator.createPasscode()
            break
        case (.passcodeManagement, .changePasscode):
            // Execute to Change passcode
            passcodeAuthenticator.changePasscode()
            break
        case (.passcodeManagement, .deletePasscode):
            // Execute to Delete passcode
            passcodeAuthenticator.deletePasscode()
            break
        
        case (.passcodeManagement, .passcodeRules):
            // Execute to Passcode Rules
            let passcodeRulesVC = PasscodeRulesViewController()
            navigationController?.pushViewController(passcodeRulesVC, animated: true)
            break
        
        case (.sdk, .shareSecureLogs):
            // Execute to zip and archieve secure logs to share
            self.shareLogFiles()
            break
        case (.sdk, .reset):
            let alertController = UIAlertController(title: nil,
                                                    message: NSLocalizedString("reset_alert_message", comment: ""),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_reset", comment: ""), style:.destructive, handler: { (action) in
                // Execute to Reset
                try? TGFFido2Client.reset()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("alert_cancel", comment: ""), style: .cancel, handler: nil))
            navigationController?.present(alertController, animated: true, completion: nil)
            break
        default:
            break
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].sectionType.description
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = dataSource[indexPath.section]
        let row = section.rows[indexPath.row]
        var cell: UITableViewCell!
        let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier)
        cell = dequeuedCell ?? UITableViewCell(style: .subtitle, reuseIdentifier: row.reuseIdentifier)
        
        cell.textLabel?.text = row.rowType.description
        cell.detailTextLabel?.text = row.inputValue ?? ""
        cell.accessoryType = row.accessoryType

        return cell
    }
}

fileprivate struct Section {
    let sectionType: SectionType
    var rows: [Row]
}

fileprivate enum SectionType: Int, CustomStringConvertible, CaseIterable {
    case authenticators = 0
    case passcodeManagement
    case sdk
    
    var description: String {
        switch self {
        case .authenticators:
            return NSLocalizedString("registeredAuthenticators_section_title", comment: "")
        case .passcodeManagement:
            return NSLocalizedString("passcodeManagement_section_title", comment: "")
        case .sdk:
            return NSLocalizedString("sdk_section_title", comment: "")
        }
    }
}

fileprivate struct Row {
    let rowType: RowType
    let reuseIdentifier: String
    let inputValue: String?
    let accessoryType: UITableViewCell.AccessoryType
}

fileprivate enum RowType: CustomStringConvertible, CaseIterable {
    case registeredAuthenticators
    
    case createPasscode
    case changePasscode
    case deletePasscode
    case passcodeRules
    case maxRetryCount
    case baseLockoutDuration

    case shareSecureLogs
    case reset
    
    var description: String {
        switch self {
        case .registeredAuthenticators:
            return NSLocalizedString("registeredAuthenticators_cell_title", comment: "")

        case .createPasscode:
            return NSLocalizedString("createPasscode_cell_title", comment: "")
        case .changePasscode:
            return NSLocalizedString("changePasscode_cell_title", comment: "")
        case .deletePasscode:
            return NSLocalizedString("deletePasscode_cell_title", comment: "")
        case .passcodeRules:
            return NSLocalizedString("passcodeRules_cell_title", comment: "")
        case .maxRetryCount:
            return NSLocalizedString("maxRetryCount_cell_title", comment: "")
        case .baseLockoutDuration:
            return NSLocalizedString("baseLockoutDuration_cell_title", comment: "")
            
        case .shareSecureLogs:
            return NSLocalizedString("shareSecureLogs_cell_title", comment: "")
        case .reset:
            return NSLocalizedString("reset_cell_title", comment: "")
        }
    }
}
