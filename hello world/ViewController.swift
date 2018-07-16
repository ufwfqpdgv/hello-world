//
//  ViewController.swift
//  hello world
//
//  Created by lyw on 2018/7/6.
//  Copyright © 2018年 lyw. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var label: NSTextField!
    
    @IBAction func button(_ sender: Any) {
        let greeting = "Hello!"
        label.stringValue = greeting
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // 我的
    override func keyDown(with event:NSEvent){
        let n = event.characters!
        label.stringValue = n
    }
}
