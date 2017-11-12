//
//  ViewController.swift
//  RecyclAR
//
//  Created by Soon Sung Hong on 11/10/17.
//  Copyright © 2017 Soon Sung Hong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVKit
import Vision

extension UILabel
{
    func addImage(imageName: String, afterLabel bolAfterLabel: Bool = false)
    {
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
        
        if (bolAfterLabel)
        {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
            strLabelText.append(attachmentString)
            
            self.attributedText = strLabelText
        }
        else
        {
//            let strLabelText: NSAttributedString = NSAttributedString(string: self.text!)
            let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
//            mutableAttachmentString.append(strLabelText)
            
            self.attributedText = mutableAttachmentString
        }
    }
    
    func removeImage()
    {
        let text = self.text
        self.attributedText = nil
        self.text = text
    }
}

extension UIImage{
    class func imageWithView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    var recycleable: Array<String> = ["cards","books","shredded paper","ink cartidges","box","paper","cardboard","bulb","plastic bottle","bottle","textile","bag","can","metal can","juice box","cups","cup"]
    
    var erecycleable:Array<String> = ["electronic device","mobile phone","phone","laptop","batteries","power cords","television","monitor","display","cord","cd","dvd","technology","notebook","display device","computer keyboard"]
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var status: UILabel!
    var recycleablecounter:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
//
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
        
        let delayInSeconds = 7.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds){
            self.status.text = "ready"
            self.status.textColor = UIColor.green
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //Plane Detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.status.text = "scanning"
        self.status.textColor = UIColor.darkGray
        
        guard let touch = touches.first else{return}
        let result = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint]) //you want to add an anchor here
        guard let hitResult = result.last else {return}
        let hitTransform = SCNMatrix4(hitResult.worldTransform) //transforms into SCN matrix
        let hitVector = SCNVector3Make(hitTransform.m41,hitTransform.m42,hitTransform.m43)
        createLabel(position: hitVector)
    }
    
    @IBAction func reset(_ sender: UIButton) {
        print("Reset Button")
        sceneView.scene.rootNode.enumerateChildNodes{(node,stop) -> Void in
            node.removeFromParentNode()
        }
    }
    
    @IBAction func recycle(_ sender: UIButton) {
        print("Recycle Button")
        sceneView.scene.rootNode.enumerateChildNodes{(node,stop) -> Void in
            node.removeFromParentNode()
        }
        if (recycleablecounter > 1){
            status.text = "recycled \(recycleablecounter) items"
        } else {
            status.text = "recycled \(recycleablecounter) item"
        }
        
        status.textColor = UIColor.blue
        status.font = status.font.withSize(20)
        let delayInSeconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds){
            self.status.text = "ready"
            self.status.textColor = UIColor.green
        }
        //push the counter up to AWS
        let awshelper = AWSDBHelper()
        awshelper.configuration()
        awshelper.updateScoreBoard(Phone_Number: "hello", score: recycleablecounter)
        
        //intiate the counter
        recycleablecounter = 0
    }
    
    func converCItoUIImage(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage,from: cmage.extent)!
        return UIImage(cgImage: cgImage)
    }
    
  
    func createLabel(position: SCNVector3){
        var image = sceneView.snapshot()
        let googleHelper = GoogleAPIHelper()
        var base64 = googleHelper.base64EncodeImage(image)
        googleHelper.createRequest(with: base64)
    
        let delayInSeconds = 3.0
        var counter:Int = 0
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds){
            for object in googleHelper.result{
                if (self.recycleable.contains(object)){
                    self.isRecycleable(object, position: position)
                    //keeps track of how many objects are recycled
                    self.recycleablecounter = self.recycleablecounter + 1
                    break;
                }
                counter = counter + 1
                if (self.erecycleable.contains(object)){
                    self.isERecycleable(object, position: position)
                    self.recycleablecounter = self.recycleablecounter + 1
                    break;
                }
            }
        
            if (counter == googleHelper.result.count){
                self.isNotRecycleable(googleHelper.result[0], position: position)
            }
        }
        self.status.text = "ready"
        self.status.textColor = UIColor.green
    }
    
   
    func isERecycleable(_ label:String,position:SCNVector3) {
        
        let boxNode = SCNNode()
        boxNode.scale = SCNVector3(x:1,y:1,z:1)
        boxNode.opacity = 1.0
        boxNode.position = position
        
        //Set up card view
        let imageView = UIView(frame:CGRect(x:0,y:0,width:800,height:600))
        imageView.backgroundColor = .white
        imageView.alpha = 1.0
        let titleLabel = UILabel (frame: CGRect(x:70,y:64,width: imageView.frame.width-224,height:84))
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        if (label.characters.count > 6){
            titleLabel.font = UIFont(name: "Avenir",size: 60)
        } else {
            titleLabel.font = UIFont(name: "Avenir",size: 84)
        }
        titleLabel.text = label.capitalized
        titleLabel.backgroundColor = .clear
        imageView.addSubview(titleLabel)
        
        let image = UILabel(frame: CGRect(x:240,y:200,width:imageView.frame.width-128,height:300))
        image.addImage(imageName: "erecycling.png")
        imageView.addSubview(image)
        
        let texture = UIImage.imageWithView(view: imageView)
        let labelNode = SCNNode()
        let labelGeometry = SCNPlane(width:0.13,height:0.09)
        labelGeometry.firstMaterial?.diffuse.contents = texture
        labelNode.geometry = labelGeometry
        labelNode.position.y += 0.09
        labelNode.position.z += 0.0055
        
        boxNode.addChildNode(labelNode)
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func isRecycleable(_ label:String,position:SCNVector3) {

        let boxNode = SCNNode()
        boxNode.scale = SCNVector3(x:1,y:1,z:1)
        boxNode.opacity = 1.0
        boxNode.position = position
        
        //Set up card view
        let imageView = UIView(frame:CGRect(x:0,y:0,width:800,height:600))
        imageView.backgroundColor = .white
        imageView.alpha = 1.0
        let titleLabel = UILabel (frame: CGRect(x:70,y:64,width: imageView.frame.width-224,height:84))
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        if (label.characters.count > 6){
            titleLabel.font = UIFont(name: "Avenir",size: 60)
        } else {
            titleLabel.font = UIFont(name: "Avenir",size: 84)
        }
        titleLabel.text = label.capitalized
        titleLabel.backgroundColor = .clear
        imageView.addSubview(titleLabel)
        
        let image = UILabel(frame: CGRect(x:240,y:200,width:imageView.frame.width-128,height:300))
        image.addImage(imageName: "001-recycling2.png")
        imageView.addSubview(image)
        
        let texture = UIImage.imageWithView(view: imageView)
        let labelNode = SCNNode()
        let labelGeometry = SCNPlane(width:0.13,height:0.09)
        labelGeometry.firstMaterial?.diffuse.contents = texture
        labelNode.geometry = labelGeometry
        labelNode.position.y += 0.09
        labelNode.position.z += 0.0055
        
        boxNode.addChildNode(labelNode)
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    func isNotRecycleable(_ label:String,position:SCNVector3) {
        
        //        virtualObjectInteraction.selectedObject = virtualObject
        //        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
        //        let SCNPlane()
        //
        //        updateQueue.async {
        //            self.sceneView.scene.rootNode.addChildNode(virtualObject)
        //        }
        let boxNode = SCNNode()
        boxNode.scale = SCNVector3(x:1,y:1,z:1)
        boxNode.opacity = 1.0
        boxNode.position = position
        
        //Set up card view
        let imageView = UIView(frame:CGRect(x:0,y:0,width:800,height:600))
        imageView.backgroundColor = .white
        imageView.alpha = 1.0
        let titleLabel = UILabel (frame: CGRect(x:70,y:64,width: imageView.frame.width-224,height:84))
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        if (label.characters.count > 6){
            titleLabel.font = UIFont(name: "Avenir",size: 60)
        } else {
            titleLabel.font = UIFont(name: "Avenir",size: 84)
        }
        titleLabel.text = label.capitalized
        titleLabel.backgroundColor = .clear
        imageView.addSubview(titleLabel)
        
        let image = UILabel(frame: CGRect(x:240,y:200,width:imageView.frame.width-128,height:300))
        image.addImage(imageName: "nuclear-power (1).png")
        imageView.addSubview(image)
        
        let texture = UIImage.imageWithView(view: imageView)
        let labelNode = SCNNode()
        let labelGeometry = SCNPlane(width:0.13,height:0.09)
        labelGeometry.firstMaterial?.diffuse.contents = texture
        labelNode.geometry = labelGeometry
        labelNode.position.y += 0.09
        labelNode.position.z += 0.0055
        
        boxNode.addChildNode(labelNode)
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }


    // MARK: - ARSCNViewDelegate
    
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
}
