//
//  PreviewImageViewController.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/14.
//

import UIKit

class PreviewImageViewController: UIViewController, UIScrollViewDelegate {

    var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        return scrollView
    }()
    
    var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        return iv
    }()
    
    var cancelButton: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .white
        btn.alpha = 0.3
        btn.layer.cornerRadius = 25
        btn.imageView?.contentMode = .scaleToFill
        btn.setImage(UIImage(named: Cancel_Image_Name), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    deinit {
        print(type(of: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
    }
    
    func setupViews() {
        scrollView.delegate = self
        scrollView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        imageView.frame = CGRect(x: scrollView.frame.origin.x, y: scrollView.frame.origin.y, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
        self.view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        self.view.addSubview(cancelButton)
        cancelButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 15).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        cancelButton.addTarget(self, action: #selector(cancelBtnAction), for: .touchUpInside)
    }
    
    func setImage(image: UIImage) {
        imageView.image = image
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        for view in scrollView.subviews {
            if view .isKind(of: UIView.self) {
                return view
            }
        }
        return nil
    }
    
    @objc func cancelBtnAction() {
        self.dismiss(animated: true, completion: nil)
    }
}
