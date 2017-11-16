//
//  LocationManager.h
//  InstantSDK
//
//  Created by Vijay on 26/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "InstantDataBase.h"

typedef NS_ENUM(NSUInteger, LocationPermission)
{
    ///location permission fail
    LocationPermissionFail =0,
    ///location permission successful
    LocationPermissionSuccess =1 ,
    ///phone usage enable
    LocationPermissionPhoneUsageEnable =2
};

static NSString * const lastlocationdatekey=@"lastlocationdate";
@interface LocationManager : NSObject<CLLocationManagerDelegate>
/*!
 * @discussion Creates location manager singletone class. It manages all location related information like location name,time,latitude,longitude and date.
 */

+(LocationManager *)sharedLocationManager;

@property(strong,nonatomic)CLLocationManager *locationManager;

@property (strong, nonatomic)CLGeocoder *geocoder;

@property(nonatomic)BOOL isStanderedLocation;

-(NSString *)cutNumberInto4DecimalPoint:(double)number;

/*!
 * @discussion Starts location service using significant change location. If location service successfully starts handler returns status LocationPermissionSuccess. If location permission fails handler returns LocationPermissionFail. If phone usage is enabled handler returns LocationPermissionPhoneUsageEnable.
 */
typedef void (^locationPermissionCustomCompletionBlock)(LocationPermission locationPermission);
-(void)startSignificantLocation:(locationPermissionCustomCompletionBlock)handler;

/*!
 * @discussion Starts location service using significant change location. If significant location service starts successfully returns Yes otherwise No.
 */
- (BOOL )startSignificantLocation;



/*!
 * @discussion Stops location service. If location service successfully stop handler returns Yes otherwise fail handler returns No.
 */
-(void)stopSignificantLocation:(void(^)(BOOL isStop))handler;

/*!
 * @discussion Starts location service using standard location service.
 */
-(void)startStanderedLocation;

/*!
 * @discussion Updates location time in place table of database when app moves from background to foregound and.
 
 */

-(void)backgroundToForgroundLocationUpdate;


/*!
 * @discussion Updates location using location array update current timestamp and returns location array.
 * @param location location is array contains of latitude, longitude, altitude, accuracy and timestamp.
 
 * @return returns location array to update location time.
 */


-(NSMutableArray *)updateLocatinTimeStamp:(NSArray *)location;


/*!
 * @discussion Saves current location in NSUserDefaults to find last and current location time interval difference.
 */
-(BOOL)saveCurrentLocationInNSUserDefault:(NSMutableArray *)locations;

/*!
 * @discussion Finds a last midnight using passed date.
 * @param date .
 * @return midnight date using passed date.
 */
-(NSDate *)midNightOfLastNight :(NSDate *)date;

/*!
 * @discussion Finds next midnight using passed date.
 * @param date .
 * @return next midnight using passed date.
 */

-(NSDate *)nextMidNight:(NSDate *)date;

/*!
 * @discussion Ckecks Location permission allow or denied.
 
 */
-(BOOL)checkLocationPermission;



@end




