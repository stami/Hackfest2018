//
//  ImageViewController.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit
import SwiftyButton

class ImageViewController: UIViewController {

    let image: UIImage

    lazy var imageView = UIImageView()
    lazy var processImageButton = PressableButton()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
        }
        imageView.contentMode = .scaleAspectFit
        imageView.image = image

        processImageButton.setTitle("Process", for: .normal)
        processImageButton.addTarget(self, action: #selector(handleProcessImageButtonTap), for: .touchUpInside)
        view.addSubview(processImageButton)
        processImageButton.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.bottom.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(60)
        }
    }

    @objc func handleProcessImageButtonTap() {

    }
}
