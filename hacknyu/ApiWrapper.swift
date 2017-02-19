//
//  ApiWrapper.swift
//  NYT Best
//
//  Created by Ishan Handa on 20/09/16.
//  Copyright © 2016 Ishan Handa. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

class NYTimesAPIWrapper  {
    static let sharedInstance = NYTimesAPIWrapper()

    fileprivate let baseURL = "http://ec2-54-208-250-157.compute-1.amazonaws.com:5000/directions"

    typealias CompletionBlock = (AlamofireAPIResponse) -> Void
}


// MARK: - API Interaction Methods

extension NYTimesAPIWrapper {
    
    func getDirections(to: String, from: String, completion: @escaping CompletionBlock) {
        let urlString = baseURL
        print("Starting Directions request with URL String: \(urlString)")
        
        let params = ["from": from,
                      "to": to]
        print("Parameters: \(params)")
        
        Alamofire.request(urlString, parameters: params).responseObject { (response: DataResponse<DirectionsResponse>) in
            print(response.request as Any)  // original URL request
            print(response.response as Any) // HTTP URL response
            print(response.data as Any)     // server data
            print(response.result)   // result of response serialization
            
            if let error = response.result.error {
                print(error.localizedDescription)
                let apiResponse = AlamofireAPIResponse.init(response: nil, errorCode: 0, errorMessage: error.localizedDescription, successful: false)
                completion(apiResponse)
            } else if let directionsResponse = response.result.value {
                print(directionsResponse)
                let routes = directionsResponse.routes!.sorted { $0.crimeRate! < $1.crimeRate! }
                directionsResponse.routes = routes
                let apiResponse = AlamofireAPIResponse.init(response: directionsResponse, errorCode: 0, errorMessage: nil, successful: true)
                completion(apiResponse)
            }
            
            if let directionsResponse = response.result.value {
                print(directionsResponse)
            }
            
            if let JSON = response.result.value {
                print("JSON: \(JSON)")
            }
        }
    }
}
