//
//  settingsViewController.swift
//  Smartlink
//
//  Created by Jorge Macias on 11/24/14.
//  Copyright (c) 2014 Diincasa. All rights reserved.
//

import UIKit
import CoreData
class settingsViewController: UIViewController, UITextFieldDelegate {

    var myData = [NSManagedObject]()

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var textFieldUser: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var textViewResults: UITextView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.text = parameterRetrieve("url")
        portTextField.text = parameterRetrieve("port")
        textFieldUser.text = parameterRetrieve("user")
        textFieldPassword.text = parameterRetrieve("password")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func hideKeyboard(sender: AnyObject) {
                commandTextField.resignFirstResponder()
    }
    @IBAction func hideKeybForUser(sender: AnyObject) {
        textFieldUser.resignFirstResponder()
    }
    @IBAction func hideKeybForPasswd(sender: UITextField) {
        textFieldPassword.resignFirstResponder()
    }
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        urlTextField.resignFirstResponder()
        portTextField.resignFirstResponder()

        return true
    }

    @IBAction func saveButtonTapped(sender: UIButton) {
        urlTextField.resignFirstResponder()
        parameterDelete("url")
        parameterInsert("url", myValue: urlTextField.text)
        urlTextField.text = parameterRetrieve("url")
        parameterDelete("port")
        parameterInsert("port", myValue: portTextField.text)
        portTextField.text = parameterRetrieve("port")
        parameterDelete("user")
        parameterInsert("user", myValue: textFieldUser.text)
        textFieldUser.text = parameterRetrieve("user")
        parameterDelete("password")
        parameterInsert("password", myValue: textFieldPassword.text)
        textFieldPassword.text = parameterRetrieve("password")
    }

    @IBAction func serverTestButtonTapped(sender: UIButton) {
        var request = HTTPTask()
        var auth = HTTPAuth(username: parameterRetrieve("user"), password: parameterRetrieve("password"))
        auth.persistence = .Permanent
        request.auth = auth
        request.responseSerializer = JSONResponseSerializer()
        var myUrl:String = urlTextField.text + ":" + portTextField.text + "/" + "greeting"
        request.GET(myUrl, parameters: nil, success: {(response: HTTPResponse) in
                 if let dict = response.responseObject as? Dictionary<String,AnyObject> {
                    let myresult = dict["id"] as String
                    //Apple will only let you modify UI components on the main event loop
                    // If you do not know if you are on the main thread, you can check it out by doing NSThread.isMainThread()
                    dispatch_sync(dispatch_get_main_queue()) {
                            self.textViewResults.text=self.textViewResults.text + myresult+"\r\n"
                    }
            }
            },failure: {(error: NSError, response: HTTPResponse?) in
                println(response)
                //println("error: \(error)")
                // Error
                let alertController = UIAlertController(title: "Error", message:
                    "No connection", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
        })
    }

    @IBAction func sendButtonTapped(sender: UIButton) {
        // Enabling notifications
        // 192.1.1.27/gatt/nodes/1/characteristics/handle/23/value
        var request = HTTPTask()
        var auth = HTTPAuth(username: parameterRetrieve("user"), password: parameterRetrieve("password"))
        auth.persistence = .Permanent
        request.auth = auth
        //we have to add the explicit type, else the wrong type is inferred. See the vluxe.io article for more info.
        var myUrl:String = urlTextField.text + ":" + portTextField.text + "/" + "gatt/nodes/1/characteristics/handle/21/value"
        let params: Dictionary<String,AnyObject> = ["data": "AQA="]
        request.PUT(myUrl, parameters: params, success: {(response: HTTPResponse) in
            dispatch_sync(dispatch_get_main_queue()) {
                self.textViewResults.text=self.textViewResults.text + "notification enabled"+"\r\n"
                var res = self.executeCommand(self.commandTextField.text)
             }
            },failure: {(error: NSError, response: HTTPResponse?) in
                println("error: \(error)")
                let alertController = UIAlertController(title: "Error", message:
                    "No connection", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        })
        
    }
    
    func executeCommand(cmd: String) -> Bool {
        var eval = false
        var request = HTTPTask()
        var auth = HTTPAuth(username: parameterRetrieve("user"), password: parameterRetrieve("password"))
        auth.persistence = .Permanent
        request.auth = auth
        //we have to add the explicit type, else the wrong type is inferred. See the vluxe.io article for more info.
        var myUrl:String = urlTextField.text + ":" + portTextField.text + "/" + "gatt/nodes/1/characteristics/handle/23/value"
        let params: Dictionary<String,AnyObject> = ["data": convertStringToBase64(cmd)]
        request.PUT(myUrl, parameters: params, success: {(response: HTTPResponse) in
            dispatch_sync(dispatch_get_main_queue()) {
                self.retrieveResponse()
                eval = true
            }
            },failure: {(error: NSError, response: HTTPResponse?) in
                println("error: \(error)")
                let alertController = UIAlertController(title: "Error", message:
                    "No connection", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                
        })
        return eval
    }
    
    func retrieveResponse() {
        var request = HTTPTask()
        var auth = HTTPAuth(username: parameterRetrieve("user"), password: parameterRetrieve("password"))
        auth.persistence = .Permanent
        request.auth = auth
        request.responseSerializer = JSONResponseSerializer()
        var myUrl:String = urlTextField.text + ":" + portTextField.text + "/" + "gatt/nodes/1/characteristics/handle/19"
        request.GET(myUrl, parameters: nil, success: {(response: HTTPResponse) in
            if let dict = response.responseObject as? Dictionary<String,AnyObject> {
                let myresult = dict["value"] as String
                //Apple will only let you modify UI components on the main event loop
                // If you do not know if you are on the main thread, you can check it out by doing NSThread.isMainThread()
                dispatch_sync(dispatch_get_main_queue()) {
                    self.textViewResults.text=self.textViewResults.text + self.convertBase64ToString(myresult)+"\r\n"
                }
            }
            },failure: {(error: NSError, response: HTTPResponse?) in
                //println("error: \(error)")
                // Error
                let alertController = UIAlertController(title: "Error", message:
                    "No connection", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
        })

    }
    
    func convertStringToBase64(parameter :
        String)->String{
        let plainData = parameter.dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(.allZeros)
        return base64String!
    }

    func convertBase64ToString(parameter: String)->String{
        let decodedData = NSData(base64EncodedString: parameter, options: .allZeros)
        let decodedString = NSString(data: decodedData!, encoding: NSUTF8StringEncoding)
     return decodedString!
    }
    func parameterInsert(id: String, myValue: String){
        urlTextField.resignFirstResponder()
        portTextField.resignFirstResponder()
        let myDelegate=UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext=myDelegate.managedObjectContext
        let entity = NSEntityDescription.entityForName("Parameters", inManagedObjectContext: managedContext!)
        let newData=NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        newData.setValue(id, forKey: "id")
        newData.setValue(myValue, forKey: "stringValue")
        var error:NSError?=nil
        managedContext?.save(&error)
        if  (error != nil) {
            println("Can not save \(error)")
        }
        else {
            println(newData)
            println("Object Saved")}
    }
    func parameterDelete(id: String){
        let myDelegate=UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = myDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName:"Parameters")
        fetchRequest.predicate = NSPredicate(format: "id= %@",id)
        var error:NSError?=nil
        let fetchedResults = managedContext?.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        var bas: NSManagedObject!
        for bas: AnyObject in fetchedResults! {
            managedContext?.deleteObject(bas as NSManagedObject)
        }
        managedContext?.save(&error)
        if  (error != nil) {
            println("Can not delete \(error), \(error?.userInfo)")
        }
        else {
            println("object deleted")}
    }
    func parameterRetrieve(id: String)->String{
        var returnString: String = ""
        let myDelegate=UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = myDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName:"Parameters")
        fetchRequest.predicate = NSPredicate(format: "id= %@",id)
        var error:NSError?
        let fetchedResults = managedContext?.executeFetchRequest(fetchRequest, error: &error) as [NSManagedObject]?
        if let results = fetchedResults {
            myData = results
            if myData.count > 0 {
                // Retrieve several registers
//                println("data: \(myData.count)")
//                for i in 0..<myData.count {
//                    let myItem=myData[i]
//                    println(myItem.valueForKey("id") as String?)
//                    urlTextField.text=myItem.valueForKey("stringValue") as String?
//                    println(myItem.valueForKey("stringValue") as String?)
                    //println(myItem.valueForKey("stringValue") as String?)
                    //portTextField.text=myItem.valueForKey("password") as String?
                // Retrieve only one item, the first one
                let  myItem=myData[0]
                  returnString = myItem.valueForKey("stringValue") as String
                }
            } else {
                returnString = " "
                println("Could not fetch \(error)")
            }
        return returnString
     }
 }
//let plainString = "r1"
//
//let plainData = plainString.dataUsingEncoding(NSUTF8StringEncoding)
//let base64String = plainData?.base64EncodedStringWithOptions(.allZeros)
//var result: String = ""
//result = base64String!
//println(result)
//
//
//
//
//let decodedData = NSData(base64EncodedString: base64String!, options: .allZeros)
//let decodedString = NSString(data: decodedData!, encoding: NSUTF8StringEncoding)
//println(decodedString)

