//
//  HomeCameraViewController.swift
//  MomBank
//
//  Created by Sabath, Matthew on 7/4/19.
//  Copyright © 2019 Sabath, Matthew. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation
import AssetsLibrary
import AVKit


class HomeCameraViewController: UIViewController {
    
    enum UIState {
        case normal
        case addMess
    }
    
    enum CameraState {
        case back
        case front
    }
    
    @IBOutlet weak var recordingControlsContainerViewBottomSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraInnerBlackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraInnerBlackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var enableCameraPermissionsButton: UIButton!
    @IBOutlet weak var recordingControlsContainerView: UIView!
    @IBOutlet weak var cameraInnerBlackContainerView: UIView!
    @IBOutlet weak var cameraInnerWhiteContainerView: UIView!
    @IBOutlet weak var videoPreviewContainerView: UIView!
    @IBOutlet weak var cameraOuterContainerView: UIView!
    @IBOutlet weak var uploadMessIconImageView: UIImageView!
    @IBOutlet weak var addMessPhotoButton: UIButton!
    
    var photoSelectionUtility = PhotoSelectionUtility()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var videoFileOutput = AVCaptureMovieFileOutput()
    
    var capturePhotoOutput: AVCapturePhotoOutput?
    var videoCaptureSession = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    var audioDeviceInput: AVCaptureDeviceInput!
    var moviePlayer: AVPlayerViewController!
    var timer: Timer!
    
    var currentCameraState: CameraState = .back
    var userChosenVideoAssetURL: URL?
    var userUploadingNewVideo: Bool!
    var capturedImage: UIImage?
    
    var displayingHomeAlert = false
    var recordedTime = 0.0
    var initialLoad = true
    var isSaving = false
    
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCameraPermissionFlow),
                                               name: Notification.Name(Constants.kUserClosedDownHomeAlertView),
                                               object: nil)
        setupUI()
        
        if displayingHomeAlert == false {
            handleCameraPermissionFlow()
        }
        
        photoSelectionUtility.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        capturedImage = nil
    }
    
    
    // MARK: - UI
    func setupUI() {
        cameraOuterContainerView.layer.cornerRadius = 38
        cameraInnerBlackContainerView.layer.cornerRadius = 33
        cameraInnerWhiteContainerView.layer.cornerRadius = 31
        
    }
    
    func setupCamera() {
        
        var captureDevice: AVCaptureDevice?
        
        if currentCameraState == .back {
            captureDevice = defaultBackCamera()
            
        } else {
            captureDevice = defaultFrontCamera()
        }
        
        guard let v = captureDevice else {
            return
        }
        
        capturePhotoOutput = AVCapturePhotoOutput()
        
        capturePhotoOutput!.isHighResolutionCaptureEnabled = true
        videoCaptureSession.addOutput(capturePhotoOutput!)
        
        do {
            videoCaptureSession.beginConfiguration()
            
            videoDeviceInput = try AVCaptureDeviceInput(device: v)
            
            if (videoCaptureSession.canAddInput(videoDeviceInput) == true) {
                videoCaptureSession.addInput(videoDeviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true

            if (videoCaptureSession.canAddOutput(videoFileOutput)) {
                videoCaptureSession.addOutput(videoFileOutput)
            }
            
            let queue = DispatchQueue(label: "com.mombank.queue", attributes: [])
            
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer()
            
            videoPreviewLayer.frame = videoPreviewContainerView.bounds
            videoPreviewContainerView.layer.addSublayer(videoPreviewLayer)
            videoPreviewLayer.session = videoCaptureSession
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoCaptureSession.commitConfiguration()
            
        } catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    func refreshCameraView() {
        
        videoCaptureSession.removeInput(videoDeviceInput)
        
        var captureDevice: AVCaptureDevice?
        
        if currentCameraState == .back {
            captureDevice = defaultBackCamera()
            
        } else {
            captureDevice = defaultFrontCamera()
        }
        
        guard let v = captureDevice else {
            return
        }
        
        capturePhotoOutput = AVCapturePhotoOutput()
        
        capturePhotoOutput!.isHighResolutionCaptureEnabled = true
        
        if (videoCaptureSession.canAddOutput(videoFileOutput)) {
            videoCaptureSession.addOutput(capturePhotoOutput!)
        }
        
        do {
            videoCaptureSession.beginConfiguration()
            
            videoDeviceInput = try AVCaptureDeviceInput(device: v)
            
            if (videoCaptureSession.canAddInput(videoDeviceInput) == true) {
                videoCaptureSession.addInput(videoDeviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true

            if (videoCaptureSession.canAddOutput(videoFileOutput)) {
                videoCaptureSession.addOutput(videoFileOutput)
            }
            
            let queue = DispatchQueue(label: "com.mombank.queue", attributes: [])
            
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer()
            
            videoPreviewLayer.frame = videoPreviewContainerView.bounds
            videoPreviewContainerView.layer.addSublayer(videoPreviewLayer)
            videoPreviewLayer.session = videoCaptureSession
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoCaptureSession.commitConfiguration()
            
        } catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    func startCamera() {
        videoCaptureSession.startRunning()
    }
    
    @objc func handleCameraPermissionFlow() {
        
        let permission = AVCaptureDevice.authorizationStatus(for: .video)
        
        if permission == .notDetermined {
            
            AVCaptureDevice.requestAccess(for: .video,
                                          completionHandler: { accessGranted in
             
                DispatchQueue.main.async {
                    
                    if accessGranted == true {
                        self.setupCamera()
                        self.startCamera()
                    
                    } else {
                        self.updateUIWithNoCameraPermissions()
                    }
                }
            })
            
            
        } else if permission == .denied || permission == .restricted {
            self.updateUIWithNoCameraPermissions()
            
        } else { // authorized
            setupCamera()
            startCamera()
        }
    }
    
    func updateUIWithNoCameraPermissions() {
        enableCameraPermissionsButton.isHidden = false 
    }
    

    // MARK: - Update
    func updateUIWithState(_ state: UIState) {
        displayAddMessVC()
    }
    
    func displayAddMessVC() {
        
        let vc = AddMessStepOneViewController(image: capturedImage!)
        let navigationController = UINavigationController()
        
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.pushViewController(vc, animated: true)
        navigationController.setNavigationBarHidden(true, animated: true)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    func cameraButtonActionDown(_ isDown: Bool) {
        
        if isDown == true {
            
            UIView.animate(withDuration: 0.2) {
                self.cameraInnerBlackViewWidthConstraint.constant = 58
                self.cameraInnerBlackViewHeightConstraint.constant = 58
                self.view.layoutIfNeeded()
            }
            
        } else {
            
            UIView.animate(withDuration: 0.2) {
                self.cameraInnerBlackViewWidthConstraint.constant = 62
                self.cameraInnerBlackViewHeightConstraint.constant = 62
                self.view.layoutIfNeeded()
            }
        }
    }

    
    // MARK: - IBAction
    @IBAction func tappedCaptureButton(_ sender: Any) {
        
        cameraButtonActionDown(false)
        
        let status = SubscriptionManager.sharedManager.subscriptionStatus
        
        if ((status == .subscribed) || (status == .trial)) {
            capturePhoto()
        
        } else {
            throwMembershipRequiredAlert()
        }
    }
    
    @IBAction func tappedCameraSwitchButton(_ sender: Any) {
        
        if currentCameraState == .back {
            currentCameraState = .front
        
        } else {
            currentCameraState = .back
        }
        
        refreshCameraView()
    }
    
    @IBAction func touchedDownCameraButton(_ sender: Any) {
        cameraButtonActionDown(true)
    }
    
    @IBAction func touchedDragOutside(_ sender: Any) {
        cameraButtonActionDown(false)
    }
    
    @IBAction func tappedEnableCameraPermissionsButton(_ sender: Any) {
        
        if let phoneSettingsUrl = URL(string: UIApplication.openSettingsURLString) {
            
            UIApplication.shared.open(phoneSettingsUrl,
                                      options: [:]) { (sucess) in
            }
        }
    }
    
    @IBAction func tappedUploadMessImageButton(_ sender: Any) {
        
        let status = SubscriptionManager.sharedManager.subscriptionStatus
        
        if ((status == .subscribed) || (status == .trial)) {
            
            if isSaving == false {
                isSaving = true
                
                addMessPhotoButton.isUserInteractionEnabled = false
                uploadMessIconImageView.isHidden = true
                activityIndicatorView.startAnimating()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.photoSelectionUtility.submitPhotoSelectOptionFromViewController(self)
                }
            }
        
        } else {
            throwMembershipRequiredAlert()
        }
    }
    
    
    // MARK: - Capture Photo
    func capturePhoto() {
        
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    
    // MARK: - Camera Utility
    func defaultBackCamera() -> AVCaptureDevice? {
        
        if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera,
                                                for: AVMediaType.video,
                                                position: .back) {
            return device
            
        } else if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                       for: AVMediaType.video,
                                                       position: .back) {
            return device
            
        } else {
            return nil
        }
    }
    
    func defaultFrontCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera,
                                                for: AVMediaType.video,
                                                position: .front) {
            return device
            
        } else if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                       for: AVMediaType.video,
                                                       position: .front) {
            return device
            
        } else {
            return nil
        }
    }
    
    
    // MARK: - Alerts
    func throwMembershipRequiredAlert() {
        
        AlertsManager.determineSubscriptionOrTrialExpiredAlert { (alert) in
            
            let vc = HomeAlertViewController(alert)
            vc.delegate = self
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: true, completion: nil)
        }
    }
}


// MARK: - HomeAlertViewControllerDelegate
extension HomeCameraViewController: HomeAlertViewControllerDelegate {
    
    func userTappedSubscribeButton() {
        
        DispatchQueue.main.async {
        
            let vc = ManageSubscriptionsViewController(presentedModally: true)
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: true, completion: nil)
        }
    }
}


// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension HomeCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
    }
}


// MARK: - AVPlayerViewControllerDelegate
extension HomeCameraViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController,
                              failedToStartPictureInPictureWithError error: Error) {
        
        // todo: handle error
    }
}


// MARK: - AVCapturePhotoCaptureDelegate
extension HomeCameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        let cImage = UIImage.init(data: imageData, scale: 1.0)
        
        if let image = cImage {
            
            self.capturedImage = image
            
            DispatchQueue.main.async {
                self.displayAddMessVC()
            }
        }
    }
}


// MARK: - AddMessViewControllerDelegate
extension HomeCameraViewController: AddMessStepOneViewControllerDelegate {
    
    func successfullyAddedMess() {
        updateUIWithState(.normal)
    }
    
    func userCancelled() {
        updateUIWithState(.normal)
    }
}


// MARK: - PhotoSelectionUtilityDelegate
extension HomeCameraViewController: PhotoSelectionUtilityDelegate {
    
    func photoSelectionUtilityUserCanceledPhotoUpload() {
        
        addMessPhotoButton.isUserInteractionEnabled = true
        uploadMessIconImageView.isHidden = false
        activityIndicatorView.stopAnimating()
        capturedImage = nil
        isSaving = false
    }
    
    func photoSelectionUtilityDidReturnImage(_ image: UIImage) {
   
        addMessPhotoButton.isUserInteractionEnabled = true
        uploadMessIconImageView.isHidden = false
        activityIndicatorView.stopAnimating()
        capturedImage = nil
        isSaving = false
        
        capturedImage = image
        displayAddMessVC()
    }
}
