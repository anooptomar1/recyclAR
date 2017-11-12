//
//  GoogleAPIHelper.swift
//  RecyclAR
//
//  Created by Soon Sung Hong on 11/11/17.
//  Copyright © 2017 Soon Sung Hong. All rights reserved.
//

import UIKit
import SwiftyJSON

class GoogleAPIHelper: NSObject {

    let session = URLSession.shared
    var result:Array<String> = []
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var labelResults:UITextView!
    @IBOutlet weak var faceResults: UITextView!
    
    
    var googleAPIKey = "AIzaSyD0kT5jWWp6ajMRevT4aRYv_LaeC-txR24"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        let imageNSData: NSData = NSData(data:(UIImagePNGRepresentation(image))!)
        let imageSize: Int = imageNSData.length
        // Resize the image if it exceeds the 2MB API limit
        
        if (imageSize > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func createRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 10
                    ],
                    [
                        "type": "FACE_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            
            // Use SwiftyJSON to parse results
            guard let json = try? JSON(data: dataToParse) else {return}
            let errorObj: JSON = json["error"]
            
//            self.imageView.isHidden = true
//            self.labelResults.isHidden = false
//            self.faceResults.isHidden = false
//            self.faceResults.text = ""
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                self.labelResults.text = "Error code \(errorObj["code"]): \(errorObj["message"])"
            } else {
                // Parse the response
                print(json)
                let responses: JSON = json["responses"][0]
                
                // Get face annotations
//                let faceAnnotations: JSON = responses["faceAnnotations"]
//                if faceAnnotations != nil {
//                    let emotions: Array<String> = ["joy", "sorrow", "surprise", "anger"]
//
//                    let numPeopleDetected:Int = faceAnnotations.count
//
//                    self.faceResults.text = "People detected: \(numPeopleDetected)\n\nEmotions detected:\n"
//
//                    var emotionTotals: [String: Double] = ["sorrow": 0, "joy": 0, "surprise": 0, "anger": 0]
//                    var emotionLikelihoods: [String: Double] = ["VERY_LIKELY": 0.9, "LIKELY": 0.75, "POSSIBLE": 0.5, "UNLIKELY":0.25, "VERY_UNLIKELY": 0.0]
//
//                    for index in 0..<numPeopleDetected {
//                        let personData:JSON = faceAnnotations[index]
//
//                        // Sum all the detected emotions
//                        for emotion in emotions {
//                            let lookup = emotion + "Likelihood"
//                            let result:String = personData[lookup].stringValue
//                            emotionTotals[emotion]! += emotionLikelihoods[result]!
//                        }
//                    }
//                    // Get emotion likelihood as a % and display in UI
//                    for (emotion, total) in emotionTotals {
//                        let likelihood:Double = total / Double(numPeopleDetected)
//                        let percent: Int = Int(round(likelihood * 100))
//                        self.faceResults.text! += "\(emotion): \(percent)%\n"
//                    }
//                } else {
//                    self.faceResults.text = "No faces found"
//                }
                
                // Get label annotations
                let labelAnnotations: JSON = responses["labelAnnotations"]
                let numLabels: Int = labelAnnotations.count
                var labels: Array<String> = []
                if numLabels > 0 {
                   // var labelResultsText:String = "Labels found: "
                    for index in 0..<numLabels {
                        let label = labelAnnotations[index]["description"].stringValue
                        labels.append(label)
                    }
//                    for label in labels {
//                        // if it's not the last item add a comma
//                        if labels[labels.count - 1] != label {
//                            labelResultsText += "\(label), "
//                        } else {
//                            labelResultsText += "\(label)"
//                        }
//                    }
                    self.result = labels
                    
                    //self.labelResults.text = labelResultsText
                } else {
                    self.labelResults.text = "No labels found"
                }
            }
        })
        
    }
    
    
}
