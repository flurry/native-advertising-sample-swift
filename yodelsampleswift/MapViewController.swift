//
//  MapViewController.swift
//  yodelsampleswift
//
//  Copyright 2016 Yahoo! Inc.
//
//  Licensed under the terms of the zLib license. Please see LICENSE file in the project root for terms.
//
import UIKit
import MapKit
import Flurry_iOS_SDK

class MapViewController: UIViewController, MKMapViewDelegate, UINavigationControllerDelegate, FlurryAdNativeDelegate {
    
    //create a map item that will hold the map data our search finds
    var mapItem: MKMapItem?
    //create a variable to hold the location we will search for
    var location: String = ""
    //create an instance of our expandable ad space
    let expandableAd = FlurryAdNative(space: "SwiftYodelTravelsExpandableAdSpace")
    
    //connect the view that will hold the ad
    @IBOutlet weak var adView: UIView!
    
    //connect our labels, buttons, and images from the adView
    @IBOutlet weak var adTitleLabel: UILabel!
    @IBOutlet weak var adDescriptionLabel: UILabel!
    @IBOutlet weak var adSourceLabel: UILabel!
    @IBOutlet weak var adSponsoredImage: UIImageView!
    @IBOutlet weak var adExpandButton: UIButton!
    @IBOutlet weak var adCallToAction: UIButton!
    @IBOutlet weak var adImage: UIImageView!
    
    //connect height constraints fror the ad's image view and description label so that we can set them to 0 and thus collapse the ads
    @IBOutlet weak var adImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var adDescriptionHeightConstraint: NSLayoutConstraint!
    
    //connect our mapView
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        
        //creates the ad space and fetches the ad
        expandableAd?.adDelegate = self
        expandableAd?.viewControllerForPresentation = self
        expandableAd?.fetchAd()
        
        //hides the ad view until an ad arrives
        self.adView.hidden = true
        
        //makes the ad view rounded
        self.adView.layer.cornerRadius = 10
        self.adView.clipsToBounds = true
        
        //change the title bar to be the title we passed
        self.title = location
        
        //become a delegate of the navigation controller so we can capture when the user presses the back button
        self.navigationController?.delegate = self
        
        //set the delegate of the map view to this view controller and the map view type to be a satellite flyover
        self.mapView.delegate = self
        mapView.mapType = .SatelliteFlyover
        
        //update the map by calling this function
        updateMap()
    }
    func adNativeDidFetchAd(nativeAd: FlurryAdNative!) {
        NSLog("Native Ad for Space \(nativeAd.space) Received Ad with \(nativeAd.assetList.count) assets")
        
        //if the expandable ad exists and is ready, call our function to put it into the ad view
        if nativeAd.ready == true {
            //unhide the adView
            self.adView.hidden = false
            
            //call our funtion to set up the view
            self.setupAdView()
        }
    }
    func adNative(nativeAd: FlurryAdNative!, adError: FlurryAdError, errorDescription: NSError!) {
        NSLog("Native Ad for Space \(nativeAd.space) Received Error \(adError), with description: \(errorDescription)")
    }
    
    func setupAdView() {
        
        //force the adView to be collapsed by setting the Image View and Description Label to heights of 0
        self.adImageHeightConstraint.constant = 0
        self.adDescriptionHeightConstraint.constant = 0
        
        //set the adView to be collapsed and assign a pencil view tracer to it with the corresponding expand and CTA buttons
        expandableAd?.displayState = FLURRY_NATIVE_AD_COLLAPSED
        expandableAd?.setPencilViewToTrack(adView, withExpandButton: adExpandButton, andCTAButton: adCallToAction)
        
        //extract assets from ad and put them into labels, buttons, and imageviews
        if let assets = expandableAd?.assetList{
            for asset in assets {
                
                switch(asset.name! as String) {
                case "headline":
                    self.adTitleLabel.text = asset.value
                    
                case "summary":
                    self.adDescriptionLabel.text = asset.value
                    
                case "secHqImage":
                    if let url = NSURL(string: asset.value) {
                        if let imageData = NSData(contentsOfURL: url) {
                            let image = UIImage(data: imageData)
                            self.adImage.image = image
                        }
                    }
                    
                case "source":
                    self.adSourceLabel.text = asset.value
                    
                case "secHqBrandingLogo":
                    if let url = NSURL(string: asset.value) {
                        if let imageData = NSData(contentsOfURL: url) {
                            self.adSponsoredImage.image = UIImage(data: imageData)
                        }
                    }
                case "callToAction":
                    //set the CTA button's title to be all uppercase
                    self.adCallToAction.setTitle(asset.value.uppercaseString, forState: [])
                    
                default: ();
                }
            }
        }
    }
    
    //this function is called every time the display state is changed
    func adNativeExpandToggled(nativeAd: FlurryAdNative!) {
        
        //if the display state was changed to collapsed
        if (self.expandableAd?.displayState == FLURRY_NATIVE_AD_COLLAPSED) {
            //call our function to show the collapsed view
            self.showCollapsed()
            
            // if the display states was changed to expanded
        } else if (self.expandableAd?.displayState == FLURRY_NATIVE_AD_EXPANDED){
            //call our function to show the expanded view
            self.showExpanded()
        }
    }
    
    func showCollapsed() {
        //set the view to be a tracked collapsed (pencil) view
        expandableAd?.setPencilViewToTrack(adView, withExpandButton: adExpandButton, andCTAButton: adCallToAction)
        
        //set the image and description height constraints to be 0, forcing them to hide
        //note that both of these constraints are >= constraints
        self.adImageHeightConstraint.constant = 0
        self.adDescriptionHeightConstraint.constant = 0
        
        //set the expand button's image to point down
        self.adExpandButton.setImage(UIImage(named: "expandArrow") , forState: [])
        
        //animate the constraint changes
        UIView.animateWithDuration(0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func showExpanded() {
        //set the view to be a tracked expanded view
        expandableAd?.setExpandedViewToTrack(adView, withExpandButton: adExpandButton, andCTAButton: adCallToAction)
        
        //set the image height proportional to the width of the screen and the description height to 90
        //note that both of these constraints are >= constraints
        self.adImageHeightConstraint.constant = self.view.bounds.width * (627/1200)
        self.adDescriptionHeightConstraint.constant = 90
        
        // set the expand button's image to point up
        self.adExpandButton.setImage(UIImage(named: "collapseArrow"), forState: [])
        
        //animate the constraint changes
        UIView.animateWithDuration(0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    //each time the expand button is clicked, change the display state of the ad - this will call adNativeExpandToggled()
    @IBAction func expandButtonClicked(sender: AnyObject) {
        if (self.expandableAd?.displayState == FLURRY_NATIVE_AD_COLLAPSED) {
            self.expandableAd?.displayState = FLURRY_NATIVE_AD_EXPANDED
            
        } else if (self.expandableAd?.displayState == FLURRY_NATIVE_AD_EXPANDED){
            self.expandableAd?.displayState = FLURRY_NATIVE_AD_COLLAPSED
        }
    }
    
    func updateMap() {
        //create a local search request and make the request our location string
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = location
        
        //arbitrarily create a region to "hint" this request (it does not matter because our locations are all over the world)
        let center = CLLocationCoordinate2DMake(35, -90);
        let span = MKCoordinateSpanMake(100, 100);
        let region = MKCoordinateRegionMake(center, span);
        request.region = region
        
        //create a search with our request and start it with a completion block
        let search = MKLocalSearch.init(request: request)
        search.startWithCompletionHandler { (response, error) in
            
            //check to make sure items were found in the response
            if let items = response?.mapItems {
                
                //take the first item found
                self.mapItem = items[0]
                
                //set our center coordiante, distance, pitch, and heading for our camera
                let coordinate = self.mapItem!.placemark.coordinate
                let distance: CLLocationDistance = 650
                let pitch: CGFloat = 60
                let heading = 90.0
                
                //create a camera with these parameters
                let camera = MKMapCamera(lookingAtCenterCoordinate: coordinate,
                    fromDistance: distance,
                    pitch: pitch,
                    heading: heading)
                
                //set the our map view's camera to the one we just created
                self.mapView.camera = camera
            }
        }
    }
    
    //this is called when the user presses the back button to be taken to the previous screen
    func navigationController(navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        //if the view controller we are going to is the main one
        if let _ = viewController as? ViewController {
            //end the timer for the logged Flurry event
            Flurry.endTimedEvent("post_clicked", withParameters: nil)
        }
    }
    
    
    @IBAction func openButtonPressed(sender: AnyObject) {
        
        //log event in Flurry that user opened this in the maps app
        Flurry.logEvent("opened_in_Maps", withParameters: ["place_name": location])
        
        //open the found maps item in the maps app with a hybrid satellite camera
        self.mapItem?.openInMapsWithLaunchOptions([MKLaunchOptionsMapTypeKey: 2])
        
    }
}