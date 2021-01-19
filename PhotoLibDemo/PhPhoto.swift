//
//  PhPhoto.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/12.
//

import Foundation
import UIKit
import Photos
import PhotosUI

enum SourceType {
    case camera
    case photoAlbum
}

protocol PhPhotoDelegate: NSObject {
    func getImageArrayWith(phPhoto: PhPhoto, sourceType: SourceType, imageArray: [UIImage]?)
}

class PhPhoto: NSObject, UINavigationControllerDelegate {
    typealias isLoading = (Bool, UIViewController) -> ()
    var coll = LimitPHPhotoCollectionViewController()
    var itemSize: CGSize?
    var sourceType: SourceType?
    var isLoadingCallBack: isLoading?
    
    private weak var delegate: PhPhotoDelegate?
    private var selecLimit = 1
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        print(type(of: self))
    }
    
    init(target: Any) {
        super.init()
        PHPhotoLibrary.shared().register(self)
        self.delegate = target as? PhPhotoDelegate
    }
    
    func addImageAction(selectionLimit: Int) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionP = UIAlertAction(title: "拍照", style: .default) { (action) in
            self.sourceType = .camera
            self.authorizeCamera()
        }
        actionP.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        actionP.setValue(UIColor.black, forKey: "titleTextColor")
        controller.addAction(actionP)
        
        let actionT = UIAlertAction(title: "照片圖庫", style: .default) { (action) in
            self.sourceType = .photoAlbum
            self.authorizePhotoAlbum(selectionLimit: selectionLimit)
        }
        actionT.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        actionT.setValue(UIColor.black, forKey: "titleTextColor")
        controller.addAction(actionT)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        controller.addAction(cancelAction)
        guard let vc = self.delegate as? UIViewController else { return }
        vc.present(controller, animated: true, completion: nil)
    }
    
    //相機狀態請求
    private func authorizeCamera() {
        let camStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch (camStatus){
        case .authorized: //允許
            openCamera()
        case .notDetermined: //未決定,請求授權
            AVCaptureDevice.requestAccess(for: AVMediaType.video,  completionHandler: { [weak self] (status) in
                DispatchQueue.main.async(execute: {
                    self?.authorizeCamera()
                })
            })
        default: //預設，如都不是以上狀態
            DispatchQueue.main.async(execute: {
                self.defaultAlert(title: "提醒", message: "允許相機授權才可於APP內開啟相機")
            })
        }
    }
    
    //相簿狀態請求
    private func authorizePhotoAlbum(selectionLimit: Int) {
        selecLimit = selectionLimit
        var photoLibraryStatus: PHAuthorizationStatus?
        if #available(iOS 14, *) {
            photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            photoLibraryStatus = PHPhotoLibrary.authorizationStatus()
        }
        switch photoLibraryStatus {
        case .authorized: //允許
            openPhotoAlbum(selectionLimit: selectionLimit)
        case .limited:
            if #available(iOS 14, *) {
                handleChangedLibrary(selectionLimit: selectionLimit, isPresent: true)
            }
        case .notDetermined: //未決定,請求授權
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async(execute: {
                    self.authorizePhotoAlbum(selectionLimit: selectionLimit)
                })
            })
        default: //預設，如都不是以上狀態
            DispatchQueue.main.async(execute: {
                self.defaultAlert(title: "提醒", message: "允許相簿授權才可於APP內開啟相簿")
            })
        }
    }
    
    //開啟相簿
    private func openPhotoAlbum(selectionLimit: Int) {
        guard let vc = self.delegate as? UIViewController else { return }
        if #available(iOS 14, *) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = selectionLimit
            let pickerVc = PHPickerViewController(configuration: configuration)
            pickerVc.modalPresentationStyle = .fullScreen
            pickerVc.delegate = self
            vc.present(pickerVc, animated: true, completion: nil)
        } else {
            let photoImagePC = UIImagePickerController()
            photoImagePC.modalPresentationStyle = .fullScreen
            photoImagePC.delegate = self
            photoImagePC.sourceType = .savedPhotosAlbum
            vc.show(photoImagePC, sender: vc)
        }
    }
    
    //開啟相機
    private func openCamera() {
        guard let vc = self.delegate as? UIViewController else { return }
        let photoImagePC = UIImagePickerController()
        photoImagePC.modalPresentationStyle = .fullScreen
        photoImagePC.delegate = self
        photoImagePC.sourceType = .camera
        photoImagePC.cameraFlashMode = .off
        vc.show(photoImagePC, sender: vc)
    }
    
    //預設事件
    private func defaultAlert(title: String = "", message: String = "") {
        guard let vc = self.delegate as? UIViewController else { return }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let canceAlertion = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let settingAction = UIAlertAction(title: "設定", style: .default, handler: { (action) in
            let url = URL(string: UIApplication.openSettingsURLString)
            if let url = url, UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                        print("跳至設定")
                    })
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        alertController.addAction(canceAlertion)
        alertController.addAction(settingAction)
        vc.present(alertController, animated: true, completion: nil)
    }
}

extension PhPhoto: PHPickerViewControllerDelegate {
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let sourceType = sourceType else { return }
        let semaphore = DispatchSemaphore(value: 0)
        var imageArr = [UIImage]()
        let itemProviders = results.map(\.itemProvider)
        for (i, itemProvider) in itemProviders.enumerated() where itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                semaphore.signal()
                guard let image = image as? UIImage else { return }
                imageArr.append(image)
                if i == itemProviders.count - 1 {
                    self.delegate?.getImageArrayWith(phPhoto: self, sourceType: sourceType, imageArray: imageArr)
                }
            }
            semaphore.wait()
        }
    }
}

extension PhPhoto: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let sourceType = sourceType, let image = info[.originalImage] as? UIImage else { return }
        var imageArr = [UIImage]()
        if picker.sourceType == .camera {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        imageArr.append(image)
        self.delegate?.getImageArrayWith(phPhoto: self, sourceType: sourceType, imageArray: imageArr)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension PhPhoto: PHPhotoLibraryChangeObserver, LimitPHPhotoDelegate {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        handleChangedLibrary(selectionLimit: selecLimit)
    }
    
    
    func handleChangedLibrary(selectionLimit: Int, isPresent: Bool = false) {
        DispatchQueue.main.async {
            let scale = UIScreen.main.scale
            self.itemSize = CGSize(width: ((self.delegate as? UIViewController)!.view.frame.width / 3 - 1)*scale, height: ((self.delegate as? UIViewController)!.view.frame.width / 3 - 1)*scale)
            guard let vc = self.delegate as? UIViewController, let itemSize = self.itemSize else { return }
            //reloadData一次
            var fetchResultCount = 0
            var imageCount = 0
            self.coll.delegate = self
            self.coll.selectionLimit = selectionLimit
            self.coll.imageModelArr = [LimitImageModel]()
            self.coll.modalPresentationStyle = .fullScreen
            //如果有推過vc 重新初始化imageModelArr reloadData (因為不會進fetchResult.enumerateObjects)
            if vc.presentedViewController != nil {
                self.coll.collectionView.reloadData()
            }
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            fetchResult.enumerateObjects { (obj, boo, stop) in
                //總共幾個obj
                fetchResultCount += 1
                let requestOpeion = PHImageRequestOptions()
                requestOpeion.resizeMode = .exact
                requestOpeion.deliveryMode = .highQualityFormat
                PHImageManager.default().requestImage(for: obj, targetSize: itemSize, contentMode: .aspectFill, options: requestOpeion) { (image, info) in
                    //imageCount=0第一次進來以及有present過頁面
                    if (imageCount == 0 && vc.presentedViewController != nil) {
                        self.isLoadingCallBack!(true, self.coll)
                    //第一次進來 需要present頁面
                    } else if  imageCount == 0 && isPresent {
                        self.isLoadingCallBack!(true, vc)
                    }
                    //篩選出共幾張為圖片
                    imageCount += 1
                    guard let image = image else {return}
                    self.coll.imageModelArr?.append(LimitImageModel(image: image, isSelect: false, phAsset: obj))
                    //結束判斷是否為image 有些影片會被帶入所以自定義count
                    if fetchResultCount == imageCount {
                        self.isLoadingCallBack!(false, vc)
                        //判斷是否present過vc 如果present過則reloadData 退出function
                        if vc.presentedViewController != nil {
                            self.coll.collectionView.reloadData()
                            return
                        }
                        //系統observer不會把isPresent參數帶入，所以預設為不present
                        //前段註解沒推過才會進入這一行 如果為系統observer則不present 如果點擊事件則present
                        if isPresent {
                            vc.present(self.coll, animated: true, completion: nil)
                            self.coll.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func getLimitImage(image: [UIImage]) {
        guard let sourceType = sourceType, let delegate = self.delegate else { return }
        delegate.getImageArrayWith(phPhoto: self, sourceType: sourceType, imageArray: image)
    }
}


