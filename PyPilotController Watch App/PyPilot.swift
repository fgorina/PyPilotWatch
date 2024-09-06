//
//  PyPilot.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 5/9/24.
//

import Foundation

class PyPilot : ObservableObject{
    
    enum TackState : Int {
        case none = 0
        case begin = 1
        case waiting = 2
        case tacking = 3
    }
    
    enum TackDirection : Int {
        case port = -1
        case none = 0
        case starboard = 1
    }
    static var shared : PyPilot = PyPilot()
    
    var heading : Double = 180.0
    var target : Double = 90.0
    var mode : Int = 0
    var rudderAngle : Double = 0.0
    var tackState : TackState = .none
    var tackDirection : TackDirection = .none
    
    
    init() {
        print("Creating a PyPilot object")
    }
    
    func connect(){
         print("Connecting to PyPilot")
        
        
    }
    
    func close(){
        print("Disconnecting to PyPilot")
    }
    
    func setTarget(_ rhumb : Double){
        target = rhumb
        print("Sending \(rhumb) to PyPilot")
    }
    
    func setMode(_ mode : Int){
        self.mode = mode
        print("Setting mode to  \(mode) to PyPilot")
    }
    
    func tackPort(){
        print("Sending tack port to PyPilot")
    }
    
    func tackStarboard(){
        print("Sending tack Starboard to PyPilot")
    }
}
