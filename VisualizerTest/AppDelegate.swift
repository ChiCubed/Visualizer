//
//  AppDelegate.swift
//  VisualizerTest
//
//  Created by Albert Smith on 5/2/17.
//  Copyright © 2017 Albert Smith. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    lazy var ssView = VisualizerView(frame: NSZeroRect, isPreview: false)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if ssView != nil {
            ssView!.frame = window.contentView!.bounds
            window.contentView!.addSubview(ssView!)
            ssView!.startAnimation()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        ssView!.stopAnimation()
    }
    
    @IBAction func showPopoverWindow(sender: AnyObject?) {
        if ssView!.hasConfigureSheet() {
            ssView!.stopAnimation()
            let swindow = ssView!.configureSheet()!
            window.beginSheet(swindow) { response in
                swindow.orderOut(self)
                self.ssView!.startAnimation()
            }
        }
    }
}

