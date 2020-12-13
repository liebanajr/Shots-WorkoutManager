//
//  Log.swift
//  Shots
//
//  Created by Juan I Rodriguez on 06/04/2020.
//  Copyright © 2020 Juan I Rodriguez. All rights reserved.
//

import Foundation

enum LOGLEVEL{
    case DEBUG
    case TRACE
    case INFO
    case WARNING
    case ERROR
}

struct Log {
        
    static func debug(_ message: String){
        if K.minLogLevel == .DEBUG {
            print("\(Date()) 🐜 - \(message)")
        }
    }
    
    static func trace(_ message: String){
        if K.minLogLevel == .TRACE || K.minLogLevel == .DEBUG {
            print("\(Date()) 🔘 - \(message)")
        }
    }
    
    static func info(_ message: String){
        if K.minLogLevel == .TRACE || K.minLogLevel == .INFO || K.minLogLevel == .DEBUG{
            print("\(Date()) ℹ️ - \(message)")
        }
    }
    
    static func warning(_ message: String){
        if K.minLogLevel == .TRACE || K.minLogLevel == .INFO || K.minLogLevel == .WARNING || K.minLogLevel == .DEBUG {
            print("\(Date()) ⚠️ - \(message)")
        }
    }
    
    static func error(_ message: String, callFunctionName : String = #function, callFileName : String = #file, callLine : Int = #line){
        print("\(Date()) ❌ - \(message) - 🕵️‍♀️ File: \(callFileName), Line: \(callLine)")
    }

}
