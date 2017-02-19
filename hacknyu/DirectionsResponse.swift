//
//  DirectionsResponse.swift
//  hacknyu
//
//  Created by Ishan Handa on 19/02/17.
//  Copyright © 2017 Ishan Handa. All rights reserved.
//

import Foundation
import ObjectMapper

class Location: Mappable {
    var lat: Double?
    var long: Double?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        lat <- map["lat"]
        long <- map["lon"]
    }
}

class Route: Mappable {
    
    var crimeLocations: [Location]?
    var crimeRate: Double?
    var departureOffset: Double?
    var polyline: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        crimeLocations <- map["crime_locations"]
        crimeRate <- map["crime_rate"]
        departureOffset <- map["departure_offset"]
        polyline <- map["polyline"]
    }
}


class DirectionsResponse: Mappable {
    
    var departure: Int?
    var from: String?
    var to: String?
    var routes: [Route]?
    var travelMode: String?

    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        departure <- map["departure"]
        from <- map["from"]
        to <- map["to"]
        routes <- map["routes"]
        travelMode <- map["travel_mode"]
    }
}
