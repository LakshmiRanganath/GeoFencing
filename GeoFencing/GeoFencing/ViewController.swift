//
//  ViewController.swift
//  GeoFencing
//
//  Created by Lakshmi on 22/02/23.
//


import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - LifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationManager.shared.getUserLocation { [weak self] location in
            DispatchQueue.main.async {[weak self] in
                guard let self = self else {return}
                self.addMapPin(location: location ?? CLLocation())
            }
        }
    }
    
    // MARK: - Helper Functions
    func addMapPin(location: CLLocation) {
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        // set camera to zoom in
        mapView.setRegion(MKCoordinateRegion(center: location.coordinate,
                                         span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)),
                      animated: true)
        mapView.addAnnotation(pin)
        LocationManager.shared.resolveLocationName(with: location) { [weak self] locationName in
            self?.title = locationName
        }
    }
}

