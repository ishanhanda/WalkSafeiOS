//
//  ApiResponse.swift
//  NYT Best
//
//  Created by Ishan Handa on 20/09/16.
//  Copyright © 2016 Ishan Handa. All rights reserved.
//

import Foundation


/// Response instance used to communicate with the api.
struct AlamofireAPIResponse {
    let errorMsg: String?
    let errorCode: Int
    let responseObject: DirectionsResponse?
    let isSuccessful: Bool
    
    init(response: DirectionsResponse?, errorCode:Int, errorMessage:String?, successful:Bool) {
        self.responseObject = response
        self.errorCode = errorCode
        self.errorMsg = errorMessage
        self.isSuccessful = successful
    }
}
