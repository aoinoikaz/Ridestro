//
//  ContentView.swift
//  Ride Stro
//
//  Created by devon tomlin on 2024-07-28.
//

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
                            
                            VStack(alignment: .leading) {
                                Text("Earnings Trends in Kitchener-Waterloo")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                HStack {
                                    Text("Today:")
                                    Spacer()
                                }
                                HStack {
                                    Text("This Week:")
                                    Spacer()
                                }
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
                                    .background(Color.black)
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
                let duration = 1.5
                let progress = (now.truncatingRemainder(dividingBy: duration)) / duration
                let startingWidth = geometry.size.width / 20
                let maxWidth = geometry.size.width

                // Width of the moving capsule changes over time
                let capsuleWidth = startingWidth + (maxWidth - startingWidth) * progress

                ZStack {
                    // Background stationary gray line
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 2)

                    // Moving blue line that shoots outward
                    Capsule()
                        .fill(Color.pink)
                        .frame(width: capsuleWidth, height: 2)
                        .offset(x: (geometry.size.width - capsuleWidth) / 2)
                        .opacity(1.0 - progress) // Fade out as it moves outward
                }
            }
        }
        .frame(height: 10)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
