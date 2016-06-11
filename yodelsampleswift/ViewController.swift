//
//  ViewController.swift
//  yodelsampleswift
//
//  Copyright 2015 Yahoo! Inc.
//
//  Licensed under the terms of the zLib license. Please see LICENSE file in the project root for terms.
//

import UIKit
import Flurry_iOS_SDK
import MapKit


class ViewController: UIViewController, FlurryAdNativeDelegate, UITableViewDelegate, UITableViewDataSource  {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var activityFooter: UIActivityIndicatorView!
    
    //this count will go down to 0 when we have the ads, here we set it to what we want initially
    var nativeAdsWanted = 3
    
    //how many posts we want on startup and how many we want to load when the user gets to the end of the feed
    let initialPostsWanted = 9
    let additionalPostsToGet = 6
    
    //how many times we want to retry fetching ads and a count that makes sure we don't go over this
    let adFetchRetryMaximum = 10
    var adFetchRetryCount = 0
    
    //this keeps track of what post index we are at so that we dont pull the same posts from Tumblr
    var postIndex = 0
    
    //this string will be updated to a location when the user clicks a post cell and then passed to the map view controller
    var locationToPass = ""
    
    // this bool will be true when we are not currently waiting on posts and false if we are
    var shouldGetPosts = true

    var posts: [PostClass] = []{
        didSet{
            //when posts are added reload the table view on the main thread
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                
            //because posts have been returned, set this variable to true
            self.shouldGetPosts = true
            
            })
        }
    }
    
    // this list will hold ads that we have requested but are not ready
    var pendingAdList: [FlurryAdNative] = []
    // this list will hold our ready ads that will be dispalyed
    var nativeAdList: [FlurryAdNative] = [] {
        didSet {
            //when ads are added reload the table view
            self.tableView.reloadData()
            
        }
    }
 

    
    override func viewDidLoad() {
     
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //makes the back bar button item not include the previous contoller's title
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        //removes the separators by making them invisible
        self.tableView.separatorColor = UIColor.clearColor()
        
        self.setupAds()
        
        callGetPosts(initialPostsWanted)
        
        super.viewDidLoad()
        
    }
    
    func callGetPosts(postsWanted: Int) {
        
        //If we are not currently waiting on posts, this calls our get posts method
        if self.shouldGetPosts == true {
            
            getPosts(String(postsWanted), source: "breathtakingdestinations", index: String(postIndex)) { (postDictionaries) -> Void in
                
                //pass our post dictionaries to our parsePosts function to return instances of the PostClass class
                let newPosts = parsePosts(postDictionaries)
                
                //for each new post, start downloading the image
                for newPost in newPosts {
                    downloadImageForPost(newPost, success: { (returnedPost) -> Void in
                        
                        //once image is downloaded append this post to our list of posts ready to be displayed
                        self.posts.append(returnedPost)
                        
                    })
                }
            }
            //adds the number posts we wanted to the post index so next time we'll start grabbing posts at that point
            postIndex = postIndex + postsWanted
            
            //sets this to false while we are waiting on the posts to be returned
            self.shouldGetPosts = false
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //our table view is all one section and we want as many rows as we have posts
        return posts.count + nativeAdList.count
        
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //looks at the row to insert an ad at the beginning and then every 4th post
        //also checks to make sure there are enough ads in the native ad list
        if indexPath.row % 4 == 0 && nativeAdList.count > indexPath.row / 4 {
            
            let cellIndex = indexPath.row/4
            
            let cell = self.tableView.dequeueReusableCellWithIdentifier("adCell") as! NativeAdCell
            
            //makes the cell view rounded
            cell.view.layer.cornerRadius = 10
            cell.view.clipsToBounds = true
            //makes the highlight around the cell when it is tapped rounded
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            
            //sets a property of the cell to contain the ad
            //this allows us to remove the tracking view when the cell gets reused
            cell.nativeAd = nativeAdList[cellIndex]
            
            self.nativeAdList[cellIndex].trackingView = cell
            
            
            if let assets = nativeAdList[cellIndex].assetList{
                for asset in assets {
                    switch(asset.name!) {
                    case "headline":
                        cell.streamTitleLabel.text = asset.value;
                        
                    case "summary":
                        cell.streamDescriptionLabel.text = asset.value
                        
                    case "secHqImage":
                        if let url = NSURL(string: asset.value!!) {
                            if let imageData = NSData(contentsOfURL: url) {
                                let image = UIImage(data: imageData);
                                cell.streamImageView.image = image
                            }
                        }
                        
                    case "source":
                        //add the word "by" to our label to fit the style
                        cell.streamSourceLabel.text = "by \(asset.value as String)";
                        
                    case "secHqBrandingLogo":
                        if let url = NSURL(string: asset.value!!) {
                            if let imageData = NSData(contentsOfURL: url) {
                                cell.streamSponsoredImageView.image = UIImage(data: imageData);
                            }
                        }
                        
                    default: ();
                        
                    }
                }
            }
            return cell
            
        
        //if we are out of ads but this is where an ad should go,
        //or if we do not yet have enough ready posts to fill the spot,
        //we'll put in an empty cell with a height of zero
        } else if indexPath.row % 4 == 0 || (indexPath.row * 3 / 4) > posts.count - 1 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("emptyCell")
            return cell!

         //create cells from Tumblr posts we retrieved if this cell is not a multiple of 4 or we ran out of ads
        } else {
            
            //this produces an inclusive index for the posts for when every 4th cell is an ad
            let cellIndex = indexPath.row * 3 / 4

            let cell = self.tableView.dequeueReusableCellWithIdentifier("postCell") as! TumblrPostCell
            
            //makes the cell view rounded
            cell.view.layer.cornerRadius = 10
            cell.view.clipsToBounds = true
            //makes the highlight around the cell when it is tapped rounded
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            
            cell.postImageView.image = posts[cellIndex].image
            cell.blogLabel.text = posts[cellIndex].blog_title
            cell.descriptionLabel.text = posts[cellIndex].place
            cell.titleLabel.text = posts[cellIndex].title
            cell.sourceLabel.text = posts[cellIndex].source
            
            cell.imageViewHeight.constant = (CGFloat(posts[cellIndex].height ?? 16) / CGFloat(posts[cellIndex].width ?? 9)) * self.view.bounds.width * 0.8
           
            return cell
    }
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        //if this is an ad cell it will be a shorter than the post cells
        if indexPath.row % 4 == 0 && nativeAdList.count > indexPath.row / 4 {
            return self.view.bounds.width * (9/16) + 90
            
        //if we are out of ads but this is where an ad should go,
        //or we don't yet have enought posts to fill this space
        //we'll put in an empty cell with a height of zero
        } else if indexPath.row % 4 == 0 || (indexPath.row * 3 / 4) > posts.count - 1 {
            return 0
            
        //if this is a post cell, set the height to 390
        } else {
            //get the index of the cell from its list
            let cellIndex = indexPath.row * 3 / 4
            let height = posts[cellIndex].height ?? 9
            let width = posts[cellIndex].width ?? 16
            
            return self.view.bounds.width * 0.8 * (CGFloat(height)/CGFloat(width)) + 100
        }
        
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // if the cell about to be displayed is the third to last last cell, get more posts to create infinite scrolling
        if indexPath.row >= posts.count + nativeAdList.count - 3{
            
            //call a function to get more cells
            self.callGetPosts(additionalPostsToGet)
            
            //get an amount of ads equal to a third of the posts
            self.nativeAdsWanted = additionalPostsToGet/3
            self.setupAds()
            
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //deselect the row
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //if this is not an ad
        if indexPath.row % 4 != 0 {
            
            //get the index of the cell from its list
            let cellIndex = indexPath.row * 3 / 4
            
            //use this index to get the location of the picture in the post ex. Seattle, Washington
            self.locationToPass = "\(posts[cellIndex].title ?? " "), \(posts[cellIndex].place ?? " ")"
            
            //log in Flurry that the user clicked a picture, log where it was in the stream, log the the name of the place they clicked, and start a timer to measure how long they explore this place
            Flurry.logEvent("post_clicked", withParameters: ["location_in_stream": String(indexPath.row), "place_name": String(self.locationToPass)], timed: true)
            
            //start a segue to go to the maps
            self.performSegueWithIdentifier("mapSegue", sender: self)
          
        // if this is an ad
        } else {
            
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // make sure this segues is the one to the MapView Controller
        if segue.identifier == "mapSegue" {
            if let controller = segue.destinationViewController as? MapViewController {
                
                //pass the location we set when the cell was clicked to the MapViewController
                controller.location = locationToPass
            }
           
        }
    }
    
    func setupAds() {
        
        //creates empty list to add ads to
        var newAdsList : [FlurryAdNative] = []
        
        //only get new ads if we want at least one
        if nativeAdsWanted >= 1 {
            for _ in 1...nativeAdsWanted {
                let nativeAd = FlurryAdNative(space: "SwiftYodelTravelsStreamAdSpace")
                
                //            // uncomment to make these ads test ads (should enable 100% fill)
                //            let adTargeting = FlurryAdTargeting()
                //            adTargeting.testAdsEnabled = true
                //            nativeAd.targeting = adTargeting
                
                //setting the ad delegate a view controller
                nativeAd.adDelegate  = self
                nativeAd.viewControllerForPresentation = self
                
                //fetching the ad from Flurry and then addding it to our list of new ads
                nativeAd.fetchAd()
                newAdsList.append(nativeAd)
            }
        }
        
        //updating our ad list to be our new ad list
        pendingAdList = newAdsList
    }
    
    func adNativeDidFetchAd(nativeAd: FlurryAdNative!) {
        NSLog("Native Ad for Space \(nativeAd.space) Received Ad with \(nativeAd.assetList.count) assets")
        
        nativeAdsWanted = nativeAdsWanted - 1
        
        //every time an ad is fetched this checks to see if there are any ready ads
        for ad in pendingAdList {
            if ad.ready {
                if let i = pendingAdList.indexOf(ad) {
                    pendingAdList.removeAtIndex(i)
                    nativeAdList.append(ad)
                } else {
                     print ("index in pending list does not exist")
                }
            }
        }
        
    }
    
    func adNative(nativeAd: FlurryAdNative!, adError: FlurryAdError, errorDescription: NSError!) {
        NSLog("Native Ad for Space \(nativeAd.space) Received Error \(adError), with description: \(errorDescription)")
        
        //retrys fetching ads a set max number of times after three seconds if ad fetching fails
        if adFetchRetryCount < adFetchRetryMaximum {
            let selector: Selector = #selector(ViewController.setupAds)
            _ = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: selector, userInfo: nil, repeats: false)
        } else { print (("AD FETCH FAILED"))
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        //For the purpose of this sample app, we will not be handle memory warnings - but you can do that here.
        //Developers should note that this app will eventually crash because of all the photos it is caching if users continue to scroll infinitiely.
        //An easy fix might just be setting a limit on how many post objects can be held. This would delete older posts as new ones came in but then users would not be able to see the posts back at the top
        //The best fix would be to create code that deletes and reload sposts at the top and bottom of the feed dynamically
        
    }
}

