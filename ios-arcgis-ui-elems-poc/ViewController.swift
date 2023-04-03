//
//  ViewController.swift
//  ios-arcgis-ui-elems-poc
//
//  Created by Samuel Haycraft on 4/1/23.
//

import UIKit
import ArcGIS

enum CurrentMode {
    case webPanelAcive
    case mapPanelActive
}

class ViewController: UIViewController, AGSGeoViewTouchDelegate, WKNavigationDelegate {
    // UI elements
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnToggle: UIButton!
    @IBOutlet weak var btnLoad: UIButton!
    
    // dbles
    private var _currentMode: CurrentMode = .webPanelAcive
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self._setupMap()
        
        self.webView.load(URLRequest(url: URL(string: "https://gdl-xcelenergytest.msappproxy.net/arcgis/rest/services")!))
        self.webView.navigationDelegate = self
        self.btnToggle.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        self.btnLoad.addTarget(self, action: #selector(self._addData), for: .touchUpInside)
        self._showBrowserUi()
        
    }
    
    // UI events
    
    @objc func buttonTapped() {
        print("Tapped!")
        if (self._currentMode == .mapPanelActive) {
            self._showBrowserUi()
        } else {
            self._showMapUi()
        }
    }
    
    
    // interface methods for AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) -> Void {
        let projectPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: AGSSpatialReference(wkid: 4326)!)! as! AGSPoint
        print(">>>>>>> DEBUG: <<<<<<< Point = \(String(describing: projectPoint))")
        
        self.coordinateLabel.text = "Lat/long = {\( String(format: "%.3f", projectPoint.x)), \(String(format: "%.3f", projectPoint.y)) }"
    }
    
    func webView( _ webView: WKWebView, didFinish navigation: WKNavigation! ) {
        print(">>>>>>> DEBUG: Navigation detected, url = \(self.webView.url!.absoluteString)")
    }
    
    // private functions
    
    private func _setupMap() -> Void {
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        let zoomPoint = AGSViewpoint(latitude: 40, longitude: -88, scale: 11500_00)
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        self.mapView.setViewpoint(zoomPoint)
        
    }
    
    @objc private func _addData() -> Void {
        let featureLayer: AGSFeatureLayer = {
            let featureServiceURL = URL(string: "https://services3.arcgis.com/GVgbJbqm8hXASVYi/arcgis/rest/services/Trailheads/FeatureServer/0")!
            let featureServiceTable = AGSServiceFeatureTable(url: featureServiceURL)
            return AGSFeatureLayer(featureTable: featureServiceTable)
        }()
        
        featureLayer.load{ [weak self] (error) in
            if let error = error {
                print("ERROR IN LOADING FEATURE LAYER <<<<<<<<<<<<<<")
                print(error.localizedDescription)
                
                return
            }
            
            self?.mapView.map!.operationalLayers.add(featureLayer)
            
            self?.mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 34.09042,
                    longitude: -118.71511,
                    scale: 200_000
                )
            )
            
            print("____ LAYER LOADED _____")
        }
        
    }
    
    private func _showMapUi() -> Void {
        self.mapView.isHidden = false
        self.webView.isHidden = true
        self.coordinateLabel.isHidden = false
        self._currentMode = .mapPanelActive
    }
    
    private func _showBrowserUi() -> Void {
        self.mapView.isHidden = true
        self.webView.isHidden = false
        self.coordinateLabel.isHidden = true
        self._currentMode = .webPanelAcive
    }
}

