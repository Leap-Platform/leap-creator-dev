//
//  LeapCameraViewController.swift
//  LeapCreatorSDK
//
//  Created by Aravind GS on 30/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import UIKit
import AVFoundation

protocol LeapCameraViewControllerDelegate: AnyObject {
    func configFetched(type: NotificationType, config: Dictionary<String,Any>)
    func paired(type: NotificationType, infoDict: Dictionary<String, Any>)
    func closed(type: NotificationType)
}

public protocol SampleAppDelegate: AnyObject {
    func sendInfo(infoDict: Dictionary<String,Any>)
}

class LeapCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    weak var delegate:LeapCameraViewControllerDelegate?
    weak var sampleAppDelegate: SampleAppDelegate?
    let cameraImage = UIImageView()
    let openCamera = UIButton()
    let closeButton = UIButton()
    let modeButton = UIButton()
    let qrCodeImage = UIImageView()
    var headingLabel = UILabel()
    var warningView: UIView?
    let simulatorDescriptionLabel = UILabel()
    let simulatorLearnMore = UIButton()
    var codeTextField: UITextField?
    let errorLabel = UILabel()
    let submitButton = UIButton(type: .system)
    let descLabel1 = UILabel()
    let descLabel2 = UILabel()
    let learnMoreButton1 = UIButton()
    let learnMoreButton2 = UIButton()
    var fetchView: UIView?
    var scannerView:UIView?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var roomManager = LeapRoomManager()
    let qrManager = LeapQRCodeManager()
    var isSimulator = false
    let previewUrl:String = {
        #if DEV
        return "https://alfred-dev-gke.leap.is/alfred/api/v1/device/preview"
        #elseif STAGE
        return "https://alfred-stage-gke.leap.is/alfred/api/v1/device/preview"
        #elseif PROD
        return "https://alfred.leap.is/alfred/api/v1/device/preview"
        #else
        return "https://alfred.leap.is/alfred/api/v1/device/preview"
        #endif
    }()
    
    private var modeWidthConstraint: NSLayoutConstraint?
    private var modeHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .black
        
        setupView()
    }
    
    func configureSampleApp() {
        if let infoDict = (UserDefaults.standard.object(forKey: "sampleAppInfoDict") as? Dictionary<String,Any>) {
            
            if let rescan = (UserDefaults.standard.object(forKey: "sampleAppRescan") as? Bool), !rescan {
                configureConnectedSampleApp(infoDict: infoDict)
            }
        
        } else {
            closeButton.isHidden = true
        }
    }
    
    func setupView() {
        setupQRCodeImage()
        setupHeadingLabel()
        setupDescLabel()
        setupCameraIcon()
        setupCameraButton()
        setupCloseButton(inView: self.view)
        setupModeButton(inView: self.view)
        setupLearnMoreButton()
        askForCameraAccess()
    }
    
    @objc func askForCameraAccess() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            DispatchQueue.main.async {
                self.setupCaptureSession()
            }
            
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                }
            }
            
        case .denied: // The user has previously denied access.
            DispatchQueue.main.async {
                self.showAlertForSettingsPage(with: constant_cameraAccess)
            }
            return
            
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            return
        }
    }
    
    private func setupQRCodeImage() {
        let image = UIImage(named: "leap_qrcode.png", in: Bundle(for: LeapCreator.self), compatibleWith: nil)
        guard let qrImage = image else { return }
        qrCodeImage.image = image
        qrCodeImage.contentMode = .scaleAspectFit
        view.addSubview(qrCodeImage)
        qrCodeImage.translatesAutoresizingMaskIntoConstraints = false
        qrCodeImage.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 10).isActive = true
        qrCodeImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        qrCodeImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45).isActive = true
        qrCodeImage.heightAnchor.constraint(equalTo: qrCodeImage.widthAnchor, multiplier: qrImage.size.height/qrImage.size.width).isActive = true
    }
    
    private func setupHeadingLabel() {
        headingLabel = UILabel()
        headingLabel.text = "Scan QR Code"
        headingLabel.textColor = .white
        headingLabel.font = UIFont(name: "Helvetica Neue Bold", size: 20)
        view.addSubview(headingLabel)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.topAnchor.constraint(equalTo: qrCodeImage.bottomAnchor, constant: 58).isActive = true
        headingLabel.centerXAnchor.constraint(equalTo: qrCodeImage.centerXAnchor).isActive = true
    }
    
    private func setupDescLabel() {
        if Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
            descLabel1.text = "1. To connect Sample app"
            descLabel1.textColor = UIColor(red: 0.655, green: 0.655, blue: 0.667, alpha: 1)
            descLabel1.textAlignment = .center
            descLabel1.numberOfLines = 0
            descLabel1.font = UIFont(name: "Helvetica Neue", size: 15)
            descLabel1.adjustsFontSizeToFitWidth = true
            view.addSubview(descLabel1)
            descLabel1.translatesAutoresizingMaskIntoConstraints = false
            descLabel1.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 20).isActive = true
            descLabel1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIScreen.main.bounds.size.width*0.07).isActive = true
            descLabel2.text = "2. To preview projects on device"
            descLabel2.textColor = UIColor(red: 0.655, green: 0.655, blue: 0.667, alpha: 1)
            descLabel2.textAlignment = .center
            descLabel2.numberOfLines = 0
            descLabel2.font = UIFont(name: "Helvetica Neue", size: 15)
            descLabel2.adjustsFontSizeToFitWidth = true
            view.addSubview(descLabel2)
            descLabel2.translatesAutoresizingMaskIntoConstraints = false
            descLabel2.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 60).isActive = true
            descLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIScreen.main.bounds.size.width*0.07).isActive = true
        } else {
            descLabel1.text = "To preview projects on device"
            descLabel1.textColor = UIColor(red: 0.655, green: 0.655, blue: 0.667, alpha: 1)
            descLabel1.textAlignment = .center
            descLabel1.numberOfLines = 0
            descLabel1.font = UIFont(name: "Helvetica Neue", size: 15)
            view.addSubview(descLabel1)
            descLabel1.translatesAutoresizingMaskIntoConstraints = false
            descLabel1.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 20).isActive = true
            descLabel1.centerXAnchor.constraint(equalTo: qrCodeImage.centerXAnchor).isActive = true
            descLabel1.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 50).isActive = true
        }
    }
    
    private func setupLearnMoreButton() {
        if Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
            learnMoreButton1.setTitleColor(UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1), for: .normal)
            learnMoreButton1.setTitle("Learn More", for: .normal)
            learnMoreButton1.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 15)
            learnMoreButton1.addTarget(self, action: #selector(learnMore1Clicked), for: .touchUpInside)
            learnMoreButton1.titleLabel?.adjustsFontSizeToFitWidth = true
            learnMoreButton1.sizeToFit()
            view.addSubview(learnMoreButton1)
            learnMoreButton1.translatesAutoresizingMaskIntoConstraints = false
            learnMoreButton1.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 14).isActive = true
            learnMoreButton1.leadingAnchor.constraint(equalTo: descLabel1.trailingAnchor, constant: UIScreen.main.bounds.width*0.015).isActive = true
            
            learnMoreButton2.setTitleColor(UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1), for: .normal)
            learnMoreButton2.setTitle("Learn More", for: .normal)
            learnMoreButton2.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 15)
            learnMoreButton2.addTarget(self, action: #selector(learnMore2Clicked), for: .touchUpInside)
            learnMoreButton2.titleLabel?.adjustsFontSizeToFitWidth = true
            learnMoreButton2.sizeToFit()
            view.addSubview(learnMoreButton2)
            learnMoreButton2.translatesAutoresizingMaskIntoConstraints = false
            learnMoreButton2.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 54).isActive = true
            learnMoreButton2.leadingAnchor.constraint(equalTo: descLabel2.trailingAnchor, constant: UIScreen.main.bounds.width*0.015).isActive = true
        } else {
            learnMoreButton1.setTitleColor(UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1), for: .normal)
            learnMoreButton1.setTitle("Learn More", for: .normal)
            learnMoreButton1.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 15)
            learnMoreButton1.addTarget(self, action: #selector(learnMore1Clicked), for: .touchUpInside)
            view.addSubview(learnMoreButton1)
            learnMoreButton1.translatesAutoresizingMaskIntoConstraints = false
            learnMoreButton1.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            learnMoreButton1.topAnchor.constraint(equalTo: descLabel1.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    private func setupCameraButton() {
        openCamera.backgroundColor = UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1)
        openCamera.layer.cornerRadius = 20
        openCamera.layer.masksToBounds = true
        openCamera.setTitle("Open Camera", for: .normal)
        openCamera.setTitleColor(.white, for: .normal)
        openCamera.titleLabel?.font = UIFont(name: "Helvetica Neue Bold", size: 15)
        openCamera.addTarget(self, action: #selector(askForCameraAccess), for: .touchUpInside)
        view.addSubview(openCamera)
        openCamera.translatesAutoresizingMaskIntoConstraints = false
        openCamera.topAnchor.constraint(equalTo: cameraImage.bottomAnchor, constant: 30).isActive = true
        openCamera.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        openCamera.heightAnchor.constraint(equalToConstant: 40).isActive = true
        openCamera.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
    }
    
    private func setupCameraIcon() {
        let image = UIImage(named: "leap_camera.png", in: Bundle(for: LeapCreator.self), compatibleWith: nil)
        guard let icon = image else { return }
        cameraImage.image = icon
        cameraImage.contentMode = .scaleAspectFit
        view.addSubview(cameraImage)
        cameraImage.translatesAutoresizingMaskIntoConstraints = false
        cameraImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 149).isActive = true
        cameraImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cameraImage.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cameraImage.heightAnchor.constraint(equalTo: cameraImage.widthAnchor, multiplier: icon.size.height/icon.size.width).isActive = true
    }
    
    private func setupCloseButton(inView:UIView) {
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.2)
        closeButton.layer.cornerRadius = 16
        closeButton.layer.masksToBounds = true
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        guard let image = UIImage(named: "leap_option_cross.png", in: Bundle(for: LeapCreator.self), compatibleWith: nil) else { return }
        closeButton.setImage(image, for: .normal)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        inView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: inView.topAnchor, constant: 30).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: inView.leadingAnchor, constant: 16).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor).isActive = true
    }
    
    @objc func setupCaptureSession() {

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        setupScannerView()
        captureSession = AVCaptureSession()
        
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        guard captureSession != nil else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height * 0.5)
        previewLayer?.videoGravity = .resizeAspectFill
        guard previewLayer != nil else { return }
        scannerView?.layer.addSublayer(previewLayer!)
        guard scannerView != nil else { return }
        setupCloseButton(inView: scannerView!)
        setupModeButton(inView: scannerView!)
        captureSession?.startRunning()
    }
    
    private func setupScannerView() {
        scannerView = UIView(frame: .zero)
        guard let scanner = scannerView  else { return }
        view.addSubview(scanner)
        scanner.translatesAutoresizingMaskIntoConstraints = false
        scanner.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scanner.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scanner.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scanner.bottomAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metaDataObj = metadataObjects.first,
              let readableObj = metaDataObj as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObj.stringValue else { return }
        let data = Data(stringValue.utf8)
        captureSession?.stopRunning()
        
        //Check if is leap QR
        guard let infoDict =  try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any>  else {
            presentWarning(constant_invalidQRCodeWarning)
            return
        }
        
        validateScannedInfo(infoDict: infoDict)
    }
    
    func validateScannedInfo(infoDict: Dictionary<String, Any>) {
        //Check if is owner Leap
        guard infoDict["owner"] as? String == "LEAP"  else {
            presentWarning(constant_invalidQRCodeWarning)
            setupCodeErrorLabel(withText: "Invalid Code", alignment: .center)
            return
        }
        
        // Check if is iOS Platform
        guard infoDict["platformType"] as? String == "IOS" else {
            presentWarning(constant_invalidQRCodeWarning)
            setupCodeErrorLabel(withText: "Invalid Code", alignment: .center)
            return
        }
        
        // Check if is of type PREVIEW
        if let id = infoDict[constant_id] as? String, infoDict[constant_type] as? String == constant_PREVIEW {
            let projectName = infoDict[constant_projectName] as? String ?? ""
            fetchPreviewConfig(previewId: id, projectName: projectName)
        } else if infoDict[constant_type] as? String == constant_SAMPLE_APP, Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
            configureConnectedSampleApp(infoDict: infoDict)
        } else if infoDict[constant_type] as? String == constant_PAIRING {
            startValidationForPairing(infoDict: infoDict)
        } else {
            presentWarning(constant_invalidQRCodeWarning)
            setupCodeErrorLabel(withText: "Invalid Code", alignment: .center)
        }
    }
    
    func startValidationForPairing(infoDict: Dictionary<String, Any>) {
        guard let roomId = infoDict[constant_roomId] as? String else { return }
        guard let _ = LeapCreatorShared.shared.apiKey else {
            self.presentWarning(constant_connectSampleAppWarningForPairing)
            return
        }
        presentLoader()
        roomManager.validateRoomId(roomId: roomId) { [weak self] (success) in
            DispatchQueue.main.async {
                self?.fetchView?.removeFromSuperview()
                if success {
                    let projectName = infoDict[constant_projectName] as? String ?? ""
                    UserDefaults.standard.setValue(projectName, forKey: constant_currentProjectName)
                    self?.delegate?.paired(type: .pairing, infoDict: infoDict)
                    self?.dismiss(animated: true, completion: nil)
                    
                } else {
                    self?.presentWarning(constant_somethingWrong)
                }
            }
        }
    }
    
    func presentLoader() {
        fetchView = UIView(frame: .zero)
        fetchView?.layer.cornerRadius = 8
        fetchView?.layer.masksToBounds = true
        fetchView?.backgroundColor = UIColor(white: 0, alpha: 0.8)
        guard scannerView != nil else { return }
        scannerView?.addSubview(fetchView!)
        fetchView?.translatesAutoresizingMaskIntoConstraints = false
        fetchView?.centerXAnchor.constraint(equalTo: scannerView!.centerXAnchor).isActive = true
        fetchView?.centerYAnchor.constraint(equalTo: scannerView!.centerYAnchor).isActive = true
        fetchView?.widthAnchor.constraint(equalToConstant: 100).isActive = true
        fetchView?.heightAnchor.constraint(equalTo: fetchView!.widthAnchor).isActive = true
        
        let activity = UIActivityIndicatorView(style: .whiteLarge)
        fetchView?.addSubview(activity)
        activity.startAnimating()
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.centerXAnchor.constraint(equalTo: fetchView!.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: fetchView!.centerYAnchor).isActive = true
    }
    
    func fetchPreviewConfig(previewId: String, projectName: String) {
        guard let url = URL(string: previewUrl) else { return }
        var req = URLRequest(url: url)
        let bundleShortVersionString = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Empty"
        req.addValue(bundleShortVersionString, forHTTPHeaderField: "x-app-version-name")
        req.addValue(previewId, forHTTPHeaderField: "x-preview-id")
        guard let apiKey = LeapCreatorShared.shared.apiKey else {
            self.presentWarning(constant_connectSampleAppWarningForPreview)
            return
        }
        presentLoader()
        req.addValue(apiKey, forHTTPHeaderField: "x-auth-id")
        
        let task = URLSession.shared.dataTask(with: req) { [weak self] (data, respsonse, error) in
            DispatchQueue.main.async {
                self?.fetchView?.removeFromSuperview()
                guard let httpresponse = respsonse as? HTTPURLResponse, httpresponse.statusCode == 200 else {
                    self?.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                guard error == nil, let data = data else {
                    self?.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                guard let previewDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any> else {
                    self?.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                self?.previewLayer?.removeFromSuperlayer()
                self?.scannerView?.removeFromSuperview()
                self?.scannerView = nil
                UserDefaults.standard.setValue(projectName, forKey: constant_currentProjectName)
                self?.delegate?.configFetched(type: .preview, config: previewDict)
                self?.dismiss(animated: true, completion: nil)
            }
        }
        task.resume()
    }
    
    private func configureConnectedSampleApp(infoDict: Dictionary<String, Any>) {
        self.delegate?.configFetched(type: .sampleApp, config: infoDict)
        self.sampleAppDelegate?.sendInfo(infoDict: infoDict)
    }
    
    func presentWarning(_ title:String) {
        guard scannerView != nil else { return }
        warningView = UIView(frame: .zero)
        warningView?.backgroundColor = UIColor(white: 0, alpha: 0.7)
        scannerView?.addSubview(warningView!)
        warningView?.translatesAutoresizingMaskIntoConstraints = false
        warningView?.leadingAnchor.constraint(equalTo: scannerView!.leadingAnchor).isActive = true
        warningView?.topAnchor.constraint(equalTo: scannerView!.topAnchor).isActive = true
        warningView?.trailingAnchor.constraint(equalTo: scannerView!.trailingAnchor).isActive = true
        warningView?.bottomAnchor.constraint(equalTo: scannerView!.bottomAnchor).isActive = true
        
        let warningLabel = UILabel(frame: .zero)
        warningLabel.text = title
        warningLabel.numberOfLines = 0
        warningLabel.textAlignment = .center
        warningLabel.textColor = .white
        warningLabel.font = UIFont(name: "Helvetica Neue Bold", size: 20)
        warningView?.addSubview(warningLabel)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.centerXAnchor.constraint(equalTo: warningView!.centerXAnchor).isActive = true
        warningLabel.centerYAnchor.constraint(equalTo: warningView!.centerYAnchor).isActive = true
        
        let cameraButton = UIButton(frame: .zero)
        cameraButton.setTitle("Scan again", for: .normal)
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.layer.cornerRadius = 20
        cameraButton.layer.masksToBounds = true
        cameraButton.backgroundColor =  UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1)
        cameraButton.titleLabel?.font = UIFont(name: "Helvetica Neue Bold", size: 15)
        cameraButton.addTarget(self, action: #selector(scanAgain), for: .touchUpInside)
        warningView?.addSubview(cameraButton)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.centerXAnchor.constraint(equalTo: warningView!.centerXAnchor).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cameraButton.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 20).isActive = true
        cameraButton.widthAnchor.constraint(equalTo: scannerView!.widthAnchor, multiplier: 0.33).isActive = true
        
        setupCloseButton(inView: warningView!)
        setupModeButton(inView: warningView!)
    }
    
    @objc func closeButtonClicked() {
        dismiss(animated: true, completion: nil)
        delegate?.closed(type: Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId ? .sampleApp : .genericApp)
    }
    
    @objc func learnMore1Clicked() {
        if Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
            let connectSampleAppUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.connectSampleApp ?? constant_connectSampleAppUrl
            guard let url = URL(string: connectSampleAppUrl) else { return }
            UIApplication.shared.open(url)
        } else {
            let previewDeviceUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.previewDevice ?? constant_previewDeviceUrl
            guard let url = URL(string: previewDeviceUrl) else { return }
            UIApplication.shared.open(url)
        }
    }
    
    @objc func learnMore2Clicked() {
        let previewDeviceUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.previewDevice ?? constant_previewDeviceUrl
        guard let url = URL(string: previewDeviceUrl) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc func scanAgain() {
        warningView?.removeFromSuperview()
        guard scannerView != nil else {
            setupCaptureSession()
            return
        }
        setupCloseButton(inView: scannerView!)
        setupModeButton(inView: scannerView!)
        captureSession?.startRunning()
    }
}

// For Simulator
extension LeapCameraViewController: UITextFieldDelegate {
    
    private func setupModeButton(inView: UIView) {
        modeButton.layer.borderWidth = 1.0
        modeButton.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
        modeButton.backgroundColor = UIColor(white: 0, alpha: 0.2)
        modeButton.layer.cornerRadius = 16
        modeButton.layer.masksToBounds = true
        modeButton.addTarget(self, action: #selector(modeButtonTapped), for: .touchUpInside)
        modeButton.titleLabel?.font = UIFont(name: "Helvetica Neue Bold", size: 13)
        modeButton.setTitle("Using Simulator?", for: .normal)
        inView.addSubview(modeButton)
        modeButton.translatesAutoresizingMaskIntoConstraints = false
        modeButton.topAnchor.constraint(equalTo: inView.topAnchor, constant: 30).isActive = true
        modeButton.trailingAnchor.constraint(equalTo: inView.trailingAnchor, constant: -16).isActive = true
        guard modeWidthConstraint == nil, modeHeightConstraint == nil else { return }
        modeWidthConstraint = NSLayoutConstraint(item: modeButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 135)
        modeHeightConstraint = NSLayoutConstraint(item: modeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 36)
        NSLayoutConstraint.activate([modeWidthConstraint!, modeHeightConstraint!])
    }
    
    @objc func modeButtonTapped() {
        isSimulator = !isSimulator
        
        if isSimulator {
            removeScanViews()
            setupSimulatorViews()
            
            modeButton.layer.borderWidth = 0
            modeButton.backgroundColor = .clear
            modeButton.layer.masksToBounds = false
            modeButton.setTitle(nil, for: .normal)
            guard let image = UIImage(named: "QR", in: Bundle(for: LeapCreator.self), compatibleWith: nil)?.withRenderingMode(.alwaysOriginal) else { return }
            modeButton.setImage(image, for: .normal)
            modeButton.imageView?.contentMode = .scaleAspectFit
            modeWidthConstraint?.constant = 45
            modeHeightConstraint?.constant = 45
            modeButton.updateConstraints()
        } else {
            removeSimulatorViews()
            setupView()
            
            modeButton.layer.borderWidth = 1.0
            modeButton.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
            modeButton.backgroundColor = UIColor(white: 0, alpha: 0.2)
            modeButton.setImage(nil, for: .normal)
            modeButton.layer.cornerRadius = 16
            modeButton.layer.masksToBounds = true
            modeButton.setTitle("Using Simulator?", for: .normal)
            modeWidthConstraint?.constant = 135
            modeHeightConstraint?.constant = 36
            modeButton.updateConstraints()
        }
    }
    
    func setupSimulatorViews() {
        setupCloseButton(inView: self.view)
        setupModeButton(inView: self.view)
        setupSimulatorHeadingLabel()
        setupSimulatorDescriptionLabel()
        setupSimulatorLearnMoreButton()
        setupCodeTextField()
        setupSubmitButton()
    }
    
    func removeScanViews() {
        openCamera.removeFromSuperview()
        cameraImage.removeFromSuperview()
        qrCodeImage.removeFromSuperview()
        headingLabel.removeFromSuperview()
        warningView?.removeFromSuperview()
        descLabel1.removeFromSuperview()
        descLabel2.removeFromSuperview()
        learnMoreButton1.removeFromSuperview()
        learnMoreButton2.removeFromSuperview()
        fetchView?.removeFromSuperview()
        scannerView?.removeFromSuperview()
        scannerView = nil
        previewLayer?.removeFromSuperlayer()
    }
    
    func removeSimulatorViews() {
        headingLabel.removeFromSuperview()
        simulatorDescriptionLabel.removeFromSuperview()
        simulatorLearnMore.removeFromSuperview()
        codeTextField?.removeFromSuperview()
        codeTextField = nil
        errorLabel.removeFromSuperview()
        submitButton.removeFromSuperview()
    }
    
    func setupSimulatorHeadingLabel() {
        headingLabel = UILabel()
        headingLabel.text = "Enter Code"
        headingLabel.textColor = .white
        headingLabel.font = UIFont(name: "Helvetica Neue Bold", size: 20)
        view.addSubview(headingLabel)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 112).isActive = true
        headingLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }
    
    func setupSimulatorDescriptionLabel() {
        simulatorDescriptionLabel.text = "Generate the code on the Leap \n        web app"
        simulatorDescriptionLabel.textColor = UIColor(red: 0.655, green: 0.655, blue: 0.667, alpha: 1)
        simulatorDescriptionLabel.textAlignment = .left
        simulatorDescriptionLabel.numberOfLines = 2
        simulatorDescriptionLabel.font = UIFont(name: "Helvetica Neue", size: 15)
        simulatorDescriptionLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(simulatorDescriptionLabel)
        simulatorDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        simulatorDescriptionLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 10).isActive = true
        simulatorDescriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func setupSimulatorLearnMoreButton() {
        simulatorLearnMore.setTitleColor(UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1), for: .normal)
        simulatorLearnMore.setTitle("Learn More", for: .normal)
        simulatorLearnMore.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 15)
        simulatorLearnMore.addTarget(self, action: #selector(simulatorLearnMoreTapped), for: .touchUpInside)
        simulatorLearnMore.titleLabel?.adjustsFontSizeToFitWidth = true
        simulatorLearnMore.sizeToFit()
        view.addSubview(simulatorLearnMore)
        simulatorLearnMore.translatesAutoresizingMaskIntoConstraints = false
        simulatorLearnMore.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 22).isActive = true
        simulatorLearnMore.leadingAnchor.constraint(equalTo: simulatorDescriptionLabel.trailingAnchor, constant: -110).isActive = true
    }
    
    @objc func simulatorLearnMoreTapped() {
        let qrSecretUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.generateQrHelp ?? constant_QRSecretUrl
        guard let url = URL(string: qrSecretUrl) else { return }
        UIApplication.shared.open(url)
    }
    
    func setupCodeTextField() {
        codeTextField = UITextField()
        let dashBorder = CAShapeLayer()
        dashBorder.strokeColor = UIColor(red: 0.379, green: 0.374, blue: 0.463, alpha: 1).cgColor
        dashBorder.fillColor = nil
        dashBorder.lineDashPattern = [6, 6]
        guard codeTextField != nil else { return }
        view.addSubview(codeTextField!)
        codeTextField?.autocapitalizationType = .none
        codeTextField?.backgroundColor = .clear
        codeTextField?.textColor = .white
        codeTextField?.font = UIFont(name: "Helvetica Neue Bold", size: 28)
        codeTextField?.textAlignment = .center
        codeTextField?.borderStyle = .roundedRect
        codeTextField?.returnKeyType = .done
        codeTextField?.delegate = self
        codeTextField?.addTarget(self, action: #selector(setPrefix), for: .editingChanged)
        codeTextField?.translatesAutoresizingMaskIntoConstraints = false
        codeTextField?.topAnchor.constraint(equalTo: simulatorDescriptionLabel.bottomAnchor, constant: 30).isActive = true
        codeTextField?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        codeTextField?.widthAnchor.constraint(equalToConstant: 190).isActive = true
        codeTextField?.heightAnchor.constraint(equalToConstant: 58).isActive = true
        codeTextField?.frame = CGRect(x: 0, y: 0, width: 190, height: 58)
        let bounds = codeTextField?.bounds
        dashBorder.path = UIBezierPath(roundedRect: bounds ?? CGRect(x: 0, y: 0, width: 190, height: 58), cornerRadius: 10).cgPath
        dashBorder.frame = bounds ?? CGRect(x: 0, y: 0, width: 190, height: 58)
        codeTextField?.layer.addSublayer(dashBorder)
    }
    
    @objc func setPrefix() {
        codeTextField?.text = String(codeTextField?.text?.prefix(6) ?? "")
    }
    
    // UITextField Delegate Method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // dismiss keyboard
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorLabel.removeFromSuperview()
    }
    
    func setupCodeErrorLabel(withText text: String = "Incorrect code or app version", alignment: NSTextAlignment = .left) {
        guard codeTextField != nil else { return }
        errorLabel.text = text
        errorLabel.textColor = UIColor(red: 0.882, green: 0.439, blue: 0.439, alpha: 1)
        errorLabel.textAlignment = alignment
        errorLabel.numberOfLines = 0
        errorLabel.font = UIFont(name: "Helvetica Neue", size: 12)
        errorLabel.adjustsFontSizeToFitWidth = true
        errorLabel.addImage(imageName: "Error.png")
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.topAnchor.constraint(equalTo: codeTextField!.bottomAnchor, constant: 5).isActive = true
        errorLabel.leadingAnchor.constraint(equalTo: codeTextField!.leadingAnchor).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: codeTextField!.trailingAnchor).isActive = true
    }
    
    func setupSubmitButton() {
        guard codeTextField != nil else { return }
        submitButton.backgroundColor = UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1)
        submitButton.layer.cornerRadius = 20
        submitButton.layer.masksToBounds = true
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont(name: "Helvetica Neue Bold", size: 15)
        submitButton.addTarget(self, action: #selector(submitCode), for: .touchUpInside)
        view.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.topAnchor.constraint(equalTo: codeTextField!.bottomAnchor, constant: 50).isActive = true
        submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        submitButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
    }
    
    @objc func submitCode() {
        guard codeTextField != nil else { return }
        qrManager.valideCode(with: codeTextField?.text ?? "") { [weak self] success in
            DispatchQueue.main.async {
                print(self?.qrManager.qrCodeDict ?? [:])
                if success {
                    self?.validateScannedInfo(infoDict: self?.qrManager.qrCodeDict ?? [:])
                } else {
                    self?.setupCodeErrorLabel()
                }
            }
        }
    }
}
