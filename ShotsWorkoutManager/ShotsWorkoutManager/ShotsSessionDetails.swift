//
//  workoutSessionDetails.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

public class ShotsSessionDetails : NSObject{
    
    public var cumulativeCaloriesBurned : Int
    public var cumulativeDistance : Int
    public var averageHeartRate : Int
    public var maxHeartRate : Int
    public var maxHRAtEnd : Int
    public var minHRAtEnd : Int
    public var minHeartRate : Int
    public var currentHeartRate : Int
    public var endCounter : Int
    public var elapsedSeconds : Int
    public var arrowCounter : Int
    public var endDate : Date?
    public var startDate : Date
    public var sessionType : String?
    
    public let sessionId : String
    
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
