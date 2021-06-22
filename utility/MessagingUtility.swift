//
//  MessagingUtility.swift
//  MomBank
//
//  Created by Matthew Sabath on 8/18/20.
//  Copyright © 2020 Sabath, Matthew. All rights reserved.
//

import Foundation
import MessageUI

@objc protocol MessagingUtilityDelegate: class {
    
    @objc optional func messagingUtilityUserCancelledMessage()
    @objc optional func messagingUtilityUserSentMessage()
}

class MessagingUtility: NSObject, UINavigationControllerDelegate,
                        MFMessageComposeViewControllerDelegate {
    
    weak var delegate: MessagingUtilityDelegate?

    weak var viewController: UIViewController!
    
    
    class func canSendMessages() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    // MARK: - Initializers
    func presentMessageView(_ vc: UIViewController,
                            contactPhone: String,
                            messPhoto: UIImage?,
                            messPhotoFileName: String?,
                            message: String) {
        
        viewController = vc
        
        let composeVC = MFMessageComposeViewController()
        
        composeVC.messageComposeDelegate = self
        composeVC.recipients = [contactPhone]
        composeVC.body = message

        if let photo = messPhoto, let name = messPhotoFileName {
          
            let dataImage =  photo.pngData()
            
            composeVC.addAttachmentData(dataImage!,
                                        typeIdentifier: "image/png",
                                        filename: name)
        }
        
        viewController.present(composeVC,
                               animated: true,
                               completion: nil)
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        
        switch result {
            
            case .cancelled:
                viewController.dismiss(animated: true, completion: nil)
                delegate?.messagingUtilityUserCancelledMessage?()
                
            case .failed:
                viewController.dismiss(animated: true, completion: nil)
                delegate?.messagingUtilityUserCancelledMessage?()
                
            case .sent:
                viewController.dismiss(animated: true, completion: nil)
                delegate?.messagingUtilityUserSentMessage?()
        }
    }
}
