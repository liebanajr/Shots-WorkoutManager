//
//  WorkoutController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 12/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import HealthKit
import WatchConnectivity

enum ShotsSessionType : String{
    case FREE = "free"
    case GOAL = "goal"
    case MANUAL = "manual"
}

protocol ShotsWorkoutDelegate {
    func workoutManager(didStartWorkout withData: ShotsSessionDetails)
    func workoutManager(didPauseWorkout withData: ShotsSessionDetails)
    func workoutManager(didResumeWorkout withData: ShotsSessionDetails)
    func workoutManager(didStopWorkout withData: ShotsSessionDetails)
    func workoutManager(didUpdateSession data: ShotsSessionDetails)
    func workoutManager(didLockScreen withData: ShotsSessionDetails?)
}

class ShotsWorkoutManager: NSObject {
    
//    MARK: Singleton. Only one workout is allowed to run at a time
    
    static let shared = ShotsWorkoutManager()
    
//    MARK: Delegate
    
    var delegate: ShotsWorkoutDelegate?
    
//    MARK: HealthKit objects
    var workoutSession : HKWorkoutSession?
    var builder : HKLiveWorkoutBuilder?
    var healthStore : HKHealthStore
    var workoutConfiguration : HKWorkoutConfiguration
    
//    MARK: Dependencies
    var motionManager: ShotsMotionManager?
    var sessionData : ShotsSessionDetails?
    let wcSession = WCSession.default
    
//    MARK: State management
    var isWorkoutRunning : Bool?
    var isSaveWorkoutActive = true
        
    init(isSaveWorkoutActive saveWorkout : Bool = true) {
        healthStore = HKHealthStore()
        workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .archery
        workoutConfiguration.locationType = .outdoor
        isSaveWorkoutActive = saveWorkout
        super.init()
        
    }
    
//   MARK: Workout lifecycle
    
    func startWorkout(id sessionId : String, type sessionType: ShotsSessionType?){
        
        switch sessionType {
            case .FREE:
                    Log.trace("Starting free workout session")
                    //      Listen for prediction event
                motionManager = ShotsMotionManager(sampleFrequency: K.sampleFrequency)
                    motionManager?.startMotionUpdates()
            case .GOAL:
                    Log.trace("Starting goal workout session")
                    //      Listen for prediction event
                motionManager = ShotsMotionManager(sampleFrequency: K.sampleFrequency)
                    motionManager?.startMotionUpdates()
            case .MANUAL:
                        Log.trace("Starting manual workout session")
            default:
                Log.warning("Session type not recognized")
        }
        
//        WE don't create workout and helathkit objects if no workout save is needed (development)
        if isSaveWorkoutActive {
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
                builder = workoutSession!.associatedWorkoutBuilder()
                builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)

                workoutSession!.delegate = self
                builder!.delegate = self
            } catch {
                Log.warning("Unable to create workout session: \(error)")
            }
        } else {
            Log.warning("No healthkit objects are being created")
        }
        
        sessionData = ShotsSessionDetails(sessionId: sessionId)
        sessionData?.sessionType = sessionType?.rawValue ?? "no_type"
        
        workoutSession?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { (success, error) in
            guard success else {
                fatalError("Error collecting workout data: \(error!)")
            }
        }
        isWorkoutRunning = true
        WKInterfaceDevice.current().play(.start)
        delegate?.workoutManager(didStartWorkout: sessionData!)
    }
    
    func pauseWorkout(){
        if let isRunning = isWorkoutRunning{
            if !isRunning {
                Log.warning("Can't pause workout if it's not running")
                return
            }
            
            if sessionData?.sessionType == ShotsSessionType.MANUAL.rawValue {
                Log.error("Can't pause on a manual workout")
                return
            }
            workoutSession?.pause()
            motionManager?.pauseMotionUpdates()
            sessionData?.elapsedSeconds = Int(motionManager!.timeStamp)
            isWorkoutRunning = false
            WKInterfaceDevice.current().play(.stop)
            delegate!.workoutManager(didPauseWorkout: sessionData!)
            
        } else {
            Log.warning("Can't pause workout if it's not started")
        }
    }
    
    func resumeWorkout(){
        if let isRunning = isWorkoutRunning{
            if isRunning {
                Log.warning("Can't resume workout if it's already running")
                return
            }
            workoutSession?.resume()
            motionManager?.resumeMotionUpdates()
            isWorkoutRunning = true
            WKInterfaceDevice.current().play(.start)
            delegate!.workoutManager(didResumeWorkout: sessionData!)
        } else {
            Log.warning("Can't resume workout if it's not started")
        }
    }
    
    func stopWorkout(){
        
        if let isRunning = isWorkoutRunning, isRunning {
            Log.trace("Trying to end workout")
            workoutSession?.end()
            sessionData?.endDate = Date()
            builder?.endCollection(withEnd: Date()) { (success, error) in
                guard success else {
                    Log.error("Couldn't finish collection: \(error!)")
                    return
                }
                self.builder?.finishWorkout { (_, error) in
                    if error != nil {
                        Log.error("Couldn't finish workout: \(error!)")
                    }
                }
            }
                
            Log.trace("Trying to end workout")
            if sessionData?.sessionType == ShotsSessionType.MANUAL.rawValue{
                let startDate = sessionData?.startDate
                let endDate = sessionData?.endDate
                let interval = endDate?.timeIntervalSince(startDate!)
                sessionData?.elapsedSeconds = Int(interval!)
            } else {
                motionManager?.stopMotionUpdates()
                sessionData?.elapsedSeconds = Int(motionManager!.timeStamp)
            }
            isWorkoutRunning = nil
            WKInterfaceDevice.current().play(.stop)
            delegate?.workoutManager(didStopWorkout: sessionData!)
        } else {
            Log.warning("Can't stop workout if it's not running")
        }
            
    }
    
//    MARK: Session Data management
    
    func addArrow(){
        sessionData?.arrowCounter += 1
        delegate?.workoutManager(didUpdateSession: sessionData!)
    }
    
    func removeArrow(){
        if sessionData!.arrowCounter <= Int16(1) {
            sessionData?.arrowCounter = 0
        } else {
            sessionData?.arrowCounter -= 1
        }
        delegate?.workoutManager(didUpdateSession: sessionData!)
    }
    
//    MARK: Other functions
    
    func lockScreen(){
        if workoutSession?.state == .running{
            WKInterfaceDevice.current().enableWaterLock()
            delegate!.workoutManager(didLockScreen: sessionData)
        } else {
            Log.warning("Can't lock screen when no workout session is active")
        }
    }
}

// MARK: HKLiveWorkoutBuilderDelegate methods

extension ShotsWorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)!
            self.updateWorkoutForQuantityType(quantityType, statistics)
            
            delegate?.workoutManager(didUpdateSession: sessionData!)
        }
    }
    
    func updateWorkoutForQuantityType(_ quantityType: HKQuantityType, _ statistics: HKStatistics){
                    
        switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.meter()))
                sessionData?.cumulativeDistance = value
                return
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.kilocalorie()))
                sessionData?.cumulativeCaloriesBurned = value
                return
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let value = Int(statistics.mostRecentQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let maxValue = Int(statistics.maximumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let minValue = Int(statistics.minimumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let avgValue = Int(statistics.averageQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                
                sessionData?.currentHeartRate = value
                if maxValue > sessionData!.maxHeartRate {
                    sessionData!.maxHeartRate = maxValue
                }
                if minValue < sessionData!.minHeartRate {
                    sessionData!.minHeartRate = minValue
                }
                sessionData!.averageHeartRate = avgValue
                return
            default:
                return
        }
            
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        Log.trace("Workout builder collected event: \(workoutBuilder.dataSource!)")
    }
    
}

//    MARK: HKWorkoutSessionDelegate methods

extension ShotsWorkoutManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        let startState = getWorkoutSessionStateName(state: fromState)
        let endState = getWorkoutSessionStateName(state: toState)
        Log.trace("Workout session changed from \(startState) to \(endState)")
    }
    
    private func getWorkoutSessionStateName(state name : HKWorkoutSessionState) -> String{
        switch name {
            case .ended:
                 return "Ended"
            case .notStarted:
                return "Not started"
            case .paused:
                 return "Paused"
            case .prepared:
                 return "Prepared"
            case .running:
                 return "Running"
            case .stopped:
                 return "Stopped"
            default:
                 return "XXX"
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Log.error("Workout session failed with error: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        if event.type == .pauseOrResumeRequest {
            Log.info("Received pause or resume request")
            if let runningState = isWorkoutRunning {
                if runningState {
                    Log.info("Workout running. Pausing")
                    pauseWorkout()
                } else {
                    Log.info("Workout paused. Resuming")
                    resumeWorkout()
                }
            }
        }
    }
    
    
}