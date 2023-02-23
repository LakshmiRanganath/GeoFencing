//
//  LocationManager.swift
//  GeoFencing
//
//  Created by Lakshmi on 23/02/23.
//

import UIKit
import CoreLocation
import UserNotifications

class LocationManager : NSObject{
    static let shared = LocationManager()
    let manager = CLLocationManager()
    var currentLocation : CLLocation?{
        didSet{
            evaluateClosestRegions()
        }
    }
    var allRegions : [CLRegion] = [] 
    var completion: ((CLLocation?) -> Void)?
    var locations = [CLLocationCoordinate2DMake(12.953013054035946, 77.5417514266668), CLLocationCoordinate2DMake(12.95428866232216, 77.5438757362066),CLLocationCoordinate2DMake(12.95558517552543, 77.54565672299249),CLLocationCoordinate2DMake(12.956442543452548, 77.54752354046686),CLLocationCoordinate2DMake(12.95675621390793, 77.54919723889215),CLLocationCoordinate2DMake(12.957069883968225, 77.55112842938287),CLLocationCoordinate2DMake(12.957711349517467, 77.55308710458465),CLLocationCoordinate2DMake(12.958464154110917, 77.55514704110809),CLLocationCoordinate2DMake(12.959656090062529, 77.5559409749765),CLLocationCoordinate2DMake(12.960814324441305, 77.5574167738546),CLLocationCoordinate2DMake(12.961253455257907, 77.5592192183126),CLLocationCoordinate2DMake(12.96156308861349, 77.56126500049922),CLLocationCoordinate2DMake(12.961814019848779, 77.56308890262935),CLLocationCoordinate2DMake(12.962775920574138, 77.56592131534907),CLLocationCoordinate2DMake(12.963340512746937, 77.5676379291186),CLLocationCoordinate2DMake(12.96411114676894, 77.56951526792183),CLLocationCoordinate2DMake(12.964382986146292, 77.5717254081501),CLLocationCoordinate2DMake(12.964584624077109, 77.57370388966811),CLLocationCoordinate2DMake(12.964542802687657, 77.57591402989638),CLLocationCoordinate2DMake(12.963795326167373, 77.57798997552734),CLLocationCoordinate2DMake(12.96358621848664, 77.58015720041138),CLLocationCoordinate2DMake(12.963481664580394, 77.58189527185303)]
    
    public func getUserLocation(completion: @escaping ((CLLocation?) -> Void)) {
        self.completion = completion
        // manager.requestWhenInUseAuthorization()
        manager.requestAlwaysAuthorization()
        manager.delegate = self
        manager.startUpdatingLocation()
        manager.distanceFilter = 100
        DispatchQueue.main.async {
            self.manager.startMonitoringSignificantLocationChanges()
        }
        
        for (i,reg) in locations.enumerated() {
            let geoFenceRegion: CLCircularRegion = CLCircularRegion(center: reg, radius: 10, identifier: "Location \(i + 1)")
            allRegions.append(geoFenceRegion)
        }
        
    }
    
    func evaluateClosestRegions() {

        var allDistance : [Double] = []

        //Calulate distance of each region's center to currentLocation
        for region in allRegions{
            let circularRegion = region as! CLCircularRegion
            guard let currentLocation = self.currentLocation else {
                return
            }
            let distance = currentLocation.distance(from: CLLocation(latitude: circularRegion.center.latitude, longitude: circularRegion.center.longitude))
            allDistance.append(distance)
        }

        let distanceOfEachRegionToCurrentLocation = zip(allRegions, allDistance)

        //sort and get 20 closest
        let twentyNearbyRegions = distanceOfEachRegionToCurrentLocation
            .sorted{ region1, region2 in return region1.1 < region2.1 }
            .prefix(20)

        // Remove all regions you were tracking before
        for region in allRegions{
            manager.stopMonitoring(for: region)
        }

        twentyNearbyRegions.forEach{
            manager.startMonitoring(for: $0.0)
        }

    }
    
    public func resolveLocationName(with location: CLLocation, completion: @escaping ((String?) -> Void)) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: .current) { placemarks, error in
            guard let place = placemarks?.first, error == nil else {
                completion(nil)
                return
            }
            var name = ""
            if let locality = place.locality {
                name += locality
            }
            if let adminRegion = place.administrativeArea {
                name += ", \(adminRegion)"
            }
            completion(name)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager  : CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        currentLocation = location
        completion?(currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            postLocalNotifications(withTitle: "Entered: \(region.identifier)")
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            postLocalNotifications(withTitle: "Exited: \(region.identifier)")
        }
        
    }
}

// MARK: - Notification ==> Register Notification on AppDelegate
extension LocationManager {
    func postLocalNotifications(withTitle: String){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = withTitle
        content.body = ""
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let notificationRequest:UNNotificationRequest = UNNotificationRequest(identifier: "Region", content: content, trigger: trigger)
        center.add(notificationRequest)
    }
}

