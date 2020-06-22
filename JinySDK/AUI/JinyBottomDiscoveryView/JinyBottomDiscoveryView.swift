//
//  JinyBottomDiscovery.swift
//  JinySDK
//
//  Created by Aravind GS on 05/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

import UIKit.UIGestureRecognizerSubclass

protocol  JinyBottomDiscoveryDelegate {
    
    func discoveryPresentedWithOptInButton(_ button:UIButton)
    func discoverySheetDismissed()
    func optOutButtonClicked()
    func optInButtonClicked()
    func discoveryLanguageButtonClicked()
    
}

class JinyBottomDiscovery: UIView {
    
    private var delegate:JinyBottomDiscoveryDelegate
    private var languages:Array<String>
    private var titleText:String
    private var optInText:String
    private var optOutText:String
    private var themeColor:UIColor
    var bottomConstForHolder:NSLayoutConstraint?
    let screenHeight = UIScreen.main.bounds.height
    
    private var panRecognizer: JinySwipeDismiss?
    
    
    
    
    private lazy var backdrop:UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(optOutClicked)))
        view.backgroundColor = UIColor(white: 0, alpha: 0.0)
        return view
    }()
    
    private lazy var holder:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.clipsToBounds = false
        view.layer.masksToBounds = false
        return view
    }()
    
    private lazy var sheet:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.cornerRadius = 8.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var dragRect:JinyDragRect = {
        let view = JinyDragRect(frame: .zero)
        return view
    }()
    
    private lazy var title:UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 23)
        label.textColor = UIColor(red: 0.17, green: 0.16, blue: 0.17, alpha: 1.00)
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var optInButton:JinyOptInButton = {
        let button = JinyOptInButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setImage(UIImage.getImageFromBundle("jiny_continue"), for: .normal)
        return button
    }()
    
    private lazy var optOutButton:UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return button
    }()
    
    var languageButton:JinyLanguageButton?
    
    private lazy var poweredBy:JinyPoweredBy = {
        let poweredBy = JinyPoweredBy(frame: .zero)
        return poweredBy
    }()
    
    private lazy var iconHolder:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var icon:UIImageView = {
        let image = UIImageView(frame: .zero)
        image.image = UIImage.getImageFromBundle("jiny_icon")
        return image
    }()
    
    init(withDelegate:JinyBottomDiscoveryDelegate, header:String, jinyLanguages:Array<String>, optIn:String, optOut:String, color:UIColor) {
        delegate = withDelegate
        languages = jinyLanguages
        titleText = header
        optInText =  optIn
        optOutText = optOut
        languages = jinyLanguages
        themeColor = UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00)
        super.init(frame: CGRect.zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension JinyBottomDiscovery {
    
    private func setupView() {
        
        
        guard let keyWindow = UIApplication.shared.keyWindow else { return }
        self.backgroundColor = .clear
        keyWindow.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: keyWindow, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([leadingConst, topConst, trailingConst, bottomConst])
        
        setupBackDrop()
        setupHolder()
        
    }
    
    private func setupBackDrop() {
        
        addSubview(backdrop)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: backdrop, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: backdrop, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: backdrop, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: backdrop, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, topConst, trailingConst, bottomConst])
        
        
    }
    
    private func setupHolder() {
        
        setupSheet()
        setupIconHolder()
        panRecognizer = JinySwipeDismiss(target: self, actionToDismiss: #selector(optOutClicked), view: holder)
        holder.addGestureRecognizer(panRecognizer!)
        addSubview(holder)
        holder.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: holder, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: holder, attribute: .trailing, multiplier: 1, constant: 0)
        bottomConstForHolder = NSLayoutConstraint(item: holder, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: screenHeight)
        let topConst = NSLayoutConstraint(item: holder, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .top, multiplier: 1, constant: 64)
        
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConstForHolder!, topConst])
        
    }
    
    private func setupSheet() {
        
        setupSheetSubviews()
        
        holder.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: sheet, attribute: .leading, relatedBy: .equal, toItem: holder, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: holder, attribute: .trailing, relatedBy: .equal, toItem: sheet, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: holder, attribute: .bottom, relatedBy: .equal, toItem: sheet, attribute: .bottom, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: sheet, attribute: .top, relatedBy: .equal, toItem: holder, attribute: .top, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, topConst])
    }
    
    private func setupIconHolder() {
        
        setupIcon()
        iconHolder.backgroundColor = themeColor
        iconHolder.layer.borderColor = UIColor.white.cgColor
        iconHolder.layer.borderWidth = 2.0
        iconHolder.layer.cornerRadius = 25
        iconHolder.layer.masksToBounds = true
        holder.addSubview(iconHolder)
        iconHolder.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: iconHolder, attribute: .leading, relatedBy: .equal, toItem: holder, attribute: .leading, multiplier: 1, constant: 21)
        let heightConst = NSLayoutConstraint(item: iconHolder, attribute: .height, relatedBy: .equal, toItem:  nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let widthConst = NSLayoutConstraint(item: iconHolder, attribute: .width, relatedBy: .equal, toItem:  nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let yCenterConst = NSLayoutConstraint(item: iconHolder, attribute: .centerY, relatedBy: .equal, toItem: holder, attribute: .top, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst,heightConst,widthConst,yCenterConst])
        
    }
    
    private func setupIcon() {
        icon.contentMode = .scaleAspectFit
        iconHolder.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: icon, attribute: .leading, relatedBy: .equal, toItem: iconHolder, attribute: .leading, multiplier: 1, constant: 10)
        let trailingConst = NSLayoutConstraint(item: iconHolder, attribute: .trailing, relatedBy: .equal, toItem: icon, attribute: .trailing, multiplier: 1, constant: 10)
        let bottomConst = NSLayoutConstraint(item: iconHolder, attribute: .bottom, relatedBy: .equal, toItem: icon, attribute: .bottom, multiplier: 1, constant: 10)
        let topConst = NSLayoutConstraint(item: icon, attribute: .top, relatedBy: .equal, toItem: iconHolder, attribute: .top, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, topConst])
        
    }
    
    private func setupSheetSubviews() {
        
        setupDragRect()
        setupTitle()
        setupOptInButton()
        setupOptOutButton()
        setupLanguageButton()
        setupPoweredByHolder()
        
    }
    
    private func setupDragRect() {
        sheet.addSubview(dragRect)
        dragRect.translatesAutoresizingMaskIntoConstraints = false
        
        let topConst = NSLayoutConstraint(item: dragRect, attribute: .top, relatedBy: .equal, toItem: sheet, attribute: .top, multiplier: 1, constant: 20)
        let centerXConst = NSLayoutConstraint(item: dragRect, attribute: .centerX, relatedBy: .equal, toItem: sheet, attribute: .centerX, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([topConst, centerXConst])
        
    }
    
    private func setupTitle() {
        title.text = titleText
        title.textAlignment = .center
        sheet.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: title, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: sheet, attribute: .leading, multiplier: 1, constant: 60)
        
        topAndCenterXConstraintsForSheetSubviews(forView: title, toView: dragRect, preferred: 65, min: 20)
        
        NSLayoutConstraint.activate([leadingConst])
    }
    
    private func setupOptInButton() {
        
        optInButton.backgroundColor = themeColor
        optInButton.setTitle(optInText, for: .normal)
        optInButton.layer.cornerRadius = 21
        optInButton.layer.masksToBounds = true
        sheet.addSubview(optInButton)
        optInButton.addTarget(self, action: #selector(optInClicked), for: .touchUpInside)
        optInButton.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConst = NSLayoutConstraint(item: optInButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 42)
        let widthConst = NSLayoutConstraint(item: optInButton, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 162)
        
        topAndCenterXConstraintsForSheetSubviews(forView: optInButton, toView: title, preferred: 40, min: 15)
        
        NSLayoutConstraint.activate([heightConst, widthConst])
        
    }
    
    private func setupOptOutButton() {
        
        optOutButton.setTitle(optOutText, for: .normal)
        optOutButton.setTitleColor(UIColor(red: 0.38, green: 0.38, blue: 0.39, alpha: 1.00), for: .normal)
        sheet.addSubview(optOutButton)
        optOutButton.addTarget(self, action: #selector(optOutClicked), for: .touchUpInside)
        optOutButton.translatesAutoresizingMaskIntoConstraints = false
        
        topAndCenterXConstraintsForSheetSubviews(forView: optOutButton, toView: optInButton, preferred: 25, min: 15)
        
    }
    
    private func setupLanguageButton() {
        if languages.count < 2 { return }
        languageButton = JinyLanguageButton(_image: UIImage.getImageFromBundle("jiny_language")!, _language1: languages[0], _languge2: languages[1], color: themeColor)
        sheet.addSubview(languageButton!)
        languageButton!.addTarget(self, action: #selector(languageButtonClicked), for: .touchUpInside)
        languageButton!.translatesAutoresizingMaskIntoConstraints = false
        
        topAndCenterXConstraintsForSheetSubviews(forView: languageButton!, toView: optOutButton, preferred: 15, min: 10)
        
        
    }
    
    private func setupPoweredByHolder() {
        sheet.addSubview(poweredBy)
        poweredBy.translatesAutoresizingMaskIntoConstraints = false
        
        var topView:UIButton?
        
        if languages.count < 2 { topView = optOutButton }
        else { topView = languageButton }
        
        let leadingConst = NSLayoutConstraint(item: poweredBy, attribute: .leading, relatedBy: .equal, toItem: sheet, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: sheet, attribute: .trailing, relatedBy: .equal, toItem: poweredBy, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: sheet, attribute: .bottom, relatedBy: .equal, toItem: poweredBy, attribute: .bottom, multiplier: 1, constant: 0)
        let prefTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .equal, toItem: topView!, attribute: .bottom, multiplier: 1, constant: 15)
        prefTopConst.priority = .defaultLow
        let minTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: topView!, attribute: .bottom, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, prefTopConst, minTopConst])
        
    }
    
    private func topAndCenterXConstraintsForSheetSubviews(forView:UIView, toView:UIView, preferred:CGFloat, min:CGFloat) {
        
        let prefTopConst = NSLayoutConstraint(item: forView, attribute: .top, relatedBy: .equal, toItem: toView, attribute: .bottom, multiplier: 1, constant: preferred)
        prefTopConst.priority = .defaultLow
        let minTopConst = NSLayoutConstraint(item: forView, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: toView, attribute: .bottom, multiplier: 1, constant: min)
        let centerXConst = NSLayoutConstraint(item: forView, attribute: .centerX, relatedBy: .equal, toItem: sheet, attribute: .centerX, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([prefTopConst, minTopConst, centerXConst])
        
    }

}

extension JinyBottomDiscovery {
    
    @objc private func optOutClicked() {
        dismissView {
            self.delegate.optOutButtonClicked()
        }
        
    }
    
    @objc private func optInClicked() {
        dismissView {
            self.delegate.optInButtonClicked()
        }
        
    }
    
    @objc private func languageButtonClicked() {
        dismissView {
            self.delegate.discoveryLanguageButtonClicked()
        }
        
    }
    
}


extension JinyBottomDiscovery {
    
    func presentBottomDiscovery() {
        self.layoutSubviews()
        
        self.bottomConstForHolder?.constant = 0
        UIView.animate(withDuration: 1, animations: {
            self.layoutSubviews()
        }) { (completed) in
            UIView.animate(withDuration: 0.2, animations: {
                self.backdrop.backgroundColor = UIColor(white: 0, alpha: 0.6)
            },completion: {(animationCompleted) in
                self.delegate.discoveryPresentedWithOptInButton(self.optInButton)
            })
        }
        
    }
    
    @objc func dismissView( dismissed: @escaping ()->Void) {
        
        self.bottomConstForHolder?.constant = screenHeight
        UIView.animate(withDuration: 0.5) {
            self.layoutSubviews()
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.layoutSubviews()
        }) { (completed) in
            
            UIView.animate(withDuration: 0.3, animations: {
                self.backdrop.backgroundColor = UIColor(white: 0, alpha: 0.0)
            }) { (backdropDismissed) in
                self.removeFromSuperview()
                dismissed()
            }
        }
    }
    
}
