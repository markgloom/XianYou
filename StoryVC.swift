//
//  StoryVC.swift
//  XianYou
//
//  Created by Thomas Tu on 6/5/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class StoryVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var authorIcon: NSImageView!
    @IBOutlet weak var authorName: NSTextField!
    @IBOutlet var storyView: NSTextView!
    @IBOutlet weak var commentTable: NSTableView!
    @IBOutlet weak var storyImage: NSImageView!
    @IBOutlet var commentText: NSTextView!
    
    @IBAction func sendComment(sender: NSButton) {
        let storyText = commentText.string!
        if storyText.characters.count < 3 {
            let alertView:NSAlert = NSAlert()
            alertView.messageText = "发帖失败"
            alertView.informativeText = "字数少于 3."
            alertView.addButtonWithTitle("知道了")
            alertView.runModal()
        } else {
            
            var post: String = "text=\(storyText)&thing_id=\(fnID)&api_type=json"
            if commentImage.image != nil {
                let forImage = PostVC()
                let urlImage = forImage.uploadImage(commentImage)
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
                        self.commentText.string! = ""
                        self.commentImage.image = nil
                        //                        let valueOfJson = jsonData.valueForKey("json") as! NSDictionary
                        //                        let success = valueOfJson.valueForKey("data") as! NSArray
                        //                        if(success == []) {
                        //                            self.commentText.string! = ""
                        //                            let alertView:NSAlert = NSAlert()
                        //                            alertView.messageText = "发帖成功"
                        //                            alertView.informativeText = "发帖成功"
                        //                            alertView.addButtonWithTitle("知道了")
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
    
    var imageName = ""
    
    @IBAction func addCommentImage(sender: NSButton) {
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
                self.commentImage.image = image
            }
        })
    }
    @IBOutlet weak var commentImage: NSImageView!
    var tableData = []
    var tableDataComment = []
    var fnID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if fnID != "" {
            getStoryJSON("http://forum.apptao.com/comments/\(fnID)/.json?bypass=1&limit=100000&sort=new&tree=0&floor=1")
        }
    }
    
    func getStoryJSON(whichReddit : String){
        let mySession = NSURLSession.sharedSession()
        let url: NSURL = NSURL(string: whichReddit)!
        let networkTask = mySession.dataTaskWithURL(url, completionHandler : {data, response, error -> Void in
            let theJSON = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSArray
            let theJSONDictionary = theJSON[0] as! NSDictionary
            let theCommentDictionary = theJSON[1] as! NSDictionary
            let results : NSArray = theJSONDictionary["data"]!["children"] as! NSArray
            let resultsComment = theCommentDictionary["data"]!["children"] as! NSArray
            dispatch_async(dispatch_get_main_queue(), {
                self.tableData = results
                self.tableDataComment = resultsComment
                self.showStory()
                self.commentTable!.reloadData()
            })
        })
        networkTask.resume()
    }
    
    func showStory() {
        let redditEntry : NSMutableDictionary = self.tableData[0] as! NSMutableDictionary
        let selftextString = redditEntry["data"]!["selftext"] as! String
        let authorString = redditEntry["data"]!["author"] as! String
        let selftextItem = convertStringToDictionary(selftextString)
        let textArray = selftextItem!["items"]! as! NSArray
        let textDictionary = textArray[0] as! NSDictionary
        let textString = (textDictionary["text"]! as? String)!
        self.storyView.string = "\(textString)"
        self.authorName.stringValue = "\(authorString)"
        if let authorIconURL = redditEntry["data"]!["author_icon"] as? NSString{
            let imageURL = NSURL(string: authorIconURL as String)
            self.authorIcon.image = NSImage(contentsOfURL: imageURL!)
        }
        if textArray.count == 2 {
            let imageDictionary = textArray[1] as? NSDictionary
            storyImage.image = imageDictionary!["url"] as? NSImage
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return tableDataComment.count
    }
    
    var replyID = ""
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell: CommentCell = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! CommentCell
        
        let redditEntry : NSMutableDictionary = self.tableDataComment[row] as! NSMutableDictionary
        
        let bodyString = redditEntry["data"]!["body"] as! String
//        let floor = redditEntry["data"]!["comment_floor"] as! NSNumber
//            print(floor)
        cell.comment.stringValue = bodyString
//        if let authorIconURL = redditEntry["data"]!["author_icon"] as? NSString{
//            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
//                let imageURL = NSURL(string: authorIconURL as String)
//                dispatch_async(dispatch_get_main_queue()) {
//                    cell.authorImage.image = NSImage(contentsOfURL: imageURL!)
//                }
//            }
//        }
        cell.authorLabel.stringValue = (redditEntry["data"]!["author"] as? String)!
        
        if let replyArray = redditEntry["data"]!["atusers"] as? NSArray {
            cell.replyLabel.stringValue = "@ "
            cell.replyLabel.stringValue += replyArray[0]["name"] as! String
        }
        
//        if let imageString = redditEntry["data"]!["imagejson"] as? String {
//            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
//                let imageDictionary = self.convertStringToDictionary(imageString)
//                dispatch_async(dispatch_get_main_queue()) {
//                    cell.commentImage.image = imageDictionary!["url"] as? NSImage
//                }
//            }
//        }
        return cell
    }
    
    
    //    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    //
    ////        var amountOfLinesToBeShown:CGFloat = 6
    ////        var maxHeight:CGFloat = tableView.cell.textField.font.lineHeight * amountOfLinesToBeShown
    //
    //        let str = tableDataComment[row]["data"]!!["body"] as! String
    //        print(str)
    //        let c:Int = str.characters.count
    //        print(c)
    //        var cgfloat = CGFloat(c/5)
    //        print(cgfloat)
    //        if let img = tableDataComment[row]["data"]!!["imagejson"] as? String {
    //            cgfloat += 50
    //        } else {
    //        if cgfloat > 40 {
    //        return cgfloat
    //            }
    //        }
    //        else {
    //            return 40
    //            }
    //    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let myTableViewFromNotification = notification.object as! NSTableView
        let indexes = myTableViewFromNotification.selectedRowIndexes
        var index = indexes.firstIndex
        while index != NSNotFound {
            let feedIndex = self.tableDataComment[index] as! NSMutableDictionary
            replyID = feedIndex["data"]!["id"] as! String
            index = indexes.indexGreaterThanIndex(index)
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "reply" {
            let svc = segue.destinationController as! Reply
            svc.replyID = replyID
        }
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    @IBAction func floor(sender: NSButton) {
        var results = [String]()
        var resultsComment = []
        var author = ""
        let mySession = NSURLSession.sharedSession()
        
        let url: NSURL = NSURL(string: "http://forum.apptao.com/comments/378436358/.json?bypass=1&limit=100000&sort=new&tree=0&floor=1")!
        let networkTask = mySession.dataTaskWithURL(url, completionHandler : {data, response, error -> Void in
            let theJSON = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSArray
            //        let theJSONDictionary = theJSON[0] as! NSDictionary
            let theCommentDictionary = theJSON[1] as! NSDictionary
            //        let results : NSArray = theJSONDictionary["data"]!["children"] as! NSArray
            resultsComment = theCommentDictionary["data"]!["children"] as! NSArray
            for i in 0..<resultsComment.count {
                let floor = resultsComment[i]["data"]!!["comment_floor"] as! NSNumber
                author = resultsComment[i]["data"]!!["author"] as! String
                if Int(floor) > 298 && Int(floor) < 849 {
                    if results.contains(author) == false {
                        results.append(author)
                    }
                }
            }
            print(results)
            
        })
        networkTask.resume()
    }
    
}

extension NSTableCellView {
    
}
