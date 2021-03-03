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
    func phPhotoCanceled()
}

class PhPhoto: NSObject, UINavigationControllerDelegate {
    
    typealias isLoading = (Bool, UIViewController) -> ()
//    var coll: LimitPHPhotoCollectionViewController?
    var itemSize: CGSize?
    var sourceType: SourceType?
    var isLoadingCallBack: isLoading?
    
    private weak var delegate: PhPhotoDelegate?
    private var selecLimit = 1
    
    deinit {
        print(type(of: self))
    }
    
    init(target: Any) {
        super.init()
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
                guard let vc = delegate as? UIViewController else { return }
                let coll = LimitPHPhotoCollectionViewController()
                coll.delegate = self
                coll.selectionLimit = selectionLimit
                vc.present(coll, animated: true, completion: nil)
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

extension PhPhoto: LimitPHPhotoDelegate{
    func phPhotoDidCancel() {
        self.delegate?.phPhotoCanceled()
    }
    
    func getLimitImage(image: [UIImage]) {
        guard let sourceType = sourceType else { return }
        self.delegate?.getImageArrayWith(phPhoto: self, sourceType: sourceType, imageArray: image)
    }
}


