//
//  VisualizerView.swift
//  Visualizer
//
//  Created by Albert Smith on 5/2/17.
//  Copyright © 2017 Albert Smith. All rights reserved.
//

import Foundation
import Cocoa
import ScreenSaver
import AudioKit
import OpenGL


class NonOpaqueOpenGLView: NSOpenGLView {
    override var isOpaque: Bool {
        get {
            return false
        }
        set {
        }
    }
}



let numBars = 50
let outScale = 1.0
let radiusScale: CGFloat = 0.3

var input: AKMicrophone! = nil
var mixer: AKMixer! = nil
var output: AKBooster! = nil
var fft: AKFFTTap! = nil


var stopped = true

class VisualizerView: ScreenSaverView {
    var lines: [GLfloat] = []
    var VBO: GLuint = 0
    var glView: NSOpenGLView!
    
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        glView = NonOpaqueOpenGLView(frame: NSZeroRect)
        
        self.addSubview(glView)
        self.setupOpenGL()
        
        if input == nil {
            initAudioKit()
        }
        
        initLines(frameSize: self.frame)
        
        if stopped {
            stopped = false
            startAudioKit()
        }
        
        self.animationTimeInterval = 1.0/30.0
    }

    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }
    
    func setupOpenGL() {
        glView.openGLContext!.makeCurrentContext()
        
        glGenBuffers(1, &VBO)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*lines.count, lines, GLenum(GL_STREAM_DRAW))
        
        glClearColor(0.0, 0.0, 0.0, 0.0)
    }
    
    deinit {
        glView.removeFromSuperview()
        glDeleteBuffers(1, &VBO)
    }

    func initLines(frameSize: NSRect) {
        var ratio: CGFloat = 1
        if (frameSize.width != 0) {
            ratio = frameSize.height / frameSize.width
        }
        for i in 0..<numBars {
            let p = CGPoint(x: radiusScale * ratio * CGFloat(cos(i * Double.pi * 2.0 / numBars)), y: radiusScale * CGFloat(sin(i * Double.pi * 2.0 / numBars)))
            lines += [GLfloat(p.x), GLfloat(p.y), GLfloat(p.x), GLfloat(p.y)]
        }
    }
    
    func initAudioKit() {
        input = AKMicrophone()
        do { try input.setDevice(AudioKit.inputDevice!) } catch {}
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
        
        glView.openGLContext!.makeCurrentContext()
        
        glViewport(0, 0, GLsizei(newSize.width), GLsizei(newSize.height))
        glView.setFrameSize(newSize)
        
        glView.openGLContext!.update()
        
        initLines(frameSize: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
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
        
        glView.openGLContext!.makeCurrentContext()
        
        // update buffers
        glBindBuffer(UInt32(GL_ARRAY_BUFFER) as GLenum, VBO)
        glBufferData(UInt32(GL_ARRAY_BUFFER) as GLenum, MemoryLayout<GLfloat>.size*lines.count, lines, GLenum(GL_STREAM_DRAW))
        
        glVertexAttribPointer(0, 2, GLenum(GL_FLOAT), GLboolean(false), GLsizei(MemoryLayout<GLfloat>.stride * 2), nil)
        glEnableVertexAttribArray(0)
        
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glLineWidth(10.0)
        
        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(lines.count))
        
        glFlush()
    }
    
    func decibelScale(_ val: Double) -> Double {
        return val*1.0//(pow(10.0, val/20.0)-1.0) * 20.0
    }
    
    override func animateOneFrame() {
        if input == nil {
            initAudioKit()
        }
        if stopped {
            stopped = false
            startAudioKit()
        }
        
        var ratio: CGFloat = 1
        if (self.frame.width != 0) {
            ratio = self.frame.height / self.frame.width
        }
        for i in 0..<numBars {
            let size = min(CGFloat(decibelScale(fft.fftData[i])*outScale),1.0)
            let p = CGPoint(x: (radiusScale + size) * ratio * CGFloat(cos(i * Double.pi * 2.0 / numBars)), y: (radiusScale + size) * CGFloat(sin(i * Double.pi * 2.0 / numBars)))
            lines[i*4 + 2] = GLfloat(p.x)
            lines[i*4 + 3] = GLfloat(p.y)
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
