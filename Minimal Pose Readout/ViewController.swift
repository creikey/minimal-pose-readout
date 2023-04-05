//
//  ViewController.swift
//  Minimal Pose Readout
//
//  Created by Omkar Bhope on 4/3/23.
//

import UIKit
import AVFoundation
import MLKitVision
import MLKitPoseDetectionAccurate


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    @IBOutlet var previewView: PreviewView!
    var poseDetector: PoseDetector!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    // this function is copy and pasted from https://developers.google.com/ml-kit/vision/pose-detection/ios
    func imageOrientation(
      deviceOrientation: UIDeviceOrientation,
      cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
      switch deviceOrientation {
      case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
      case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
      case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
      case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
      case .faceDown, .faceUp, .unknown:
        return .up
      default: // this clause added to appease warning, could be bad or something
          return .up
      }
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation(
          deviceOrientation: UIDevice.current.orientation,
          cameraPosition: AVCaptureDevice.Position.front)
        
        var results: [Pose]
        do {
            results = try self.poseDetector.results(in: image)
        } catch let error {
          print("Failed to detect pose with error: \(error.localizedDescription).")
          return
        }
        
        /*guard let detectedPoses = results, !detectedPoses.isEmpty else {
          print("Pose detector returned no results.")
          return
        }*/
        let detectedPoses = results
        guard !detectedPoses.isEmpty else {
            print("Pose detector returned no results")
            return
        }

        for pose in detectedPoses {
          let leftAnkleLandmark = pose.landmark(ofType: .leftAnkle)
          if leftAnkleLandmark.inFrameLikelihood > 0.5 {
            let position = leftAnkleLandmark.position
              print("left ankle position: ", position)
          }
            let leftEye = pose.landmark(ofType: .leftEye)
            if leftEye.inFrameLikelihood > 0.5 {
                print("left eye position: ", leftEye.position)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
            for: .video, position: .front)
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
            else { return }
        captureSession.addInput(videoDeviceInput)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(output)
        self.previewView.videoPreviewLayer.session = self.captureSession

        captureSession.startRunning()
        
        let options = AccuratePoseDetectorOptions()
        options.detectorMode = .stream
        self.poseDetector = PoseDetector.poseDetector(options: options)
    }
}

