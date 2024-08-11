//
//  LocationManager.swift
//  Ride Stro
//
//  Created by devon tomlin on 2024-07-28.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        } else {
            // Handle location services being disabled
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.locationManager.startUpdatingLocation()
            }
        case .notDetermined:
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .restricted, .denied:
            // Handle restricted/denied state
            break
        @unknown default:
            break
        }
    }
}
