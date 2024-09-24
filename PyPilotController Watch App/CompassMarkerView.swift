//
//  CompassMarkerView.swift
//  PyPilotController Watch App
//
//  Created by Francisco Gorina Vanrell on 6/9/24.
//

import Foundation
import SwiftUI

struct Marker: Hashable {
    let degrees: Double
    let label: String

    init(degrees: Double, label: String = "") {
        self.degrees = degrees
        self.label = label
    }

    func degreeText() -> String {
        return String(format: "%.0f", self.degrees)
    }

    static func markers() -> [Marker] {
        return [
            Marker(degrees: 0, label: "N"),
            Marker(degrees: 30),
            Marker(degrees: 60),
            Marker(degrees: 90, label: "E"),
            Marker(degrees: 120),
            Marker(degrees: 150),
            Marker(degrees: 180, label: "S"),
            Marker(degrees: 210),
            Marker(degrees: 240),
            Marker(degrees: 270, label: "W"),
            Marker(degrees: 300),
            Marker(degrees: 330)
        ]
    }
    
    static func rudderMarkers() -> [Marker] {
        return [
            Marker(degrees: -30),
            Marker(degrees: -20),
            Marker(degrees: -10),
            Marker(degrees: 0),
            Marker(degrees: 10),
            Marker(degrees: 20),
            Marker(degrees: 30)
        ]
    
    }
}

struct CompassMarkerView: View {
    let marker: Marker
    let compassDegress: Double

    var body: some View {
        VStack {
            Text(marker.degreeText())
                .font(.system(size: 12, weight: .light))
                .fontWeight(.light)
                .rotationEffect(self.textAngle())
            
            Capsule()
                .frame(width: self.capsuleWidth(),
                       height: self.capsuleHeight())
                .foregroundColor(self.capsuleColor())
            
            Text(marker.label)
                .font(.system(size: 12, weight: .bold))
                .rotationEffect(self.textAngle())
                .padding(.bottom, 90) // 180
        }.rotationEffect(Angle(degrees: marker.degrees))
    }
    
    private func capsuleWidth() -> CGFloat {
        return self.marker.degrees == 0 ? 5 : 2
    }

    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 20 : 10//45 : 30
    }

    private func capsuleColor() -> Color {
        return self.marker.degrees == 0 ? .red : .gray
    }

    private func textAngle() -> Angle {
        return Angle(degrees: -self.compassDegress - self.marker.degrees)
    }
}


struct RudderMarkerView: View {
    let marker: Marker
   
    var body: some View {
        VStack {
            Text(marker.degreeText())
                .font(.system(size: 12, weight: .light))
                .fontWeight(.light)
                .rotationEffect(self.textAngle())
            
            Capsule()
                .frame(width: self.capsuleWidth(),
                       height: self.capsuleHeight())
                .foregroundColor(self.capsuleColor())
            
            Text(marker.label)
                .font(.system(size: 12, weight: .bold))
                .rotationEffect(self.textAngle())
                .padding(.bottom, 150) // 180
        }.rotationEffect(Angle(degrees: 180 - (marker.degrees * 2)))
            .offset(x: 0, y: -40)
    }
    
    private func capsuleWidth() -> CGFloat {
        return self.marker.degrees == 0 ? 5 : 2
    }

    private func capsuleHeight() -> CGFloat {
        return self.marker.degrees == 0 ? 20 : 10//45 : 30
    }

    private func capsuleColor() -> Color {
        return self.marker.degrees == 0 ? .red : .gray
    }

    private func textAngle() -> Angle {
        return Angle(degrees: 180 - self.marker.degrees)
    }
}
