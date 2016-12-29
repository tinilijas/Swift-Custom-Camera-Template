//
//  CameraViewController.swift
//  Kodius - Camera template
//
//  Created by Tin Ilijaš on 28/12/2016.
//  Copyright © 2016 Tin Ilijaš. All rights reserved.
//

import UIKit
import AVFoundation

enum Status: Int {
    case preview, still, error
}

class CameraViewController: UIViewController, CameraDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureSendButton: UIButton!
    @IBOutlet weak var cameraStatusLabel: UILabel!
    @IBOutlet weak var capturePhotoView: UIImageView!
    @IBOutlet weak var resetButton: UIButton!
    
    var preview: AVCaptureVideoPreviewLayer?
    
    var camera: Camera?
    var status: Status = .preview
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.establishVideoPreviewArea()
    }
    
    func initializeCamera() {
        self.cameraStatusLabel.text = "Starting Camera"
        self.camera = Camera(sender: self)
    }
    
    func establishVideoPreviewArea() {
        self.preview = AVCaptureVideoPreviewLayer(session: self.camera?.session)
        self.preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.preview?.frame = self.cameraView.bounds
        self.preview?.cornerRadius = 8.0
        self.cameraView.layer.addSublayer(self.preview!)
    }
    
    @IBAction func captureFrame(_ sender: Any) {
        if self.status == .preview {
            self.cameraStatusLabel.text = "Capturing Photo"
            UIView.animate(withDuration: 0.225, animations: { () -> Void in
                self.cameraView.alpha = 0.0;
                self.cameraStatusLabel.alpha = 1.0
            })
            
            self.camera?.captureStillImage({ (image) -> Void in
                if image != nil {
                    self.capturePhotoView.image = image;
                    
                    UIView.animate(withDuration: 0.225, animations: { () -> Void in
                        self.capturePhotoView.alpha = 1.0;
                        self.cameraStatusLabel.alpha = 0.0;
                    })
                    self.status = .still
                } else {
                    self.cameraStatusLabel.text = "Uh oh! Something went wrong. Try it again."
                    self.status = .error
                }
                
                self.captureSendButton.setTitle("Send", for: UIControlState())
            })
        } else if self.status == .still || self.status == .error {
            if self.capturePhotoView.image != nil {
                loadingScreenForLogin()
              
                // Here we implement send method :)
                
                self.dismiss(animated: true, completion: nil) //  end of loading screen
                activateCamera()
            }
        }
    }
    
    @IBAction func resetFrame(_ sender: Any) {
        if self.status == .still || self.status == .error {
            activateCamera()
        }
    }
    
    func activateCamera() {
        UIView.animate(withDuration: 0.225, animations: { () -> Void in
            self.capturePhotoView.alpha = 0.0;
            self.cameraStatusLabel.alpha = 0.0;
            self.cameraView.alpha = 1.0;
            self.captureSendButton.setTitle("Capture", for: UIControlState())
        }, completion: { (done) -> Void in
            self.capturePhotoView.image = nil;
            self.status = .preview
        })
    }
    
    // MARK: Camera Delegate
    
    func cameraSessionConfigurationDidComplete() {
        self.camera?.startCamera()
    }
    
    func cameraSessionDidBegin() {
        self.cameraStatusLabel.text = "Reseting camera"
        UIView.animate(withDuration: 0.225, animations: { () -> Void in
            self.cameraStatusLabel.alpha = 0.0
            self.cameraView.alpha = 1.0
            self.capturePhotoView.alpha = 1.0
        })
    }
    
    func cameraSessionDidStop() {
        self.cameraStatusLabel.text = "Camera Stopped"
        UIView.animate(withDuration: 0.225, animations: { () -> Void in
            self.cameraStatusLabel.alpha = 1.0
            self.cameraView.alpha = 0.0
        })
    }
    
    func loadingScreenForLogin() {
        let loading = UIAlertController(title: nil, message: "Sending...", preferredStyle: .alert)
        
        loading.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 5,y: 5,width: 50,height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        loading.view.addSubview(loadingIndicator)
        present(loading, animated: true, completion: nil)
    }
}
