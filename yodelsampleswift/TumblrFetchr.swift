//
//  TumblrFetchr.swift
//  yodelsampleswift
//
//  Copyright 2016 Yahoo! Inc.
//
//  Licensed under the terms of the zLib license. Please see LICENSE file in the project root for terms.
//

import Foundation
import UIKit


public func getPosts(amount: String, source: String, index: String, success: ((postsDictionaries: NSDictionary!) -> Void)) {
    
    //create a url with the variables we need to request picture posts from the Tumblr API
    let formattedUrl = NSURL(string: "https://api.tumblr.com/v2/blog/\(source).tumblr.com/posts/photo?api_key=PwUMdp5I7xesNof05NprxPrMJIwTNdxSMETzFkIg8V4yfQ7Rzj&limit=\(amount)&offset=\(index)")
    
    //create session and request
    let session = NSURLSession.sharedSession()
    let request = NSURLRequest(URL: formattedUrl!)
    
    //start a GET request that will return a response with our post data as a JSON
    session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
        if error == nil {
            //convert the data returned from the request into a JSON object, use no reading options
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0))
                //force this json into NSDictionary form and return it to be parsed through
                success(postsDictionaries: json as! NSDictionary)
            } catch {
                print ("Error with converting data from Tumblr")
            }
            
        } else {
            print ("Error with fetching data from Tumblr")
        }
    }).resume()
}



public func parsePosts(data: NSDictionary) -> ([PostClass]) {
    
    //create an empty list for post objects
    var newPosts: [PostClass] = []
    
    //make sure our response exists and continas posts
    if let response = data["response"] as? [String: AnyObject] {
        if let posts = response["posts"] as? [AnyObject] {
            
            //parse through each post returned, making sure each object exisits before adding it to a post instance
            for post in posts {
                
                let postInstance = PostClass()
                postInstance.blog_title = post["blog_name"] as? String
                let info = post["summary"] as? String
                
                //separates our summary string (description of the picture) into parts by these characters
                let separatedString: [String] = info!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "()"))
                
                // finds the name of the person by looking for the word "by"
                for str in separatedString {
                    if str.containsString("by") {
                        postInstance.source = str
                    }
                    
                    //if the post does not fit our format (contains these dashes) we will skip it and not add the post object to our list of post objects to be passed
                    if str.containsString("- ") {
                        
                        //separates the locations for example "Eiffel Tower - France" -> ["Eiffel Tower ", "France"] and sets them to be title and place, respectively
                        let locations = str.componentsSeparatedByString("- ")
                        postInstance.title = locations[0]
                        postInstance.place = locations[1]
                        
                        //makes sure photos were returned for the post and looks through them
                        if let photos = post["photos"] as? [AnyObject] {
                            for photo in photos {
                                
                                //gets the URL to download the largest photo (original size)
                                if let original_size = photo["original_size"] as? [String: AnyObject] {
                                    if let url = original_size["url"] as? String {
                                        postInstance.url = url
                                        
                                        //gets the height and width of the photo so we now how to size our cell later
                                        postInstance.height = original_size["height"] as? Int
                                        postInstance.width = original_size["width"] as? Int
                                        
                                        //finally, if a post has had all of these attributes, it is added to our list of new post objects
                                        newPosts.append(postInstance)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return newPosts
    
}

public func downloadImageForPost(post: PostClass, success:(post: PostClass) -> Void)  {
    
    //makes sure url exists
    if let url = post.url {
        
        //creates a NSURL, session, and request
        let formattedUrl = NSURL(string: url)
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: formattedUrl!)
        
        //starts a GET request that will return data for the photo
        session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
            
            //converts the data returned into a UIImage
            post.image = UIImage(data: data!)
            
            //returns the post object
            success(post: post)
     
        }).resume()
    }
}

