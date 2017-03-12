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


class VisualizerView: ScreenSaverView {
    var rects: [NSRect] = []
    let audioEngine = AVAudioEngine()
    
    var input: AKMicrophone! = nil
    var mixer: AKMixer! = nil
    var output: AKBooster! = nil
    var fft: AKFFTTap! = nil
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        initRects()
        
        Swift.print(AudioKit.availableInputs!)
        
        input = AKMicrophone()
        do { try input.setDevice(AudioKit.availableInputs![0]) } catch {}
        mixer = AKMixer(input)
        output = AKBooster(mixer, gain:0)
        
        AudioKit.output = output
        AudioKit.start()
        
        output.start()
        
        fft = AKFFTTap(mixer)
        
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
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
    }
    
    override func startAnimation() {
        super.startAnimation()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
    }
    
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        let context = NSGraphicsContext.current()
        context!.cgContext.setFillColor(CGColor.white)
        for rect in rects {
            context!.cgContext.fill(rect)
        }
    }
    
    override func animateOneFrame() {
        for i in 0..<numBars {
            rects[i].size.height = CGFloat(fft.fftData[i]*outScale)*self.frame.height
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
