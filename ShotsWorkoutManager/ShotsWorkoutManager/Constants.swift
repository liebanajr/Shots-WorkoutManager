//
//  Constants.swift
//  ShotsWorkoutManager
//
//  Created by Juan Rodríguez on 10/12/20.
//

import Foundation

struct K {
    #if DEBUG
    static let minLogLevel : LOGLEVEL = .DEBUG
    #else
    static let minLogLevel : LOGLEVEL = .WARNING
    #endif
    
    static let csvTextHeader = "Time Stamp,Accelerometer X,Accelerometer Y,Accelerometer Z,Gyroscope X,Gyroscope Y,Gyroscope Z,Transformed accelerometer X,Transformed accelerometer Y,Transformed accelerometer Z,Gravity X,Gravity Y,Gravity Z\n"
    static let sensorScaleFactor = 1.0
    static let sensorPrecision : String = "%.8f"
    static let timeStampPrecision : String  = "%.2f"
    static let csvSeparator = ","
    static let sampleFrequency = 30.0
}
