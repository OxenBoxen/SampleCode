//
//  CNContactStoreUtility.swift
//  MomBank
//
//  Created by Matthew Sabath on 11/6/19.
//  Copyright © 2019 Sabath, Matthew. All rights reserved.
//

import Foundation
import ContactsUI
import Contacts
import UIKit


@objc protocol ContactSelectionUtilityDelegate: class {
    
    @objc optional func contactSelectionUtilityDidReturnContact(_ contact: CNContact)
    @objc optional func contactSelectionUtilityUserCanceled()
}

class ContactSelectionUtility: NSObject, CNContactPickerDelegate {
    
    weak var delegate: ContactSelectionUtilityDelegate?
       
    var contactPickerController = CNContactPickerViewController()
    weak var viewController: UIViewController!
    let kAppName = "MomBank"
    
    
    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    func selectContactFromViewController(_ vc: UIViewController) {
        
        viewController = vc
        
        let status = CNContactStore.authorizationStatus(for: .contacts) 
        
        if status == .notDetermined {
            
            CNContactStore().requestAccess(for: .contacts) { (access, error) in
                
                if error == nil {
                    self.presentContactViewController()
                    
                } else {
                    self.throwGeneralErrorAlert()
                }
            }

        } else if status == .restricted {
            throwContactsRestrictedAlert()
            
        } else if status == .denied {
            throwContactsDeniedAlert()
        
        } else {
            // authorized
            presentContactViewController()
        }
    }
    
    func presentContactViewController() {
        
        DispatchQueue.main.async {
            
            let vc = CNContactPickerViewController()
            
            vc.delegate = self
            
            if let vc = self.viewController?.presentedViewController {
                vc.presentedViewController!.present(vc, animated: true, completion: nil)
                
            } else {
                
                if let navVC = self.viewController.navigationController {
                    navVC.present(vc, animated: true, completion: nil)
                    
                } else {
                    self.viewController.present(vc, animated: true, completion: nil)
                }
            }
        }
    }

    
    // MARK: - CNContactPickerDelegate
    func contactPicker(_ picker: CNContactPickerViewController,
                       didSelect contact: CNContact) {
        
        delegate?.contactSelectionUtilityDidReturnContact?(contact)
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        delegate?.contactSelectionUtilityUserCanceled?()
    }
    
    
    // MARK: - Alerts
    func throwGeneralErrorAlert() {
        
        DispatchQueue.main.async {
            
            let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                       message: "Seems there was a problem getting Contacts data. " +
                                                                                "Please try again!",
                                                                       preferredStyle: .alert)
            
            let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                        style: .default) { [weak self] _  in
                
                self?.delegate?.contactSelectionUtilityUserCanceled?()
            }
            
            alertController.addAction(okAction)
            
            self.viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func throwContactsRestrictedAlert() {
        
        DispatchQueue.main.async {
            let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                       message: "Seems like there are some restrictions for importing Contacts data. " +
                                                                                "This could be due to Parental Controls being in place. " +
                                                                                "You may need to update this via the Settings app.",
                                                                       preferredStyle: .alert)
            
            let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                        style: .default) { [weak self] _  in
                
                self?.delegate?.contactSelectionUtilityUserCanceled?()
            }
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
                
                if let phoneSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    
                    UIApplication.shared.open(phoneSettingsUrl,
                                              options: [:]) { (sucess) in
                    }
                }
            }
            
            alertController.addAction(settingsAction)
            alertController.addAction(okAction)
            
            self.viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func throwContactsDeniedAlert() {
        
        DispatchQueue.main.async {
            let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                       message: "\(self.kAppName) needs access to your Contacts in order to import Contacts data. " +
                                                                                "Please go to the Settings App and re-allow Contacts permissions",
                                                                       preferredStyle: .alert)
            
            let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                        style: .default) { [weak self] _  in
                
                self?.delegate?.contactSelectionUtilityUserCanceled?()
            }
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
                
                if let phoneSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    
                    UIApplication.shared.open(phoneSettingsUrl,
                                              options: [:]) { (sucess) in
                    }
                }
            }
            
            alertController.addAction(settingsAction)
            alertController.addAction(okAction)
            
            self.viewController.present(alertController, animated: true, completion: nil)
        }
    }
}
