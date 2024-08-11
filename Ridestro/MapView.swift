//
//  MapView.swift
//  Ride Stro
//
//  Created by devon tomlin on 2024-07-28.
//

import SwiftUI
@_spi(Experimental) import MapboxMaps

struct MapView: UIViewRepresentable {
    var userLocation: CLLocationCoordinate2D?
    @Binding var isMapCentered: Bool
    @Binding var mapView: MapboxMaps.MapView?

    func makeUIView(context: Context) -> MapboxMaps.MapView {
        guard let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String else {
            fatalError("Access token not found in Info.plist")
        }

        let resourceOptions = ResourceOptions(accessToken: accessToken)
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions, styleURI: .dark)
        let newMapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: mapInitOptions)

        newMapView.ornaments.compassView.isHidden = true
        newMapView.ornaments.scaleBarView.isHidden = true
        newMapView.ornaments.logoView.isHidden = true
        newMapView.ornaments.attributionButton.isHidden = true
        
        // Add puck for showing current location
        let configuration = Puck2DConfiguration.makeDefault(showBearing: true)
        newMapView.location.options.puckType = .puck2D(configuration)
        
        // Listen to camera changes
        newMapView.mapboxMap.onEvery(.cameraChanged) { [self] _ in
            guard let userLocation = userLocation else { return }
            let mapCenter = newMapView.cameraState.center
            let zoomLevel = newMapView.cameraState.zoom
            let bearing = newMapView.cameraState.bearing
            let pitch = newMapView.cameraState.pitch

            // Define small tolerances for comparisons
            let coordinateTolerance = 0.0001
            let zoomTolerance: CGFloat = 0.1
            let bearingTolerance: Double = 1.0
            let pitchTolerance: Double = 1.0

            // Check if map is centered based on all camera attributes
            let isCentered = (abs(mapCenter.latitude - userLocation.latitude) < coordinateTolerance &&
                              abs(mapCenter.longitude - userLocation.longitude) < coordinateTolerance &&
                              abs(zoomLevel - 14.0) < zoomTolerance &&
                              abs(bearing) < bearingTolerance &&
                              abs(pitch) < pitchTolerance)

            // Always update the state in the main thread
            DispatchQueue.main.async {
                isMapCentered = isCentered
            }
        }

        DispatchQueue.main.async {
            self.mapView = newMapView
        }

        return newMapView
    }

    func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
        if isMapCentered, let userLocation = userLocation {
            let cameraOptions = CameraOptions(center: userLocation, zoom: 14)
            uiView.mapboxMap.setCamera(to: cameraOptions)
        }
    }
}
