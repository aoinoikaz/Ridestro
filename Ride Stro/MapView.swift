//
//  MapView.swift
//  Ride Stro
//
//  Created by devon tomlin on 2024-07-28.
//

import SwiftUI
@_spi(Experimental) import MapboxMaps

struct MapView: UIViewRepresentable {
    var userLocation: CLLocationCoordinate2D
    @Binding var mapView: MapboxMaps.MapView?

    func makeUIView(context: Context) -> MapboxMaps.MapView 
    {
        guard let accessToken = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String else {
            fatalError("Access token not found in Info.plist")
        }

        let resourceOptions = ResourceOptions(accessToken: accessToken)
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions, styleURI: .streets)
        let newMapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: mapInitOptions)

        newMapView.ornaments.compassView.isHidden = true
        newMapView.ornaments.logoView.isHidden = true
        newMapView.ornaments.attributionButton.isHidden = true

        // Add puck for showing current location
        newMapView.location.options.puckType = .puck2D()

        DispatchQueue.main.async {
            self.mapView = newMapView
        }

        return newMapView
    }

    func updateUIView(_ uiView: MapboxMaps.MapView, context: Context) {
        let cameraOptions = CameraOptions(center: userLocation, zoom: 12)
        uiView.mapboxMap.setCamera(to: cameraOptions)
    }
}
