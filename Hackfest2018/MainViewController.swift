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

        // Shadow under the image
        let shadowContainer = UIView()
        shadowContainer.backgroundColor = .white
        view.addSubview(shadowContainer)
        shadowContainer.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(shadowContainer.snp.width).dividedBy(Constants.photo.widthRatio)
        }
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowRadius = 15
        shadowContainer.layer.shadowOpacity = 0.5
        shadowContainer.layer.shadowOffset = .zero
        shadowContainer.backgroundColor = .white

        let instructionsStack = UIStackView()
        instructionsStack.axis = .vertical
        instructionsStack.spacing = 20

        [
            "Step 1. Select a image from the camera icon",
            "Step 2. The image is scaled and cropped automagically to match official mug shot specs",
            "Step 3. ?",
            "Step 4. Profit",
            ].map(createInstructionsLabel)
            .forEach(instructionsStack.addArrangedSubview)

        shadowContainer.addSubview(instructionsStack)
        instructionsStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        let imageContainer = UIView()
        imageContainer.clipsToBounds = true
        view.addSubview(imageContainer)
        imageContainer.snp.makeConstraints { make in
            make.edges.equalTo(shadowContainer)
        }

        // Taken image
        imageContainer.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill

        // Guide lines
        view.addSubview(guidesImageView)
        guidesImageView.snp.makeConstraints { make in
            make.edges.equalTo(shadowContainer)
        }
        guidesImageView.contentMode = .scaleAspectFit
        guidesImageView.image = UIImage(named: "guides")
        guidesImageView.isHidden = true

        // Show Guides
        let showGuidesSwitch = UISwitch()
        showGuidesSwitch.addTarget(self, action: #selector(showGuides), for: .valueChanged)
        let showGuidesLabel = UILabel()
        showGuidesLabel.text = "Show guides"
        view.addSubview(showGuidesSwitch)
        view.addSubview(showGuidesLabel)
        showGuidesSwitch.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(shadowContainer.snp.bottom).offset(40)
            make.left.equalTo(view.safeAreaLayoutGuide).inset(40)
        }
        showGuidesLabel.snp.makeConstraints { make in
            make.centerY.equalTo(showGuidesSwitch)
            make.left.equalTo(showGuidesSwitch.snp.right).offset(20)
            make.right.equalTo(view.safeAreaLayoutGuide).inset(40)
        }

        // Process Button
        button.setTitle("Share", for: .normal)
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(showGuidesSwitch.snp.bottom).offset(40)
            make.bottom.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(60)
        }

        setButtonEnabled(false)
    }

    func createInstructionsLabel(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.text = text
        return label
    }

    func setButtonEnabled(_ isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.5
    }

    @objc func showGuides(sender: UISwitch) {
        guidesImageView.isHidden = !sender.isOn
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

            self.drawFaceLandmarksOnImage(face)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

                guard let rect = PassportImageCropper().rectForPassport(imageSize: image.size, face: face)
                    else { return }

                let scale = image.size.height / rect.height
                let moveX = (image.size.width / 2 - rect.midX) * (self.imageView.frame.width / image.size.width)
                let moveY = (image.size.height / 2 - rect.midY) * (self.imageView.frame.height / image.size.height)

                let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
                let moveTransform = CGAffineTransform(translationX: moveX, y: moveY)
                let transform = moveTransform.concatenating(scaleTransform)

                UIView.animate(withDuration: 0.5, animations: {
                    self.imageView.transform = transform
                }, completion: { _ in
                    self.imageView.transform = CGAffineTransform.identity

                    let croppedImage = image.cgImage!.cropping(to: rect)!
                    self.imageView.image = UIImage(cgImage: croppedImage)
                })

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
