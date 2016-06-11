# Yodel Travels- iOS Sample App in Swift

## Learning Goals
Yodel Travels is a recognized iOS sample app built in Swift using Yahoo’s Flurry. It was made to showcase Flurry’s analytics and ad-serving platforms and demonstrate best practices for logging analytics events and implementing native and expandable ads. By reviewing the well-commented sample code a Swift developer can learn how to best:
* Implement monetizable native ads into an infinite table view

    * Set up an ad space

    * Asynchronously fetch ads

    * Initialize and display ad assets

    * Track the view for the ad

* Create insightful events in an analytics platform

    * Establish Key Performance Indicators

    * Name events and event parameters (view-object-action)

    * Log events

* Other useful learnings 

    * Pulling content via the Tumblr API and NSURL requests

    * Manipulating MapKit to use natural language search

## App Goals

Yodel Travels is also a fully-functional app with it’s own intrinsic purpose. Essentially, it allows users to discover unexpected travel destinations and then virtually explore them. App success is measured by users exploring destinations, but also by users occasionally clicking ads to earn revenue for the publisher. To analyze this we must establish Key Performance Indicators (KPIs).
* User Success
    * User clicks a destination to explore in 3D flyover view
    * User goes to this destination in the Apple Maps app
* Publisher Success
    * User clicks an ad
    * User completes the task inside an ad (ie. downloading an app)

Questions to consider to create parameters that measure this success:
  * How much time did the user spend exploring this destination?
  * Did this destination have a 3D flyover view?
  * What was the name of this destination?
  * At what position in the feed was this destination/Ad?

## Requirements:

- Xcode 7+
- iOS 9.0+

Open yodelsampleswift.xcworkspace in Xcode to begin working with the project.

This repository comes bundled with the following libraries:

- Flurry SDK v7.6.3 via Cocoapods (required for support of native ads and analytics)

You can adjust the Pod versions by using [Cocoapods](http://cocoapods.org/).

## Get Started With Flurry

For more info on getting started with Flurry for iOS, see
[here](https://developer.yahoo.com/flurry/docs/analytics/gettingstarted/ios/).

## License

Licensed under the terms of the zLib license:

Copyright 2016 Yahoo Inc.

This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
