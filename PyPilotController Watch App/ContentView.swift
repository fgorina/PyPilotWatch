//
//  ContentView.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 5/9/24.
//
import Foundation
import SwiftUI

enum FieldName {
    case command
    case mode
    
}
struct ContentView: View {
    
    @Environment(\.scenePhase) var phase : ScenePhase
    @StateObject var server = PyPilot()
    
    
    @State var commandEditable = false
    @State var modeEditable = false
    
    @State var aboutToTackStarboard = false
    @State var aboutToTackPort = false
    
    @FocusState private var focusField : FieldName?
    
    @State private var focusCommand = false
    @State private var focusMode = false
    
    
    
    let modeNames = [ "Compass", "GPS", "Wind", "True Wind"]
    
    var body: some View {
        NavigationStack{
            ZStack{
                VStack{
                    if !server.engaged {  // Show rudder angle!!!
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
                               height:200)
                        .onTapGesture {
                            server.doSendRudderAngle(0.0)
                        }
                        
                    }else { // Show rhumb
                        ZStack {
                            ForEach(Marker.markers(), id: \.self) { marker in
                                CompassMarkerView(marker: marker,
                                                  compassDegress: -server.heading)
                            }
                            Text("\(Int(server.editedCommand.rounded()))")
                                .font(.system(size: 20))
                                .focusable(focusCommand)
                                .focused($focusField, equals: .command)
                                .padding([.leading, .trailing], 5)
                                .rotationEffect(Angle(degrees: server.heading))
                                .border(focusField == .command ? .green : .clear)
                                .digitalCrownRotation($server.editedCommand, from: !server.engaged ? -30 : 0.0, through: !server.engaged ? 30 : 359.0, by: 1.0, sensitivity: .medium, isContinuous: server.engaged, isHapticFeedbackEnabled: true)
                                .onTapGesture {
                                    if focusField == .command {
                                        
                                        if !server.engaged {
                                            server.doSendRudderAngle(server.editedCommand)
                                        }else{
                                            server.setCommand(server.editedCommand)
                                        }
                                        focusField = nil
                                        focusCommand = false
                                        focusMode = false
                                        
                                    }else{
                                        focusCommand = true
                                        focusMode = false
                                        focusField = .command
                                    }
                                }
                        }
                        .frame(width: 220  ,
                               height:200)
                        .rotationEffect(Angle(degrees: -server.heading))
                    }
               
                    HStack{
                        if !server.engaged {
                            Image(systemName: "play.circle")
                                .foregroundColor(.green)
                                .onTapGesture {
                                    if server.connectionState == .connected {
                                        server.engage()
                                    }
                                }
                            
                        }else{
                            Image(systemName: "stop.circle")
                                .frame(height: 10)
                                .foregroundColor(.red)
                                .onTapGesture {
                                    if server.connectionState == .connected {
                                        server.disengage()
                                    }
                                }
                        }
                        
                        
                        Text("\(modeNames[Int(server.editedMode)])")
                            .frame(width: 80)
                            .focusable(focusMode)
                            .focused($focusField, equals: .mode)
                            .padding([.leading, .trailing], 10)
                            .padding([.top, .bottom], 5)
                            .digitalCrownRotation($server.editedMode, from: 0.0, through: 3.0, by: 1.0, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: focusMode)
                            .border(focusMode ? .green : .clear)
                            .onTapGesture {
                                if focusMode{
                                    server.setMode(PyPilot.modes[Int(server.editedMode)])
                                    server.editedCommand = Double(!server.engaged ? server.rudderAngle : server.command)
                                        focusField = nil
                                        focusMode = false
                                        focusCommand = false
                                }else{
                                    server.editedMode = Double(PyPilot.modes.firstIndex(where: { e in
                                        e == server.mode
                                    }) ?? 0)
                                    focusMode = true
                                    focusCommand = false
                                    focusField = .mode
                                   
                                }
                            }
                        
                        Image(systemName: "circle.fill")
                            .frame(height: 10)
                            .foregroundColor(server.connectionState == .connected ? .green : .red)
                            .onTapGesture {
                                if server.connectionState == .disconnected {
                                    server.connect()
                                }
                            }
                        
                    }.padding([.top], -30)
                    
                }.blur(radius: server.connectionState != .connected ? 4.0 : 0.0)
                if server.connectionState != .connected {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if server.connectionState == .disconnected {
                                server.connect()
                            }
                        }
                    Text("Tap to connect")
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }else if server.errorMessage != nil &&   !server.errorMessage!.isEmpty {
                    Capsule()
                        .background(.ultraThinMaterial)
                        .frame(width: 180, height: 40)
                        .onTapGesture {
                            server.errorMessage = nil
                        }
                    Text(server.errorMessage!)
                    
                }
                
            }.toolbar{
                ToolbarItem(placement: .topBarLeading){
                    Image(systemName: !server.engaged ? "arrow.left" : "arrow.turn.up.left")
                        .foregroundColor(aboutToTackPort ? .orange :
                                            (((server.tackState == .tacking &&
                                               server.tackDirection == .port) || server.rudderCommand == .port) ? .green : .primary))
                    
                    //.frame(width: 50, height: 30)
                        .onTapGesture {
                            if !server.engaged{
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
                            if(server.engaged){
                                
                                WKInterfaceDevice.current().play(.success)
                                if aboutToTackPort {
                                    aboutToTackPort = false
                                }else{
                                    aboutToTackPort = true
                                    aboutToTackStarboard = false
                                }
                            }
                        }
                }
               
                
                ToolbarItem(placement: .topBarTrailing){
                    Image(systemName: !server.engaged ? "arrow.right" : "arrow.turn.up.right")
                        .foregroundColor(aboutToTackStarboard ? .orange :
                                            (((server.tackState == .tacking &&
                                               server.tackDirection == .starboard) || server.rudderCommand == .starboard) ? .green : .primary))
                    //.frame(width: 50, height: 30)
                        .onTapGesture {
                            if !server.engaged {
                                
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
                            if(server.engaged){
                                WKInterfaceDevice.current().play(.success)
                                if aboutToTackStarboard {
                                    aboutToTackStarboard = false
                                }else{
                                    aboutToTackStarboard = true
                                    aboutToTackPort = false
                                }
                            }
                        }
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
