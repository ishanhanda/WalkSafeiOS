//
//  MKPolyline+MKPolyline_MKPolyline_EncodedString.h
//  hacknyu
//
//  Created by Ishan Handa on 19/02/17.
//  Copyright © 2017 Ishan Handa. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKPolyline (MKPolyline_MKPolyline_EncodedString)
+ (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString;
@end
