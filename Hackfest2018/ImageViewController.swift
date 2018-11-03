//
//  ImageViewController.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit
import SwiftyButton
import Vision

class ImageViewController: UIViewController {

    let image: UIImage

    lazy var guidesImageView = UIImageView()
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
        imageView.image = image

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
        processImageButton.setTitle("Process", for: .normal)
        processImageButton.addTarget(self, action: #selector(handleProcessImageButtonTap), for: .touchUpInside)
        view.addSubview(processImageButton)
        processImageButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(imageView.snp.bottom).offset(40)
            make.bottom.left.right.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.height.equalTo(60)
        }
    }

    @objc func handleProcessImageButtonTap() {

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

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.imageView.image = PassportImageCropper().cropImageToFitFace(image: self.image, face: face)
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
        imageView.image = image.withFaceLandmarksDrawn(face)
    }
}
