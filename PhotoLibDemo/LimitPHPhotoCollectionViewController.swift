//
//  LimitPHPhotoCollectionViewController.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/13.
//

import UIKit
import PhotosUI

private let reuseIdentifier = "PHPhotoImageCell"

protocol LimitPHPhotoDelegate: NSObject {
    func getLimitImage(image: [UIImage])
    func phPhotoDidCancel()
}

class LimitPHPhotoCollectionViewController: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource , UICollectionViewDelegateFlowLayout, LimitImageNavViewDelegate, PHPhotoImageCellDelegate, PHPhotoLibraryChangeObserver {
    
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
    var fetchList: PHFetchResult<PHAsset>?
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        print(type(of: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.shared().register(self)
        setupViews()
        self.collectionView.register(PHPhotoImageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchImages()
    }
    
    //抓所選圖片
    func fetchImages() {
        imageModelArr = [LimitImageModel]()
        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.fetchList = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: option)
        var assets: [PHAsset] = [PHAsset]()
        self.fetchList?.enumerateObjects({ (obj, idx, stop) in
            let asset = obj as PHAsset
            //            print("照片名:", asset.value(forKey: "filename"))
            assets.append(asset)
        })
        //        let numStr = "全部圖片名: \(assets.count)"
        for set in assets {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            DispatchQueue.main.async {
                PHImageManager.default().requestImage(for: set, targetSize: CGSize(width: self.view.frame.width / 2.4, height: self.view.frame.width / 2.4), contentMode: .aspectFit, options: options) { [weak self] (image, info) in
                    guard let image = image else { return }
                    self?.imageModelArr?.append(LimitImageModel(image: image, isSelect: false, phAsset: set))
                    self?.collectionView.reloadData()
                }
            }
            
        }
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
        //获取原图
        guard let asset = imageModelArr?[indexPath.row].phAsset else { return }
        DispatchQueue.main.async {
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize , contentMode: .default, options: nil, resultHandler: { [weak self] (image, _: [AnyHashable : Any]?) in
                guard let image = image else { return }
                let previewImageVc = PreviewImageViewController()
                previewImageVc.setImage(image: image)
                self?.present(previewImageVc, animated: true, completion: nil)
            })
        }
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
        guard let imageModelArr = imageModelArr else { return }
        imageModelArr[index].isSelect = isSelected
        
        topNavView.doneButton.isEnabled = false
        for item in imageModelArr {
            if item.isSelect! {
                topNavView.doneButton.isEnabled = true
            }
        }
        
        collectionView.reloadData()
    }
    
    func navViewCancelPress() {
        self.delegate?.phPhotoDidCancel()
        self.dismiss(animated: true, completion: nil)
    }
    
    //把選取的相片傳出去
    func navViewDonePress() {
        guard let imageModelArr = imageModelArr else { return }
        var imageArr = [UIImage]()
        if topNavView.cancelButton.isEnabled {
            let assets = imageModelArr.filter({$0.isSelect == true})
            for asset in assets {
                    guard let phAsset = asset.phAsset else { return }
                PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: nil) { [weak self] (data, str, CGImagePropertyOrientation, info) in
                    guard let data = data, let image = UIImage(data: data) else { return }
                    imageArr.append(image)
                    if imageArr.count == assets.count {
                        self?.delegate?.getLimitImage(image: imageArr)
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        fetchImages()
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
