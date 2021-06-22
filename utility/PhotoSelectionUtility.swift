//
//  PhotoSelectionUtility.swift
//  MomBank
//
//  Created by Matthew Sabath on 7/6/19.
//  Copyright © 2019 Sabath, Matthew. All rights reserved.
//

import Foundation
import Photos
import UIKit


@objc protocol PhotoSelectionUtilityDelegate: class {
    
    @objc optional func photoSelectionUtilityDidReturnImage(_ image: UIImage)
    @objc optional func photoSelectionUtilityDidReturnVideoFileURL(_ fileURL: URL)
    @objc optional func photoSelectionUtilityUserCanceledPhotoUpload()
}


class PhotoSelectionUtility: NSObject, UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
    
    weak var delegate: PhotoSelectionUtilityDelegate?
    
    var imagePickerController = UIImagePickerController()
    weak var viewController: UIViewController!
    var userPickingVideo = false
    
    let kAppName = "MomBank"
    
    // MARK: - Initializer
    override init() {
        super.init()
    }
    
    
    // MARK: - Called
    func submitPhotoOptionsFromViewController(_ vc: UIViewController) {
        viewController = vc
        presentSelctionView()
    }
    
    func submitPhotoSelectOptionFromViewController(_ vc: UIViewController) {
        viewController = vc
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            
            PHPhotoLibrary.requestAuthorization({ (status) in
                
                if status == .authorized {
                    self.presentImagePickerController()
                } else {
                    self.throwPhotosDeniedAlert()
                }
            })
            
        } else if status == .authorized {
            presentImagePickerController()
        } else {
            throwPhotosDeniedAlert()
        }
    }
    
    func submitUserVideoFromViewController(_ vc: UIViewController) {
        
        userPickingVideo = true
        viewController = vc
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            
            PHPhotoLibrary.requestAuthorization({ (status) in
                
                if status == .authorized {
                    self.presentVideoController()
                    
                } else {
                    self.throwChooseVideoDeniedAlert()
                }
            })
            
        } else if status == .authorized {
            presentVideoController()
            
        } else {
            throwChooseVideoDeniedAlert()
        }
    }
    
    
    // MARK: - UI
    fileprivate func presentSelctionView() {
        
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        if cameraAvailable {
            
            let actionSheet = UIAlertController(title: "Submit Photo",
                                                message: "",
                                                preferredStyle: UIAlertController.Style.actionSheet)
            
            let cameraAction = UIAlertAction(title: "Take Photo",
                                             style: .default,
                                             handler: { [weak self] _ in
                
                self?.performSelector(onMainThread: #selector(PhotoSelectionUtility.takeNewPhoto),
                                      with: nil,
                                      waitUntilDone: false)
                
            })
            
            let choosePhotoAction = UIAlertAction(title: "Choose Photo",
                                                  style: .default,
                                                  handler: { [weak self] _ in
                                                    
                self?.performSelector(onMainThread: #selector(PhotoSelectionUtility.choosePhotoFromLibrary),
                                      with: nil,
                                      waitUntilDone: false)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .default,
                                             handler: { _ in
                
                actionSheet.dismiss(animated: true, completion: nil)
            })
            
            actionSheet.addAction(cameraAction)
            actionSheet.addAction(choosePhotoAction)
            actionSheet.addAction(cancelAction)
            
            viewController!.present(actionSheet, animated: true, completion: nil)
            
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    
    // MARK: - Actions
    @objc func choosePhotoFromLibrary() {
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .notDetermined {
            
            PHPhotoLibrary.requestAuthorization({ (status) in
                
                if status == .authorized {
                    self.presentImagePickerController()
                } else {
                    self.throwPhotosDeniedAlert()
                }
            })
            
        } else if status == .authorized {
            presentImagePickerController()
        } else {
            throwPhotosDeniedAlert()
        }
    }
    
    @objc func takeNewPhoto() {
        
        let authStatusCamera = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if authStatusCamera == .notDetermined {
            
            if let _ = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                             mediaType: .video,
                                                             position: .front).devices.first?.localizedName {
                
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                    
                    if granted == true {
                        self.presentCameraController()
                    } else {
                        self.throwCameraDeniedAlert()
                    }
                }
            }
            
        } else if authStatusCamera == .authorized {
            
            presentCameraController()
            
        } else {
            throwCameraDeniedAlert()
        }
    }
    
    func presentCameraController() {
        
        DispatchQueue.main.async {
            self.imagePickerController.sourceType = .camera
            self.imagePickerController.delegate = self
            
            self.presentImagePickerController(self.imagePickerController)
        }
    }
    
    func presentImagePickerController() {
        
        DispatchQueue.main.async {
            self.imagePickerController = UIImagePickerController()
            self.imagePickerController.sourceType = .photoLibrary
            self.imagePickerController.delegate = self
        
            self.presentImagePickerController(self.imagePickerController)
        }
    }
    
    func presentVideoController() {
        
        DispatchQueue.main.async {
            self.imagePickerController = UIImagePickerController()
            self.imagePickerController.sourceType = .photoLibrary
            self.imagePickerController.mediaTypes = ["public.movie"]
            self.imagePickerController.delegate = self
            
            self.presentImagePickerController(self.imagePickerController)
        }
    }
    
    
    // MARK: - presenting View Controller
    func presentImagePickerController(_ pickerController: UIViewController) {
        
        DispatchQueue.main.async {
            
            if let vc = self.viewController?.presentedViewController {
                
                vc.presentedViewController!.present(pickerController, animated: true, completion: nil)
                
            } else {
                
                if let navVC = self.viewController.navigationController {
                    
                    navVC.present(pickerController, animated: true, completion: nil)
                    
                } else {
                    self.viewController.present(pickerController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    // MARK: - ImagePickerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        if userPickingVideo == true {

            if let videoUrl = info[.mediaURL] as? URL {

                picker.dismiss(animated: true) { () -> Void in
                    self.delegate?.photoSelectionUtilityDidReturnVideoFileURL?(videoUrl)
                }

            } else {
                delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
            }

        } else {

            if let image = info[.originalImage] as? UIImage {

                picker.delegate = self
                picker.dismiss(animated: true) { () -> Void in
                    self.delegate?.photoSelectionUtilityDidReturnImage?(self.normalizedImage(image))
                }

            } else {
                delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Image Manipulation
    func normalizedImage(_ image: UIImage) -> UIImage {
        
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        let imageRect = CGRect(x: 0,
                               y: 0,
                               width: image.size.width,
                               height: image.size.height)
        
        image.draw(in: imageRect)
        
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return normalizedImage!
    }
    
    
    // MARK: - Alerts
    func throwPhotosDeniedAlert() {
        
        let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                   message: "\(kAppName) requires access to your Photos Library in order to select a photo for a Mess. " +
                                                                            "Please go to your Settings and re-allow Photos permissions.",
                                                                   preferredStyle: .alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                    style: .default) { [weak self] _  in
            
            self?.delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
        }
        
        let settingsAction = UIAlertAction(title: "Settings",
                                           style: .default) { (alertAction) in
            
            if let phoneSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
                
                UIApplication.shared.open(phoneSettingsUrl,
                                          options: [:]) { (sucess) in
                }
            }
        }
        
        alertController.addAction(settingsAction)
        alertController.addAction(okAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func throwChooseVideoDeniedAlert() {
        
        let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                   message: "\(kAppName) needs access to your camera roll in order for you to select a video from your library. " +
                                                                            "Please go to the Settings App and re-allow camera roll permissions",
                                                                   preferredStyle: .alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                    style: .default) { [weak self] _  in
            
            self?.delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
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
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func throwCameraDeniedAlert() {
        
        let alertController: UIAlertController = UIAlertController(title: "Oops!",
                                                                   message: "\(kAppName) needs access to your camera in order to take a photo. " +
                                                                            "Please go to the Settings App and re-allow camera permissions",
                                                                   preferredStyle: .alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "Ok",
                                                    style: .default) { [weak self] _  in
            
            self?.delegate?.photoSelectionUtilityUserCanceledPhotoUpload?()
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
        
        viewController.present(alertController, animated: true, completion: nil)
    }
}

