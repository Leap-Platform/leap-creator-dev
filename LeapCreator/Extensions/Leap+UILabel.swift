//
//  Leap+UILabel.swift
//  LeapCoreSDK
//
//  Created by Ajay S on 24/06/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    func addImage(imageName: String, afterLabel right: Bool = false) {
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName, in: Bundle(for: LeapCreator.self), compatibleWith: nil)
        attachment.bounds = CGRect(x: 0, y: -5, width: attachment.image?.size.width ?? 16, height: attachment.image?.size.height ?? 16)
        let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
        
        if right {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
            strLabelText.append(attachmentString)
            self.attributedText = strLabelText
        }
        else {
            let strLabelText: NSAttributedString = NSAttributedString(string: " \(self.text!)")
            let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
            mutableAttachmentString.append(strLabelText)
            self.attributedText = mutableAttachmentString
        }
    }
    
    func removeImage() {
        let text = self.text
        self.attributedText = nil
        self.text = text
    }
}
