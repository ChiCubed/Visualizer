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
import CoreAudioKit
import AVFoundation
import Accelerate

// We'll first try a STFT with 0% overlap and a half-cosine window.
// of course something like 50% overlap is more accurate.
// if this is too slow, we can try a rectangular window.

// We'll clip data below approximately -30 dB.

let numBars = 100
let outScale = 1.0
let bufferLength = 100



// Adapted from https://www.objc.io/issues/16-swift/rapid-prototyping-in-swift-playgrounds/
func sqrt(_ x: [Double]) -> [Double] {
    var results = [Double](repeating:0.0, count:x.count)
    vvsqrt(&results, x, [Int32(x.count)])
    return results
}

let fft_weights: FFTSetupD = vDSP_create_fftsetupD(vDSP_Length(log2(Float(bufferLength))), FFTRadix(kFFTRadix2))!

func fft(inputArray:[Double]) -> [Double] {
    var inputArray = inputArray
    var fftMagnitudes = [Double](repeating:0.0, count:inputArray.count)
    var zeroArray = [Double](repeating:0.0, count:inputArray.count)
    var splitComplexInput = DSPDoubleSplitComplex(realp: &inputArray, imagp: &zeroArray)
    
    vDSP_fft_zipD(fft_weights, &splitComplexInput, 1, vDSP_Length(log2(CDouble(inputArray.count))), FFTDirection(FFT_FORWARD));
    vDSP_zvabsD(&splitComplexInput, 1, &fftMagnitudes, 1, vDSP_Length(inputArray.count));
    
    let roots = sqrt(fftMagnitudes) // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
    var normalizedValues = [Double](repeating:0.0, count:inputArray.count)
    
    vDSP_vsmulD(roots, vDSP_Stride(1), [2.0 / Double(inputArray.count)], &normalizedValues, vDSP_Stride(1), vDSP_Length(inputArray.count))
    return normalizedValues
}



class VisualizerView: ScreenSaverView {
    var rects: [NSRect] = []
    let audioEngine = AVAudioEngine()
    
    var needsFFT = false
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        initRects()
        
        let inputNode = audioEngine.inputNode!
        let bus = 0
        
        inputNode.installTap(onBus: bus, bufferSize: AVAudioFrameCount(bufferLength), format: inputNode.inputFormat(forBus: bus)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                if self.needsFFT {
                    self.needsFFT = false
                    var samples: [Double] = []
                    // Store the samples
                    for i in 0 ..< buffer.frameLength {
                        samples.append(Double(buffer.floatChannelData![0][Int(i)]))
                    }
                    let heights = fft(inputArray: samples)
                
                    for i in 0 ..< numBars {
                        self.rects[i].size.height = CGFloat(heights[i] * Double(frame.size.height) * 50 * outScale)
                    }
                }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            Swift.print("Error")
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
        self.needsDisplay = true
        self.needsFFT = true
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
}
