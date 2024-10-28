//
//  ViewController.swift
//  CameraControl
//
//  Created by Fihade Liang on 2024/10/28.
//

import Foundation
import UIKit
import AVFoundation
import AVKit


class CameraViewController: UIViewController {
    // Camera preview layer
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let interactionQueue = DispatchQueue(label: "interactionQueue")
    private var currentFontSize: CGFloat = 24
    
    var textLabel: UILabel = {
        let lable = UILabel()
        lable.text = "Camera Control Text"
        lable.textColor = .lightGray
        lable.textAlignment = .center
        return lable
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        startCapture()
        handleInteractionsAndControls(on: view)
        
        textLabel.font = UIFont.systemFont(ofSize: currentFontSize)
        textLabel.frame = view.bounds
        view.addSubview(textLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textLabel.frame = view.bounds
    }
    
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .denied:
            alertCameraAccessNeeded()
        default:
            break
        }
    }
    
    private func setupCamera() {
        // Configure capture session
        captureSession.sessionPreset = .photo
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        guard captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)
        
        // Add photo output
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.addOutput(photoOutput)
        
//        // Setup preview layer
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = view.layer.bounds
//        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Start capture session
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    private func alertCameraAccessNeeded() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this feature",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "Settings",
            style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
    
}

// MARK: Camera Control Configuration
extension CameraViewController {
    func handleInteractionsAndControls(on view: UIView) {
        guard #available(iOS 18.0, *) else { return }
        guard let _ = self.getDeviceFromSession(captureSession) else { return }
        self.clearInteractionsAndControls(on: view)

        let interaction = AVCaptureEventInteraction { event in
            debugPrint("[AVCaptureEventInteraction] Event Phase: \(event.phase)")
        }
        view.addInteraction(interaction)

        // Custom Slider about Font Size
        let customSlider = AVCaptureSlider("Font size", symbolName:"textformat.size", in: 0.1...5)
        customSlider.value = 1.0
        customSlider.setActionQueue(self.interactionQueue) { val in
            DispatchQueue.main.async {[weak self] in
                self?.textLabel.font = UIFont.systemFont(ofSize: 24*CGFloat(val))
                self?.currentFontSize = CGFloat(24*val)
            }
        }
        
        // Custom Picker about fonts
        let fonts = [UIFont.systemFont(ofSize: currentFontSize), UIFont.boldSystemFont(ofSize: currentFontSize), UIFont.italicSystemFont(ofSize: currentFontSize)]
        let customPicker = AVCaptureIndexPicker("Fonts", symbolName: "camera.filters", localizedIndexTitles: ["Regualr", "Bold", "Italic"])
        customPicker.setActionQueue(self.interactionQueue) { index in
            debugPrint("[AVCaptureIndexPicker] Index: \(index)")
            DispatchQueue.main.async {[weak self] in
                self?.textLabel.font = fonts[index].withSize(self?.currentFontSize ?? 24)
            }
            
        }

        let controls = [customSlider, customPicker]
        for control in controls {
            if self.captureSession.canAddControl(control) {
                self.captureSession.addControl(control)
            }
        }
        // Commit
        self.captureSession.commitConfiguration()
    }
    
    private func clearInteractionsAndControls(on view: UIView) {
        guard #available(iOS 18.0, *) else { return }
        view.interactions.forEach({ view.removeInteraction($0) })
        self.captureSession.controls.forEach({ self.captureSession.removeControl($0) })
    }
    
    func getDeviceFromSession(_ session: AVCaptureSession) -> AVCaptureDevice? {
        // Get video input ports from session
        let inputs = session.inputs.compactMap { $0 as? AVCaptureDeviceInput }
        
        // Get first video device
        return inputs.first?.device
    }
    
    // Setup Camera Control
    func startCapture() {
        // 处理其他开始录制的逻辑...
        if #available(iOS 18.0, *) {
            captureSession.setControlsDelegate(self, queue: interactionQueue)
        }
    }
}

// MARK: AVCaptureSessionControlsDelegate
extension CameraViewController: AVCaptureSessionControlsDelegate {
    func sessionControlsDidBecomeActive(_ session: AVCaptureSession) {
        debugPrint("[AVCaptureSessionControlsDelegate] sessionControlsDidBecomeActive")
    }
    
    func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) {
        debugPrint("[AVCaptureSessionControlsDelegate] sessionControlsWillEnterFullscreenAppearance")
    }
    
    func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) {
        debugPrint("[AVCaptureSessionControlsDelegate] sessionControlsWillExitFullscreenAppearance")
    }
    
    func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) {
        debugPrint("[AVCaptureSessionControlsDelegate] sessionControlsDidBecomeInactive")
    }
}
