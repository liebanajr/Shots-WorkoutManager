//
//  WorkoutManager.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 12/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import CoreMotion
import simd

struct MotionDataPoint {
    
    var accX : Double
    var accY : Double
    var accZ : Double
    var gyrX : Double
    var gyrY : Double
    var gyrZ : Double
    var gravX : Double
    var gravY : Double
    var gravZ : Double
    var transformedAccX : Double
    var transformedAccY : Double
    var transformedAccZ : Double
    var timeStamp : Double
    
    init(){
        
        accX = 0.0
        accY = 0.0
        accZ = 0.0
        gyrX = 0.0
        gyrY = 0.0
        gyrZ = 0.0
        gravX = 0.0
        gravY = 0.0
        gravZ = 0.0
        transformedAccX = 0.0
        transformedAccY = 0.0
        transformedAccZ = 0.0
        timeStamp = 0.0
        
    }
    
}

protocol ShotsMotionManagerDelegate {
    func motionManager(didAppend dataPoint: MotionDataPoint)
}

public class ShotsMotionManager: NSObject {
    
    var motionDataPoints : Array<MotionDataPoint>
    var motion : CMMotionManager?
    var timeStamp : Double
    
    var delegate : ShotsMotionManagerDelegate?
        
    public var isCrownInverted = false
    public var isWatchHandInverted = false
    private var inverter = 1.0
    
    var sampleInterval = 1.0/30.0
    
    init(sampleFrequency f : Double) {
        motionDataPoints = []
        timeStamp = 0.0
        sampleInterval = 1.0 / f
        
        super.init()
    }
    
//    MARK: Managing data
    
    public func toCSVString() -> String{
        
        var resultString = K.csvTextHeader
        
        for dataPoint in motionDataPoints {
            
            resultString.append(String(format: K.timeStampPrecision, dataPoint.timeStamp) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accZ * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrZ * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.transformedAccX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.transformedAccY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.transformedAccZ * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gravX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gravY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gravZ * K.sensorScaleFactor) + "\n")
            
        }
        
        return resultString
        
    }
        
    private func storeDeviceMotion(_ deviceMotion: CMDeviceMotion, _ timeStamp: Double) -> MotionDataPoint{
        
        var motionDataPoint = MotionDataPoint()
        motionDataPoint.accX = deviceMotion.userAcceleration.x * inverter
        motionDataPoint.accY = deviceMotion.userAcceleration.y * inverter
        motionDataPoint.accZ = deviceMotion.userAcceleration.z
        motionDataPoint.gyrX = deviceMotion.rotationRate.x * inverter
        motionDataPoint.gyrY = deviceMotion.rotationRate.y * inverter
        motionDataPoint.gyrZ = deviceMotion.rotationRate.z
        motionDataPoint.gravX = deviceMotion.gravity.x * inverter
        motionDataPoint.gravY = deviceMotion.gravity.y * inverter
        motionDataPoint.gravZ = deviceMotion.gravity.z
        
        let accVector = [motionDataPoint.accX,motionDataPoint.accY,motionDataPoint.accZ]
        let gravityVector = [motionDataPoint.gravX,motionDataPoint.gravY,motionDataPoint.gravZ]
        let transformedAccVector = ShotsMotionManager.transformAccReferenceFrameWithGravity(acceleration: accVector, gravity: gravityVector)
        
        motionDataPoint.transformedAccX = transformedAccVector[0]
        motionDataPoint.transformedAccY = transformedAccVector[1]
        motionDataPoint.transformedAccZ = transformedAccVector[2]
        
        motionDataPoint.timeStamp = timeStamp
        
        motionDataPoints.append(motionDataPoint)
        return motionDataPoint
        
    }
    
    private func performDatapointActions(_ dataPoint : CMDeviceMotion?, _ error: Error?){
        if error != nil {
            Log.error("Encountered error while starting device motion updates: \(error!)")
        }
        if dataPoint != nil {
            let dataPoint = self.storeDeviceMotion(dataPoint!, timeStamp)
//            Add sample and perform activity prediction
            delegate?.motionManager(didAppend: dataPoint)
            timeStamp += sampleInterval
        }
    }
    
//    MARK: Managing device motion

    
    public func startMotionUpdates(){
        
        motion = CMMotionManager()
        motion!.deviceMotionUpdateInterval = sampleInterval
        
        if WKInterfaceDevice.current().crownOrientation == .left {
            Log.info("Inverting XY for crown left")
            self.isCrownInverted = true
        }
        if WKInterfaceDevice.current().wristLocation == .right {
            Log.info("Inverting XY for Watch on right hand")
            self.isWatchHandInverted = true
        }
        
        if (isCrownInverted && !isWatchHandInverted) || (!isCrownInverted && isWatchHandInverted) {
            inverter = -1.0
        }
        
        if motion!.isDeviceMotionAvailable {
            
            Log.trace("Starting motion updates...")
            timeStamp = 0.0
            motion!.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
                self.performDatapointActions(deviceMotion, error)
            }
            
        } else {
            Log.warning("Device motion not available")
        }
        
    }
    
    public func pauseMotionUpdates(){
        Log.trace("Pausing motion updates")
        motion?.stopDeviceMotionUpdates()
    }
    
    public func resumeMotionUpdates(){
        Log.trace("Resuming motion updates")
        motion?.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
            self.performDatapointActions(deviceMotion, error)
        }
    }
    
    public func stopMotionUpdates() {
        
        Log.trace("Stopping motion updates...")
        motion?.stopDeviceMotionUpdates()
        motion = nil
        
    }
    
//    MARK: Utility geometric functions
    private static func calculateAngle(vectorA a: simd_double3, vectorB b: simd_double3) -> Double{
        let norm_a = simd_normalize(a)
        let norm_b = simd_normalize(b)
        let dotProduct = simd_dot(norm_a, norm_b)
        let angle = acos(dotProduct)

        return angle
    }

    static func transformAccReferenceFrameWithGravity(acceleration vector: [Double], gravity g: [Double]) -> [Double]{
        guard vector.count == 3 && g.count == 3 else {Log.error("Vectors are not 3D");return vector}
        let v = simd_double3(vector[0], vector[1], vector[2])
        let used_g = -simd_normalize(simd_double3(g[0], g[1], g[2]))
        let z_axis = simd_double3(0.0,0.0,1.0)
        let rotation_angle = calculateAngle(vectorA: used_g, vectorB: z_axis)
        let rotation_axis = simd_normalize(simd_cross(used_g,z_axis))
        let quaternion = simd_quatd(angle: rotation_angle, axis: rotation_axis)
        let resultVector = quaternion.act(v)

        return [resultVector.x,resultVector.y,resultVector.z]
    }

}
