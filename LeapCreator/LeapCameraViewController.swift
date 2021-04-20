//
//  LeapCameraViewController.swift
//  LeapCreatorSDK
//
//  Created by Aravind GS on 30/03/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import UIKit
import AVFoundation

protocol LeapCameraViewControllerDelegate: class {
    func configFetched(type: NotificationType, config:Dictionary<String,Any>, projectName:String)
    func closed(type: NotificationType)
}

public protocol SampleAppDelegate: class {
    func sendInfo(infoDict: Dictionary<String,Any>)
}

class LeapCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    weak var delegate:LeapCameraViewControllerDelegate?
    weak var sampleAppDelegate: SampleAppDelegate?
    var notificationType: NotificationType = .preview
    let cameraImage = UIImageView()
    let openCamera = UIButton()
    let closeButton = UIButton()
    let qrCodeImage = UIImageView()
    let headingLabel = UILabel()
    var warningView:UIView?
    let descLabel1 = UILabel()
    let descLabel2 = UILabel()
    let learnMoreButton1 = UIButton()
    let learnMoreButton2 = UIButton()
    var fetchView: UIView?
    var scannerView:UIView?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .black
        
        if let infoDict = (UserDefaults.standard.object(forKey: "sampleAppInfoDict") as? Dictionary<String,Any>), let rescan = (UserDefaults.standard.object(forKey: "sampleAppRescan") as? Bool) {
            
            if rescan {
                
               notificationType = .sampleApp
                
               setupView()
            
            } else {
            
               configureSampleApp(infoDict: infoDict)
            }

        } else {
            
            if Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
                
                notificationType = .sampleApp
                
                closeButton.isHidden = true
            
            } else {
                
                closeButton.isHidden = false
            }
            
            setupView()
        }
    }
    
    func setupView() {
        setupQRCodeImage()
        setupHeadingLabel()
        setupDescLabel()
        setupCameraIcon()
        setupCameraButton()
        setupCloseButton(inView: self.view)
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
                    self.showAlertToSettings()
                }
                return

            case .restricted: // The user can't grant access due to restrictions.
                return
        @unknown default:
            return
        }
    }
    
    func showAlertToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        let goButton = "Go"
        var goAction = UIAlertAction(title: goButton, style: .default, handler: nil)
        let cancelButton = "Cancel"
        let cancelAction = UIAlertAction(title: cancelButton, style: .cancel, handler: nil)
        if UIApplication.shared.canOpenURL(settingsUrl) {

            goAction = UIAlertAction(title: goButton, style: .default, handler: {(alert: UIAlertAction!) -> Void in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            })
        }

        let alert = UIAlertController(title: "Permission Required", message: constant_cameraAccess, preferredStyle: .alert)
        alert.addAction(goAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
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
        headingLabel.text = "Scan QR Code"
        headingLabel.textColor = .white
        headingLabel.font = UIFont(name: "Helvetica Neue Bold", size: 20)
        view.addSubview(headingLabel)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.topAnchor.constraint(equalTo: qrCodeImage.bottomAnchor, constant: 58).isActive = true
        headingLabel.centerXAnchor.constraint(equalTo: qrCodeImage.centerXAnchor).isActive = true
    }
    
    private func setupDescLabel() {
        if notificationType == .preview {
            descLabel1.text = "To preview projects on device"
            descLabel1.textColor = .white
            descLabel1.textAlignment = .center
            descLabel1.numberOfLines = 0
            descLabel1.font = UIFont(name: "Helvetica Neue", size: 15)
            view.addSubview(descLabel1)
            descLabel1.translatesAutoresizingMaskIntoConstraints = false
            descLabel1.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 20).isActive = true
            descLabel1.centerXAnchor.constraint(equalTo: qrCodeImage.centerXAnchor).isActive = true
            descLabel1.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 50).isActive = true
        } else {
            descLabel1.text = "1. To connect Sample app"
            descLabel1.textColor = .white
            descLabel1.textAlignment = .center
            descLabel1.numberOfLines = 0
            descLabel1.font = UIFont(name: "Helvetica Neue", size: 15)
            descLabel1.adjustsFontSizeToFitWidth = true
            view.addSubview(descLabel1)
            descLabel1.translatesAutoresizingMaskIntoConstraints = false
            descLabel1.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 20).isActive = true
            descLabel1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIScreen.main.bounds.size.width*0.07).isActive = true
            descLabel2.text = "2. To preview projects on device"
            descLabel2.textColor = .white
            descLabel2.textAlignment = .center
            descLabel2.numberOfLines = 0
            descLabel2.font = UIFont(name: "Helvetica Neue", size: 15)
            descLabel2.adjustsFontSizeToFitWidth = true
            view.addSubview(descLabel2)
            descLabel2.translatesAutoresizingMaskIntoConstraints = false
            descLabel2.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 60).isActive = true
            descLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIScreen.main.bounds.size.width*0.07).isActive = true
        }
    }
    
    private func setupLearnMoreButton() {
        if notificationType == .preview {
            learnMoreButton1.setTitleColor(UIColor(red: 78/255, green: 79/255, blue: 1, alpha: 1), for: .normal)
            learnMoreButton1.setTitle("Learn More", for: .normal)
            learnMoreButton1.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 15)
            learnMoreButton1.addTarget(self, action: #selector(learnMore1Clicked), for: .touchUpInside)
            view.addSubview(learnMoreButton1)
            learnMoreButton1.translatesAutoresizingMaskIntoConstraints = false
            learnMoreButton1.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            learnMoreButton1.topAnchor.constraint(equalTo: descLabel1.bottomAnchor, constant: 16).isActive = true
        } else {
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
        cameraImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 94).isActive = true
        cameraImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cameraImage.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cameraImage.heightAnchor.constraint(equalTo: cameraImage.widthAnchor, multiplier: icon.size.height/icon.size.width).isActive = true
        
    }
    private func setupCloseButton(inView:UIView) {
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.8)
        closeButton.layer.cornerRadius = 16
        closeButton.layer.masksToBounds = true
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        guard let image = UIImage(named: "leap_option_cross.png", in: Bundle(for: LeapCreator.self), compatibleWith: nil) else { return }
        closeButton.setImage(image, for: .normal)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        inView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.topAnchor.constraint(equalTo: inView.topAnchor, constant:30).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: inView.trailingAnchor, constant: -16).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor).isActive = true
    }
    
    @objc func setupCaptureSession() {
        
        setupScannerView()
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height * 0.5)
        previewLayer.videoGravity = .resizeAspectFill
        scannerView?.layer.addSublayer(previewLayer)
        guard scannerView != nil else { return }
        setupCloseButton(inView: scannerView!)
        captureSession.startRunning()
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
        captureSession.stopRunning()
        
        //Check if is leap QR
        guard let infoDict =  try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any>,
              infoDict["owner"] as? String == "LEAP"  else {
                presentWarning(constant_invalidQRCodeWarning)
                return
              }
        
        // Check if is iOS Platform
        guard infoDict["platformType"] as? String == "IOS" else {
            presentWarning(constant_invalidQRCodeWarning)
            return
        }
        
        // Check if is of type PREVIEW
        if let id = infoDict["id"] as? String, infoDict["type"] as? String == "PREVIEW" {
           notificationType = .preview
           let projectName = infoDict["projectName"] as? String ?? ""
           fetchPreviewConfig(previewId: id, projectName:projectName)
        
        } else if infoDict["platformType"] as? String == "IOS", infoDict["type"] as? String == "SAMPLE_APP", Bundle.main.bundleIdentifier == constant_LeapPreview_BundleId {
            
            configureSampleApp(infoDict: infoDict)
            
        } else {
            presentWarning(constant_invalidQRCodeWarning)
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
            self.presentWarning(constant_connectSampleAppWarning)
            return
        }
        presentLoader()
        req.addValue(apiKey, forHTTPHeaderField: "x-auth-id")
        
        let task = URLSession.shared.dataTask(with: req) { (data, respsonse, error) in
            DispatchQueue.main.async {
                self.fetchView?.removeFromSuperview()
                guard let httpresponse = respsonse as? HTTPURLResponse, httpresponse.statusCode == 200 else {
                    self.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                guard error == nil, let data = data else {
                    self.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                guard let previewDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any> else {
                    self.presentWarning(constant_incorrectAppOrVersionWarning)
                    return
                }
                self.previewLayer.removeFromSuperlayer()
                self.scannerView?.removeFromSuperview()
                self.delegate?.configFetched(type: .preview, config: previewDict, projectName: projectName)
                self.dismiss(animated: true, completion: nil)
            }
        }
        task.resume()
    }
    
    func configureSampleApp(infoDict: Dictionary<String, Any>) {
        
        notificationType = .sampleApp
        self.delegate?.configFetched(type: .sampleApp, config: infoDict, projectName: "")
        self.sampleAppDelegate?.sendInfo(infoDict: infoDict)
    }
    
    func presentWarning(_ title:String) {
        warningView = UIView(frame: .zero)
        warningView?.backgroundColor = UIColor(white: 0, alpha: 0.7)
        guard scannerView != nil else { return }
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
    }
    
    @objc func closeButtonClicked() {
        dismiss(animated: true, completion: nil )
        delegate?.closed(type: notificationType)
    }
    
    @objc func learnMore1Clicked() {
        if notificationType == .preview {
            let previewDeviceUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.previewDevice ?? constant_previewDeviceUrl
            guard let url = URL(string: previewDeviceUrl) else { return }
            UIApplication.shared.open(url)
        } else {
            let connectSampleAppUrl = LeapCreatorShared.shared.creatorConfig?.documentation?.connectSampleApp ?? constant_connectSampleAppUrl
            guard let url = URL(string: connectSampleAppUrl) else { return }
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
        captureSession.startRunning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
