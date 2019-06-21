//
//  commentTableCell.swift
//  XianYou
//
//  Created by Thomas Tu on 6/10/16.
//  Copyright © 2016 Thomas Tu. All rights reserved.
//

import Cocoa

class CommentCell : NSTableCellView {
    @IBOutlet weak var authorLabel: NSTextFieldCell!
    
    @IBOutlet weak var commentImage: NSImageView!
    @IBOutlet weak var authorImage: NSImageView!
    @IBOutlet weak var replyLabel: NSTextField!
    @IBOutlet weak var comment: NSTextField!
    @IBAction func reply(sender: NSButton) {
        
    }
    
}
