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


extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        print("Mapview =========")
        print(String(describing: self.mapView))
        print(String(describing: self.mapView.window))
        print(String(describing: self.webView.window))
        return view.window!
    }
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
    private var _session: ASWebAuthenticationSession?
    private let _clientId: String = "be867936-b5b6-4bdd-b29e-fc6c932733b3"
    private let _appId: String = "601ff8c0-9157-428b-b436-38feda19daa3"

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self._setupMap()
        
        //        self.webView.load(URLRequest(url: URL(string: "https://gdl-xcelenergytest.msappproxy.net/arcgis/rest/services")!))
        //        self.webView.navigationDelegate = self
        self.webView.isHidden = true
        self.btnToggle.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        self.btnLoad.addTarget(self, action: #selector(self._addData), for: .touchUpInside)
        self._showBrowserUi()
        self._showMapUi()
        self._setupAuthSession()
        
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
    
    private func _getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    private func _setupAuthSession() -> Void {
        let authUrlString = "https://login.microsoftonline.com/\(self._appId)/oauth2/v2.0/authorize?response_type=code&client_id=\(self._clientId)&scope=openid&redirect_uri=msauth.com.xcelenergy.gasfee.development%3A%2F%2Fauth"
        
        guard let authURL = URL(string: authUrlString) else { return }
        
        let scheme = "msauth.com.xcelenergy.gasfee.development"
        
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
            
            print("We are authed... I guess? callback = \(String(describing: callbackURL))")
            
            let codeToken = self._getQueryStringParameter(url: callbackURL.absoluteString, param: "code")!
            self._issueCodeForToken(code: codeToken)
            
        }
        
        self._session!.presentationContextProvider = self
        
    }
    
    private func _issueTestRestRequest(accessToken: String) -> Void {
        let url = "https://"
    }
    
    private func _issueCodeForToken(code: String) -> Void {
        print("<<<<<< DEBUG >>>>>> in [_issueCodeForToken]")
        
        let url = URL(string: "https://login.microsoftonline.com/\(self._appId)/oauth2/v2.0/token?")!
        //
        //        let requestData = ["code": code, "client_id": clientId, "grant_type": "authorization_code"]
        let requestData = "code=\(code)&grant_type=authorization_code&scope=openid&client_id=\(self._clientId)&redirect_uri=msauth.com.xcelenergy.gasfee.development%3A%2F%2Fauth".data(using: .utf8)
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: requestData) { data, response, error in
            print("in callback for token!")
            print(String(data: data!, encoding: .utf8)!)
            let callbackDataUrl = String(data: data!, encoding: .utf8)!
            
            //            let oauthToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyIsImtpZCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyJ9.eyJhdWQiOiJiZTg2NzkzNi1iNWI2LTRiZGQtYjI5ZS1mYzZjOTMyNzMzYjMiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC82MDFmZjhjMC05MTU3LTQyOGItYjQzNi0zOGZlZGExOWRhYTMvIiwiaWF0IjoxNjgwNjM1MDA2LCJuYmYiOjE2ODA2MzUwMDYsImV4cCI6MTY4MDYzODkwNiwiYW1yIjpbInB3ZCJdLCJmYW1pbHlfbmFtZSI6IkhheWNyYWZ0IiwiZ2l2ZW5fbmFtZSI6IlNhbXVlbCIsImlwYWRkciI6IjI0LjEyOC4zNi4xODgiLCJuYW1lIjoiSGF5Y3JhZnQsIFNhbXVlbCBHIiwib2lkIjoiZjIxNGE2ZTMtNGE1Yy00YWVmLWE5ZDgtN2IzMTlmNDhjODM5Iiwib25wcmVtX3NpZCI6IlMtMS01LTIxLTE5NTExODY3ODAtNDYyOTI0MTQtMzEzODUxODEzNy0xODMyNTkiLCJyaCI6IjAuQVNnQXdQZ2ZZRmVSaTBLME5qai0yaG5hb3paNWhyNjJ0ZDFMc3A3OGJKTW5NN01vQUVNLiIsInN1YiI6Ims5aU83MmY4NjVlQ3NYZ3JGMFJnajdZYnJaeHZiZEpSYjZoeERWSmcycVUiLCJ0aWQiOiI2MDFmZjhjMC05MTU3LTQyOGItYjQzNi0zOGZlZGExOWRhYTMiLCJ1bmlxdWVfbmFtZSI6IjMwODIyN0Bjb3JwLnhjZWxlbmVyZ3kubmV0IiwidXBuIjoiMzA4MjI3QGNvcnAueGNlbGVuZXJneS5uZXQiLCJ1dGkiOiJ3SG9uY3hxbkhFQ09IMW1QVUVoQkFRIiwidmVyIjoiMS4wIn0.fy4Uv3lrOwuCoUHdfcI5q0BJpB4V1k-z0wNO6TmsSSdXorUWFmZXc8TzuF3-SzJsuVI3SCkHyVV4YDG4vC44KQddz_lIXo8_gP1I9rTbbC9LVZUqewbrfrjwp7FPtLCKQbDG9GctAH7SeMGpCXgUpQFD9c84uiypj7iqIqktNXt2b1lt-QXpdqKyKawo36kSiV3Ed5a-RO-i1K3TVs-x4ot9ODWtxUYAzuVEyfXtPs-8LjneD04fduqQIiKy4cPHGLmIEcWdz876xiCY1CvcDaLiguvnguaqBcsU85pVLx3x6GVtzsbdADg2kO-f89v9DAFOq-minyw9jkGuEwUhUg"
            //            let oauthToken = "PAQABAAAAAAD--DLA3VO7QrddgJg7Wevr3_guf_W8ZOdYmilQ02Rwg3Hu4_lZX6lANTtwn1-vwnBVI0AlUTwv7zcSPAbHQKyRtQBcxOzq1npcEPjWutV9ee3FknP5z_wdwmOJZES1gY5ZFX9g9dL97lBmhY449iqtu55y6C6tNTNQRC3hYBis7yvypysCNYm4BEGgM76SI8JJxjgcmmSpCnTB7zYnIiPfkc5c7_Fx75-28OBvt-QvyVwpr5YRb84n5C_a2zP5Irptmd3jLRRY8w0FRnplwxRSpeFEWq7NNlDDogSCZ74ylNxMO0YEOeh9y46UkvtxN9YCU0nTVQa6D8kTC1aVofFEUDML1XNrWBo-S6got8rR7ksNqmS6ergg3CozAXvqIDuHBSfIWLqtXOEZLwXPWL69GT4tLy6PK6s2LFQ61g4x8I86AQcj44one4Q5EA_JeaoAHMRZ-aoGv39AuzaYdNefu3-IpBmZ0XGBOzRjNOMUfEtVgL5OSNEWKAAJ6fmgCpslJ3cl7kmPmPjMXUfq2tybatZxFQgODrElEGX1T49KYcuNJL3hUdoNMGxPHu4qKfREVSdNmGFw44vsMDFhGKkB3FL-xsHVwhx31ZEih1JKfJxeqELpY0xrnb4QR_vX5Nd4aR7uZPpefU9yPtaFeesoIAA"
            
            do {
                print(String(describing: data))
                if let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any] {
                    let accessToken = json["access_token"] as! String
                    print("access token = \(accessToken)")
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
    
    @objc private func _addData() -> Void {
        self._session!.start()
    }
    
    private func _addDataHelper() -> Void {
        
        let featureLayer: AGSFeatureLayer = {
            // let featureServiceURL = URL(string: "https://services3.arcgis.com/GVgbJbqm8hXASVYi/arcgis/rest/services/Trailheads/FeatureServer/0")!
            let featureServiceURL = URL(string: "https://gdl-xcelenergytest.msappproxy.net/arcgis/rest/services/GFEE/Gas_Distribution/FeatureServer/11")!
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

