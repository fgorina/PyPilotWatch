//
//  ContentView.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 5/9/24.
//
import Foundation
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var phase : ScenePhase
    @StateObject var server = PyPilot()
    
    
    @State var commandEditable = false
    @State var modeEditable = false

    @State var aboutToTackStarboard = false
    @State var aboutToTackPort = false
     
    @FocusState private var modeFocusState : Bool
    @FocusState private var targetFocusState : Bool
     
    
    let modeNames = [ "Compass", "GPS", "Wind", "True Wind", "Rudder"]
    
    var body: some View {
        ZStack{
        VStack{
            HStack{
                Image(systemName: server.mode == .rudder ? "arrow.left" : "arrow.turn.up.left")
                    .foregroundColor(aboutToTackPort ? .orange :
                                        (((server.tackState == .tacking &&
                                           server.tackDirection == .port) || server.rudderCommand == .port) ? .green : .primary))
                
                    .frame(width: 50, height: 30)
                    .onTapGesture {
                        if server.mode == .rudder {
                            if server.rudderCommand == .port {
                                server.sendRudderCommand(.none)
                            }else{
                                server.sendRudderCommand(.port)
                            }
                        }else if aboutToTackPort {
                            server.tackPort()
                            aboutToTackPort = false
                        } else if server.tackState == .tacking && server.tackDirection == .port{
                            server.cancelTack()
                            aboutToTackPort = false
                            aboutToTackStarboard = false
                        }
                    }
                    .onLongPressGesture {
                        if(server.mode != .rudder){
                            
                            WKInterfaceDevice.current().play(.success)
                            if aboutToTackPort {
                                aboutToTackPort = false
                            }else{
                                aboutToTackPort = true
                                aboutToTackStarboard = false
                            }
                        }
                    }.padding([.top], 15)
                Spacer()
                
                
                Text("\(Int(server.editedCommand.rounded()))")
                    .font(.system(size: 24))
                    .focusable(commandEditable)
                    .focused($targetFocusState)
                    .padding([.leading, .trailing], 10)
                    .border(targetFocusState ? .green : .clear)
                    .digitalCrownRotation($server.editedCommand, from: server.mode == .rudder ? -30 : 0.0, through: server.mode == .rudder ? 30 : 359.0, by: 1.0, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
                    .onTapGesture {
                        if commandEditable {
                            if targetFocusState {
                                if server.mode == .rudder{
                                    server.doSendRudderAngle(server.editedCommand)
                                }else{
                                    server.setCommand(server.editedCommand)
                                }
                                targetFocusState = false
                                modeFocusState = false
                            }
                            //mode = Double(server.mode)
                            
                            commandEditable = false
                        }else{
                            commandEditable = true
                            modeFocusState = false
                            targetFocusState = true
                        }
                        
                    }
                
                Spacer()
                Image(systemName: server.mode == .rudder ? "arrow.right" : "arrow.turn.up.right")
                    .foregroundColor(aboutToTackStarboard ? .orange :
                                        (((server.tackState == .tacking &&
                                           server.tackDirection == .starboard) || server.rudderCommand == .starboard) ? .green : .primary))
                    .frame(width: 50, height: 30)
                    .onTapGesture {
                        if server.mode == .rudder {
                            
                            if server.rudderCommand == .starboard {
                                server.sendRudderCommand(.none)
                            }else{
                                server.sendRudderCommand(.starboard)
                            }
                            
                        }else if aboutToTackStarboard {
                            server.tackStarboard()
                            aboutToTackStarboard = false
                        } else if server.tackState == .tacking && server.tackDirection == .starboard{
                            server.cancelTack()
                            aboutToTackPort = false
                            aboutToTackStarboard = false
                        }
                    }
                    .onLongPressGesture {
                        if(server.mode != .rudder){
                            WKInterfaceDevice.current().play(.success)
                            if aboutToTackStarboard {
                                aboutToTackStarboard = false
                            }else{
                                aboutToTackStarboard = true
                                aboutToTackPort = false
                            }
                        }
                    }.padding([.top], 15)
            }
            
            if server.mode == .rudder {  // Show rudder angle!!!
                ZStack(alignment: Alignment(horizontal: .center, vertical: .center))
                {
                    ForEach(Marker.rudderMarkers(), id: \.self) { marker in
                        RudderMarkerView(marker: marker) // Shoud be server.heading
                    }
                    VStack{
                        
                        Text("\(Int(server.heading.rounded()))").font(.system(size: 24)).offset(x: 0.0, y: -25)
                        Capsule().frame(width: 3,
                                        height: 50)
                        .offset(x: 0, y: 10)
                        .foregroundColor(.green)
                        
                        .rotationEffect(Angle(degrees:  -(server.rudderAngle * 2)), anchor: UnitPoint.top)
                        .offset(x: 0, y: -35)
                    }
                }
                .frame(width: 200  ,
                       height:139)
                .onTapGesture {
                    server.doSendRudderAngle(0.0)
                }
                
                
                
            }else { // Show rhumb
                ZStack {
                    ForEach(Marker.markers(), id: \.self) { marker in
                        CompassMarkerView(marker: marker,
                                          compassDegress: -server.heading)
                    }
                    Text("\(Int(server.heading.rounded()))").font(.system(size: 16))
                        .rotationEffect(Angle(degrees: server.heading))
                }
                .frame(width: 200  ,
                       height:139)
                .rotationEffect(Angle(degrees: -server.heading))
            }
            
            HStack{
                if server.mode == .rudder {
                    Spacer().frame(width: 10).padding(.leading, 25)
                }else{
                    Image(systemName: "stop.circle")
                        .foregroundColor(.red)
                        .frame(width: 10).padding(.leading, 25)
                        .disabled(server.mode == .rudder)
                        .onTapGesture {
                            if server.connectionState == .connected {
                                server.setMode(.rudder)
                            }
                        }
                }
                Spacer()
                Text("\(modeNames[Int(server.editedMode)])").font(.system(size: 18))
                    .focusable(modeEditable)
                    .padding([.leading, .trailing], 10)
                    .padding([.top, .bottom], 5)
                    .focused($modeFocusState)
                    .border(modeFocusState ? .green : .clear)
                    .digitalCrownRotation($server.editedMode, from: 0.0, through: 4.0, by: 1.0, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    .onTapGesture {
                        if modeEditable{
                            if modeFocusState {
                                server.setMode(PyPilot.modes[Int(server.editedMode)])
                            }
                            server.editedCommand = Double(server.mode == .rudder ? server.rudderAngle : server.command)
                            modeEditable = false
                            targetFocusState  = false
                            modeFocusState = false
                        }else{
                            modeEditable = true
                            targetFocusState = false
                            modeFocusState = true
                            
                        }
                    }
                Spacer()
                
                Image(systemName: "circle.fill")
                    .foregroundColor(server.connectionState == .connected ? .green : .red)
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 25)
                    .onTapGesture {
                        if server.connectionState == .disconnected {
                            server.connect()
                        }
                    }
            }
            
        }
            if server.connectionState != .connected {
                RoundedRectangle(cornerRadius: 15)
                    .background(.ultraThinMaterial)
                    .frame(width: 170, height: 120)
                    .onTapGesture {
                        if server.connectionState == .disconnected {
                            server.connect()
                        }
                    }
                VStack{
                    Text("Disconnected!").foregroundColor(.red).fontWeight(.bold)
                    Text("Tap to reconnect").foregroundColor(.red).fontWeight(.bold)
                }
            }
    }.onChange(of: phase) { oldValue, newValue in
                switch newValue {
                case .active:
                    server.connect()
                    server.editedCommand  = server.command
                    server.editedMode = Double(PyPilot.modes.firstIndex(where: { e in
                        e == server.mode
                    }) ?? 0)
                    
                    break;
                case .inactive:
                    server.close()
                    break;
                default:
                    server.close()
                    break
                }
            }

        }
}

#Preview {
    ContentView()
}
