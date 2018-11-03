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
import Vision

class MainViewController: UIViewController {

    var selectedImage: UIImage? {
        didSet {
            imageView.image = selectedImage
        }
    }

    lazy var guidesImageView = UIImageView()
    lazy var imageView = UIImageView()
    lazy var button = PressableButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationItem.title = "Hackfest 2018"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(handlePickImageButtonTap))

        // Guide lines
        view.addSubview(guidesImageView)
        guidesImageView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(guidesImageView.snp.width).dividedBy(Constants.photo.widthRatio)
        }
        guidesImageView.contentMode = .scaleAspectFit
        guidesImageView.image = UIImage(named: "guides")

        // Taken image
        view.insertSubview(imageView, belowSubview: guidesImageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(guidesImageView)
        }
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white

        // Shadow under the image
        let shadowContainer = UIView()
        shadowContainer.backgroundColor = .white
        view.insertSubview(shadowContainer, belowSubview: imageView)
        shadowContainer.snp.makeConstraints { make in
            make.edges.equalTo(guidesImageView)
        }
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowRadius = 15
        shadowContainer.layer.shadowOpacity = 0.5
        shadowContainer.layer.shadowOffset = .zero

        // Process Button
        button.setTitle("Share", for: .normal)
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(imageView.snp.bottom).offset(40)
            make.bottom.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(60)
        }

        setButtonEnabled(false)
    }

    func setButtonEnabled(_ isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
    }

    @objc func handleButtonTap() {
        guard let image = imageView.image
            else { return print("no image to share") }

        let targetSize = CGSize(width: Constants.photo.width, height: Constants.photo.height)
        let resizedImage = image.resize(targetSize: targetSize)

        let activityViewController = UIActivityViewController(activityItems: [resizedImage], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - Process Image

    func processImage() {

        guard let image = selectedImage
            else { return print("No image selected") }

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest() { (request: VNRequest, error: Error?) in

            if let error = error {
                print("Failed to get face landmarks: \(error.localizedDescription)")
                return
            }

            guard let results = request.results,
                !results.isEmpty else {
                    self.showAlert(title: "No faces detected", message: "Select an image that has a face in it.")
                    return
            }

            let faces = results.compactMap { $0 as? VNFaceObservation }

            guard faces.count == 1 else {
                self.showAlert(title: "Multiple faces detected", message: "Select an image that has a single face in it.")
                return
            }

            let face = faces.first!

            // drawFaceLandmarksOnImage(face)

            DispatchQueue.main.async {
                self.imageView.image = PassportImageCropper().cropImageToFitFace(image: image, face: face)
                self.setButtonEnabled(true)
            }
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: orientation, options: [:])

        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print("Failed to perform request: \(error.localizedDescription)")
        }
    }

    func drawFaceLandmarksOnImage(_ face: VNFaceObservation) {
        let image = selectedImage?.withFaceLandmarksDrawn(face)
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    // MARK: - Image Picker

    @objc func handlePickImageButtonTap() {
        openImagePicker()
    }

    func openImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    func useImage(_ image: UIImage) {
        selectedImage = image
        DispatchQueue.global(qos: .userInitiated).async {
            self.processImage()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
            else { return print("ImagePicker did finish without image") }

        if image.imageOrientation == .up {
            useImage(image)
        } else {
            if let imageInUpOrientation = image.fixedOrientation() {
                useImage(imageInUpOrientation)
            } else {
                showAlert(title: "Couldn't convert the image orientation", message: nil)
            }
        }
    }
}

extension MainViewController: UINavigationControllerDelegate { }
