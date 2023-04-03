//
//  ViewController.swift
//  ios-arcgis-ui-elems-poc
//
//  Created by Samuel Haycraft on 4/1/23.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSGeoViewTouchDelegate, WKNavigationDelegate {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    private var _firstNav: Bool = true
    
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
        
        self.mapView.isHidden = true
        
        self.webView.load(URLRequest(url: URL(string: "https://google.com")!))
        
        self.webView.navigationDelegate = self
    }
    
    
    // interface methods for AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) -> Void {
        let projectPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: AGSSpatialReference(wkid: 4326)!)! as! AGSPoint
        print(">>>>>>> DEBUG: <<<<<<< Point = \(String(describing: projectPoint))")
        
        self.debugLabel.text = "Lat/long = {\( String(format: "%.3f", projectPoint.x)), \(String(format: "%.3f", projectPoint.y)) }"
    }
    
    func webView( _ webView: WKWebView, didFinish navigation: WKNavigation! ) {
        print(">>>>>>> DEBUG: Navigation detected, url = \(self.webView.url!.absoluteString)")
        if (!self._firstNav) {
            self.mapView.isHidden = false
            self.webView.isHidden = true
            return
        }
        print("DEBUG:  navigation detected...")
        
        self._firstNav = false
    }
    
}

