//
//  ContentView.swift
//  Ride Stro
//
//  Created by devon tomlin on 2024-07-28.
//

import Charts
import SwiftUI
import Combine
@_spi(Experimental) import MapboxMaps


struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isOnline = false
    @State private var earnings: Double = 0.00
    @State private var cancellable: AnyCancellable?
    @State private var offset = CGSize.zero
    @State private var finalOffset: CGFloat = 0
    @State private var isPanelOpen = false
    @State private var isMapCentered = true
    @State private var mapView: MapboxMaps.MapView? = nil
    
    var body: some View {
        ZStack {
            // Map View
            if let userLocation = locationManager.userLocation {
                MapView(
                    userLocation: userLocation,
                    isMapCentered: $isMapCentered,
                    mapView: $mapView
                )
                .ignoresSafeArea()
                
                VStack {
                    // Top icons: Hamburger menu and Lock icon
                    HStack {
                        Button(action: {
                            // Menu action
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .padding(20)
                                .bold()
                                .background(Color.white)
                                .foregroundColor(Color.pink)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                             
                        }
                        Spacer()
                        Button(action: {
                            // Security action
                        }) {
                            Image(systemName: "magnifyingglass")
                                .padding(15)
                                .bold()
                                .foregroundColor(Color.pink)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)

                        }
                    }
                    .padding([.leading, .trailing], 20)
                    .padding(.top, 15)
                    .opacity(isPanelOpen ? 0.0 : max(0, 1 - Double(abs(offset.height) / (UIScreen.main.bounds.height / 2))))
                    
                    // Earnings Badge at the Top, centered
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Text(attributedEarnings)
                                .font(.headline)
                        }
                        .padding(15)
                        .background(Color.black)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                        Spacer()
                    }
                    .padding(.top, -60)
                    .opacity(isPanelOpen ? 0.0 : max(0, 1 - Double(abs(offset.height) / (UIScreen.main.bounds.height / 2))))
                    
                    Spacer()
                    
                    // Sliding Panel with Go Online/Offline button
                    ZStack(alignment: .top) {
                        VStack {
                            if isOnline {
                                VStack(alignment: .center) {
                                    Text("Finding pings...")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    LoadingAnimation()
                                        .frame(height: 8)
                                        .padding(.horizontal, 10)
                                }
                            }
                            else
                            {
                                VStack(alignment: .center) {
                                    Text("You're offline.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            
                            VStack(alignment: .leading) {
                                Text("Earnings Trends in Kitchener-Waterloo")
                                    .font(.subheadline)
                                    .padding(.bottom, 5)
                               
                                DemandChartView()
                                    .frame(height: 120)
                                    .padding(.horizontal)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            
                            Spacer()
                            
                            // "Go Offline" button inside the panel
                            if isOnline {
                                Button(action: {
                                    withAnimation {
                                        isPanelOpen.toggle()
                                        isOnline.toggle()
                                    }
                                }) {
                                    Text("Go Offline")
                                        .padding()
                                        .frame(width: 150, height: 50)
                                        .background(Color.pink)
                                        .foregroundColor(.white)
                                        .cornerRadius(25)
                                        .shadow(radius: 5)
                                }
                                .padding(.bottom, 20)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .offset(y: isPanelOpen ? 0 : UIScreen.main.bounds.height / 2)
                        .offset(y: offset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    self.offset = gesture.translation
                                    self.finalOffset = gesture.translation.height
                                }
                                .onEnded { gesture in
                                    withAnimation(.easeInOut) {
                                        if self.offset.height < -50 {
                                            self.isPanelOpen = true
                                        } else if self.offset.height > 50 {
                                            self.isPanelOpen = false
                                        }
                                        self.finalOffset = 0
                                        self.offset = .zero
                                    }
                                }
                        )
                        
                        // Centered "Go Online" Button above the panel
                        if !isOnline {
                            Button(action: {
                                withAnimation {
                                    isOnline.toggle()
                                }
                            }) {
                                Text("GO")
                                    .padding(30)
                                    .bold()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .opacity(isPanelOpen ? 0.0 : max(0, 1 - Double(abs(offset.height) / (UIScreen.main.bounds.height / 2))))
                            .offset(y: isPanelOpen ? -UIScreen.main.bounds.height / 2 + 90 + offset.height : UIScreen.main.bounds.height / 2 - 90 + offset.height)
                        }
                        
                        // Recenter Button
                        if !isMapCentered {
                            HStack {
                                Spacer()
                                Button(action: {
                                    recenter()
                                }) {
                                    Image(systemName: "location.fill")
                                        .padding(12)
                                        .background(Color.white)
                                        .foregroundColor(Color.black)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                                .offset(y: isPanelOpen ? -UIScreen.main.bounds.height / 2 + 60 + offset.height : UIScreen.main.bounds.height / 2 - 60 + offset.height)
                                .opacity(isPanelOpen ? 0.0 : max(0, 1 - Double(abs(offset.height) / (UIScreen.main.bounds.height / 2))))
                            }
                            .padding(.trailing, 20)
                        }
                    }
                }
            } else {
                Text("Ridestro...")
                    .font(.title)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            locationManager.requestLocation()
            cancellable = locationManager.$userLocation
                .sink { location in
                    if location != nil {
                        // Perform any additional setup when location is available
                    }
                }
        }
        .onDisappear {
            cancellable?.cancel()
        }
    }
    
    var attributedEarnings: AttributedString {
        var earningsString = AttributedString(localized: "$\(earnings, specifier: "%.2f")")
        earningsString[earningsString.range(of: "$")!].foregroundColor = .pink
        earningsString[earningsString.range(of: String(format: "%.2f", earnings))!].foregroundColor = .white
        return earningsString
    }
    
    func recenter() {
        if let mapView = self.mapView, let userLocation = locationManager.userLocation {
            UIView.animate(withDuration: 1.5) {
                let cameraOptions = CameraOptions(center: userLocation, zoom: 14, bearing: 0, pitch: 0)
                mapView.mapboxMap.setCamera(to: cameraOptions)
            }
        }
    }
}

struct LoadingAnimation: View {
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let duration = 4.0  // Total duration for one complete cycle
                let progress = (now.truncatingRemainder(dividingBy: duration)) / duration

                // Calculate current expansion/collapse factor
                let factor = abs(1 - 2 * progress)  // Expands from 0 to 1 and collapses back to 0

                // Pink line width and offset calculation
                let maxOffset = geometry.size.width / 2
                let currentWidth = maxOffset * (1 - factor)
                let minOpacity = 0.3  // Minimum opacity to avoid being too bright
                let maxOpacity = 0.6  // Maximum opacity to create a more subtle effect
                let opacity = minOpacity + (maxOpacity - minOpacity) * sin(progress * .pi * 2)

                ZStack {
                    // Background stationary gray line
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 2)

                    // Pink line expanding from center and collapsing back to center
                    Capsule()
                        .fill(Color.pink.opacity(opacity))
                        .frame(width: currentWidth * 2, height: 2)
                }
                .frame(width: geometry.size.width, alignment: .center)
            }
        }
        .frame(height: 2)
    }
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct DemandChartView: View {
    var body: some View {
        Chart {
            ForEach(hourlyData) { data in
                BarMark(
                    x: .value("Time", data.hour),
                    y: .value("Demand", data.demand)
                )
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [.pink.opacity(0.6), .purple.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        if intValue == 0 {
                            Text("Low")
                        } else if intValue == 50 {
                            Text("Med")
                        } else if intValue == 100 {
                            Text("High")
                        }
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 24]) { hour in
                AxisValueLabel() {
                    if let intValue = hour.as(Int.self) {
                        Text(intValue.asString())
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .padding(.top, 10)
    }

    var hourlyData: [DemandData] {
        return [
            DemandData(hour: 0, demand: 50),
            DemandData(hour: 1, demand: 60),
            DemandData(hour: 2, demand: 30),
            DemandData(hour: 3, demand: 80),
            DemandData(hour: 4, demand: 100),
            DemandData(hour: 5, demand: 60),
            DemandData(hour: 6, demand: 40),
            DemandData(hour: 7, demand: 90),
            DemandData(hour: 8, demand: 120),
            DemandData(hour: 9, demand: 80),
            DemandData(hour: 10, demand: 110),
            DemandData(hour: 11, demand: 50),
            DemandData(hour: 12, demand: 70),
            DemandData(hour: 13, demand: 90),
            DemandData(hour: 14, demand: 60),
            DemandData(hour: 15, demand: 80),
            DemandData(hour: 16, demand: 100),
            DemandData(hour: 17, demand: 70),
            DemandData(hour: 18, demand: 90),
            DemandData(hour: 19, demand: 120),
            DemandData(hour: 20, demand: 110),
            DemandData(hour: 21, demand: 50),
            DemandData(hour: 22, demand: 80),
            DemandData(hour: 23, demand: 90)
        ]
    }
}

struct DemandData: Identifiable {
    var id = UUID()
    var hour: Int
    var demand: Double
}

extension Int {
    func asString() -> String {
        if self == 0 {
            return "12AM"
        } else if self < 12 {
            return "\(self)AM"
        } else if self == 12 {
            return "12PM"
        } else if self == 24 {
            return "12AM"
        } else {
            return "\(self - 12)PM"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
