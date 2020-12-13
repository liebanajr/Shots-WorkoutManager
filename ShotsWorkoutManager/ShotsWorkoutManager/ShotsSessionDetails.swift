//
//  workoutSessionDetails.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

class ShotsSessionDetails : NSObject{
    
    var cumulativeCaloriesBurned : Int
    var cumulativeDistance : Int
    var averageHeartRate : Int
    var maxHeartRate : Int
    var maxHRAtEnd : Int
    var minHRAtEnd : Int
    var minHeartRate : Int
    var currentHeartRate : Int
    var endCounter : Int
    var elapsedSeconds : Int
    var arrowCounter : Int
    var endDate : Date?
    var startDate : Date
    var sessionType : String?
    
    let sessionId : String
    
    init(sessionId id: String) {
        self.cumulativeCaloriesBurned = 0
        self.cumulativeDistance = 0
        self.averageHeartRate = 0
        self.maxHeartRate = 40
        self.minHeartRate = 90
        self.currentHeartRate = 0
        self.endCounter = 1
        self.elapsedSeconds = 0
        self.arrowCounter = 0
        self.maxHRAtEnd = 1
        self.minHRAtEnd = 1
        self.startDate = Date()
        
        self.sessionId = id
    }
    
}
