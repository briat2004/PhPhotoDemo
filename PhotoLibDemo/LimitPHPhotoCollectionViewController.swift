//
//  LimitPHPhotoCollectionViewController.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/13.
//

import UIKit

private let reuseIdentifier = "PHPhotoImageCell"

protocol LimitPHPhotoDelegate: NSObject {
    func getLimitImage(image: [UIImage])
}

class LimitPHPhotoCollectionViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout, LimitImageNavViewDelegate, PHPhotoImageCellDelegate {
    
    weak var delegate: LimitPHPhotoDelegate?
    var selectionLimit: Int?
    
    
    var topNavView: LimitImageNavView = {
        let view = LimitImageNavView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let coll = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        coll.translatesAutoresizingMaskIntoConstraints = false
        return coll
    }()
    
    var imageModelArr: [LimitImageModel]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        self.collectionView.register(PHPhotoImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageModelArr?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PHPhotoImageCell
        cell?.selectionLimit = self.selectionLimit
        cell?.imageModel = imageModelArr
        cell?.delegate = self
        cell?.imageView.image = imageModelArr?[indexPath.row].image
        cell?.selectButton.isSelected = imageModelArr?[indexPath.row].isSelect ?? false
        cell?.selectButton.tag = indexPath.row + 1000
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let image = imageModelArr?[indexPath.row].image else { return }
        let previewImageVc = PreviewImageViewController()
        previewImageVc.setImage(image: image)
        self.present(previewImageVc, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width / 3 - 1, height: self.view.frame.width / 3 - 1)
    }
    
    //選照片
    func selectImageWith(isSelected: Bool, index: Int) {
        
        imageModelArr?[index].isSelect = isSelected
        
        topNavView.doneButton.isEnabled = false
        guard let imageModelArr = imageModelArr else { return }
        for item in imageModelArr {
            if item.isSelect! {
                topNavView.doneButton.isEnabled = true
            }
        }
        
        collectionView.reloadData()
    }
    
    func navViewCancelPress() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func navViewDonePress() {
        var imageArr = [UIImage]()
        if topNavView.cancelButton.isEnabled {
            guard let imageModelArr = imageModelArr else { return }
            for item in imageModelArr {
                guard let image = item.image, let isSelect = item.isSelect else { return }
                if isSelect {
                    imageArr.append(image)
                }
            }
            self.dismiss(animated: true) { [weak self] in
                guard let self = self, let delegate = self.delegate else { return }
                delegate.getLimitImage(image: imageArr)
            }
        }
    }
    
    func setupViews() {
        self.view.backgroundColor = .black
        self.collectionView.backgroundColor = .black
        var leading = self.view.leadingAnchor
        var trailing = self.view.trailingAnchor
        var top = self.view.topAnchor
        var bottom = self.view.bottomAnchor
        if #available(iOS 11, *) {
            leading = self.view.safeAreaLayoutGuide.leadingAnchor
            trailing = self.view.safeAreaLayoutGuide.trailingAnchor
            top = self.view.safeAreaLayoutGuide.topAnchor
            bottom = self.view.safeAreaLayoutGuide.bottomAnchor
        }
        
        self.view.addSubview(topNavView)
        topNavView.leadingAnchor.constraint(equalTo: leading, constant: 5).isActive = true
        topNavView.trailingAnchor.constraint(equalTo: trailing, constant: -5).isActive = true
        topNavView.topAnchor.constraint(equalTo: top, constant: 5).isActive = true
        topNavView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        topNavView.delegate = self
        
        self.view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: leading).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailing).isActive = true
        collectionView.topAnchor.constraint(equalTo: topNavView.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottom).isActive = true
    }

    
    
}
