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




let numBars = 50
let outScale = 1.0

var input: AKMicrophone! = nil
var mixer: AKMixer! = nil
var output: AKBooster! = nil
var fft: AKFFTTap! = nil


enum VisualizerType {
    case bar, line
}

var currType = VisualizerType.line



// For smooth curve through points
struct ControlPoints {
    let p1: CGPoint
    let p2: CGPoint
}


var stopped = true

class VisualizerView: ScreenSaverView {
    var rects: [NSRect] = []
    var line: NSBezierPath = NSBezierPath()
    
    var w: CGFloat! = nil
    
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        w = self.frame.width/CGFloat(numBars+2)
        
        switch currType {
        case .bar:
            initRects()
        case .line:
            initLine()
        }
        
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
        for i in 1...numBars {
            rects.append(NSRect(x:CGFloat(i)*w,y:0,width:w,height:0))
        }
    }
    
    func initLine() {
        // nothing to see here
    }
    
    func initAudioKit() {
        input = AKMicrophone()
        do { try input.setDevice(AudioKit.availableInputs![0]) } catch {}
        mixer = AKMixer(input)
        output = AKBooster(mixer, gain:0)
        
        AudioKit.output = output
        
        fft = AKFFTTap(mixer)
        
        stopped = true
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
        context!.cgContext.setStrokeColor(CGColor.white)
        
        switch currType {
        case .bar:
            for rect in rects {
                context!.cgContext.fill(rect)
            }
        case .line:
            line.stroke()
        }
    }
    
    func decibelScale(_ val: Double) -> Double {
        return (pow(10.0, val/20.0)-1.0) * 20.0
    }
    
    func calculateControlPoints(_ points: [NSPoint]) -> [ControlPoints] {
        // https://github.com/Ramshandilya/Bezier/
        
        var point1: [CGPoint?] = []
        var point2: [CGPoint?] = []
        
        let num = points.count-1
        if num==1 {
            point1.append(CGPoint(
                x: (2*points[0].x + points[1].x)/3,
                y: (2*points[0].y + points[1].y)/3))
            point2.append(CGPoint(
                x: (2*point1[0]!.x - points[0].x),
                y: (2*point1[0]!.y - points[0].y)))
        } else {
            point1 = Array(repeating:nil, count:num)
            
            var rhs = [CGPoint]()
            
            var a = [Double]()
            var b = [Double]()
            var c = [Double]()
            
            for i in 0..<num {
                var rhsx = CGFloat(0)
                var rhsy = CGFloat(0)
                
                let p0 = points[i]
                let p3 = points[i+1]
                if i == 0 {
                    a.append(0)
                    b.append(2)
                    c.append(1)
                    
                    rhsx = p0.x + 2*p3.x
                    rhsy = p0.y + 2*p3.y
                } else if i == num-1 {
                    a.append(2)
                    b.append(7)
                    c.append(0)
                    
                    rhsx = 8*p0.x + p3.x
                    rhsy = 8*p0.y + p3.y
                } else {
                    a.append(1)
                    b.append(4)
                    c.append(1)
                    
                    rhsx = 4*p0.x + 2*p3.x
                    rhsy = 4*p0.y + 2*p3.y
                }
                
                rhs.append(CGPoint(x:rhsx,y:rhsy))
            }
            
            for i in 1...num {
                let rhsx = rhs[i].x
                let rhsy = rhs[i].y
                
                let prevRhsx = rhs[i-1].x
                let prevRhsy = rhs[i-1].y
                
                let m = a[i]/b[i-1]
                b[i] -= m * c[i-1]
                
                rhs[i] = CGPoint(x: rhsx - CGFloat(m) * prevRhsx,
                                 y: rhsy - CGFloat(m) * prevRhsy)
            }
        }
    }
    
    override func animateOneFrame() {
        if input == nil {
            initAudioKit()
        }
        if stopped {
            stopped = false
            startAudioKit()
        }
        
        switch currType {
        case .bar:
            for i in 0..<numBars {
                let height = min(CGFloat(decibelScale(fft.fftData[i])*outScale)*self.frame.height,self.frame.height)
                rects[i].size.height = height
            }
        case .line:
            line = NSBezierPath()
            
            var points: [NSPoint] = []
            for i in 1...numBars {
                let height = min(CGFloat(decibelScale(fft.fftData[i])*outScale)*self.frame.height,self.frame.height)
                points.append(NSPoint(x:CGFloat(i)*w,y:height))
            }
            
            let controlPoints = calculateControlPoints(points)
            for i in 0..<numBars {
                if i == 0 {
                    line.move(to: points[0])
                } else {
                    line.curve(to: points[i],
                               controlPoint1: controlPoints[i-1].p1,
                               controlPoint2: controlPoints[i-1].p2)
                }
            }
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
