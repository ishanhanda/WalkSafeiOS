//
//  ViewController.swift
//  hacknyu
//
//  Created by Ishan Handa on 19/02/17.
//  Copyright © 2017 Ishan Handa. All rights reserved.
//

import UIKit
import GoogleMaps
import LFHeatMap
import GooglePlaces
import SVProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var imageView: UIImageView!
//    var mapView: GMSMapView!
    var directionsResponse: DirectionsResponse?
    
    @IBOutlet var fromField: UITextField!
    @IBOutlet var toField: UITextField!
    @IBOutlet var animationSwitch: UISwitch!
    
    var activeTextField: UITextField!
    
    var animates = false
        
    @IBAction func goButtonTapped(_ sender: Any) {
    
        mapView.removeOverlays(mapView.overlays)
        
        let from = self.fromField.text!
        let to = self.toField.text!
        
        SVProgressHUD.show()
        DispatchQueue.global(qos: .userInitiated).async {
            NYTimesAPIWrapper.sharedInstance.getDirections(to: to, from: from) { (apiResponse) in
                if let error = apiResponse.errorMsg {
                    print(error)
                } else {
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        self.directionsResponse = apiResponse.responseObject
                        self.drawPaths(zoom: true)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setDefaultMaskType(.black)
        
        mapView.mapType = .standard
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D.init(latitude: 40.754223, longitude: -73.982161),
            span: MKCoordinateSpan.init(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.region = region
        mapView.delegate = self
        
        imageView.contentMode = .center
        
        self.fromField.delegate = self
        self.toField.delegate = self
        
        view.bringSubview(toFront: imageView)
        view.bringSubview(toFront: animationSwitch)
        
        self.animationSwitch.isOn = animates
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    var primaryRoute: Route? = nil
    
    func drawPaths(zoom: Bool = false) {
        guard let response = directionsResponse else {
            return
        }
        
        for route in response.routes! {
            let path = GMSPath(fromEncodedPath: route.polyline!)!
            
            var coordinates: [CLLocationCoordinate2D] = []
            
            for i in 0..<Int(path.count()) {
                coordinates += [path.coordinate(at: UInt(i))]
            }

            let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
            line.title = route.polyline!

            self.mapView.add(line)
            
            if primaryRoute == nil {
                primaryRoute = route
            }
        }
        
        self.plotHeatMap(routes: response.routes!)
        
        if zoom {
            let path = GMSPath(fromEncodedPath: primaryRoute!.polyline!)!
            var coordinates: [CLLocationCoordinate2D] = []
            
            for i in 0..<Int(path.count()) {
                coordinates += [path.coordinate(at: UInt(i))]
            }
            let polylines = MKPolyline(coordinates: coordinates, count: coordinates.count)
            let rect = MKCoordinateRegionForMapRect(polylines.boundingMapRect)
            self.mapView.setRegion(rect, animated: true)
        }

    }
    
    
    func plotHeatMap(routes: [Route]) {
        SVProgressHUD.show()
        DispatchQueue.global(qos: .userInitiated).async {
            var locations: [CLLocation] = []
            
            for route in routes {
                let locs = route.crimeLocations!.map { (location) -> CLLocation in
                    let location = CLLocation.init(latitude: location.lat!, longitude: location.long!)
                    return location
                }
                
                locations += locs
            }
            
            
            let weights = Array.init(repeating: 1, count: locations.count)
            
            if self.animates {
                var heatmaps: [UIImage] = []
                
                for i in stride(from: 0.2, to: 0.8, by: 0.01) {
                    let heatmap = LFHeatMap.heatMap(for: self.mapView, boost: Float(i), locations: locations, weights: weights)!
                    heatmaps += [heatmap]
                }
                
                let rev = heatmaps.reversed()
                heatmaps += rev
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.imageView.animationImages = heatmaps
                    self.imageView.animationDuration = 1
                    self.imageView.animationRepeatCount = 0
                    self.imageView.startAnimating()
                }
            } else {
                self.imageView.layer.removeAllAnimations()
                let heatmap = LFHeatMap.heatMap(for: self.mapView, boost: 0.4, locations: locations, weights: weights)!
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.imageView.image = heatmap
                }
            }
            // Bounce back to the main thread to update the UI
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func polyLineWithEncodedString(encodedString: String) -> MKPolyline {
        let bytes = (encodedString as NSString).utf8String
        let length = encodedString.lengthOfBytes(using: String.Encoding.utf8)
        var idx: Int = 0
        
        var count = length / 4
        var coords = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: count)
        var coordIdx: Int = 0
        
        var latitude: Double = 0
        var longitude: Double = 0
        
        while (idx < length) {
            var byte = 0
            var res = 0
            var shift = 0
            
            repeat {
                idx += 1
                byte = Int(bytes![idx] - Int8(0x3F))
                res |= (byte & 0x1F) << shift
                shift += 5
            } while (byte >= 0x20)
            
            let deltaLat = ((res & 1) != 0x0 ? ~(res >> 1) : (res >> 1))
            latitude += Double(deltaLat)
            
            shift = 0
            res = 0
            
            repeat {
                idx += 1
                byte = Int(bytes![idx] - Int8(0x3F))
                res |= (byte & 0x1F) << shift
                shift += 5
            } while (byte >= 0x20)
            
            let deltaLon = ((res & 1) != 0x0 ? ~(res >> 1) : (res >> 1))
            longitude += Double(deltaLon)
            
            let finalLat: Double = latitude * 1E-5
            let finalLon: Double = longitude * 1E-5
            
            let coord = CLLocationCoordinate2DMake(finalLat, finalLon)
            coordIdx += 1
            coords[coordIdx] = coord
            
            if coordIdx == count {
                let newCount = count + 10
                let temp = coords
//                coords.deallocate(capacity: count)
                coords = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: newCount)
                for index in 0..<count {
                    coords[index] = temp[index]
                }
                temp.deinitialize()
                count = newCount
            }
            
        }
        
        let polyLine = MKPolyline(coordinates: coords, count: coordIdx)
        coords.deinitialize()
        
        return polyLine
    }
    
    
    @IBAction func animateSwithcChanged(_ sender: Any) {
        self.animates = (sender as! UISwitch).isOn
        if let response = self.directionsResponse {
            self.plotHeatMap(routes: response.routes!)
        }
    }
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let line = overlay as? MKPolyline {
            let render = MKPolylineRenderer(overlay: line)
            render.strokeColor = UIColor.blue
            render.lineWidth = 5
            return render
        }
        
        return MKPolylineRenderer()
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.imageView.isHidden = true
        self.animates = false
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let response = self.directionsResponse {
            self.plotHeatMap(routes: response.routes!)
        }
        self.imageView.isHidden = false
    }
}


extension ViewController: UITextFieldDelegate {
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        
        present(acController, animated: true, completion: nil)
        self.activeTextField = textField
    }
}


extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        (viewController as UIViewController).dismiss(animated: true, completion: nil)
        activeTextField.text = place.formattedAddress
    }
    
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        (viewController as UIViewController).dismiss(animated: true, completion: nil)
    }
    
    
//    func viewController(_ viewController: GMSAutocompleteViewController, didSelect prediction: GMSAutocompletePrediction) -> Bool {
//        return true
//        self.dismiss(animated: viewController, completion: nil)
//        activeTextField.text = place.formattedAddress
//    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        (viewController as UIViewController).dismiss(animated: true, completion: nil)
    }
}



