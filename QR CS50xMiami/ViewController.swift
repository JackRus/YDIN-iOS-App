//
//  ViewController.swift
//  YDIN - Attendance Management System for CS50xMiami
//
//  Final Project.
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
    
  
    /* Button to switch the cameras */

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
        
        // Checks if camera is available
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
        
        // brings Button and to the front
        view.bringSubview(toFront: switcherView)
        
        // begin capture session
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
     / Switches the cameras beetwen front and back
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
        var stringQR  = code!.components(separatedBy: ",")
        
        // takes current date and time
        let date = Date()
        let formatterDate = DateFormatter()
        let formatterTime = DateFormatter()
        formatterDate.dateFormat = "yyyy-MM-dd" // case-sensetive
        formatterTime.dateFormat = "HH:mm:ss"
        let resultDate = formatterDate.string(from: date)
        let resultTime = formatterTime.string(from: date)
        
        
        // TIME CONTROL
        var maxTime = ""
        var minTime = ""
        
        if (stringQR.count == 7)
        {
            if stringQR[6] == "lecture"
            {
                maxTime = "21:00:00"
                minTime = "17:00:00"
            }
            else if stringQR[6] == "section12_14"
            {
                maxTime = "14:30:00"
                minTime = "11:00:00"
            }
            else if stringQR[6] == "section9_11"
            {
                maxTime = "11:30:00"
                minTime = "08:30:00"
            }
            else if stringQR[6] == "coding"
            {
                maxTime = "17:00:00"
                minTime = "11:00:00"
            }
            else if stringQR[6] == "track"
            {
                maxTime = "22:00:00"
                minTime = "17:00:00"
            }
            else if stringQR[6] == "special"
            {
                maxTime = "23:59:59"
                minTime = "00:00:00"
            }
        }
        
        // Checking if QR String is CS50 string and has current date and time
        if (stringQR.count == 7)
            && (stringQR[0] == "CS5OxMiami")
            && (resultDate == stringQR[2])
            && (resultTime > stringQR[3])
            && (resultTime > minTime)
            && (resultTime < maxTime)
            && (stringQR[3] > minTime)
            && (stringQR[3] < maxTime)

        {
            // Visual "GREEN" confirmation that QR is scanned and is OK
            animatePop(message: "SUCCESSFULLY SCANNED!", color: UIColor.green)
            AudioServicesPlaySystemSound(SystemSoundID(1025))

            //put the link of the php file here. The php file connects the mysql and swift
            let request = NSMutableURLRequest(url: NSURL(string: "https://jackrus.net/dbserv.php")! as URL)
            
            // HTTP METHOD
            request.httpMethod = "POST"
            
            // QUERY
            let postString =
                // [0] - CS5OxMiami, [1] - ID, [2] - date, [3] - time, [4] - name, [5] - lastname, [7] - event_type
                "a=\(stringQR[1])&b=\(stringQR[2])&c=\(stringQR[3])&d=\(stringQR[4])&e=\(stringQR[5])&f=\(stringQR[6])"
            
            // URL + QUERY
            request.httpBody = postString.data(using: String.Encoding.utf8)
            let task = URLSession.shared.dataTask(with: request as URLRequest)
            {
                data, response, error in
                if error != nil
                {
                    print("error=\(String(describing: error))")
                    return
                }
            
                // PHP response control, prints to console
                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("===> PHP Response = \(String(describing: responseString))")
        
            }
            task.resume()
        }
        
        // if Date isn't correct --> dark orange message and sound
        else if (stringQR.count == 7)
            && (stringQR[0] == "CS5OxMiami")
            && ((resultDate != stringQR[2])
                 || (resultTime < stringQR[3])
                 || (resultTime < minTime)
                 || (resultTime > maxTime)
                 || (stringQR[3] < minTime)
                 || (stringQR[3] > maxTime))
        {
            animatePop(message: "Please, RESET your QR Code.", color: UIColor.init(red: 236/255.0, green: 161/255.0, blue: 10/255.0, alpha: 1.0))
            AudioServicesPlaySystemSound(SystemSoundID(1034))
        }
        
        // If QR Code isn't CS50 QR Code --> red message
        else
        {
            animatePop(message: "Wrong QR Code!", color: UIColor.red)
            AudioServicesPlaySystemSound(SystemSoundID(1034))
        }
        
        //creates delay between scans
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)
        {
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
        UIView.animate(withDuration: 3.0, animations: {
            self.addItemView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.addItemView.alpha = 0
            
        }) {(success:Bool) in
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
