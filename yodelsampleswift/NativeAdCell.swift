//
//  NativeAdCell.swift
//  yodelsampleswift
//
//  Copyright 2016 Yahoo! Inc.
//
//  Licensed under the terms of the zLib license. Please see LICENSE file in the project root for terms.
//

import Flurry_iOS_SDK
import UIKit

class NativeAdCell: UITableViewCell {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var streamTitleLabel: UILabel!
    @IBOutlet weak var streamDescriptionLabel: UILabel!
    @IBOutlet weak var streamImageView: UIImageView!
    @IBOutlet weak var streamSponsoredLabel: UILabel!
    @IBOutlet weak var streamSponsoredImageView: UIImageView!
    @IBOutlet weak var streamSourceLabel: UILabel!
    
    var nativeAd: FlurryAdNative!
    
    //override this cell's perepare for reuse function (called when the cell is moving off screen and will be recycled)
    override func prepareForReuse() {
        //remove the ad-tracking view from this cell so we can assign a new tracking view
        nativeAd.removeTrackingView()
    }
}

