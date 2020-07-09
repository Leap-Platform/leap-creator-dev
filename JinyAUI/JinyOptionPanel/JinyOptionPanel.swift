//
//  JinyOptionPanel.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 06/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol JinyOptionPanelDelegate {
    
    func failedToShowOptionPanel()
    func optionPanelPresented()
    func muteButtonClicked()
    func repeatButtonClicked()
    func chooseLanguageButtonClicked()
    func optionPanelDismissed()
    func optionPanelCloseClicked()
}

class JinyOptionPanel: UIView {
    
    private var delegate:JinyOptionPanelDelegate
    private var sheetBottomConst:NSLayoutConstraint?
    
    private lazy var optionSheet:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.cornerRadius = 5.0
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var buttonsHolder:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var dragRect:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.00)
        view.layer.cornerRadius = 3.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var closeButton:UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage.getImageFromBundle("jiny_close"), for: .normal)
        button.addTarget(self, action: #selector(closeClicked), for: .touchUpInside)
        return button
    }()
    
    private lazy var poweredBy:JinyPoweredBy = {
        let poweredBy = JinyPoweredBy(frame: .zero)
        return poweredBy
    }()
    
    private var muteButton:JinyOptionPanelButton
    
    private var repeatButton:JinyOptionPanelButton
    
    private var chooseLanguageButton:JinyOptionPanelButton?
    
    
    init(withDelegate:JinyOptionPanelDelegate, repeatText:String, muteText:String, languageText:String?) {
        delegate = withDelegate
        repeatButton = JinyOptionPanelButton(_icon: UIImage.getImageFromBundle("jiny_repeat")!, _text: repeatText)
        if languageText != nil { chooseLanguageButton = JinyOptionPanelButton(_icon: UIImage.getImageFromBundle("jiny_change_lang")!, _text: languageText!) }
        muteButton = JinyOptionPanelButton(_icon: UIImage.getImageFromBundle("jiny_mute")!, _text: muteText)
        super.init(frame: CGRect.zero)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOutside)))
        
        guard setupOptionPanel() else {
            delegate.failedToShowOptionPanel()
            return
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


extension JinyOptionPanel {
    
    private func setupOptionPanel() -> Bool {
        guard let keyWindow = UIApplication.shared.keyWindow else { return false }
        
        
        setupOptionSheet()
        
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        keyWindow.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: keyWindow, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, topConst, trailingConst, bottomConst])
        
        return true
    }
    
    private func setupOptionSheet() {
        
        setupDragRect()
        setupButtonHolder()
        setupPoweredBy()
        setupCloseButton()
        
        let swipeGesture = JinySwipeDismiss(target: self, actionToDismiss: #selector(tapOutside), view: optionSheet)
        optionSheet.addGestureRecognizer(swipeGesture)
        addSubview(optionSheet)
        optionSheet.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: optionSheet, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        leadingConst.priority = .defaultLow
        sheetBottomConst = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: optionSheet, attribute: .bottom, multiplier: 1, constant: -200)
        let centerXConst = NSLayoutConstraint(item: optionSheet, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, sheetBottomConst!,centerXConst])
        
    }
    
    func setupDragRect() {
        
        optionSheet.addSubview(dragRect)
        dragRect.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConst = NSLayoutConstraint(item: dragRect, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 36)
        let heightConst = NSLayoutConstraint(item: dragRect, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 6)
        let topConst = NSLayoutConstraint(item: dragRect, attribute: .top, relatedBy: .equal, toItem: optionSheet, attribute: .top, multiplier: 1, constant:20)
        let centerXConst = NSLayoutConstraint(item: dragRect, attribute: .centerX, relatedBy: .equal, toItem: optionSheet, attribute: .centerX, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([widthConst, heightConst, topConst, centerXConst])
    }
    
    func setupButtonHolder() {
        
        setupRepeatButton()
        setupMuteButton()
        if chooseLanguageButton != nil { setupLanguageButton() }
        
        optionSheet.addSubview(buttonsHolder)
        buttonsHolder.translatesAutoresizingMaskIntoConstraints = false
        
        let centerXConst = NSLayoutConstraint(item: buttonsHolder, attribute: .centerX, relatedBy: .equal, toItem: optionSheet, attribute: .centerX, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: buttonsHolder, attribute: .top, relatedBy: .equal, toItem: dragRect, attribute: .top, multiplier: 1, constant: 30)
        let leadingConst = NSLayoutConstraint(item: buttonsHolder, attribute: .leading, relatedBy: .lessThanOrEqual, toItem: optionSheet, attribute: .leading, multiplier: 1, constant: 60)
        NSLayoutConstraint.activate([centerXConst, topConst, leadingConst])
        
    }
    
    private func setupRepeatButton() {
        
        buttonsHolder.addSubview(repeatButton)
        repeatButton.addTarget(self, action: #selector(repeatButtonClicked), for: .touchUpInside)
        repeatButton.translatesAutoresizingMaskIntoConstraints = false
        
        let centerYConst = NSLayoutConstraint(item: repeatButton, attribute: .centerY, relatedBy: .equal, toItem: buttonsHolder, attribute: .centerY, multiplier: 1, constant: 0)
        
        if chooseLanguageButton != nil {
            
            let centerXConst = NSLayoutConstraint(item: repeatButton, attribute: .centerX, relatedBy: .equal, toItem: buttonsHolder, attribute: .centerX, multiplier: 1, constant: 0)
            NSLayoutConstraint.activate([centerXConst])
        } else {
            let leadingConst = NSLayoutConstraint(item: repeatButton, attribute: .leading, relatedBy: .equal, toItem: buttonsHolder, attribute: .centerX, multiplier: 1, constant: 65)
            NSLayoutConstraint.activate([leadingConst])
        }
        
        
        let topConst = NSLayoutConstraint(item: repeatButton, attribute: .top, relatedBy: .equal, toItem: buttonsHolder, attribute: .top, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([centerYConst, topConst])
        
    }
    
    private func setupMuteButton() {
        
        buttonsHolder.addSubview(muteButton)
        muteButton.addTarget(self, action: #selector(muteButtonClicked), for: .touchUpInside)
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        
        let centerYConst = NSLayoutConstraint(item: muteButton, attribute: .centerY, relatedBy: .equal, toItem: repeatButton, attribute: .centerY, multiplier: 1, constant: 0)
        let leadingConst = NSLayoutConstraint(item: muteButton, attribute: .leading, relatedBy: .equal, toItem: buttonsHolder, attribute: .leading, multiplier: 1, constant: 0)
        if chooseLanguageButton != nil {
            let trailingConst = NSLayoutConstraint(item: repeatButton, attribute: .leading, relatedBy: .equal, toItem: muteButton, attribute: .trailing, multiplier: 1, constant: 65)
            NSLayoutConstraint.activate([trailingConst])
        } else {
            let trailingConst = NSLayoutConstraint(item: buttonsHolder, attribute: .centerX, relatedBy: .equal, toItem: muteButton, attribute: .trailing, multiplier: 1, constant: 65)
            NSLayoutConstraint.activate([trailingConst])
        }
        NSLayoutConstraint.activate([centerYConst, leadingConst])
        
    }
    
    private func setupLanguageButton() {
        
        buttonsHolder.addSubview(chooseLanguageButton!)
        chooseLanguageButton!.addTarget(self, action: #selector(languageButtonClicked), for: .touchUpInside)
        chooseLanguageButton!.translatesAutoresizingMaskIntoConstraints = false
        
        let centerYConst = NSLayoutConstraint(item: chooseLanguageButton!, attribute: .centerY, relatedBy: .equal, toItem: repeatButton, attribute: .centerY, multiplier: 1, constant: 0)
        let leadingConst = NSLayoutConstraint(item: chooseLanguageButton!, attribute: .leading, relatedBy: .equal, toItem: repeatButton, attribute: .trailing, multiplier: 1, constant: 70)
        let trailingConst = NSLayoutConstraint(item: buttonsHolder, attribute: .trailing, relatedBy: .equal, toItem: chooseLanguageButton!, attribute: .trailing, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([centerYConst, leadingConst, trailingConst])
        
    }
    private func setupPoweredBy() {
        optionSheet.addSubview(poweredBy)
        poweredBy.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: poweredBy, attribute: .leading, relatedBy: .equal, toItem: optionSheet, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: optionSheet, attribute: .trailing, relatedBy: .equal, toItem: poweredBy, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: optionSheet, attribute: .bottom, relatedBy: .equal, toItem: poweredBy, attribute: .bottom, multiplier: 1, constant: 0)
        let prefTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .equal, toItem: buttonsHolder, attribute: .bottom, multiplier: 1, constant: 20)
        prefTopConst.priority = .defaultLow
        let minTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: buttonsHolder, attribute: .bottom, multiplier: 1, constant: 15)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, prefTopConst, minTopConst])
    }
    
    private func setupCloseButton() {
        
        optionSheet.addSubview(closeButton)
        closeButton.tintColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1.00)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConst = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 18)
        let aspectConst = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: closeButton, attribute: .width, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: closeButton, attribute: .top, relatedBy: .equal, toItem: optionSheet, attribute: .top, multiplier: 1, constant: 15)
        let trailingConst = NSLayoutConstraint(item: optionSheet, attribute: .trailing, relatedBy: .equal, toItem: closeButton, attribute: .trailing, multiplier: 1, constant: 15)
        NSLayoutConstraint.activate([heightConst, aspectConst, topConst, trailingConst])
        
    }
    
}

extension JinyOptionPanel {
    func presentPanel() {
        self.layoutIfNeeded()
        self.sheetBottomConst?.constant = 0
        UIView.animate(withDuration: 1, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = UIColor(white: 0, alpha: 0.6)
                self.layoutIfNeeded()
            }) { (_) in
                self.delegate.optionPanelPresented()
            }
        }
        
    }
    
    @objc private func tapOutside() {
        dismissOptionPanel {
            self.delegate.optionPanelDismissed()
        }
    }
}

extension JinyOptionPanel {
    
    func dismissOptionPanel(completion: @escaping()->Void) {
        self.layoutIfNeeded()
        self.sheetBottomConst?.constant = -200
        UIView.animate(withDuration: 0.5, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = UIColor(white: 0, alpha: 0.0)
            }) { (_) in
                self.removeFromSuperview()
                completion()
            }
        }
    }
    
}


extension JinyOptionPanel {
    
    @objc private func muteButtonClicked() {
        dismissOptionPanel {
            self.delegate.muteButtonClicked()
        }
    }
    
    @objc private func repeatButtonClicked() { dismissOptionPanel {
        self.delegate.repeatButtonClicked()
        }
    }
    
    @objc private func languageButtonClicked() {
        dismissOptionPanel {
            self.delegate.chooseLanguageButtonClicked()
        }
    }
    
    @objc private func closeClicked() {
        dismissOptionPanel {
            self.delegate.optionPanelCloseClicked()
        }
    }
    
}
