//
//  LimitImageNavView.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/13.
//

import UIKit

protocol LimitImageNavViewDelegate: NSObject {
    func navViewCancelPress()
    func navViewDonePress()
}

class LimitImageNavView: UIView {

    weak var delegate: LimitImageNavViewDelegate?
    
    var cancelButton: UIButton = {
       let button = UIButton()
        button.backgroundColor = .clear
        button.setTitleColor(.blue, for: .normal)
        button.setTitle("取消", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var doneButton: UIButton = {
       let button = UIButton()
        button.isEnabled = false
        button.backgroundColor = .clear
        button.setTitleColor(.blue, for: .normal)
        button.setTitle("完成", for: .normal)
        button.setTitle("完成", for: .disabled)
        button.setTitleColor(.gray, for: .disabled)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAction()
    }
    
    private func setupViews() {
        self.addSubview(cancelButton)
        cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        cancelButton.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: cancelButton.heightAnchor).isActive = true
        
        self.addSubview(doneButton)
        doneButton.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        doneButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        doneButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor).isActive = true
        doneButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor).isActive = true
    }
    
    private func setupAction() {
        cancelButton.addTarget(self, action: #selector(cancelPress), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(donePress), for: .touchUpInside)
    }
    
    @objc func cancelPress() {
        guard let delegate = delegate else { return }
        delegate.navViewCancelPress()
    }
    
    @objc func donePress() {
        guard let delegate = delegate else { return }
        delegate.navViewDonePress()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
