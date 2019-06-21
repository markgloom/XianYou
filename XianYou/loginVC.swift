//
//  loginVC.swift
//  XianYou
//
//  Created by Thomas Tu on 5/29/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class LoginVC: NSViewController, NSTextFieldDelegate {
    
    
    @IBOutlet var txtUsername : NSTextField!
    @IBOutlet var txtPassword : NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func signinTapped(sender : NSButton) {
        let username:NSString = txtUsername.stringValue.encodeURIComponent()!
        let password:NSString = txtPassword.stringValue.encodeURIComponent()!
        
        if ( username.isEqualToString("") || password.isEqualToString("") ) {
            
            let alertView: NSAlert = NSAlert()
            alertView.messageText = "登录失败!"
            alertView.informativeText = "请输入用户名和密码"
            
            alertView.addButtonWithTitle("知道了")
            alertView.runModal()
        } else {
            
            let post:NSString = "user=\(username)&passwd=\(password)"
            
            let url:NSURL = NSURL(string:"http://forum.apptao.com/api/login2")!
            
            let postData:NSData = post.dataUsingEncoding(NSUTF8StringEncoding)!
            
            let postLength:NSString = String( postData.length )
            
            let request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.HTTPBody = postData
            request.setValue(postLength as String, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: {(urlData, response, error) in
                if urlData != nil {
                    let res = response as! NSHTTPURLResponse!;
                    NSLog("Response code: %ld", res.statusCode);
                    if res.statusCode >= 200 && res.statusCode < 300 {
                        let responseData:NSString  = NSString(data:urlData!, encoding:NSUTF8StringEncoding)!
                        NSLog("Response ==> %@", responseData);
                        do {
                            let jsonData:NSDictionary = try NSJSONSerialization.JSONObjectWithData(urlData!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                            let valueOfJson = jsonData.valueForKey("json") as! NSDictionary
                            let success = valueOfJson.valueForKey("errors") as! NSArray
                            if(success == [])
                            {
                                NSLog("Login SUCCESS");
                                
                                let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                                prefs.setObject(username, forKey: "USERNAME")
                                prefs.setInteger(1, forKey: "ISLOGGEDIN")
                                prefs.synchronize()
                                self.getCookies(response!)
                                dispatch_async(dispatch_get_main_queue()){
                                    self.dismissViewController(self)
                                }
                                
                            } else {
                                let error_msg = "用户名或密码错误"
                                
                                let alertView:NSAlert = NSAlert()
                                alertView.messageText = "登录失败!"
                                alertView.informativeText = error_msg as String
                                
                                alertView.addButtonWithTitle("知道了")
                                alertView.runModal()
                                
                            }
                            
                        } catch _ {
                            let alertView:NSAlert = NSAlert()
                            alertView.messageText = "登录失败!"
                            alertView.informativeText = "连接失败"
                            alertView.addButtonWithTitle("知道了")
                            alertView.runModal()
                        }
                    } else {
                        let alertView:NSAlert = NSAlert()
                        alertView.messageText = "登录失败!"
                        alertView.informativeText = "连接失败"
                        alertView.addButtonWithTitle("知道了")
                        alertView.runModal()
                    }
                    
                }
            })
            task.resume()
        }
    }
    
    private func getCookies(response: NSURLResponse){
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if let headerFields = httpResponse.allHeaderFields as? [String: String] {
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headerFields, forURL: response.URL!)
                print(cookies)
            }
        }
    }
    
    func textFieldShouldReturn(textField: NSTextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
}

extension String {
    
    func encodeURIComponent() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-_.!~*'()")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
    }
}
