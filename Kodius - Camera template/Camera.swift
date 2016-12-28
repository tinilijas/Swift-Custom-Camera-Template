//
//  Camera.swift
//  Kodius - Camera template
//
//  Created by Tin Ilijaš on 28/12/2016.
//  Copyright © 2016 Tin Ilijaš. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol CameraDelegate {
    func cameraSessionConfigurationDidComplete()
    func cameraSessionDidBegin()
    func cameraSessionDidStop()
}

class Camera: NSObject {
    weak var delegate: CameraDelegate?
    
    var session: AVCaptureSession!
    var sessionQueue: DispatchQueue!
    var stillImageOutput: AVCaptureStillImageOutput?
    
    init(sender: AnyObject) {
        super.init()
        self.delegate = sender as? CameraDelegate
        self.setObservers()
        self.initializeSession()
    }
    
    deinit {
        self.removeObservers()
    }
    
    // MARK: Session
    
    func initializeSession() {
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        self.sessionQueue = DispatchQueue(label: "camera session", attributes: [])
        
        self.sessionQueue.async {
            self.session.beginConfiguration()
            self.addVideoInput()
            self.addStillImageOutput()
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                NSLog("Session initialization did complete")
                self.delegate?.cameraSessionConfigurationDidComplete()
            }
        }
    }
    
    func startCamera() {
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    func stopCamera() {
        self.sessionQueue.async {
            self.session.stopRunning()
        }
    }
    
    func captureStillImage(_ completed: @escaping (_ image: UIImage?) -> Void) {
        if let imageOutput = self.stillImageOutput {
            self.sessionQueue.async(execute: { () -> Void in
                
                var videoConnection: AVCaptureConnection?
                for connection in imageOutput.connections {
                    let c = connection as! AVCaptureConnection
                    
                    for port in c.inputPorts {
                        let p = port as! AVCaptureInputPort
                        if p.mediaType == AVMediaTypeVideo {
                            videoConnection = c;
                            break
                        }
                    }
                    
                    if videoConnection != nil {
                        break
                    }
                }
                
                if videoConnection != nil {
                    imageOutput.captureStillImageAsynchronously(from: videoConnection) { imageSampleBuffer, error in
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        let image: UIImage? = UIImage(data: imageData!)!
                        
                        DispatchQueue.main.async {
                            completed(image)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completed(nil)
                    }
                }
            })
        } else {
            completed(nil)
        }
    }
    
    
    // MARK: Configuration
    
    func addVideoInput() {
        let device: AVCaptureDevice = self.deviceWithMediaTypeWithPosition(AVMediaTypeVideo as NSString, position: AVCaptureDevicePosition.back)
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
        } catch {
            print(error)
        }
    }
    
    func addStillImageOutput() {
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if self.session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
    }
    
    func deviceWithMediaTypeWithPosition(_ mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices: NSArray = AVCaptureDevice.devices(withMediaType: mediaType as String) as NSArray
        var captureDevice: AVCaptureDevice = devices.firstObject as! AVCaptureDevice
        for device in devices {
            let d = device as! AVCaptureDevice
            if d.position == position {
                captureDevice = d
                break;
            }
        }
        return captureDevice
    }
    
    // MARK: Observers
    
    func setObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(Camera.sessionDidStart(_:)), name: NSNotification.Name.AVCaptureSessionDidStartRunning, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Camera.sessionDidStop(_:)), name: NSNotification.Name.AVCaptureSessionDidStopRunning, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func sessionDidStart(_ notification: Notification) {
        DispatchQueue.main.async {
            NSLog("Session did start")
            self.delegate?.cameraSessionDidBegin()
        }
    }
    
    func sessionDidStop(_ notification: Notification) {
        DispatchQueue.main.async {
            NSLog("Session did stop")
            self.delegate?.cameraSessionDidStop()
        }
    }
    
}
