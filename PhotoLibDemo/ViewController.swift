//
//  ViewController.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/12.
//

import UIKit

class ViewController: UIViewController, PhPhotoDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let addImageButton = UIButton()
    let button = UIButton()
    let camera = UIButton()
    var photo: PhPhoto?
    
    var loadingView = UIActivityIndicatorView()
    
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    var imageArr: [UIImage]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        photo = PhPhoto(target: self)
        
        photo?.isLoadingCallBack = { [weak self] (isLoading, vc) in
            print(isLoading, vc)
            guard let self = self else { return }
            self.loadingView.translatesAutoresizingMaskIntoConstraints = false
            vc.view.addSubview(self.loadingView)
            self.loadingView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            self.loadingView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            self.loadingView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.loadingView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            self.loadingView.color = .gray
            self.loadingView.style = .large
            isLoading ? self.loadingView.startAnimating() : self.loadingView.stopAnimating()
            
        }
        
    }
    
    func setupViews() {
        overrideUserInterfaceStyle = .light
        self.view.backgroundColor = .white
        addImageButton.frame = CGRect(x: 0, y: 40, width: 50, height: 50)
        addImageButton.backgroundColor = .red
        addImageButton.addTarget(self, action: #selector(addImageAction), for: .touchUpInside)
        self.view.addSubview(addImageButton)
        self.view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: addImageButton.bottomAnchor).isActive = true
        if #available(iOS 11.0, *) {
            tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
    }
    
    
    @objc func addImageAction() {
        if self.photo == nil {
            photo = PhPhoto(target: self)
        }
        photo?.addImageAction(selectionLimit: 1)
    }
    
    func getImageArrayWith(phPhoto: PhPhoto, sourceType: SourceType, imageArray: [UIImage]?) {
        guard let imageArray = imageArray else { return }
//        print(sourceType ,imageArray.count, imageArray)
        imageArr = imageArray
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.photo = nil
    }
    
    func phPhotoCanceled() {
        self.photo = nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageArr?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let image = imageArr?[indexPath.row]
        let newImage = image?.imageWithNewSize(size: CGSize(width: 1024, height: 1024))
        cell.imageView?.image = UIImage(data: (newImage?.compressImageMid(maxLength: 1024 * 1024))!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

extension UIImage {
    //二分壓縮法
    func compressImageMid(maxLength: Int) -> Data? {
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: 1) else { return nil }
        if data.count < maxLength {
            return data
        }
        print("壓縮前kb", data.count / 1024, "KB")
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = self.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(maxLength) * 0.9 {
                min = compression
            } else if data.count > maxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        
            return data
        
    }
    
    public func imageWithNewSize(size: CGSize) -> UIImage? {
        
        if self.size.height > size.height {
            
            let width = size.height / self.size.height * self.size.width
            
            let newImgSize = CGSize(width: width, height: size.height)
            
            UIGraphicsBeginImageContext(newImgSize)
            
            self.draw(in: CGRect(x: 0, y: 0, width: newImgSize.width, height: newImgSize.height))
            
            let theImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            guard let newImg = theImage else { return  nil}
            
            return newImg
            
        } else {
            
            let newImgSize = CGSize(width: size.width, height: size.height)
            
            UIGraphicsBeginImageContext(newImgSize)
            
            self.draw(in: CGRect(x: 0, y: 0, width: newImgSize.width, height: newImgSize.height))
            
            let theImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            guard let newImg = theImage else { return  nil}
            
            return newImg
        }
        
    }

}

