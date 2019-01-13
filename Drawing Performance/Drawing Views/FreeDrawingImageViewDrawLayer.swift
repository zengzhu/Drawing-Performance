//
//  FreeDrawingImageView.swift
//
//  Created by Besher on 2018-12-30.
//  Copyright © 2018 Besher Al Maleh. All rights reserved.
//

import UIKit

// Slow GPU
class FreeDrawingImageViewDrawLayer: UIView, DrawingSpace {
    
    var drawingLayer: CAShapeLayer?
    var flattenedLayer: CALayer?
    var flattenedImage: CGImage?
    var displayLink: CADisplayLink?
    var line = [CGPoint]()
    
    var autoPoints = [CGPoint]()
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let newTouchPoint = touches.first?.location(in: self) else { return }
        stopDrawing()
        line.append(newTouchPoint)
        layer.setNeedsDisplay()
        checkIfTooManyPointsIn(&line)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        flattenImage()
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        let drawingLayer = self.drawingLayer ?? CAShapeLayer()
        let linePath = UIBezierPath()
        drawingLayer.contentsScale = Display.scale


        for (index, point) in line.enumerated() {
            if index == 0 {
                linePath.move(to: point)
            } else {
                linePath.addLine(to: point)
            }
        }

        drawingLayer.path = linePath.cgPath
        drawingLayer.opacity = 1
        drawingLayer.lineWidth = lineWidth
        drawingLayer.lineCap = .round
        drawingLayer.fillColor = UIColor.clear.cgColor
        drawingLayer.strokeColor = lineColor.cgColor

        if self.drawingLayer == nil {
            self.drawingLayer = drawingLayer
            layer.addSublayer(drawingLayer)
        }
    }
    
    func checkIfTooManyPointsIn(_ line: inout [CGPoint]) {
        let maxPoints = 2500
        if line.count > maxPoints {
            updateFlattenedLayer()
            // we leave two points to ensure no gaps or sharp angles
            _ = line.removeFirst(maxPoints - 2)
        }
    }
    
    func flattenImage() {
        updateFlattenedLayer()
        line.removeAll()
    }
    
    func updateFlattenedLayer() {
        let flattened: CALayer
        
        // if it exists, we reuse it
        if let flattenedLayer = self.flattenedLayer {
            flattened = flattenedLayer
        } else {
            // otherwise we create a new one
            flattened = CALayer()
            self.layer.insertSublayer(flattened, below: drawingLayer)
            flattened.frame = self.bounds
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, Display.scale)
        if let context = UIGraphicsGetCurrentContext() {
            
            // keep old drawing
            if let oldDrawing = flattenedLayer {
                if let oldImage = oldDrawing.contents {
                    let cgImage = oldImage as! CGImage
                    let uiImage = UIImage(cgImage: cgImage)
                    uiImage.draw(in: self.bounds)
                }
            }
            
            // add new drawings
            drawingLayer?.render(in: context)
            
            let output = UIGraphicsGetImageFromCurrentImageContext()
            flattened.contents = output?.cgImage
            self.flattenedLayer = flattened
        }
        UIGraphicsEndImageContext()
    }
    
    func drawSpiral() {
        let link = CADisplayLink(target: self, selector: #selector(drawSpiralLink))
        link.add(to: .main, forMode: .default)
        displayLink = link
    }
    
    @objc func drawSpiralLink() {
        if self.autoPoints.isEmpty {
            self.createSpiral()
            self.flattenImage()
        } else {
            self.line.append(self.autoPoints.removeFirst())
            self.layer.setNeedsDisplay()
            self.checkIfTooManyPointsIn(&self.line)
        }
    }
    
    func calculateRectBetween(lastPoint: CGPoint, newPoint: CGPoint) -> CGRect {
        var rect = CGRect.zero
        
        let originX = min(lastPoint.x, newPoint.x) - (lineWidth / 2)
        let originY = min(lastPoint.y, newPoint.y) - (lineWidth / 2)
        
        let maxX = max(lastPoint.x, newPoint.x) + (lineWidth / 2)
        let maxY = max(lastPoint.y, newPoint.y) + (lineWidth / 2)
        
        let width = maxX - originX
        let height = maxY - originY
        
        rect = CGRect(x: originX, y: originY, width: width, height: height)
        
        return rect
    }
    
    func getImageRepresentation() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    func clear() {
        flattenedLayer?.removeFromSuperlayer()
        flattenedLayer = nil
        drawingLayer?.removeFromSuperlayer()
        drawingLayer = nil
        line.removeAll()
        autoPoints.removeAll()
        layer.setNeedsDisplay()
    }
}