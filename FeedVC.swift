//
//  FeedVC.swift
//  XianYou
//
//  Created by Thomas Tu on 6/5/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class FeedVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate {
    
    @IBOutlet weak var usernameLabel: NSTextField!
    
    @IBOutlet weak var newFeedTable: NSTableView!
    @IBOutlet weak var hotFeedTable: NSTableView!
    
    @IBAction func postStory(sender: NSButton) {
        self.performSegueWithIdentifier("postStory", sender: self)
    }
    var tableData: NSMutableArray = []
    var tableDataNew: NSMutableArray = []
    var tableDataHot: NSMutableArray = []
    var storyID = ""
    var after = ""
    
    //    @IBOutlet weak var StoryText: NSTextField!
    //    @IBOutlet weak var UserIcon: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        getRedditJSON("http://forum.apptao.com/r/ar_discuss/new/.json?bypass=1&after=#tmpl_list_story&limit=100", whichTable: tableDataNew, whichFeed: newFeedTable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let isLoggedIn:Int = prefs.integerForKey("ISLOGGEDIN") as Int
        if (isLoggedIn != 1) {
            self.performSegueWithIdentifier("gotologin", sender: self)
        } else {
            self.usernameLabel.stringValue = (prefs.valueForKey("USERNAME") as? String)!
        }
    }
    
    @IBAction func logoutTapped(sender : NSButton) {
        
        let appDomain = NSBundle.mainBundle().bundleIdentifier
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
        self.usernameLabel.stringValue = "未登录"
        self.performSegueWithIdentifier("gotologin", sender: self)
    }
    
    
    func getRedditJSON(whichReddit : String, whichTable: NSMutableArray, whichFeed: NSTableView){
        let mySession = NSURLSession.sharedSession()
        let url: NSURL = NSURL(string: whichReddit)!
        let networkTask = mySession.dataTaskWithURL(url, completionHandler : {data, response, error -> Void in
            let theJSON = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSMutableDictionary
            let results = theJSON["data"]!["children"] as! NSMutableArray
            let afterString = theJSON["data"]!["after"] as! String
            self.after = afterString
            dispatch_async(dispatch_get_main_queue(), {
//                self.tableData = results
                for i in 0..<results.count {
                    whichTable.addObject(results[i])
                    self.tableData = whichTable
                }
                whichFeed.reloadData()
            })
        })
        networkTask.resume()
    }
    
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        if (tabViewItem?.identifier)! as! String == "new" {
            getRedditJSON("http://forum.apptao.com/r/ar_discuss/new/.json?bypass=1&after=#tmpl_list_story&limit=100", whichTable: tableDataNew, whichFeed: newFeedTable)
        } else {
            getRedditJSON("http://forum.apptao.com/r/ar_discuss/hot/.json?bypass=1&after=#tmpl_list_story&limit=100", whichTable: tableDataHot, whichFeed: hotFeedTable)
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cell: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView
        
        let redditEntry : NSMutableDictionary = self.tableData[row] as! NSMutableDictionary
        
        let selftextString = redditEntry["data"]!["selftext"] as! String
        
        let selftextItem = convertStringToDictionary(selftextString)
        
        let textArray = selftextItem!["items"]! as! NSArray
        
        let textDictionary = textArray[0] as! NSDictionary
        
        cell.textField!.stringValue = textDictionary["text"]! as! String
        
        if  let pictureURL = selftextItem!["preview_pic_url"] as? NSString {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
                let imageURL = NSURL(string: pictureURL as String)
                dispatch_async(dispatch_get_main_queue()) {
                    cell.imageView?.image = NSImage(contentsOfURL: imageURL!)
                }
            }
        }
        
        return cell
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let myTableViewFromNotification = notification.object as! NSTableView
        let indexes = myTableViewFromNotification.selectedRowIndexes
        var index = indexes.firstIndex
        while index != NSNotFound {
            let feedIndex = self.tableData[index] as! NSMutableDictionary
            storyID = feedIndex["data"]!["id"] as! String
            index = indexes.indexGreaterThanIndex(index)
        }
    }
    
    @IBAction func loadMoreNew(sender: AnyObject) {
        getRedditJSON("http://forum.apptao.com/r/ar_discuss/new/.json?bypass=1&after=\(after)#tmpl_list_story&limit=100", whichTable: tableDataNew, whichFeed: newFeedTable)
    }
    
    @IBAction func loadMoreHot(sender: AnyObject) {
        getRedditJSON("http://forum.apptao.com/r/ar_discuss/hot/.json?bypass=1&after=\(after)#tmpl_list_story&limit=100", whichTable: tableDataHot, whichFeed: hotFeedTable)
    }
    
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "showStory" {
            let svc = segue.destinationController as! StoryVC
            svc.fnID = storyID
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
    
}
