//
//  CameraViewModel.swift
//  RealtimeASL
//
//  Created by Emile Billeh on 22/02/2025.
//

import AVFoundation
import Vision
import CoreML
import SwiftUI

class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private var model: ASLmodel2?
    private var isTranslating = false
    private var updatePrediction: ((String, Float) -> Void)?
    private var predictionText: String?
    private var predictionConfidence: Float?
    private var predictionBuffer: [(String, Float)] = []
    private let maxBufferSize = 10  // Number of frames to smooth over

    override init() {
        super.init()
        configureCamera()
        loadModel()
    }

    private func configureCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: No camera available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(output) {
                session.addOutput(output)
            }

        } catch {
            print("Error setting up camera: \(error)")
        }

        session.commitConfiguration()
    }

    private func loadModel() {
        do {
            model = try ASLmodel2(configuration: MLModelConfiguration())
        } catch {
            print("❌ Failed to load ASL model: \(error)")
        }
    }

    func startSession() {
        DispatchQueue.global(qos: .background).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .background).async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func toggleTranslation(isTranslating: Bool, updatePrediction: @escaping (String, Float) -> Void) {
        self.isTranslating = isTranslating
        self.updatePrediction = updatePrediction

        if !isTranslating {
            updatePrediction("–", 0.0)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isTranslating, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = model else { return }

        // Convert pixel buffer to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Convert CIImage to UIImage and resize it to 299x299
        let uiImage = UIImage(ciImage: ciImage)
        let resizedImage = uiImage.resized(to: CGSize(width: 299, height: 299))

        // Convert back to CVPixelBuffer (ML model requires this format)
        guard let formattedPixelBuffer = resizedImage.toPixelBuffer() else {
            print("❌ Failed to convert image to CVPixelBuffer")
            return
        }

        // Create a CoreML request
        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: model.model)) { request, _ in
            if let results = request.results as? [VNClassificationObservation], let bestResult = results.first {
                DispatchQueue.main.async {
                    self.updatePrediction(bestResult.identifier, bestResult.confidence)
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: formattedPixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("❌ ML Processing Error: \(error)")
        }
    }
    
    func updatePrediction(_ newPrediction: String, _ newConfidence: Float) {
        DispatchQueue.main.async {
            self.predictionBuffer.append((newPrediction, newConfidence))

            if self.predictionBuffer.count > self.maxBufferSize {
                self.predictionBuffer.removeFirst()
            }

            let smoothedPrediction = self.getSmoothedPrediction()
            
            // ✅ Ensure this updates the UI in ASLToEnglishView
            self.updatePrediction?(smoothedPrediction.0, smoothedPrediction.1)
        }
    }


    private func getSmoothedPrediction() -> (String, Float) {
        let grouped = Dictionary(grouping: predictionBuffer, by: { $0.0 })
            .mapValues { predictions in
                let confidenceSum = predictions.map { $0.1 }.reduce(0, +)
                return confidenceSum / Float(predictions.count)
            }

        // Return the most frequent prediction with highest average confidence
        return grouped.max(by: { $0.value < $1.value }) ?? ("–", 0.0)
    }

}

import UIKit

extension UIImage {
    // Resize image to the required size (299x299)
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }

    // Convert UIImage to CVPixelBuffer (needed for CoreML)
    func toPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )

        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}
