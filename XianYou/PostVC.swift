//
//  PostVC.swift
//  XianYou
//
//  Created by Thomas Tu on 5/28/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class PostVC: NSViewController {
    
    @IBOutlet var textOfStory: NSTextView!
    
    @IBOutlet weak var picture: NSImageView!
    
    var imageName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        // Do any additional setup after loading the view.
    }
    
    @IBAction func addImage(sender: NSButton) {
        
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["jpg","jpeg","png"]
        panel.title = "选择一张图片"
        panel.beginWithCompletionHandler({(result:Int) in
            if(result == NSFileHandlingPanelOKButton)
            {
                let fileURL = panel.URL!
                let image = NSImage(byReferencingURL: fileURL)
                self.imageName = fileURL.lastPathComponent!
                self.picture.image = image
            }
        })
    }
    
    @IBAction func postStory(sender: NSButton) {
        
        var selftext_obj:[String: AnyObject] = ["type": "hybrid"]
        let storyText = textOfStory.string!
        var items_obj = [["type": "text","text": storyText],]
        
        if storyText.characters.count < 10 {
            let alertView:NSAlert = NSAlert()
            alertView.messageText = "发帖失败"
            alertView.informativeText = "字数少于 10."
            alertView.addButtonWithTitle("知道了")
            alertView.runModal()
        } else {
            
            if picture.image != nil {
                
                let urlImage = self.uploadImage(picture)
                let urlImage_index = urlImage.characters.indexOf("?")?.successor()
                let wh_str_start = urlImage_index
                let wh_str_end = urlImage.endIndex.advancedBy(-1)
                let wh_str = urlImage.substringWithRange(wh_str_start!...wh_str_end)
                let wh = wh_str.characters.split("|").map(String.init)
                let image_url = urlImage.substringToIndex(urlImage_index!.predecessor())
                selftext_obj["preview_pic_url"] = image_url;
                selftext_obj["preview_pic_width"] = Int(wh[0]);
                selftext_obj["preview_pic_height"] = Int(wh[1]);
                items_obj.append(["type":"picture","width": wh[0],"height": wh[1],"url":image_url])
            }
            
            selftext_obj["items"] = items_obj
            
            let data = try! NSJSONSerialization.dataWithJSONObject(selftext_obj, options: NSJSONWritingOptions.PrettyPrinted)
            let story = String(data: data, encoding: NSUTF8StringEncoding)!.encodeURIComponent()!
            let post:NSString = "text=\(story)&tags=&title=&sr=ar_discuss&kind=1"
            
            let url = NSURL(string:"http://forum.apptao.com/api/submit_withtitle/")!
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
                        let valueOfJson = jsonData.valueForKey("json") as! NSDictionary
                        let success = valueOfJson.valueForKey("errors") as! NSArray
                        if(success == []) {
                            self.textOfStory.string! = ""
                            self.picture.image = nil
//                            let alertView:NSAlert = NSAlert()
//                            alertView.messageText = "发帖成功"
//                            alertView.informativeText = "发帖成功"
//                            alertView.addButtonWithTitle("知道了")
                            dispatch_async(dispatch_get_main_queue()){
                                self.dismissViewController(self)
                            }
                        }
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
    
    
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
    func uploadImage(picture: NSImageView) -> String {
        
        var imageURL = ""
        let cgImgRef = picture.image!.CGImageForProposedRect(nil, context: nil, hints: nil)
        let image_data = NSBitmapImageRep(CGImage: cgImgRef!).representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
        
        let url = NSURL(string: "http://forum.apptao.com/bjimg5/upload")!
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let param:[String:String] = [:]
        
        request.HTTPBody = createBodyWithParameters(param, filePathKey: "file", imageDataKey: image_data, boundary: boundary)
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
            if data != nil {
                do {
                    let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    let resultOfJson = jsonData.valueForKey("result") as! NSDictionary
                    let imgurl = resultOfJson.valueForKey("imgurl") as! String
                    let imageWidth = resultOfJson.valueForKey("width") as! Int
                    let imageHeight = resultOfJson.valueForKey("height") as! Int
                    imageURL = imgurl + "?" + "\(imageWidth)" + "|" + "\(imageHeight)"
                }
                catch _ {
                    let alertView:NSAlert = NSAlert()
                    alertView.messageText = "上传图片失败!"
                    alertView.informativeText = "上传图片失败"
                    alertView.addButtonWithTitle("知道了")
                    alertView.runModal()
                }
                dispatch_semaphore_signal(semaphore)
            }
            
        }
        
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return imageURL
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData{
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData("\(value)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        
        let filename = "\(imageName)"
        let mimetype = "image/png"
        
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: \(mimetype)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(imageDataKey)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return body
    }
    
    
}

