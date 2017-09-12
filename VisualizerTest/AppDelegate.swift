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
    var timer: Timer?
    
    override init() {
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if ssView != nil {
            ssView!.frame = window.contentView!.bounds
            window.contentView!.addSubview(ssView!)
            ssView!.startAnimation()
            timer = Optional(Timer.scheduledTimer(timeInterval: ssView!.animationTimeInterval, target: self, selector: #selector(doFrame), userInfo: nil, repeats: true))
        }
    }
    
    func doFrame() {
        ssView!.animateOneFrame()
        if (ssView!.needsDisplay) {
            ssView!.draw(ssView!.frame)
            ssView!.needsDisplay = false
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        ssView!.stopAnimation()
        timer!.invalidate()
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

