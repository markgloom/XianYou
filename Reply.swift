//
//  Reply.swift
//  XianYou
//
//  Created by Thomas Tu on 6/10/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class Reply: NSViewController {
    
    @IBOutlet var replyText: NSTextView!
    @IBOutlet weak var picture: NSImageView!
    
    @IBAction func postStory(sender: NSButton) {
        let storyText = replyText.string!
        //        var items_obj = [["type": "text","text": storyText],]
        
        if storyText.characters.count < 3 {
            let alertView:NSAlert = NSAlert()
            alertView.messageText = "发帖失败"
            alertView.informativeText = "字数少于 3."
            alertView.addButtonWithTitle("知道了")
            alertView.runModal()
        } else {
            
            var post: String = "text=\(storyText)&thing_id=\(replyID)&api_type=json"
            if picture.image != nil {
                let forImage = PostVC()
                let urlImage = forImage.uploadImage(picture)
                let urlImage_index = urlImage.characters.indexOf("?")?.successor()
                let wh_str_start = urlImage_index
                let wh_str_end = urlImage.endIndex.advancedBy(-1)
                let wh_str = urlImage.substringWithRange(wh_str_start!...wh_str_end)
                let wh = wh_str.characters.split("|").map(String.init)
                let image_url = urlImage.substringToIndex(urlImage_index!.predecessor())
                var items_obj:[String: AnyObject] = [:]
                items_obj["url"] = image_url
                items_obj["width"] = Int(wh[0])
                items_obj["height"] = Int(wh[1])
                let data = try! NSJSONSerialization.dataWithJSONObject(items_obj, options: NSJSONWritingOptions.PrettyPrinted)
                let image = String(data: data, encoding: NSUTF8StringEncoding)!.encodeURIComponent()!
                post += post + "&imagejson=" + image
            }
            let url = NSURL(string:"http://forum.apptao.com/api/comment")!
            let postData:NSData = post.dataUsingEncoding(NSUTF8StringEncoding)!
            let postLength = String(postData.length)
            
            let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
            NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: url, mainDocumentURL: nil)
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.HTTPBody = postData
            request.setValue(postLength, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.allHTTPHeaderFields = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
            
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
                if data != nil {
                    do {
                        let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        let jsonData:NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                        print(dataString)
                        self.replyText.string! = ""
                        self.picture.image = nil
                        //                        let valueOfJson = jsonData.valueForKey("json") as! NSDictionary
                        //                        let success = valueOfJson.valueForKey("data") as! NSArray
                        //                        if(success == []) {
                        //                            self.commentText.string! = ""
                        //                            let alertView:NSAlert = NSAlert()
                        //                            alertView.messageText = "发帖成功"
                        //                            alertView.informativeText = "发帖成功"
                        //                            alertView.addButtonWithTitle("知道了")
                        dispatch_async(dispatch_get_main_queue()){
                            self.dismissViewController(self)
                        }
                        //                        }
                    }
                    catch _ {
                        let alertView:NSAlert = NSAlert()
                        alertView.messageText = "发帖失败!"
                        alertView.informativeText = "发帖失败"
                        alertView.addButtonWithTitle("知道了")
                    }
                }
            })
            task.resume()
        }
    }
    
    var replyID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    
}
