//
//  PyPilot.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 5/9/24.
//

import Foundation
import CoreBluetooth


enum BLEState : String {
    case on = "On"
    case off = "Off"
    case disconnected = "Disc"
    case scanning = "Scan"
    case connecting = "Cing"
    case connected = "Cted"
}


class PyPilot : NSObject,   ObservableObject{
    
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
    
    enum PilotMode : String {
        case rudder = "rudder"
        case compass = "compass"
        case gps = "gps"
        case wind = "wind"
        case trueWind = "true wind"
    }
    
    static var modes : [PilotMode] = [.compass, .gps, .wind, .trueWind, .rudder]
    //static var shared : PyPilot = PyPilot()
    @Published var connectionState : BLEState = .off
    
    
    @Published var editedCommand : Double = 90.0
    @Published var editedMode : Double = 0.0
    @Published var engaged : Bool = false
    @Published var heading : Double = 120.0
    @Published var command : Double = 90.0
    @Published var mode : PilotMode = .compass
    @Published var rudderAngle : Double = 10
    @Published var tackState : TackState = .none
    @Published var tackDirection : TackDirection = .none
    
    @Published var rudderCommand : TackDirection = .none
    
    var minRudder = -30.0
    var maxRudder = 30.0
    
    private var rudderTimer : Timer?
    
    var oldState : String = ""
    
    // MARK:  - BLE Properties
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var pilotStateCharacteristic: CBCharacteristic?

    private let serviceUUID = CBUUID(string: "f85015df-6af5-4ee3-a8cb-a8f7250d4466")
    private let commandUUID = CBUUID(string: "02804fff-8c38-485f-964a-474dc4f179b2")
    private let stateUUID = CBUUID(string: "de7f5161-6f48-4c9a-aacc-6079082e6cc7")

      
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("Creating CentralManager")
    }
    
    
    
    // MARK: - Public Methods
    
    func startScanning() {
        // Start scanning for BLE peripherals
        print("Starting scan for services \(serviceUUID.uuidString)")
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        DispatchQueue.main.async {
            self.connectionState = .scanning
        }
    }
    
    func stopScanning() {
        // Stop scanning for BLE peripherals
        print("Stop Scanning")
        centralManager.stopScan()
    }
    
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        // Connect to the specified peripheral
        print("Connecting to peripheral \(peripheral.name ?? "")")
        centralManager.connect(peripheral, options: nil)
    }
    
    func writeValueToCommandCharacteristic(_ value: String) {
        
        if let data = value.data(using: .utf8){
            // Check if the commandCharacteristic is valid and connectedPeripheral is set
            guard let commandChar = commandCharacteristic, let peripheral = connectedPeripheral else {
                print("Invalid command characteristic or not connected to a peripheral.")
                return
            }
            
            // Write the value to the write-only characteristic
            peripheral.writeValue(data, for: commandChar, type: .withResponse)
        }
        
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
    
    func engage(){
        writeValueToCommandCharacteristic("E")
    }
    
    func disengage(){
        writeValueToCommandCharacteristic("D")
    }

    
    
    func setCommand(_ command : Double){
        writeValueToCommandCharacteristic("C\(command)")
        //command = rhumb
        print("Sending \(command) to PyPilot")
    }
    
    func setMode(_ mode : PilotMode){
        writeValueToCommandCharacteristic("M"+mode.rawValue)
        //self.mode = mode
        print("Setting mode to  \(mode) to PyPilot")
    }
    func sendTackTo(_ direction : TackDirection){
        switch direction {
        case .port:
            writeValueToCommandCharacteristic("TP")
            
        case .starboard:
            writeValueToCommandCharacteristic("TS")
            
        default:
            break
        }

    }
    func tackPort(){
        //tackState = .tacking
        //tackDirection = .port
        sendTackTo(.port)
        print("Sending tack port to PyPilot")
    }
    
    func tackStarboard(){
        //tackState = .tacking
        //tackDirection = .starboard
        sendTackTo(.starboard)
        print("Sending tack Starboard to PyPilot")
    }
    
    func cancelTack(){
        writeValueToCommandCharacteristic("X")
        //tackState = .none
        //tackDirection = .none
        print("Tacking cancelled")
    }
    
    func sendRudderCommand(_ direction : TackDirection){
        rudderCommand = direction
        if let timer = rudderTimer {
            timer.invalidate()
            rudderTimer = nil
        }
        rudderCommand = direction
        if rudderCommand != .none{
            rudderTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { t in
                if self.rudderAngle >= 30 || self.rudderAngle <= -30{
                    self.rudderTimer?.invalidate()
                    self.rudderTimer = nil
                    return
                }else{
                    self.doSendRudderCommand(self.rudderCommand)
                }
            })
            
        }
    }
    
    func doSendRudderCommand(_ direction : TackDirection){
        switch direction {
        case .port:
            writeValueToCommandCharacteristic("RP")
            
        case .starboard:
            writeValueToCommandCharacteristic("RS")
            
        default:
            break
        }
        
    }
    
    func doSendRudderAngle(_ angle : Double){
        writeValueToCommandCharacteristic("Z\(angle)")
    }
    
    
}

extension PyPilot : CBCentralManagerDelegate, CBPeripheralDelegate {
   
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Bluetooth is powered on, start scanning for peripherals
            print("Bluetooth powered ON")
            DispatchQueue.main.async {
                self.connectionState = .on
            }
            startScanning()
        case .poweredOff:
            // Bluetooth is powered off
            DispatchQueue.main.async {
                self.connectionState = .off
            }
            print("Bluetooth is powered off.")
            // Handle the situation accordingly
        default:
            print("BLE Central State \(central.state)")
            break
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Called when a peripheral is discovered during scanning
        // You can filter peripherals based on your requirements and connect to the desired one
        
        print("Found \(peripheral.name ?? "" )")
        if peripheral.name == "PyPilot" || true{       //TODO: Substitute with parameter
            DispatchQueue.main.async {
                self.connectionState = .connecting
            }
            connectedPeripheral = peripheral
            connectToPeripheral(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Called when a connection to a peripheral is successful
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        
        // Discover services and characteristics of the connected peripheral
        connectedPeripheral?.discoverServices(nil)
        
        print("Connected to peripheral: \(peripheral)")
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: Error?) {
        
        print("Disconnected from  peripheral: \(peripheral)")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        
    }
    // MARK: - CBPeripheralDelegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        // Discover characteristics for each service
        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID{
                    print("Discovered service: \(service.uuid.uuidString)")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        // Check for the characteristics you need
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid.uuidString)")
                if characteristic.uuid == commandUUID {
                    commandCharacteristic = characteristic
                } else if characteristic.uuid == stateUUID {
                    pilotStateCharacteristic = characteristic
                    // Enable notifications for the read/notify characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            
            if commandCharacteristic != nil && pilotStateCharacteristic != nil {
                print("Now connected to device")
                DispatchQueue.main.async {
                    self.connectionState = .connected
                }
            }
        }
        
        // You can perform additional actions here if needed
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Called when the value of a characteristic is updated (e.g., for read/notify characteristics)
        if characteristic.uuid == pilotStateCharacteristic?.uuid {
            if let value = characteristic.value {
                if let svalue = String(data: value, encoding: .utf8){
                    
                    if svalue != oldState {
                        oldState = svalue
                        print("Received value for pilotStateCharacteristic: \(svalue)")
                        
                        let command = svalue[svalue.startIndex]
                        switch command  {
                        
                    case "E":
                        DispatchQueue.main.async{
                            self.engaged = true
                        }
                        
                    case "D":
                        DispatchQueue.main.async{
                            self.engaged = false
                        }
                        
                    case "R":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let v = Double(sparam){
                            DispatchQueue.main.async{
                                self.rudderAngle =  v
                            }
                        }
                        
                    case "H":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let v = Double(sparam){
                            DispatchQueue.main.async{
                                self.heading =  v
                            }
                        }
                        
                    case "C":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let v = Double(sparam){
                            DispatchQueue.main.async{
                                self.command =  v
                                self.editedCommand = v
                            }
                        }
                        
                    case "M":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let iv = Int(sparam){
                            if iv >= 0 && iv < PyPilot.modes.count{
                                let v = PyPilot.modes[iv]
                                DispatchQueue.main.async{
                                    self.mode = v
                                    self.editedMode = Double(iv)
                                    
                                    if (self.mode != .rudder){
                                        self.editedCommand = self.command
                                    }else{
                                        self.editedCommand = self.rudderAngle
                                    }
                                }
                            }
                        }
                        
                    case "T":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let iv = Int(sparam){
                            if let v = TackState(rawValue: iv){
                                DispatchQueue.main.async{
                                    self.tackState = v
                                }
                            }
                        }
                        
                    case "U":
                        let sparam = svalue[svalue.index(svalue.startIndex, offsetBy: 1)..<svalue.endIndex]
                        if let iv = Int(sparam){
                            if let v = TackDirection(rawValue: iv){
                                DispatchQueue.main.async{
                                    self.tackDirection = v
                                }
                            }
                        }
                        
                    default:
                        break
                        
                    }
                }
                }
            }
        }
    }
}
