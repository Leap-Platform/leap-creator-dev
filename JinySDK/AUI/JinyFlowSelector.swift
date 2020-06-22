//
//  JinyBranchSelector.swift
//  JinySDK
//
//  Created by Aravind GS on 13/05/20.
//  Copyright © 2020 Aravind GS. All rights reserved.
//

import UIKit

protocol JinyFlowSelectorDelegate {
    func failedToSetupFlowSelector(selectorView:JinyFlowSelector)
    func flowSelectorPresented(selectorView:JinyFlowSelector)
    func flowSelected(_ subflow:JinyFlow)
    func selectorViewRemoved(selectorView:JinyFlowSelector)
    func closeButtonClicked()
}

class JinyFlowSelector: UIView {
    
    let flowListArray:Array<JinyFlow>
    let branchTitle:Dictionary<String,Any>
    let backdrop:UIView
    let flowListView:UITableView
    let headerView:UIView
    let holderView:UIView
    let closeButton:UIButton
    let delegate:JinyFlowSelectorDelegate
    
    
    init(withDelegate selectorDelegate:JinyFlowSelectorDelegate, listOfFlows flowList:Array<JinyFlow>, branchTitle title:Dictionary<String,Any>) {
        backdrop = UIView()
        flowListView = UITableView()
        headerView = UIView()
        holderView = UIView()
        delegate = selectorDelegate
        flowListArray = flowList
        branchTitle = title
        closeButton = UIButton(type: .custom)
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension JinyFlowSelector {
    
    func setupView() {
        guard let parentView = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.last, flowListArray.count > 0 else {
            delegate.failedToSetupFlowSelector(selectorView: self)
            return
        }
        
        parentView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: parentView, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: parentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: parentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, trailingConst, topConst, bottomConst])
        
        flowListView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.FlowSelector.placeCellIdentifier)
        
        setupBackdrop()
        setupHolderView()
        setupHeaderView()
        setupFlowList()
        setupCloseButton()
        delegate.flowSelectorPresented(selectorView: self)
    }
    
    func setupBackdrop() {
        backdrop.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.addSubview(backdrop)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: backdrop, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: backdrop, attribute: .trailing, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: backdrop, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: backdrop, attribute: .bottom, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([leadingConst, trailingConst, topConst, bottomConst])
    }
    
    func setupFlowList() {
        flowListView.delegate = self
        flowListView.dataSource = self
//        flowListView.separatorInset = UIEdgeInsets(top: 0, left: 55, bottom: 0, right: 55)
        holderView.addSubview(flowListView)
        flowListView.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: flowListView, attribute: .leading, relatedBy: .equal, toItem: holderView, attribute: .leading, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: flowListView, attribute: .top, relatedBy: .equal, toItem: headerView, attribute: .bottom, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: holderView, attribute: .trailing, relatedBy: .equal, toItem: flowListView, attribute: .trailing, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint (item: holderView, attribute: .bottom, relatedBy: .equal, toItem: flowListView, attribute: .bottom, multiplier: 1, constant: 20)
        NSLayoutConstraint.activate([leadingConst, topConst, trailingConst, bottomConst])
    }
    
    func setupHolderView() {
        holderView.backgroundColor = UIColor.white
        holderView.layer.cornerRadius = 10.0
        holderView.layer.masksToBounds = true
        backdrop.addSubview(holderView)
        holderView.translatesAutoresizingMaskIntoConstraints = false
        
        let expectedHeight = (CGFloat(flowListArray.count) * 50.0) + 80.0 + 20
        
        let xCenter = NSLayoutConstraint(item: holderView, attribute: .centerX, relatedBy: .equal, toItem: backdrop, attribute: .centerX, multiplier: 1, constant: 0)
        let yCenter = NSLayoutConstraint(item: holderView, attribute: .centerY, relatedBy: .equal, toItem: backdrop, attribute: .centerY, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: holderView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: expectedHeight)
        let maxHeight = NSLayoutConstraint(item: holderView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 260)
        height.priority = .defaultLow
        let leadingConst = NSLayoutConstraint(item: holderView, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: backdrop, attribute: .leading, multiplier: 1.0 , constant: 20)
        let prefLeadingConst = NSLayoutConstraint(item: holderView, attribute: .leading, relatedBy: .equal, toItem: backdrop, attribute: .leading, multiplier: 1, constant: 40)
        prefLeadingConst.priority = .defaultLow
        let maxWidth = NSLayoutConstraint(item: holderView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 414)
        NSLayoutConstraint.activate([xCenter, yCenter, leadingConst, maxWidth, height, maxHeight, prefLeadingConst])
        
    }
    
    func setupHeaderView() {
        
        let title = UILabel()
        title.text = (branchTitle[Constants.FlowSelector.languageCode] as? Dictionary<String,Any>)?[Constants.FlowSelector.displayText] as? String
        title.textColor = UIColor.white
        title.textAlignment = .center
        title.font = UIFont.systemFont(ofSize: 16)
        headerView.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        
        let titleXCenter = NSLayoutConstraint(item: title, attribute: .centerX, relatedBy: .equal, toItem: headerView, attribute: .centerX, multiplier: 1, constant: 0)
        let titleYCenter = NSLayoutConstraint(item: title, attribute: .centerY, relatedBy: .equal, toItem: headerView, attribute: .centerY, multiplier: 1, constant: 0)
        let titleLead = NSLayoutConstraint(item: title, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: headerView, attribute: .leading, multiplier: 1, constant: 20)
        let titleTop = NSLayoutConstraint(item: title, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: headerView, attribute: .top, multiplier: 1, constant: 10)
        NSLayoutConstraint.activate([titleXCenter, titleYCenter, titleLead, titleTop])
        
        
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.56, blue: 0.47, alpha: 1.00)
        holderView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConst = NSLayoutConstraint(item: headerView, attribute: .leading, relatedBy: .equal, toItem: holderView, attribute: .leading, multiplier: 1, constant: 0)
        let topConst = NSLayoutConstraint(item: headerView, attribute: .top, relatedBy: .equal, toItem: holderView, attribute: .top, multiplier: 1, constant: 0)
        let trailingConst = NSLayoutConstraint(item: holderView, attribute: .trailing, relatedBy: .equal, toItem: headerView, attribute: .trailing, multiplier: 1, constant: 0)
        let heightConst = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 80)
        NSLayoutConstraint.activate([leadingConst, topConst, trailingConst, heightConst])
    }
    
    func setupCloseButton() {
        
        closeButton.setImage(UIImage.getImageFromBundle("jiny_close"), for: .normal)
        closeButton.backgroundColor = UIColor(white: 0, alpha: 0.35)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        closeButton.layer.cornerRadius = 18.0
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.layer.borderWidth = 1.0
        closeButton.layer.masksToBounds = true
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        backdrop.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConst = NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 36)
        let aspectConst = NSLayoutConstraint(item: closeButton, attribute: .width, relatedBy: .equal, toItem: closeButton, attribute: .height, multiplier: 1, constant: 0)
        let bottomConst = NSLayoutConstraint(item: holderView, attribute: .top, relatedBy: .equal, toItem: closeButton, attribute: .bottom, multiplier: 1, constant: 10)
        let trailingConst = NSLayoutConstraint(item: holderView, attribute: .trailing, relatedBy: .equal, toItem: closeButton, attribute: .trailing, multiplier: 1, constant: 5)
        NSLayoutConstraint.activate([heightConst, aspectConst, bottomConst, trailingConst])
    }
    
    @objc func closeButtonClicked() {
        delegate.closeButtonClicked()
        dismissView()
    }
    
    func dismissView() {
        self.removeFromSuperview()
        delegate.selectorViewRemoved(selectorView: self)
    }
    
}

extension JinyFlowSelector:UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flowListArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.FlowSelector.placeCellIdentifier, for: indexPath)
        cell.textLabel?.text = (flowListArray[indexPath.row].flowOptions[Constants.FlowSelector.languageCode] as? Dictionary<String, Any>)?[Constants.FlowSelector.displayText] as? String
        cell.textLabel?.textColor = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.00)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 54, bottom: 0, right: 54)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}

extension JinyFlowSelector:UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.flowSelected(flowListArray[indexPath.row])
        dismissView()
    }
    
}


extension Constants {
    struct FlowSelector {
        static let placeCellIdentifier = "place"
        static let languageCode = "hin"
        static let displayText = "displayed_text"
    }
}
