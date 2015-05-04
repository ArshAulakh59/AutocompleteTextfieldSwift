//
//  ViewController.swift
//  AutocompleteTextfieldSwift
//
//  Created by Mylene Bayan on 2/21/15.
//  Copyright (c) 2015 MaiLin. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, AutocompleteTextFieldDelegate, NSURLConnectionDataDelegate{

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var autocompleteTextfield: AutocompleteTextfield!
  
  private var responseData:NSMutableData?
  private var selectedPointAnnotation:MKPointAnnotation?
  private var connection:NSURLConnection?
  
  private let googleMapsKey = "AIzaSyD8-OfZ21X2QLS1xLzu1CLCfPVmGtch7lo"
  private let baseURLString = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    configureView()
    //initializeLocationServices()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  private func configureView(){
    autocompleteTextfield.autoCompleteDelegate = self
    autocompleteTextfield.autoCompleteTextColor = UIColor.lightGrayColor()
    autocompleteTextfield.autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)
    autocompleteTextfield.autoCompleteCellHeight = 35.0
    autocompleteTextfield.maximumAutoCompleteCount = 3
    autocompleteTextfield.hideWhenSelected = true
    autocompleteTextfield.hideWhenEmpty = false
    autocompleteTextfield.enableAttributedText = false
    var attributes = Dictionary<String,AnyObject>()
    attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
    attributes[NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12.0)
    autocompleteTextfield.autoCompleteAttributes = attributes
  }
  
  //MARK: AutocompleteTextFieldDelegate
  
  func autoCompleteTextFieldDidChange(text: String) {
    if !text.isEmpty{
      if connection != nil{
        connection!.cancel()
        connection = nil
      }
      let urlString = "\(baseURLString)?key=\(googleMapsKey)&input=\(text)"
      let url = NSURL(string: urlString.stringByAddingPercentEscapesUsingEncoding(NSASCIIStringEncoding)!)
      if url != nil{
        let urlRequest = NSURLRequest(URL: url!)
        connection = NSURLConnection(request: urlRequest, delegate: self)
      }
    }
  }
  
  func didSelectAutocompleteText(text: String, indexPath: NSIndexPath) {
    println("You selected: \(text)")
    Location.geocodeAddressString(text, completion: { (placemark, error) -> Void in
      if placemark != nil{
        let coordinate = placemark!.location.coordinate
        self.addAnnotation(coordinate, address: text)
        self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: true)
      }
    })
  }
  
  //MARK: NSURLConnectionDelegate
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
    responseData = NSMutableData()
  }
  
  func connection(connection: NSURLConnection, didReceiveData data: NSData) {
    responseData?.appendData(data)
  }

  func connectionDidFinishLoading(connection: NSURLConnection) {
    if responseData != nil{
      var error:NSError?
      if let result = NSJSONSerialization.JSONObjectWithData(responseData!, options: nil, error: &error) as? NSDictionary{
        let status = result["status"] as? String
        if status == "OK"{
          if let predictions = result["predictions"] as? NSArray{
            var locations = [String]()
            for dict in predictions as! [NSDictionary]{
              locations.append(dict["description"] as! String)
            }
            self.autocompleteTextfield.autoCompleteStrings = locations
          }
        }
      }
    }
  }
  
  func connection(connection: NSURLConnection, didFailWithError error: NSError) {
    println("Error: \(error.localizedDescription)")
  }
  
  //MARK: Map Utilities
  private func addAnnotation(coordinate:CLLocationCoordinate2D, address:String?){
    if selectedPointAnnotation != nil{
      mapView.removeAnnotation(selectedPointAnnotation)
    }
    
    selectedPointAnnotation = MKPointAnnotation()
    selectedPointAnnotation?.coordinate = coordinate
    selectedPointAnnotation?.title = address
    mapView.addAnnotation(selectedPointAnnotation)
  }
}

