//
//  PHPhotoImageCell.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/13.
//

import UIKit

protocol PHPhotoImageCellDelegate: NSObject {
    func selectImageWith(isSelected: Bool, index: Int)
}

class PHPhotoImageCell: UICollectionViewCell {
    
    weak var delegate: PHPhotoImageCellDelegate?
    var selectionLimit: Int?
    var imageSelectedCount = 0
    var imageModel: [LimitImageModel]? {
        didSet {
            imageSelectedCount = 0
            guard let imageModel = imageModel else { return }
            for item in imageModel {
                if item.isSelect! {
                    imageSelectedCount += 1
                }
            }
        }
    }
    
    var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleToFill
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    var selectButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.layer.borderColor = UIColor.gray.cgColor
        button.backgroundColor = .black
        button.alpha = 0.8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: Unselected_Image_Name), for: .normal)
        button.setImage(UIImage(named: Selected_Image_Name), for: .selected)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        imageView.addSubview(selectButton)
        selectButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -5).isActive = true
        selectButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5).isActive = true
        selectButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        selectButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        selectButton.addTarget(self, action: #selector(seleAction(sender:)), for: .touchUpInside)
    }
    
    @objc func seleAction(sender: UIButton) {
        guard let selectionLimit = selectionLimit else { return }
        let tag = sender.tag - 1000
        //超過限制張數不多選，低於限制張數可取消已選張數
        selectButton.isSelected = !(imageSelectedCount >= selectionLimit) ? !selectButton.isSelected : false
        guard let delegate = delegate else { return }
        delegate.selectImageWith(isSelected: selectButton.isSelected, index: tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
