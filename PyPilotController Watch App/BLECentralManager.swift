//
//  File.swift
//  Molinet K
//
//  Created by Francisco Gorina Vanrell on 07/09/24.
//


import Foundation

import CoreBluetooth


class BLECentralManager: {
    
    
    static var shared : BLECentralManager = BLECentralManager()

    // MARK: - Properties
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var pilotStateCharacteristic: CBCharacteristic?

    
    public var pilotState : PilotState = PilotState()

    @Published var connectionState : BLEState = .off
    
    @Published var chain : Double = 0.0
    @Published var depth : Double = 0.0

    // Add other properties as needed
    
    
    private let serviceUUID = CBUUID(string: "f85015df-6af5-4ee3-a8cb-a8f7250d4466")
    private let commandUUID = CBUUID(string: "02804fff-8c38-485f-964a-474dc4f179b2")
    private let stateUUID = CBUUID(string: "de7f5161-6f48-4c9a-aacc-6079082e6cc7")
    
    #if os(iOS)
    private var signalkServer : SignalKServer?
    #endif
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("Creating CentralManager")
    }
    

    

    func connect(){
         
        if let peripheral = connectedPeripheral {
            connectToPeripheral(peripheral)
        }else{
            if centralManager.state == .poweredOn{
                startScanning()
            }
        }
    }
    
    func close(){
        
        if let peripheral = connectedPeripheral, peripheral.state == .connected {
            centralManager.cancelPeripheralConnection(peripheral)
            
            #if os(iOS)
            if let sk = signalkServer {
                sk.close()
            }
            #endif
        }
    }

    // Add other methods as needed
    
}

extension BLECentralManager {
    

    func engage(){
        writeValueToCommandCharacteristic("E")
    }
    
    func disengage(){
        writeValueToCommandCharacteristic("D")
    }
    
    func setMode(_ mode : PilotMode){
        writeValueToCommandCharacteristic("M"+mode.rawValue)
    }
    
    func setCommand(_ command : Double){
        writeValueToCommandCharacteristic("C\(command)")
    }
    
    func tack(_ direction : TackDirection){
        
        switch direction {
        case .port:
            writeValueToCommandCharacteristic("TP")
            
        case .starboard:
            writeValueToCommandCharacteristic("TS")
            
        default:
            break
        }
        
    }
    
    func cancelTack(){
        writeValueToCommandCharacteristic("X")
    }
    
    func moveRudder(_ direction : TackDirection){
        switch direction {
        case .port:
            writeValueToCommandCharacteristic("RP")
            
        case .starboard:
            writeValueToCommandCharacteristic("RS")
            
        default:
            break
        }
       
    }
    
   
}

// Usage example:

let bleCentralManager = BLECentralManager()

// Assuming you have a Data object to write to the write-only characteristic
//let commandData = "YourCommandData".data(using: .utf8)!
//bleCentralManager.writeValueToCommandCharacteristic(commandData)
