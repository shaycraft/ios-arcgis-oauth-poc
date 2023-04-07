//
//  ViewController.swift
//  ios-arcgis-ui-elems-poc
//
//  Created by Samuel Haycraft on 4/1/23.
//

import UIKit
import ArcGIS

extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}

class ViewController: UIViewController, AGSGeoViewTouchDelegate {
    // UI elements
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var coordinateLabel: UILabel!
    @IBOutlet weak var btnLoad: UIButton!
    
    // dbles
    private var _session: ASWebAuthenticationSession?
    private let _clientId: String = "be867936-b5b6-4bdd-b29e-fc6c932733b3"
    private let _appId: String = "601ff8c0-9157-428b-b436-38feda19daa3"
    private let _scheme: String = "msauth.com.xcelenergy.gasfee.development"
    private let _redirectUri: String = "msauth.com.xcelenergy.gasfee.development%3A%2F%2Fauth%2F"
    private let _proxyBaseUri: String = "https://gdl-xcelenergytest.msappproxy.net"
    private let _scope: String = "https%3A%2F%2Fgdl-xcelenergytest.msappproxy.net%2Farcgis%2Fuser_impersonation"
//     private let _scope: String = "openid"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self._setupMap()
        
        self.btnLoad.addTarget(self, action: #selector(self._startAuth), for: .touchUpInside)
        
        self._setupAuthSession()
        
    }
    
    // interface methods for AGSGeoViewTouchDelegate
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) -> Void {
        let projectPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: AGSSpatialReference(wkid: 4326)!)! as! AGSPoint
        
        self.coordinateLabel.text = "Lat/long = {\( String(format: "%.3f", projectPoint.x)), \(String(format: "%.3f", projectPoint.y)) }"
    }
    
    // private functions
    
    private func _getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    private func _setupAuthSession() -> Void {
        print("Redirect = ")
        print(self._redirectUri)
        let authUrlString = "https://login.microsoftonline.com/\(self._appId)/oauth2/v2.0/authorize?response_type=code&client_id=\(self._clientId)&scope=\(self._scope)&redirect_uri=\(self._redirectUri)"
        
        guard let authURL = URL(string: authUrlString) else { return }
        
        let scheme = self._scheme
        
        // Initialize the session.
        self._session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme)
        { callbackURL, error in
            // Handle the callback.
            
            guard error == nil else {
                print("Got an error in auth....")
                print(error!.localizedDescription)
                print(String(describing: error))
                print(String(describing: callbackURL))
                
                self._addDataHelper()
                return
            }
            guard let callbackURL = callbackURL else {
                print("Error in callbackURL set")
                return
            }
            print(callbackURL.absoluteString)
            
            let codeToken = self._getQueryStringParameter(url: callbackURL.absoluteString, param: "code")!
            self._issueCodeForToken(code: codeToken)
            
        }
        
        self._session!.presentationContextProvider = self
        
    }
    
    private func _issueCodeForToken(code: String) -> Void {
        let url = URL(string: "https://login.microsoftonline.com/\(self._appId)/oauth2/v2.0/token?")!
        
        
        let requestData = "code=\(code)&grant_type=authorization_code&scope=\(self._scope)&client_id=\(self._clientId)&redirect_uri=\(_redirectUri)".data(using: .utf8)
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.uploadTask(with: request, from: requestData) { data, response, error in
            do {
                if let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any] {
                    let accessToken = json["access_token"] as! String
                    //print(json["id_token"]! as! String)
                    print("DEBUG:  token = ")
                    print(accessToken)
                    AGSRequestConfiguration.global().userHeaders = [ "Authorization": "Bearer \(accessToken)" ]
                    
                    self._addDataHelper()
                    
                }
            }
            catch {
                print("Error parsing json")
                print(error.localizedDescription)
            }
            
            
        }
        
        task.resume()
    }
    
    private func _setupMap() -> Void {
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        let zoomPoint = AGSViewpoint(latitude: 40, longitude: -88, scale: 11500_00)
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        self.mapView.setViewpoint(zoomPoint)
        
    }
    
    @objc private func _startAuth() -> Void {
        self._session!.start()
    }
    
    private func _addDataHelper() -> Void {
        
        let featureLayer: AGSFeatureLayer = {
            let featureServiceURL = URL(string: "\(self._proxyBaseUri)/arcgis/rest/services/GFEE/Gas_Distribution/FeatureServer/11")!
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
}

