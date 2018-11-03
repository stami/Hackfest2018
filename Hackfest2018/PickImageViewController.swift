//
//  ViewController.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyButton

protocol PickImageViewControllerDelegate: class {
    func viewController(_ viewController: PickImageViewController, didPickImage image: UIImage)
}

class PickImageViewController: UIViewController {

    weak var delegate: PickImageViewControllerDelegate?

    lazy var pickImageButton = PressableButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.title = "Hackfest 2018"

        pickImageButton.setTitle("Pick Image", for: .normal)
        pickImageButton.addTarget(self, action: #selector(handlePickImageButtonTap), for: .touchUpInside)
        view.addSubview(pickImageButton)
        pickImageButton.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(60)
        }
    }

    @objc func handlePickImageButtonTap() {
        openImagePicker()
    }

    func openImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary

        if UIDevice.current.userInterfaceIdiom == .pad {
            picker.modalPresentationStyle = .popover
            picker.popoverPresentationController?.sourceView = view
            picker.popoverPresentationController?.sourceRect = pickImageButton.frame
        }
        present(picker, animated: true, completion: nil)
    }
}

extension PickImageViewController: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            else { return print("ImagePicker did finish without image") }

        delegate?.viewController(self, didPickImage: image)
    }
}

extension PickImageViewController: UINavigationControllerDelegate {

}
