//
//  JinyLanguagePanel.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 10/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol JinyLanguagePanelDelegate {
    
    func languagePanelPresented()
    func failedToPresentLanguagePanel()
    func indexOfLanguageSelected(_ languageIndex:Int)
    func languagePanelCloseClicked()
    func languagePanelSwipeDismissed()
    func languagePanelTappedOutside()
    
}

class JinyLanguagePanel: UIView {
    
    private let delegate:JinyLanguagePanelDelegate
    private let themeColor:UIColor
    private var languages:Array<String> = []
    
    private lazy var holder:UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.cornerRadius = 5.0
        if #available(iOS 11.0, *) {
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var dragRect:JinyDragRect = {
        let view = JinyDragRect(frame: .zero)
        return view
    }()
    
    private lazy var iconHolder:UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var jinyIcon:UIImageView = {
        let image = UIImageView(frame: .zero)
        image.contentMode = .scaleAspectFit
        image.image = UIImage.getImageFromBundle("jiny_icon")
        return image
    }()
    
    private lazy var poweredBy:JinyPoweredBy = {
        let view = JinyPoweredBy(frame: .zero)
        return view
    }()
    
    private lazy var closeButton:UIButton = {
        let button = UIButton(type: .system)
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage.getImageFromBundle("jiny_close"), for: .normal)
        button.addTarget(self, action: #selector(closeClicked), for: .touchUpInside)
        return button
    }()
    
    private lazy var languageHolder:UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private var languagePanelHolderBottomConst:NSLayoutConstraint?
    
    init(withDelegate:JinyLanguagePanelDelegate, frame: CGRect, languageTexts:Array<String>, theme:UIColor) {
        delegate = withDelegate
        languages = languageTexts
        themeColor = theme
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0, alpha: 0.0)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOutside)))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension JinyLanguagePanel {
    
    private func setupView() {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            delegate.failedToPresentLanguagePanel()
            return
        }
        
        guard languages.count > 1 else {
            delegate.failedToPresentLanguagePanel()
            return
        }
        setupHolder()
        keyWindow.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        let topConst = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: 0)
        let leadingConst = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: keyWindow, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: keyWindow, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([topConst, leadingConst, trailingConst, bottomConst])
        
    }
    
    private func setupHolder() {
        
        setupDragRect()
        setupJinyIcon()
        setupLanguageHolder()
        setupPoweredBy()
        setupCloseButton()
        
        
        let swipeToClose = JinySwipeDismiss(target: self, actionToDismiss: #selector(swipeToDismiss), view: holder)
        holder.addGestureRecognizer(swipeToClose)
        self.addSubview(holder)
        holder.translatesAutoresizingMaskIntoConstraints = false
        
        let centerXConst = NSLayoutConstraint(item: holder, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let prefLeadingConst = NSLayoutConstraint(item: holder, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        prefLeadingConst.priority = .defaultLow
        languagePanelHolderBottomConst = NSLayoutConstraint (item: holder, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: (UIScreen.main.bounds.height))
        let maxWidthConst = NSLayoutConstraint(item: holder, attribute: .width, relatedBy: .lessThanOrEqual, toItem:nil, attribute: .notAnAttribute, multiplier: 1, constant: 500)
        NSLayoutConstraint.activate([centerXConst, prefLeadingConst, languagePanelHolderBottomConst!, maxWidthConst])
    }
    
    private func setupDragRect() {
        
        holder.addSubview(dragRect)
        dragRect.translatesAutoresizingMaskIntoConstraints = false
        
        let topConst = NSLayoutConstraint(item: dragRect, attribute: .top, relatedBy: .equal, toItem: holder, attribute: .top, multiplier: 1, constant: 20)
        let centerXConst = NSLayoutConstraint(item: dragRect, attribute: .centerX, relatedBy: .equal, toItem: holder, attribute: .centerX, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([topConst,centerXConst])
        
    }
    
    private func setupJinyIcon() {
        
        setupIconImageView()
        iconHolder.backgroundColor = themeColor
        iconHolder.layer.cornerRadius = 26
        iconHolder.layer.masksToBounds = true
        holder.addSubview(iconHolder)
        iconHolder.translatesAutoresizingMaskIntoConstraints = false
        
        
        let heightConst = NSLayoutConstraint(item: iconHolder, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 52)
        let aspectConst = NSLayoutConstraint(item: iconHolder, attribute: .height, relatedBy: .equal, toItem: iconHolder, attribute: .width, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: iconHolder, attribute: .top, relatedBy: .equal, toItem: dragRect, attribute: .bottom, multiplier: 1, constant: 30)
        let centerXConst = NSLayoutConstraint(item: iconHolder, attribute: .centerX, relatedBy: .equal, toItem: holder, attribute: .centerX, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([heightConst, aspectConst, topConst, centerXConst])
        
    }
    
    private func setupIconImageView() {
        
        iconHolder.addSubview(jinyIcon)
        jinyIcon.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: jinyIcon, attribute: .leading, relatedBy: .equal, toItem: iconHolder, attribute: .leading, multiplier: 1, constant: 10)
        let trailingConst = NSLayoutConstraint(item: iconHolder, attribute: .trailing, relatedBy: .equal, toItem: jinyIcon, attribute: .trailing, multiplier: 1, constant: 10)
        let bottomConst = NSLayoutConstraint(item: iconHolder, attribute: .bottom, relatedBy: .equal, toItem: jinyIcon, attribute: .bottom, multiplier: 1, constant: 10)
        let topConst = NSLayoutConstraint(item: jinyIcon, attribute: .top, relatedBy: .equal, toItem: iconHolder, attribute: .top, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, topConst])
    }
    
    private func setupCloseButton() {
        
        holder.addSubview(closeButton)
        closeButton.tintColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1.00)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConst = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        let aspectConst = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: closeButton, attribute: .width, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: closeButton, attribute: .top, relatedBy: .equal, toItem: holder, attribute: .top, multiplier: 1, constant: 20)
        let trailingConst = NSLayoutConstraint(item: holder, attribute: .trailing, relatedBy: .equal, toItem: closeButton, attribute: .trailing, multiplier: 1, constant: 20)
        NSLayoutConstraint.activate([heightConst, aspectConst, topConst, trailingConst])
        
    }
    
    private func setupLanguageHolder() {
        
        createLangRows()
        
        holder.addSubview(languageHolder)
        languageHolder.translatesAutoresizingMaskIntoConstraints = false
        
        let centerXConst = NSLayoutConstraint(item: languageHolder, attribute: .centerX, relatedBy: .equal, toItem: holder, attribute: .centerX, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: languageHolder, attribute: .top, relatedBy: .equal, toItem: jinyIcon, attribute: .bottom, multiplier: 1, constant: 30)
        let prefLeadingConst = NSLayoutConstraint(item: languageHolder, attribute: .leading, relatedBy: .equal, toItem: holder, attribute: .leading, multiplier: 1, constant: 45)
        prefLeadingConst.priority = .defaultLow
        let leadingConst = NSLayoutConstraint(item: languageHolder, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: holder, attribute: .leading, multiplier: 1, constant: 30)
        let prefWidthConst = NSLayoutConstraint(item: languageHolder, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 290)
        prefWidthConst.priority = .defaultLow
        let maxHeight = NSLayoutConstraint(item: languageHolder, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150)
        
        NSLayoutConstraint.activate([centerXConst, topConst, prefLeadingConst, leadingConst, prefWidthConst, maxHeight])
        
    }
    
    private func createLangRows() {
        
        let contentView = UIView(frame: .zero)
        languageHolder.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConst = NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: languageHolder, attribute: .top, multiplier: 1, constant: 0)
        let leadingConst = NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: languageHolder, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: languageHolder, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: languageHolder, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0)
        let equalWidthConst = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: languageHolder, attribute: .width, multiplier: 1, constant: 0)
        let equalHeightConst = NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: languageHolder, attribute: .height, multiplier: 1, constant: 0)
        equalHeightConst.priority = .defaultLow
        NSLayoutConstraint.activate([topConst, leadingConst, trailingConst, bottomConst, equalWidthConst, equalHeightConst])
        
        
        var numberofRows = languages.count/3
        if languages.count%3 > 0 { numberofRows += 1}
        guard numberofRows > 0 else { return }
        
        var previousView:UIView = contentView
        for i in 0..<numberofRows {
            let langRow = getLangRow(i)
            contentView.addSubview(langRow)
            if i == 0 {
                let langRowTopConst = NSLayoutConstraint(item: langRow, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0)
                NSLayoutConstraint.activate([langRowTopConst])
            } else {
                let langRowTopConst = NSLayoutConstraint(item: langRow, attribute: .top, relatedBy: .equal, toItem: previousView, attribute: .bottom, multiplier: 1, constant: 0)
                NSLayoutConstraint.activate([langRowTopConst])
            }
            let leadingConst = NSLayoutConstraint(item: langRow, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0)
            let trailingConst = NSLayoutConstraint(item: langRow, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0)
            NSLayoutConstraint.activate([leadingConst, trailingConst])
            previousView = langRow
        }
        let finalConst = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: previousView, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([finalConst])
        
    }
    
    private func getLangRow(_ rowNo:Int) -> JinyLanguageRow {
        var rowLanguages = [String]()
        let firstElIndex = (rowNo * 3)
        if languages.count > firstElIndex + 2 { rowLanguages = Array(languages[firstElIndex...(firstElIndex+2)]) }
        else {
            let lastElIndex = (languages.count - 1)
            rowLanguages = Array(languages[firstElIndex...lastElIndex])
        }
        return JinyLanguageRow(withDelegate: self, withLanguages: rowLanguages, rowNo: rowNo)
    }
    
    private func setupPoweredBy() {
        holder.addSubview(poweredBy)
        poweredBy.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: poweredBy, attribute: .leading, relatedBy: .equal, toItem: holder, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: holder, attribute: .trailing, relatedBy: .equal, toItem: poweredBy, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: holder, attribute: .bottom, relatedBy: .equal, toItem: poweredBy, attribute: .bottom, multiplier: 1, constant: 0)
        let prefTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .equal, toItem: languageHolder, attribute: .bottom, multiplier: 1, constant: 30)
        prefTopConst.priority = .defaultLow
        let minTopConst = NSLayoutConstraint(item: poweredBy, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: languageHolder, attribute: .bottom, multiplier: 1, constant: 15)
        NSLayoutConstraint.activate([leadingConst, trailingConst, bottomConst, prefTopConst, minTopConst])
        
    }
    
}

extension JinyLanguagePanel {
    
    func presentPanel() {
        
        self.layoutIfNeeded()
        self.languagePanelHolderBottomConst?.constant = 0
        UIView.animate(withDuration: 1, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            UIView.animate(withDuration: 0.2, animations: {
                self.backgroundColor = UIColor(white: 0, alpha: 0.6)
                self.layoutIfNeeded()
            }) { (_) in
                self.delegate.languagePanelPresented()
            }
        }
        
    }
    
    @objc private func tappedOutside() {
        dismissLanguagePanel {
            self.delegate.languagePanelTappedOutside()
        }
    }
    
    @objc private func closeClicked() {
        dismissLanguagePanel {
            self.delegate.languagePanelCloseClicked()
        }
    }
    
    @objc private func swipeToDismiss() {
        dismissLanguagePanel {
            self.delegate.languagePanelSwipeDismissed()
        }
    }
    
    func dismissLanguagePanel(completion: @escaping()->Void) {
        self.layoutIfNeeded()
        self.languagePanelHolderBottomConst?.constant = UIScreen.main.bounds.height
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

extension JinyLanguagePanel : JinyLanguageRowDelegate {
    func buttonClicked(_ rowNo: Int, buttonIndex: Int) {
        let arrayIndex = (rowNo*3) + buttonIndex
        dismissLanguagePanel {
            self.delegate.indexOfLanguageSelected(arrayIndex)
        }
        
    }
    
    func failedToIdentifyClick() {
        
    }

}
