//
//  JinyLanguageRow.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 11/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol JinyLanguageRowDelegate {
    func buttonClicked(_ rowNo:Int, buttonIndex:Int)
    func failedToIdentifyClick()
}

class JinyLanguageRow: UIView {
    
    private var languages:Array<String>
    private var row:Int
    private var delegate:JinyLanguageRowDelegate
    
    init(withDelegate:JinyLanguageRowDelegate, withLanguages:Array<String>, rowNo:Int) {
        delegate = withDelegate
        languages = withLanguages
        row = rowNo
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension JinyLanguageRow {
    
    private func setupView() {
        self.translatesAutoresizingMaskIntoConstraints = false
        if languages.count == 1 {
            viewForSingleLanguage()
        } else if languages.count == 2 {
            viewForTwoLanguages()
        } else if languages.count == 3 {
            viewForThreeLanguages()
        }
        
    }
    
    private func viewForSingleLanguage() {
        let button1 = createButton(languages[0], buttonIndex: 0)
        self.addSubview(button1)
        setConstraintsForRowTo(button1)
        setCenterYConstFor([button1])
        
        let centerXConst = NSLayoutConstraint(item: button1, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let leadingConst = NSLayoutConstraint(item: button1, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .leading, multiplier: 1, constant: 100)
        NSLayoutConstraint.activate([centerXConst, leadingConst])
    }
    
    private func viewForTwoLanguages() {
        let button1 = createButton(languages[0], buttonIndex: 0)
        let button2 = createButton(languages[1], buttonIndex: 1)
        self.addSubview(button1)
        self.addSubview(button2)
        setConstraintsForRowTo(button1)
        setCenterYConstFor([button1, button2])
        
        let button1ToMid = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: button1, attribute: .trailing, multiplier: 1, constant: 7.5)
        let midToButton2 = NSLayoutConstraint(item: button2, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 7.5)
        let button1LeadingConst = NSLayoutConstraint(item: button1, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
        
        NSLayoutConstraint.activate([button1ToMid, midToButton2, button1LeadingConst])
        
    }
    
    private func viewForThreeLanguages() {
        let button1 = createButton(languages[0], buttonIndex: 0)
        let button2 = createButton(languages[1], buttonIndex: 1)
        let button3 = createButton(languages[2], buttonIndex: 2)
        self.addSubview(button1)
        self.addSubview(button2)
        self.addSubview(button3)
        setConstraintsForRowTo(button1)
        setCenterYConstFor([button1, button2, button3])
        
        let button2CenterConst = NSLayoutConstraint(item: button2, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let button1TrailingConst = NSLayoutConstraint(item: button2, attribute: .leading, relatedBy: .equal, toItem: button1, attribute: .trailing, multiplier: 1, constant: 7.5)
        let button3LeadingConst = NSLayoutConstraint(item: button3, attribute: .leading, relatedBy: .equal, toItem: button2, attribute: .trailing, multiplier: 1, constant: 7.5)
        let button1LeadingConst = NSLayoutConstraint(item: button1, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .leading, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([button2CenterConst, button1TrailingConst, button3LeadingConst, button1LeadingConst])
    }
    
    private func setConstraintsForRowTo(_ button:UIButton) {
        let topConst = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        NSLayoutConstraint.activate([topConst])
    }
    
    private func setCenterYConstFor(_ views:Array<UIView>) {
        for view in views {
            let centerYConst = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
            NSLayoutConstraint.activate([centerYConst])
        }
    }
    
    private func createButton(_ title:String, buttonIndex:Int) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityLabel = String(buttonIndex)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1.00), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.borderColor = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1.00).cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 19
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConst = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 85)
        let heightConst = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 38)
        NSLayoutConstraint.activate([widthConst, heightConst])
        return button
    }

    @objc private func buttonClicked(_ sender:UIButton) {
        guard let buttonIndex = Int(sender.accessibilityLabel ?? "") else {
            delegate.failedToIdentifyClick()
            return
        }
        delegate.buttonClicked(row, buttonIndex: buttonIndex)
    }
}
