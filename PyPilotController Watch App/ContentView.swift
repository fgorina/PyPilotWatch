//
//  ContentView.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 5/9/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var phase : ScenePhase
    @ObservedObject var server = PyPilot.shared

    @State var targetRhumb : Double = 0
    @State var currentRhumb : Double = 360
    @State var mode = 0.0
    @State var editable = false
    
    @FocusState private var targetFocusState : Bool
    @FocusState private var modeFocusState : Bool
    
    let modeNames = ["Rudder", "Compass", "GPS", "Wind", "True Wind"]
        var body: some View {
        
            VStack{
                Text("\(Int(targetRhumb.rounded()))")
                    .font(.title)
                    .focusable(editable)
                    .focused($targetFocusState)
                    .padding([.leading, .trailing], 10)
                    .border(targetFocusState ? .green : .clear)
                    .digitalCrownRotation($targetRhumb, from: 0.0, through: 359.0, by: 1.0, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
                    .onTapGesture {
                        if editable {
                            if targetFocusState {
                                server.setTarget(targetRhumb)
                            }
                            mode = Double(server.mode)
                            
                            editable = false
                        }else{
                            editable = true
                            targetFocusState = true
                        }
                    }
                    
                Spacer()
                HStack{
                    Image(systemName: "arrow.turn.up.left")
                        .frame(width: 50, height: 60)
                        .onLongPressGesture {
                            WKInterfaceDevice.current().play(.success)
                            server.tackPort()
                     }
                    Spacer()
                    Text("\(Int(server.heading))")
                        .font(.largeTitle)
                        
                        .onTapGesture {
                            if editable {
                                editable = false
                                targetRhumb = Double(server.target)
                                mode = Double(server.mode)
                                WKInterfaceDevice.current().play(.failure)
                            }
                        }
                    Spacer()
                    Image(systemName: "arrow.turn.up.right")
                        .frame(width: 50, height: 60)
                        .onLongPressGesture {
                            WKInterfaceDevice.current().play(.success)
                            server.tackStarboard()
                    }
                }
                Spacer()
                     
                Text("\(modeNames[Int(mode)])").font(.title)
                    .focusable(editable)
                    .padding([.leading, .trailing], 10)
                    .focused($modeFocusState)
                    .border(modeFocusState ? .green : .clear)
                    .digitalCrownRotation($mode, from: 0.0, through: 4.0, by: 1.0, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    .onTapGesture {
                        if editable{
                            if modeFocusState {
                                server.setMode(Int(mode))
                            }
                            targetRhumb = Double(server.target)
                            
                            editable = false
                        }else{
                            editable = true
                            modeFocusState = true
                        }
                    }
                    
            } .onChange(of: phase) { oldValue, newValue in
                switch newValue {
                case .active:
                    server.connect()
                    targetRhumb = server.target
                    currentRhumb = server.heading
                    mode = Double(server.mode)
                    
                    break;
                case .inactive:
                    server.close()
                    break;
                default:
                    break
                }
            }

        }
}

#Preview {
    ContentView()
}
