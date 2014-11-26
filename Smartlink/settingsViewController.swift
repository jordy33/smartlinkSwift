//
//  settingsViewController.swift
//  Smartlink
//
//  Created by Jorge Macias on 11/24/14.
//  Copyright (c) 2014 Diincasa. All rights reserved.
//

import UIKit
import CoreData
class settingsViewController: UIViewController, UITextFieldDelegate , NSURLConnectionDelegate, NSXMLParserDelegate {
    var myData = [NSManagedObject]()
    var mutableData:NSMutableData  = NSMutableData.alloc()
    var currentElementName:NSString = ""
    var resultData : String = ""
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var textViewResults: UITextView!
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.text = parameterRetrieve("url")
        portTextField.text = parameterRetrieve("port")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    }

    @IBAction func serverTestButtonTapped(sender: UIButton) {
        var request = HTTPTask()
//        request.requestSerializer = JSONRequestSerializer()
        request.responseSerializer = JSONResponseSerializer()
        request.GET("http://192.1.1.27/greeting", parameters: nil, success: {(response: HTTPResponse) in
                 if let dict = response.responseObject as? Dictionary<String,AnyObject> {
                    let myresult = dict["id"] as String
                    println("print the whole response: \(myresult)")
                    //Apple will only let you modify UI components on the main event loop
                    // If you do not know if you are on the main thread, you can check it out by doing NSThread.isMainThread()
                    dispatch_sync(dispatch_get_main_queue()) {
                            self.textViewResults.text=self.textViewResults.text + myresult+"\r\n"
                    }
            }
            },failure: {(error: NSError, response: HTTPResponse?) in
                println("error: \(error)")
        })
    }

    @IBAction func sendButtonTapped(sender: UIButton) {
        var soapMessage = "" //commandTextField.text
        var urlString = "http://192.1.1.27/greeting"
        var url = NSURL(string: urlString)
        var theRequest = NSMutableURLRequest(URL: url!)
        var msgLength = String(countElements(soapMessage))
        
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length")
        theRequest.HTTPMethod = "GET"
        theRequest.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) // or false
        
        var connection = NSURLConnection(request: theRequest, delegate: self, startImmediately: true)
        connection?.start()
        
        if (connection == true) {
            var mutableData : Void = NSMutableData.initialize()
        }

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
    // NSURL Connection Delegate
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        mutableData.length = 0;
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        mutableData.appendData(data)
    }
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        println("Received info")
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(mutableData, options:    NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        
        println(jsonResult.count)
        println(jsonResult.objectForKey("id"))
        var myresults: String = jsonResult.objectForKey("id") as String
        textViewResults.text=textViewResults.text+myresults+"\r\n"
    
//        println(mutableData)
//        var xmlParser = NSXMLParser(data: mutableData)
//        xmlParser.delegate = self
//        xmlParser.parse()
//        xmlParser.shouldResolveExternalEntities = true
        
    }
    
    
    // NSXMLParserDelegate
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: NSDictionary!) {
        currentElementName = elementName
        println("parser delegate")
    }
    
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        println("parser")
        if currentElementName == "id" {
            println ("lectura: \(string)")
        }
    }


 }

//var soapMessage = "" //commandTextField.text
//var urlString = "http://192.1.1.27/greeting"
//var url = NSURL(string: urlString)
//var theRequest = NSMutableURLRequest(URL: url!)
//var msgLength = String(countElements(soapMessage))
//
//theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
//theRequest.addValue(msgLength, forHTTPHeaderField: "Content-Length")
//theRequest.HTTPMethod = "GET"
//theRequest.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) // or false
//
//var connection = NSURLConnection(request: theRequest, delegate: self, startImmediately: true)
//connection?.start()
//
//if (connection == true) {
//    var mutableData : Void = NSMutableData.initialize()
//}
