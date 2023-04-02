//
//  ViewController.swift
//  ios-arcgis-ui-elems-poc
//
//  Created by Samuel Haycraft on 4/1/23.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var debugLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self._setupMap()
    }
    
    
    // private functions
    
    private func _setupMap() -> Void {
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        let zoomPoint = AGSViewpoint(latitude: 40, longitude: -88, scale: 11500_00)
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        self.mapView.setViewpoint(zoomPoint)
    }
    
    
    // interface methods for AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) -> Void {
        let latLongPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: AGSSpatialReference(wkid: 4326)!)! as! AGSPoint
        print(">>>>>>> DEBUG: <<<<<<< Point = \(String(describing: latLongPoint))")
        
        self.debugLabel.text = "Lat/long = {\( String(format: "%.3f", latLongPoint.x)), \(String(format: "%.3f", latLongPoint.y)) }"
    }
    
}
