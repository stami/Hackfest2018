//
//  PassportImageCropper.swift
//  Hackfest2018
//
//  Created by Samuli Tamminen on 3.11.2018.
//  Copyright © 2018 Samuli Tamminen. All rights reserved.
//

import UIKit
import Vision

struct PassportImageCropper {

    func cropImageToFitFace(image: UIImage, face: VNFaceObservation) -> UIImage? {

        guard let rect = rectForPassport(imageSize: image.size, face: face)
            else { return nil }

        let croppedImage = image.cgImage!.cropping(to: rect)!
        return UIImage(cgImage: croppedImage) //, scale: image.scale, orientation: image.imageOrientation)
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

    private func rect(middleY: CGFloat, topY: CGFloat, bottomY: CGFloat) -> CGRect {

        let height = bottomY - topY
        let width = height * Constants.photo.widthRatio
        let x = middleY - (width / 2)
        let y = topY

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
