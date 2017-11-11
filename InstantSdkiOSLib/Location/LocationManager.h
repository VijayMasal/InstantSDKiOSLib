//
//  LocationManager.h
//  InstantSDK
//
//  Created by Vijay on 26/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "InstantDataBase.h"

typedef NS_ENUM(NSUInteger, LocationPermission)
{
    ///location permission fail
    LocationPermissionFail =0,
    ///location permission successfully
    LocationPermissionSuccess =1 ,
    ///phone usage enable
    LocationPermissionPhoneUsageEnable =2
};

static NSString * const lastlocationdatekey=@"lastlocationdate";
@interface LocationManager : NSObject<CLLocationManagerDelegate>
/*!
 * @discussion Create location manager singletone class. That class manages all location related information like location name,time,latitude,longitude and date.
 */

+(LocationManager *)sharedLocationManager;

@property(strong,nonatomic)CLLocationManager *locationManager;

@property (strong, nonatomic)CLGeocoder *geocoder;

@property(nonatomic)BOOL isStanderedLocation;

-(NSString *)cutNumberInto4DecimalPoint:(double)number;

/*!
 * @discussion called to start location service using significant change location.if location service successfully start handler returns status LocationPermissionSuccess .if location permission fail handler returns LocationPermissionFail.if phone usage is enable handler returns LocationPermissionPhoneUsageEnable.
 */
typedef void (^locationPermissionCustomCompletionBlock)(LocationPermission locationPermission);
-(void)startSignificantLocation:(locationPermissionCustomCompletionBlock)handler;

/*!
 * @discussion called to start location service using significant change location.if start significant location service successfully returns Yes otherwise No.
 */

- (BOOL )startSignificantLocation;

/*!
 * @discussion called to start location service using significant change location.if location service successfully start handler returns status 1 otherwise handler returns status 0.
 */

/*!
 * @discussion called to stop location service.if location service successfully stop handler returns Yes otherwise fail handler returns No.
 */
-(void)stopSignificantLocation:(void(^)(BOOL isStop))handler;

/*!
 * @discussion called to start location service using standered location service.
 */
-(void)startStanderedLocation;

/*!
 * @discussion called to update location time in place table of database when app moves from background to foregound and.
 
 */

-(void)backgroundToForgroundLocationUpdate;


/*!
 * @discussion calling update location using location array update current timestamp and returns location array.
 * @param location location is array contains of latitude, longitude, altitude, accuracy and timestamp.
 
 * @return returns location array to update location time.
 */


-(NSMutableArray *)updateLocatinTimeStamp:(NSArray *)location;


/*!
 * @discussion Saves Current location in NSUserDefaults to find last and current location time interval difference.
 */
-(BOOL)saveCurrentLocationInNSUserDefault:(NSMutableArray *)locations;

/*!
 * @discussion finding a last midnight using passed date.
 * @param date .
 * @return midnight date using passed date.
 */
-(NSDate *)midNightOfLastNight :(NSDate *)date;

/*!
 * @discussion find next midnight using passed date.
 * @param date .
 * @return next midnight using passed date.
 */

-(NSDate *)nextMidNight:(NSDate *)date;

/*!
 * @discussion Ckeck Location permission allow or denied.
 
 */
-(BOOL)checkLocationPermission;



@end




