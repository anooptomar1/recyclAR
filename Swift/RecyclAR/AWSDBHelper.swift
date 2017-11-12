//
//  AWSDBHelper.swift
//  RecyclAR
//
//  Created by Soon Sung Hong on 11/12/17.
//  Copyright © 2017 Soon Sung Hong. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognito
import AWSDynamoDB
import Foundation

let AWSSampleDynamoDBTableName = "RecyclAR"

class AWSDBHelper: NSObject {
    func configuration(){
        // Initialize the Amazon Cognito credentials provider
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:"us-east-1:e0749953-192d-4b4f-a599-6b2e5b81e2f8")
        
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    class func describeTable() -> AWSTask<AnyObject> {
        let dynamoDB = AWSDynamoDB.default()
        
        // See if the test table exists.
        let describeTableInput = AWSDynamoDBDescribeTableInput()
        describeTableInput?.tableName = AWSSampleDynamoDBTableName
        return dynamoDB.describeTable(describeTableInput!) as! AWSTask<AnyObject>
    }
    
    func updateScoreBoard(Phone_Number:String, score:Int){
        var dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(RecyclAR.self, hashKey: "+16175155778", rangeKey:nil).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print("The request failed. Error: \(error)")
            } else if let resultBook = task.result as? RecyclAR {
                // Do something with task.result.
                print(resultBook)
                print(resultBook.Recycled_Object)
            }
            return nil
        })
        let myScoreBoard = RecyclAR()
//        myScoreBoard?.Phone_Number = "+16175155778"
//        myScoreBoard?.Name = "Pablo"
//        myScoreBoard?.Recycled_Object = "10"
        myScoreBoard?.Phone_Number = nil
        myScoreBoard?.Name = nil
        myScoreBoard?.Recycled_Object = nil

        dynamoDBObjectMapper.save(myScoreBoard!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
            if let error = task.error as? NSError {
                print(myScoreBoard?.Name)
                print(myScoreBoard?.Phone_Number)
                print(myScoreBoard?.Recycled_Object)
                print(task.result)
                print("The request failed. Error: \(error)")
            } else {
                // Do something with task.result or perform other operations.
                print(task.result)
            }
            return nil
        })
//        let syncClient = AWSCognito.default()
        
        // Create a record in a dataset and synchronize with the server
//        var dataset = syncClient.openOrCreateDataset("RecyclAR")
//        dataset.setString("10", forKey:"+16175155778")
//        dataset.synchronize().continueWith {(task: AWSTask!) -> AnyObject! in
//            // Your handler code here
//
//            return nil
//        }
//        print("stored into AWSDB")
    }
    
}

class RecyclAR: AWSDynamoDBObjectModel, AWSDynamoDBModeling{

    var Phone_Number:String?
    var Name:String?
    var Recycled_Object:String?
    
    class func dynamoDBTableName() -> String {
        return "RecyclAR"
    }
    
    class func hashKeyAttribute() -> String {
        return "Phone_Number"
    }
    
    
}
