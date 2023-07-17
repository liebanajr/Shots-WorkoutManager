//
//  workoutSessionDetails.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation
import Combine

public class ShotsSessionDetails : ObservableObject {
    
    @Published public var cumulativeCaloriesBurned : Int
    @Published public var cumulativeDistance : Int
    @Published public var currentHeartRate : Int
    @Published public var endCounter : Int
    @Published public var arrowCounter : Int
    public var averageHeartRate : Int
    public var maxHeartRate : Int
    public var maxHRAtEnd : Int
    public var minHRAtEnd : Int
    public var minHeartRate : Int
    public var elapsedSeconds : Int
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
