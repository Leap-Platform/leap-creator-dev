//
//  JinyLanguageButton.swift
//  TestFlowSelector
//
//  Created by Aravind GS on 04/06/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

@IBDesignable

class JinyLanguageButton: UIButton {
    
    @IBInspectable var image:UIImage? {
        didSet {
            let tempImage = image?.withRenderingMode(.alwaysTemplate)
            langImage.image = tempImage
            langImage.tintColor = themeColor
        }
    }
    @IBInspectable var language1:String? {
        didSet {
            lang1Label.text = language1
        }
    }
    @IBInspectable var language2:String? {
        didSet{
            lang2Label.text = language2
        }
    }
    
    @IBInspectable var themeColor:UIColor  {
        didSet {
            layer.borderColor = themeColor.cgColor
            arrow.tintColor = themeColor
        }
    }
    
    private lazy var lang1Label:UILabel = {
       return UILabel()
    }()
    
    private lazy var lang2Label:UILabel = {
        return UILabel()
    }()
    
    private lazy var langImage:UIImageView = {
        return UIImageView()
    }()
    
    private var arrow:UIImageView = {
        return UIImageView()
    }()
    
    init(_image:UIImage, _language1:String, _languge2:String, color:UIColor?) {
        image = _image
        language1 = _language1
        language2 = _languge2
        themeColor = color ?? UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00)
        super.init(frame: CGRect.zero)
        setupButton()
    }
    
    override init(frame: CGRect) {
        themeColor = UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00)
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        themeColor = UIColor(red: 0.05, green: 0.56, blue: 0.27, alpha: 1.00)
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        setTitle("", for: .normal)
        layer.cornerRadius = 21.0
        layer.borderColor = themeColor.cgColor
        layer.borderWidth = 1.0
        layer.masksToBounds = true
        setupLangImage()
        setupArrow()
        setupLang1()
        setupLang2()
    }
    
}

extension JinyLanguageButton {
    
    private func setupLangImage() {
       
        langImage.image = image?.withRenderingMode(.alwaysTemplate)
        langImage.tintColor = themeColor
        addSubview(langImage)
        langImage.translatesAutoresizingMaskIntoConstraints = false
        
        yCenterConstraint(langImage)
        
        let leadingConst = NSLayoutConstraint(item: langImage, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 20)
        let widthConst = NSLayoutConstraint(item: langImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 21)
        let heightConst = NSLayoutConstraint(item: langImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 18)
        let topConst = NSLayoutConstraint(item: langImage, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 12)
        
        NSLayoutConstraint.activate([leadingConst,widthConst,heightConst, topConst])
        
    }
    
    private func setupLang1() {
        lang1Label.text = language1
        lang1Label.textColor = .black
        lang1Label.baselineAdjustment = .alignCenters
        lang1Label.textAlignment = .center
        addSubview(lang1Label)
        lang1Label.translatesAutoresizingMaskIntoConstraints = false
        
        yCenterConstraint(lang1Label)
        let trailingConst = NSLayoutConstraint (item: self, attribute: .centerX, relatedBy: .equal, toItem: lang1Label, attribute: .trailing, multiplier: 1, constant: 10)
        let leadingConst  = NSLayoutConstraint (item: lang1Label, attribute: .leading, relatedBy: .equal, toItem: langImage, attribute: .trailing, multiplier: 1, constant: 15)
        
        NSLayoutConstraint.activate([trailingConst, leadingConst])
    }
    
    private func setupLang2() {
        lang2Label.text = language2
        lang2Label.textColor = .black
        lang2Label.baselineAdjustment = .alignCenters
        lang2Label.textAlignment = .center
        addSubview(lang2Label)
        lang2Label.translatesAutoresizingMaskIntoConstraints = false
        
        yCenterConstraint(lang2Label)
        
        let leadingConst = NSLayoutConstraint (item: lang2Label, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 10)
        let trailingConst = NSLayoutConstraint(item: arrow, attribute: .leading, relatedBy: .equal, toItem: lang2Label, attribute: .trailing, multiplier: 1, constant: 15)
        
        NSLayoutConstraint.activate([leadingConst, trailingConst])
        
    }
    
    private func setupArrow() {
        let image = UIImage.getImageFromBundle("jiny_continue")?.withRenderingMode(.alwaysTemplate)
        arrow.image = image
        arrow.tintColor = themeColor
        arrow.contentMode = .scaleAspectFit
        addSubview(arrow)
        arrow.translatesAutoresizingMaskIntoConstraints = false
        
        yCenterConstraint(arrow)
        
        let trailingConst = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: arrow, attribute: .trailing, multiplier: 1, constant: 30)
        let heightConst = NSLayoutConstraint(item: arrow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
        let widthConst = NSLayoutConstraint(item: arrow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 15)
        NSLayoutConstraint.activate([trailingConst, heightConst, widthConst])
        
    }
    
    private func yCenterConstraint(_ view:UIView) {
        let yCenterConst = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([yCenterConst])
    }
    
}
