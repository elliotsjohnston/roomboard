//
//  MaterialView.swift
//  Roomboard
//
//  Created by Elliot Johnston on 12/13/22.
//

import UIKit

class MaterialView: UIView {
    
    var effect: UIVisualEffect? {
        didSet {
            materialView.effect = effect
        }
    }
    
    private lazy var materialView: UIVisualEffectView = {
        let materialView = UIVisualEffectView()
        materialView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return materialView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedMaterialViewInitialization()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedMaterialViewInitialization()
    }
    
    private func sharedMaterialViewInitialization() {
        addSubview(materialView)
        materialView.frame = bounds
    }

}
