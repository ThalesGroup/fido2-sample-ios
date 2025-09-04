//
//
// Copyright 2025 THALES. All rights reserved.
//

//
//  PasscodeRulesViewController.swift
//  fido2sample
//

import UIKit
import Fido2Ui
import Fido2

fileprivate let passcodeRulesDataSource: [Section] = [
    Section(sectionType: .passcodeSettings, rows: [
        Row(rowType: .disableScramble, reuseIdentifier: "disableScramble_reuseIdentifier", inputValue: nil, accessoryType: .none),
        Row(rowType: .minPasscodeLength, reuseIdentifier: "length_reuseIdentifier", inputValue: nil, accessoryType: .none),
        Row(rowType: .maxPasscodeLength, reuseIdentifier: "length_reuseIdentifier", inputValue: nil, accessoryType: .none),
    ]),
    Section(sectionType: .passcodeRules, rows: [
        Row(rowType: .length, reuseIdentifier: "passcodeRules_reuseIdentifier", inputValue: nil, accessoryType: .none),
        Row(rowType: .palindrome, reuseIdentifier: "passcodeRules_reuseIdentifier", inputValue: nil, accessoryType: .none),
        Row(rowType: .series, reuseIdentifier: "passcodeRules_reuseIdentifier", inputValue: nil, accessoryType: .none),
        Row(rowType: .uniform, reuseIdentifier: "passcodeRules_reuseIdentifier", inputValue: nil, accessoryType: .none),
    ])
]

class PasscodeRulesViewController: UIViewController {
    
    private var dataSource: [Section] = []
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let switchView = UISwitch(frame: .zero)
    
    // Static properties to store settings
    static var scrambledKeyboard: Bool = true
    static var minPasscodeLength: UInt = 6
    static var maxPasscodeLength: UInt = 8
    
    // Initial passcode rules. Triggered on app launch.
    static var passcodeRules: Set<TGFPasscodeRule> = [
        TGFPasscodeRuleLength(),
        TGFPasscodeRulePalindrome(),
        TGFPasscodeRuleSeries(),
        TGFPasscodeRuleUniform(),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("passcodeRules_cell_title", comment: "")
        view.backgroundColor = .systemBackground

        setupTableView()
        dataSource = passcodeRulesDataSource
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        do {
            try TGFPasscodeConfig.setPasscodeRules(PasscodeRulesViewController.passcodeRules)
        } catch let error {
            print("Error setting passcode rules: \(error.localizedDescription)")
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "disableScramble_reuseIdentifier")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "length_reuseIdentifier")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "passcodeRules_reuseIdentifier")
    }
}

extension PasscodeRulesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = dataSource[indexPath.section]
        let row = section.rows[indexPath.row]
        
        if row.reuseIdentifier == "disableScramble_reuseIdentifier" {
            switchView.setOn(true, animated: true)
            switchView.isEnabled = false
            switchView.isUserInteractionEnabled = false
            disableScrambledWithCellDisabled()
        }
        
        if indexPath.section == 0 {
            switch (row.rowType) {
            case .minPasscodeLength:
                let alertController = UIAlertController(title: RowType.minPasscodeLength.description, message: nil, preferredStyle: .alert)
                alertController.addTextField { (textField) in
                    textField.placeholder = NSLocalizedString("minPasscodeLength_placeholder", comment: "")
                    textField.keyboardType = .numberPad
                    textField.text = String(PasscodeRulesViewController.minPasscodeLength)
                }
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
                    if let value = alertController.textFields?.first?.text, let intValue = UInt(value) {
                        PasscodeRulesViewController.minPasscodeLength = intValue
                        TGFPasscodeRuleLength.setMinimum(intValue)
                    }
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
                present(alertController, animated: true, completion: nil)
                
            case .maxPasscodeLength:
                let alertController = UIAlertController(title: RowType.maxPasscodeLength.description, message: nil, preferredStyle: .alert)
                alertController.addTextField { (textField) in
                    textField.placeholder = NSLocalizedString("maxPasscodeLength_placeholder", comment: "")
                    textField.keyboardType = .numberPad
                    textField.text = String(PasscodeRulesViewController.maxPasscodeLength)
                }
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
                    if let value = alertController.textFields?.first?.text, let intValue = UInt(value) {
                        PasscodeRulesViewController.maxPasscodeLength = intValue
                        TGFPasscodeRuleLength.setMaximum(intValue)
                    }
                }))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
                present(alertController, animated: true, completion: nil)
                
            default:
                break
            }
        } else if indexPath.section == 1 {
            switch row.rowType {
            case .length:
                if let rule = PasscodeRulesViewController.passcodeRules(contain: TGFPasscodeRuleLength.self) {
                    PasscodeRulesViewController.passcodeRules.remove(rule)
                } else {
                    PasscodeRulesViewController.passcodeRules.insert(TGFPasscodeRuleLength())
                }
                
            case .palindrome:
                if let rule = PasscodeRulesViewController.passcodeRules(contain: TGFPasscodeRulePalindrome.self) {
                    PasscodeRulesViewController.passcodeRules.remove(rule)
                } else {
                    PasscodeRulesViewController.passcodeRules.insert(TGFPasscodeRulePalindrome())
                }
                
            case .series:
                if let rule = PasscodeRulesViewController.passcodeRules(contain: TGFPasscodeRuleSeries.self) {
                    PasscodeRulesViewController.passcodeRules.remove(rule)
                } else {
                    PasscodeRulesViewController.passcodeRules.insert(TGFPasscodeRuleSeries())
                }
                
            case .uniform:
                if let rule = PasscodeRulesViewController.passcodeRules(contain: TGFPasscodeRuleUniform.self) {
                    PasscodeRulesViewController.passcodeRules.remove(rule)
                } else {
                    PasscodeRulesViewController.passcodeRules.insert(TGFPasscodeRuleUniform())
                }
                
            default:
                break
            }
            
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = cell.accessoryType == .checkmark ? .none : .checkmark
            }
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        sender.isEnabled = false
        sender.isUserInteractionEnabled = false
        PasscodeRulesViewController.scrambledKeyboard = false
        
        if sender.isOn {
            disableScrambledWithCellDisabled()
        }
    }
    
    private func disableScrambledWithCellDisabled() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) else { return }
        cell.textLabel?.textColor = UIColor.lightGray
        cell.isUserInteractionEnabled = false
        cell.textLabel?.isEnabled = false
        
        // Execute to disable scramble passcode keyboard
        TGFPasscodeConfig.disableScrambled()
    }
    
    private static func passcodeRules(contain aClass: AnyClass) -> TGFPasscodeRule? {
        return PasscodeRulesViewController.passcodeRules.filter {
            $0.isMember(of: aClass.self)
        }.first
    }
}

extension PasscodeRulesViewController: UITableViewDataSource {
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

        if row.reuseIdentifier == "disableScramble_reuseIdentifier" {
            if PasscodeRulesViewController.scrambledKeyboard == false {
                switchView.setOn(true, animated: true)
                switchView.isEnabled = false
                switchView.isUserInteractionEnabled = false
                cell.textLabel?.textColor = UIColor.lightGray
                cell.isUserInteractionEnabled = false
                cell.textLabel?.isEnabled = false
            } else {
                switchView.setOn(false, animated: true)
                switchView.tag = indexPath.row
                switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            }
            cell.accessoryView = switchView
        } else if row.reuseIdentifier == "length_reuseIdentifier" {
            // Handle length cells
            if row.rowType == .minPasscodeLength {
                cell.detailTextLabel?.text = String(PasscodeRulesViewController.minPasscodeLength)
            } else if row.rowType == .maxPasscodeLength {
                cell.detailTextLabel?.text = String(PasscodeRulesViewController.maxPasscodeLength)
            }
        } else if row.reuseIdentifier == "passcodeRules_reuseIdentifier" {
            var ruleClass: AnyClass
            switch row.rowType {
            case .length:
                ruleClass = TGFPasscodeRuleLength.self
            case .palindrome:
                ruleClass = TGFPasscodeRulePalindrome.self
            case .uniform:
                ruleClass = TGFPasscodeRuleUniform.self
            case .series:
                ruleClass = TGFPasscodeRuleSeries.self
            default:
                fatalError("none else possible")
            }
            cell.accessoryType = PasscodeRulesViewController.passcodeRules(contain: ruleClass) != nil ? .checkmark : .none
        }
        return cell
    }
}

fileprivate struct Section {
    let sectionType: SectionType
    let rows: [Row]
}

fileprivate struct Row {
    let rowType: RowType
    let reuseIdentifier: String
    let inputValue: String?
    let accessoryType: UITableViewCell.AccessoryType
}

fileprivate enum SectionType: CustomStringConvertible {
    case passcodeSettings
    case passcodeRules
    
    var description: String {
        switch self {
        case .passcodeSettings:
            return NSLocalizedString("passcodeSettings_section_title", comment: "")
        case .passcodeRules:
            return NSLocalizedString("passcodeRules_section_title", comment: "")
        }
    }
}

fileprivate enum RowType: CustomStringConvertible {
    case disableScramble
    case minPasscodeLength
    case maxPasscodeLength
    case length
    case palindrome
    case series
    case uniform
    
    var description: String {
        switch self {
        case .disableScramble:
            return NSLocalizedString("disableScramble_cell_title", comment: "")
        case .minPasscodeLength:
            return NSLocalizedString("minPasscodeLength_cell_title", comment: "")
        case .maxPasscodeLength:
            return NSLocalizedString("maxPasscodeLength_cell_title", comment: "")
        case .length:
            return NSLocalizedString("passcodeRule_length_title", comment: "")
        case .palindrome:
            return NSLocalizedString("passcodeRule_palindrome_title", comment: "")
        case .series:
            return NSLocalizedString("passcodeRule_series_title", comment: "")
        case .uniform:
            return NSLocalizedString("passcodeRule_uniform_title", comment: "")
        }
    }
}
