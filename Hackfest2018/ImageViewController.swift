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

        guidesImageView.layer.borderColor = UIColor.lightGray.cgColor
        guidesImageView.layer.borderWidth = 1.0

        // Taken image
        view.insertSubview(imageView, belowSubview: guidesImageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(guidesImageView)
        }
        imageView.contentMode = .scaleAspectFit
        imageView.image = image

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
                self.cropImageToFitFace(face)
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

    func cropImageToFitFace(_ face: VNFaceObservation) {

        guard let faceRect = rectForPassport(imageSize: image.size, face: face)
            else { return showAlert(title: "No face rect", message: nil) }

        let croppedImage = image.cgImage!.cropping(to: faceRect)!

        let croppedUIImage = UIImage(cgImage: croppedImage)

        imageView.image = croppedUIImage
    }

    func rectForPassport(imageSize: CGSize, face: VNFaceObservation) -> CGRect? {

        // Face contour
        guard let faceContour = face.landmarks?.faceContour,
            !faceContour.normalizedPoints.isEmpty
            else { return nil }

        let bottomOfJawY = imageSize.height - faceContour
            .pointsInImage(imageSize: imageSize)
            .map { $0.y }
            .min()!

        // Eyes
        guard let leftEye = face.landmarks?.leftEye,
            let rightEye = face.landmarks?.rightEye
            else { return nil }

        let avgEyesY = imageSize.height - [leftEye, rightEye]
            .map { $0.pointsInImage(imageSize: imageSize) }
            .flatMap { $0 }
            .map { $0.y }
            .average()

        // Median line
        guard let medianLine = face.landmarks?.medianLine
            else { return nil }

        let avgMedianLineX = medianLine
            .pointsInImage(imageSize: imageSize)
            .map { $0.x }
            .average()

        // Eyeline is somewhat middle of the head
        let topOfForeheadY = avgEyesY - (bottomOfJawY - avgEyesY)

        let rectWithoutInsets = rect(middleY: avgMedianLineX, topY: topOfForeheadY, bottomY: bottomOfJawY)

        let heightWithInsets = Constants.photo.totalHeightRatio * rectWithoutInsets.height
        let topInset = Constants.photo.topInset / Constants.photo.height * heightWithInsets
        let bottomInset = Constants.photo.bottomInset / Constants.photo.height * heightWithInsets
        
        let rectWithInsets = rect(middleY: avgMedianLineX,
                                  topY: topOfForeheadY - topInset,
                                  bottomY: bottomOfJawY + bottomInset)

        return rectWithInsets
    }

    func rect(middleY: CGFloat, topY: CGFloat, bottomY: CGFloat) -> CGRect {

        let height = bottomY - topY
        let width = height * Constants.photo.widthRatio
        let x = middleY - (width / 2)
        let y = topY

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
