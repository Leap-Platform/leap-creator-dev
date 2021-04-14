//
//  LeapIconOptions.swift
//  OptionPanel
//
//  Created by Aravind GS on 09/02/21.
//

import UIKit


protocol LeapIconOptionsDelegate: NSObjectProtocol {
    func stopClicked()
    func languageClicked()
    func iconOptionsClosed()  // triggered by the user
    func iconOptionsDismissed()
}

class LeapIconOptions: UIView {
    
    let stop: String
    let language: String?
    let isLeftAligned: Bool
    weak var button: UIView?
    lazy var optionsView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    lazy var closeButton: UIButton = {
        return getCloseButton()
    }()
    let eachStageDuration: TimeInterval = 0.1
    let themeColor: UIColor
    var closeButtonHeightConstraint: NSLayoutConstraint?
    var imageHeightConstraint: NSLayoutConstraint?
    var panelWidthConstraint: NSLayoutConstraint?
    var optionsViewAnimateConstraint: NSLayoutConstraint?
    
    weak var delegate: LeapIconOptionsDelegate?
    
    init(withDelegate: LeapIconOptionsDelegate, stopText: String, languageText: String?, leapButton: UIView) {
        stop = stopText
        language = languageText
        button = leapButton
        isLeftAligned = leapButton.frame.origin.x < (UIScreen.main.bounds.width/2)
        themeColor = UIColor.init(hex: LeapSharedAUI.shared.iconSetting?.bgColor ?? "#000000") ?? UIColor(red: 0.23, green: 0.27, blue: 0.71, alpha: 1.00)
        delegate = withDelegate
        super.init(frame: .zero)
        setupPanel()
        self.layoutIfNeeded()
    }
    
    private override init(frame: CGRect) {
        stop = "Stop"
        language = "Language"
        themeColor = UIColor.init(hex: LeapSharedAUI.shared.iconSetting?.bgColor ?? "#000000") ?? UIColor(red: 0.23, green: 0.27, blue: 0.71, alpha: 1.00)
        isLeftAligned = true
        super.init(frame: frame)
        optionsView.alpha = 0.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LeapIconOptions {
    
    private func setupPanel() {
        
        guard let leapButton = button, let superview = leapButton.superview else { return }
        self.backgroundColor = themeColor
        superview.insertSubview(self, belowSubview: leapButton)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = (leapButton.frame.height/2)
        self.frame = leapButton.frame
        
        self.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Close constraints
        if isLeftAligned {
            closeButton.centerXAnchor.constraint(equalTo: self.leadingAnchor, constant: 27).isActive = true
        } else {
            closeButton.centerXAnchor.constraint(equalTo: self.trailingAnchor, constant: -27).isActive = true
        }
        closeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        setupOptionsView()
        optionsView.backgroundColor = .clear
        optionsView.alpha = 0.0
        self.addSubview(optionsView)
        optionsView.translatesAutoresizingMaskIntoConstraints = false
        if let _ = language { optionsView.widthAnchor.constraint(equalToConstant: 150).isActive = true }
        else { optionsView.widthAnchor.constraint(equalToConstant: 50).isActive = true }
        optionsView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        optionsView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        if isLeftAligned {
            optionsViewAnimateConstraint = NSLayoutConstraint(item: optionsView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 50)
        } else {
            optionsViewAnimateConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: optionsView, attribute: .trailing, multiplier: 1, constant: 50)
        }
        NSLayoutConstraint.activate([optionsViewAnimateConstraint!])
    }
    
    private func getCloseButton() -> UIButton {
        let closeButton = UIButton(frame: .zero)
        closeButton.alpha = 0.0
        closeButton.layer.cornerRadius = 0
        closeButton.layer.masksToBounds = true
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.2)
        let bundle = Bundle(for: type(of: self))
        guard let image = UIImage(named: "jiny_option_cross", in: bundle, compatibleWith: nil) else { fatalError("Image not found") }
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButtonHeightConstraint = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([closeButtonHeightConstraint!])
        closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor, multiplier: 1, constant: 0).isActive = true
        
        let imageView = UIImageView(image:image)
        imageView.contentMode = .scaleAspectFit
        closeButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.centerXAnchor.constraint(equalTo: closeButton.centerXAnchor, constant: 0).isActive = true
        imageView.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor, constant: 0).isActive = true
        imageHeightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil
                                                   , attribute: .notAnAttribute, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([imageHeightConstraint!])
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1, constant: 0).isActive = true
        
        closeButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
        
        return closeButton
    }
    
    private func setupOptionsView() {
        
        let stopButton = getStopButton()
        optionsView.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        
        stopButton.leadingAnchor.constraint(equalTo: optionsView.leadingAnchor).isActive = true
        stopButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
        stopButton.topAnchor.constraint(equalTo: optionsView.topAnchor).isActive = true
        
        guard let _ = language else {
            optionsView.trailingAnchor.constraint(equalTo: stopButton.trailingAnchor).isActive = true
            return
        }
        
        let languageButton = getLanguageButton()
        optionsView.addSubview(languageButton)
        languageButton.translatesAutoresizingMaskIntoConstraints = false
        
        optionsView.trailingAnchor.constraint(equalTo: languageButton.trailingAnchor).isActive = true
        languageButton.centerYAnchor.constraint(equalTo: optionsView.centerYAnchor).isActive = true
        languageButton.leadingAnchor.constraint(equalTo: stopButton.trailingAnchor, constant: 12).isActive = true
        languageButton.topAnchor.constraint(equalTo: optionsView.topAnchor).isActive = true
    }
    
    private func getStopButton() -> UIButton {
        let iconStopButton = UIButton(frame: .zero)
        
        let stopSymbol = UIView(frame: .zero)
        stopSymbol.backgroundColor = UIColor(white: 1, alpha: 0.2)
        stopSymbol.layer.masksToBounds = true
        stopSymbol.layer.cornerRadius = 6.0
        stopSymbol.layer.borderColor = themeColor == .white ? UIColor.black.cgColor : UIColor.white.cgColor
        stopSymbol.layer.borderWidth = 1.0
        iconStopButton.addSubview(stopSymbol)
        stopSymbol.translatesAutoresizingMaskIntoConstraints = false
        
        stopSymbol.widthAnchor.constraint(equalToConstant: 12).isActive = true
        stopSymbol.heightAnchor.constraint(equalTo: stopSymbol.widthAnchor).isActive = true
        stopSymbol.leadingAnchor.constraint(equalTo: iconStopButton.leadingAnchor, constant: 0).isActive = true
        stopSymbol.centerYAnchor.constraint(equalTo: iconStopButton.centerYAnchor, constant: 0).isActive = true
        
        let stopLabel = UILabel(frame: .zero)
        stopLabel.text = stop
        stopLabel.textColor = themeColor == .white ? .black : .white
        stopLabel.font = UIFont.systemFont(ofSize: 12)
        iconStopButton.addSubview(stopLabel)
        stopLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stopLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        stopLabel.leadingAnchor.constraint(equalTo: stopSymbol.trailingAnchor, constant: 6).isActive = true
        stopLabel.centerYAnchor.constraint(equalTo: stopSymbol.centerYAnchor, constant: 0).isActive = true
        iconStopButton.trailingAnchor.constraint(equalTo: stopLabel.trailingAnchor, constant: 0).isActive = true
        
        iconStopButton.addTarget(self, action: #selector(stopClicked), for: .touchUpInside)
        
        return iconStopButton
    }
    
    private func getLanguageButton() -> UIButton {
        
        let languageButton = UIButton(frame: .zero)
        let bundle = Bundle(for: type(of: self))
        guard let image = UIImage(named: "jiny_option_language", in: bundle, compatibleWith: nil) else { fatalError("Image not found") }
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        self.tintColor = themeColor == .white ? .black : .white
        let languageIcon = UIImageView(image: templateImage)
        languageIcon.contentMode = .scaleAspectFit
        languageButton.addSubview(languageIcon)
        
        languageIcon.translatesAutoresizingMaskIntoConstraints = false
        
        languageIcon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        languageIcon.heightAnchor.constraint(equalToConstant: 15).isActive = true
        languageIcon.leadingAnchor.constraint(equalTo: languageButton.leadingAnchor).isActive = true
        languageIcon.centerYAnchor.constraint(equalTo: languageButton.centerYAnchor).isActive = true
        
        let languageLabel = UILabel(frame: .zero)
        languageLabel.text = language
        languageLabel.textColor = themeColor == .white ? .black : .white
        languageLabel.font = UIFont.systemFont(ofSize: 12)
        languageButton.addSubview(languageLabel)
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        languageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        languageLabel.leadingAnchor.constraint(equalTo: languageIcon.trailingAnchor, constant: 6).isActive = true
        languageLabel.centerYAnchor.constraint(equalTo: languageIcon.centerYAnchor).isActive = true
        languageButton.trailingAnchor.constraint(equalTo: languageLabel.trailingAnchor, constant: 0).isActive = true
        
        languageButton.addTarget(self, action: #selector(languageClicked), for: .touchUpInside)
        
        return languageButton
    }
    
    func show() {
        
        let buttonHeightConstraint: NSLayoutConstraint? = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        let buttonWidthConstraint: NSLayoutConstraint? = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        if let htConst = buttonHeightConstraint { htConst.constant = 0 }
        if let widthConst = buttonWidthConstraint { widthConst.constant = 0 }
        let width: CGFloat = language != nil ? 240.0 : 140
        UIView.animate(withDuration: eachStageDuration) {
            if self.isLeftAligned {
                self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: width, height: self.frame.height)
            } else {
                guard self.button != nil else { return }
                let newXPosition = self.frame.minX - (width-self.button!.frame.width)
                self.frame = CGRect(x: newXPosition, y: self.frame.minY, width: width, height: self.frame.height)
            }
            self.button?.layer.cornerRadius = 0
            self.button?.layoutIfNeeded()
            self.layoutIfNeeded()
        } completion: { (completed) in
            self.button?.isHidden = true
            self.closeButtonHeightConstraint?.constant = 42
            self.imageHeightConstraint?.constant = 13
            self.optionsViewAnimateConstraint?.constant = 60
            UIView.animate(withDuration: self.eachStageDuration) {
                self.optionsView.alpha = 1.0
                self.closeButton.alpha = 1.0
                self.closeButton.layer.cornerRadius = 21
                self.layoutIfNeeded()
            } completion: { (secondComplete) in
                
            }
        }
    }
    
    @objc func languageClicked() {
        dismiss(true) { (_) in
           self.delegate?.languageClicked()
        }
    }
    
    @objc func stopClicked() {
        dismiss(true) { (_) in
           self.delegate?.stopClicked()
        }
    }
    
    @objc func remove() {
        dismiss(true) { (_) in
           self.delegate?.iconOptionsClosed()
        }
    }
    
    func dismiss(_ animated: Bool, _ completion: SuccessCallBack? = nil) {
        
        self.delegate?.iconOptionsDismissed()
        
        self.closeButtonHeightConstraint?.constant = 0
        self.imageHeightConstraint?.constant = 0
        self.optionsViewAnimateConstraint?.constant = 50
        
        if animated {
            
            UIView.animate(withDuration: eachStageDuration) {
                self.optionsView.alpha = 0.0
                self.closeButton.alpha = 0.0
                self.closeButton.layer.cornerRadius = 0
                self.layoutIfNeeded()
            } completion: { (_) in
                self.button?.isHidden = false
                let buttonHeightConstraint: NSLayoutConstraint? = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
                let buttonWidthConstraint: NSLayoutConstraint? = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
                if let htConst = buttonHeightConstraint { htConst.constant = self.frame.height}
                if let widthConst = buttonWidthConstraint { widthConst.constant = self.frame.height }
                UIView.animate(withDuration: self.eachStageDuration) {
                    if self.isLeftAligned {
                        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.height, height: self.frame.height)
                    } else {
                        guard self.button != nil else { return }
                        let newXPosition = self.button!.center.x - (self.frame.height/2)
                        self.frame = CGRect(x: newXPosition, y: self.frame.minY, width: self.frame.height, height: self.frame.height)
                    }
                    self.button?.layer.cornerRadius = self.frame.height/2
                    self.button?.layoutIfNeeded()
                    self.layoutIfNeeded()
                } completion: { (success) in
                    self.removeFromSuperview()
                    completion?(success)
                }
            }
            
        } else {
            self.button?.isHidden = false
            self.button?.layer.cornerRadius = self.frame.height/2
            self.button?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.removeFromSuperview()
            completion?(true)
        }
    }
}
