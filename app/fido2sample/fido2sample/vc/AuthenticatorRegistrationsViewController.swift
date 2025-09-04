//
//
// Copyright 2021-2022 THALES. All rights reserved.
//

import UIKit
import Fido2
import LocalAuthentication

// MARK: Custom Cell
class AuthenticatorCell: UITableViewCell {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let credentialLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let rpIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
        
    private let createdDate: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
      
    private let lastUsedDate: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .leading
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Setup layout
        contentView.addSubview(iconImageView)
        contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(credentialLabel)
        stackView.addArrangedSubview(rpIdLabel)
        stackView.addArrangedSubview(createdDate)
        stackView.addArrangedSubview(lastUsedDate)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            stackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Add separator line
        let separatorLine = UIView()
        separatorLine.backgroundColor = .separator
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    func configure(with authInfo: TGFFido2AuthenticatorRegistrationInfo) {
        credentialLabel.text = (Base64.encode(data: authInfo.credentialId! as Data))
        rpIdLabel.text = Base64.encode(data: authInfo.rpIdHash! as Data)
        
        if let creationDate = authInfo.creationDate {
            let formattedDate = formatDate(creationDate)
            createdDate.text = "Created: \(formattedDate)"
            createdDate.isHidden = false
        } else {
            createdDate.isHidden = true
        }
        
        if let lastUsedDate = authInfo.lastUsedDate {
            let formattedDate = formatDate(lastUsedDate)
            self.lastUsedDate.text = "Last used: \(formattedDate)"
            self.lastUsedDate.isHidden = false
        } else {
            self.lastUsedDate.isHidden = true
        }
        
        switch authInfo.verifyMethod {
        case .biometric:
            let context = LAContext()
            let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            if canEvaluate {
                switch context.biometryType {
                case .none:
                    fatalError("Device not registered with TouchID/FaceID")
                case .touchID:
                    iconImageView.image = #imageLiteral(resourceName: "authenticator_biometric")
                case .faceID:
                    iconImageView.image = #imageLiteral(resourceName: "authenticator_facial")
                default:
                    fatalError("Unsupported biometricType")
                }
            } else {
                fatalError("Error on evaluate biometricType")
            }
        case .passcode:
            iconImageView.image = #imageLiteral(resourceName: "authenticator_pin")
        case .platform:
            if #available(iOS 15.0, *) {
                iconImageView.image = UIImage(systemName: "key.fill")
                iconImageView.tintColor = UIColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1.0)
            } else {
                iconImageView.image = #imageLiteral(resourceName: "authenticator_pin")
            }
        default:
            fatalError("Unsupported verifyMethod")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectionStyle = .none
    }
}

class AuthenticatorRegistrationsViewController: UIViewController {
    
    var authenticatorRegistrationInfos: [TGFFido2AuthenticatorRegistrationInfo] = []

    fileprivate let tableView = UITableView()
    private let reuseIdentifier = "AuthenticatorCell"
    private let emptyStateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupEmptyState()
        
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
        do {
            self.authenticatorRegistrationInfos = try TGFFido2ClientFactory.client().authenticatorRegistrations()
            self.tableView.reloadData()
            updateEmptyStateVisibility()
        } catch let error as NSError {
            print(error)
        }
    }
    
    // MARK: Setup
    
    fileprivate func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.register(AuthenticatorCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 70
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
    }
    
    private func setupEmptyState() {
        emptyStateLabel.text = "No authenticators registered"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.isHidden = true
        
        view.addSubview(emptyStateLabel)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func updateEmptyStateVisibility() {
        emptyStateLabel.isHidden = !authenticatorRegistrationInfos.isEmpty
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Execute remove registered authenticator and row deletion
            do {
                let authInfo = authenticatorRegistrationInfos[indexPath.row]
                let client = try TGFFido2ClientFactory.client()
                try client.deleteAuthenticatorRegistration(authInfo)
                authInfo.wipe()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.tableView.setEditing(false, animated: true)
                    self?.toggleRightBarButton(isEdit: true)
                    self?.authenticatorRegistrationInfos.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self?.updateEmptyStateVisibility()
                }
            } catch let error {
                print("error: \(error)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            do {
                let authInfo = self.authenticatorRegistrationInfos[indexPath.row]
                let client = try TGFFido2ClientFactory.client()
                try client.deleteAuthenticatorRegistration(authInfo)
                authInfo.wipe()
                
                self.authenticatorRegistrationInfos.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.updateEmptyStateVisibility()
                completionHandler(true)
            } catch {
                print("error: \(error)")
                completionHandler(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? AuthenticatorCell else {
            fatalError("Failed to dequeue AuthenticatorCell")
        }
        
        let authInfo = authenticatorRegistrationInfos[indexPath.row]
        cell.configure(with: authInfo)
        
        return cell
    }
}
