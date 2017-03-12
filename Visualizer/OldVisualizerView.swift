//
//  VisualizerView.swift
//  Visualizer
//
//  Created by Albert Smith on 5/2/17.
//  Copyright © 2017 Albert Smith. All rights reserved.
//

import Cocoa
import ScreenSaver
import GLKit
import OpenGL
import GLUT

class VisualizerView: ScreenSaverView {
    var glView: DummyOpenGLView? = nil
    var rotation: GLfloat = 0.0
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        let attributes: [NSOpenGLPixelFormatAttribute] =
                            [UInt32(NSOpenGLPFAAccelerated),
                             UInt32(NSOpenGLPFADepthSize), 16,
                             UInt32(NSOpenGLPFAMinimumPolicy),
                             UInt32(NSOpenGLPFAClosestPolicy),
                             0]
        let format = NSOpenGLPixelFormat(attributes: attributes)
        glView = DummyOpenGLView(frame: NSZeroRect, pixelFormat: format)
        
        if glView == nil {
            fatalError("Could not initialize the OpenGL view.")
        }
        
        self.addSubview(glView!)
        self.initOpenGL()
        self.animationTimeInterval = 1.0/30.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }
    
    func initOpenGL() {
        if glView != nil {
            glView!.openGLContext!.makeCurrentContext()
            glShadeModel(GLenum(GL_SMOOTH))
            glClearColor(0.0, 0.0, 0.0, 0.0)
            glClearDepth(1.0)
            glEnable(GLenum(GL_DEPTH_TEST))
            glDepthFunc(GLenum(GL_LEQUAL))
            glHint(GLenum(GL_PERSPECTIVE_CORRECTION_HINT),
                   GLenum(GL_NICEST))
            
            rotation = 0.0
        }
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        glView!.setFrameSize(newSize)
        
        glView!.openGLContext!.makeCurrentContext()
        glViewport(0, 0, GLsizei(newSize.width), GLsizei(newSize.height))
        
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        
        // Change the view transform
        // In a past life, this could perhaps have been done as follows:
        // gluPerspective(45.0, GLfloat(newSize.width / newSize.height), 0.1, 100.0)
        // But society has clearly moved on.
        // so, for better or worse, we have the following monstrosity.
        // also thanks GLKit for returning the values as a tuple. like,
        // why would you do that? what's the point? ever heard of an Array?
        var tmp: [GLfloat] = []
        for child in Mirror(reflecting:GLKMatrix4MakePerspective(45.0, Float(newSize.width)/Float(newSize.height), 0.1, 100.0).m).children {
            tmp.append(GLfloat(child.value as! Float))
        }
        glMultMatrixf(UnsafePointer<GLfloat>(
            tmp
            ))
        // </horrible code>
        
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()
        
        glView!.openGLContext!.update()
    }
    
    
    override func startAnimation() {
        super.startAnimation()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
    }
    
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        glView!.openGLContext!.makeCurrentContext()
        
        glClear(UInt32(GL_COLOR_BUFFER_BIT)|UInt32(GL_DEPTH_BUFFER_BIT))
        glLoadIdentity()
        
        glTranslatef(0.0, 0.0, -6.0)
        glRotatef(rotation, 0.0, 1.0, 0.0)
        
        glBegin(GLenum(GL_TRIANGLES))
        glColor3f( 1.0, 0.0, 0.0 )
        glVertex3f( 0.0, 1.0, 0.0 )
        glColor3f( 0.0, 1.0, 0.0 )
        glVertex3f( -1.0, -1.0, 1.0 )
        glColor3f( 0.0, 0.0, 1.0 )
        glVertex3f( 1.0, -1.0, 1.0 )
        glColor3f( 1.0, 0.0, 0.0 )
        glVertex3f( 0.0, 1.0, 0.0 )
        glColor3f( 0.0, 0.0, 1.0 )
        glVertex3f( 1.0, -1.0, 1.0 )
        glColor3f( 0.0, 1.0, 0.0 )
        glVertex3f( 1.0, -1.0, -1.0 )
        glColor3f( 1.0, 0.0, 0.0 )
        glVertex3f( 0.0, 1.0, 0.0 )
        glColor3f( 0.0, 1.0, 0.0 )
        glVertex3f( 1.0, -1.0, -1.0 )
        glColor3f( 0.0, 0.0, 1.0 )
        glVertex3f( -1.0, -1.0, -1.0 )
        glColor3f( 1.0, 0.0, 0.0 )
        glVertex3f( 0.0, 1.0, 0.0 )
        glColor3f( 0.0, 0.0, 1.0 )
        glVertex3f( -1.0, -1.0, -1.0 )
        glColor3f( 0.0, 1.0, 0.0 )
        glVertex3f( -1.0, -1.0, 1.0 )
        glEnd()
        
        glFlush()
    }
    
    override func animateOneFrame() {
        rotation += 0.2
        
        self.needsDisplay = true
    }
    
    override func hasConfigureSheet() -> Bool {
        return false
    }
    
    override func configureSheet() -> NSWindow? {
        return nil
    }
}
