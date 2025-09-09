//
//
// Copyright 2021-2022 THALES. All rights reserved.
//

import UIKit
import Fido2

class AuthenticatorRegistrationsViewController: UIViewController, SelectableUi {
    
    var authenticatorRegistrationInfos: [TGFFido2AuthenticatorRegistrationInfo] = []
    let verifyMethod: TGFVerifyMethod
    let client = try! TGFFido2ClientFactory.client()

    fileprivate let tableView = UITableView()
    private let reuseIdentifier = "UITableViewCell"
    
    init(verifyMethod: TGFVerifyMethod,
         selectHandler: SelectableHandler?) {
        self.verifyMethod = verifyMethod
        self.selectHandler = selectHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init() {
        self.init(verifyMethod: .none, selectHandler: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        title = "Authenticator Registrations"
        view.backgroundColor = UIColor.extBackground
        layout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadData()
    }
    
    // MARK: SelectableUi
    
    var selectHandler: ((SelectableInfo) -> ())?
    
    func reloadData() {
        
        do {
            try self.authenticatorRegistrationInfos = client.authenticatorRegistrations().filter({ (authInfo) -> Bool in
                switch verifyMethod {
                case .biometric:
                    return authInfo.verifyMethod == .biometric
                case .passcode:
                    return authInfo.verifyMethod == .passcode
                case .platform:
                    return authInfo.verifyMethod == .platform
                case .none:
                    return true
                @unknown default:
                    fatalError("Unsupported verifyMethod")
                }
            })
        } catch let error {
            Logger.log(string: error.localizedDescription)
            return
        }

        self.tableView.reloadData()
    }
    
    // MARK: Setup
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = false
    }
}

extension AuthenticatorRegistrationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectHandler = self.selectHandler {
            let authInfo = authenticatorRegistrationInfos[indexPath.row]
            
            selectHandler(authInfo as! SelectableInfo)
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let authInfo = authenticatorRegistrationInfos[indexPath.row]
            do {
                try client.deleteAuthenticatorRegistration(authInfo)
            } catch _ {
                return
            }
            authInfo.wipe()
            authenticatorRegistrationInfos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
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
        cell.textLabel?.text = "CredID:\(Base64.encode(data: authInfo.credentialId! as Data))"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Singapore")
        var creationDateString = ""
        if let creationDate = authInfo.creationDate {
            creationDateString = formatter.string(from: creationDate)
        }
        var lastusedDataString = ""
        if let lastUsedDate = authInfo.lastUsedDate {
            lastusedDataString = formatter.string(from: lastUsedDate)
        }
        
        let metaData =
        "Username: \(authInfo.userName ?? "")"
        + "\nUserDisplayName: \(authInfo.userDisplayName ?? "")"
        + "\nRpId: \(authInfo.rpId ?? "")"
        + "\nRpIdHash:\(Base64.encode(data: authInfo.rpIdHash! as Data))"
        + "\nCreationDate: \(creationDateString)"
        + "\nLastUsedDate: \(lastusedDataString)"
        cell.detailTextLabel?.text = metaData
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}

extension AuthenticatorRegistrationsViewController: Layoutable {
    func layout() {
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
}

typealias SelectableHandler = ((SelectableInfo) -> ())

protocol SelectableInfo {
    var infoString: String { get }
}

protocol SelectableUi {
    var selectHandler: SelectableHandler? { get set }
    func reloadData()
}

protocol Layoutable {
    func layout()
}
