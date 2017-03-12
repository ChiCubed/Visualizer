//
//  VisualizerView.swift
//  Visualizer
//
//  Created by Albert Smith on 5/2/17.
//  Copyright © 2017 Albert Smith. All rights reserved.
//

import Cocoa
import ScreenSaver
import QuartzCore
import AudioKit

// We'll first try a STFT with 0% overlap and a half-cosine window.
// of course something like 50% overlap is more accurate.
// if this is too slow, we can try a rectangular window.

// We'll clip data below approximately -30 dB.

let numBars = 100
let outScale = 1.0
let bufferLength = 100

var input: AKMicrophone! = nil
var mixer: AKMixer! = nil
var output: AKBooster! = nil
var fft: AKFFTTap! = nil


var stopped = false

class VisualizerView: ScreenSaverView {
    var rects: [NSRect] = []
    
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        initRects()
        
        Swift.print(AudioKit.availableInputs!)
        
        if input == nil {
            initAudioKit()
        }
        
        if stopped {
            stopped = false
            startAudioKit()
        }
        
        self.animationTimeInterval = 1.0/30.0
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }

    func initRects() {
        let w = self.frame.width/CGFloat(numBars+2)
        for i in 1...numBars {
            rects.append(NSRect(x:CGFloat(i)*w,y:0,width:w,height:0))
        }
    }
    
    func initAudioKit() {
        input = AKMicrophone()
        do { try input.setDevice(AudioKit.availableInputs![0]) } catch {}
        mixer = AKMixer(input)
        output = AKBooster(mixer, gain:0)
        
        AudioKit.output = output
        
        fft = AKFFTTap(mixer)
    }
    
    func startAudioKit() {
        AudioKit.start()
        output.start()
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
    }
    
    override func startAnimation() {
        super.startAnimation()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        
        if !stopped {
            stopped = true
            output.stop()
            AudioKit.stop()
        }
    }
    
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        let context = NSGraphicsContext.current()
        context!.cgContext.setFillColor(CGColor.white)
        for rect in rects {
            context!.cgContext.fill(rect)
        }
    }
    
    func decibelScale(_ val: Double) -> Double {
        return (pow(10.0, val/20.0)-1.0) * 10.0
    }
    
    override func animateOneFrame() {
        if input == nil {
            initAudioKit()
        }
        if stopped {
            stopped = false
            startAudioKit()
        }
        for i in 0..<numBars {
            rects[i].size.height = min(CGFloat(decibelScale(fft.fftData[i])*outScale)*self.frame.height,self.frame.height/3)
        }
        self.needsDisplay = true
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
}
