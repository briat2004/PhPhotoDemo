//
//  LimitImageModel.swift
//  PhotoLibDemo
//
//  Created by BruceWu on 2021/1/13.
//

import Foundation
import UIKit

let Selected_Image_Name = "myAppCheckbox02_selected"
let Unselected_Image_Name = "myAppCheckbox02_normal"
let Cancel_Image_Name = "ic_online_service_close"

class LimitImageModel {
    
    var image: UIImage?
    var isSelect: Bool?
    
    init(image: UIImage, isSelect: Bool) {
        self.image = image
        self.isSelect = isSelect
    }
}
