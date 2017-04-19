//
//  ViewController.swift
//  YDIN - Attendance Management System
//
//  Created by Evgeny Nagimov on 4/11/17.
//  Copyright © 2017 JackRus. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // Pop Up view
    @IBOutlet var addItemView: UIView!
    @IBOutlet weak var popLabel: UILabel!
    
    /*
    //////////////////////////////
    / Button to switch the cameras
    //////////////////////////////
    */

    // action button
    @IBAction func switcher(_ sender: Any) {
        self.switchCameraInput()
    }
    // view button
    @IBOutlet weak var switcherView: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
       
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        } else {
            failed()
            return
        }
        
        // video streaming on the screen
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
        previewLayer.frame = view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        view.layer.addSublayer(previewLayer);
        
        // Brings Button and to the front
        view.bringSubview(toFront: switcherView)
        
        // Begin capturing
        captureSession.startRunning();
        
    }
    
    /*
    ////////////////////////////////////////////////////
    / Changes the position (type, not the actual camera) 
    / of the camera to the opposite
    ////////////////////////////////////////////////////
    */

    func cameraWithPosition (position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let discovery = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified) as AVCaptureDeviceDiscoverySession
        
        for device in discovery.devices as [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    /*
     //////////////////////////////////////////////
     / Switches the cameras beetwen frint and back
     //////////////////////////////////////////////
     */
    
    func switchCameraInput() {
        self.captureSession.beginConfiguration()
        var existingConnection: AVCaptureDeviceInput!
        
        for connection in self.captureSession.inputs {
            let input = connection as! AVCaptureDeviceInput
            if input.device.hasMediaType(AVMediaTypeVideo){
                existingConnection = input
            }
        }
        
        self.captureSession.removeInput(existingConnection)
        var newCamera: AVCaptureDevice!
        
        if let oldCamera = existingConnection {
            if oldCamera.device.position == .back {
                newCamera = self.cameraWithPosition(position: .front)
            } else {
                newCamera = self.cameraWithPosition(position: .back)
            }
        }
        
        var newInput:AVCaptureDeviceInput!
        do {
            newInput = try AVCaptureDeviceInput(device: newCamera)
            self.captureSession.addInput(newInput)
        } catch {
            print(error)
        }
        
        self.captureSession.commitConfiguration()
    }
    
    
    /*
    //////////////////////
    / Handles camera fails
    //////////////////////
    */
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    /*
    ///////////////////////////////////////////////////////////
    / Captures Output from QR code and makes it readable String
    ///////////////////////////////////////////////////////////
    */
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject
            
            // Stop Session When QR found
            self.captureSession?.stopRunning()
            // Server side process
            found(code: readableObject.stringValue)
        }
        dismiss(animated: true)
    }
  
    /*
    //////////////////////////////////////////////////////////////
    / Connects to a php script on the server through htttps (POST)
    //////////////////////////////////////////////////////////////
    */
    
    func found (code:String?){
        
        // Parse the string
        let stringQR  = code!.components(separatedBy: ",")
        
        // Checking if QR String is CS50 string
        if (stringQR.count == 5) && (stringQR[0] == "Evgeny")
        {
        
            // Visual confirmation that QR is scanned and is OK
            animatePop(message: "SUCCESSFULLY SCANNED!", color: UIColor.green)
            AudioServicesPlaySystemSound(SystemSoundID(1025))

            //put the link of the php file here. The php file connects the mysql and swift
            let request = NSMutableURLRequest(url: NSURL(string: "https://jackrus.net/dbserv.php")! as URL)
            request.httpMethod = "POST"
            let postString = "a=\(stringQR[0])&b=\(stringQR[1])&c=\(stringQR[2])&d=\(stringQR[3])&e=\(stringQR[4])"
            
            request.httpBody = postString.data(using: String.Encoding.utf8)
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
            
                if error != nil {
                    print("error=\(String(describing: error))")
                    return
                }
            
                // PHP response control
                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("===> PHP Response = \(String(describing: responseString))")
        
            }
            task.resume()
        }
        // If QR Code doesn't match CS50 Format
        else
        {
            animatePop(message: "Wrong QR Code!", color: UIColor.red)
            AudioServicesPlaySystemSound(SystemSoundID(1034))
        }
        
        //creates delay between scans
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.captureSession?.startRunning()
        }
    }
    
    /*
    ///////////////
    / Pop Animation
    ///////////////
    */

    func animatePop(message: String?, color: UIColor) {
        
        // Setting certain color and message
        popLabel.text = message
        popLabel.backgroundColor = color
        
        self.view.addSubview(addItemView)
        
        addItemView.center = self.view.center
        addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        addItemView.alpha = 0
        
        // Animation In
        UIView.animate(withDuration: 1.5) {
            self.addItemView.alpha = 1
            self.addItemView.transform = CGAffineTransform.identity
        }
        
        // Animation OUT
        UIView.animate(withDuration: 2.0, animations: {
            self.addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.addItemView.alpha = 0
            
        }) { (success:Bool) in
            self.addItemView.removeFromSuperview()
        }
    }
    
    /*
    /////////////////////////////////////
    / Defines the orientation as PORTRAIT
    /////////////////////////////////////
    */
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}
