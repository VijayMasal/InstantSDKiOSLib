//
//  LocationManager.m
//  InstantSDK
//
//  Created by Vijay on 26/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 12/09/17
//  Reviewed on 12/11/17

#pragma mark -Location
#import "LocationManager.h"
#import "LocationNameAndTime.h"
#import "ActivityManager.h"
#import "SleepManager.h"
#import "StepsManager.h"
@implementation LocationManager
/// Creates location manager singletone class. That class manages all location related information like location name, time, latitude, longitude and date.
static LocationManager *sharedLocationManager=nil;
+(LocationManager *)sharedLocationManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[LocationManager alloc] init];
        
    });
    
    return sharedLocationManager;
}

/// Initializes all locations related object using CoreLocation Framework
-(id)init
{
    
    if (self==[super init])
    {
        [self locationManagerInit];
        _geocoder=[[CLGeocoder alloc]init];
        
    }
    return self;
    
    
}

-(void)locationManagerInit
{
    _locationManager=[[CLLocationManager alloc]init];
    [_locationManager requestAlwaysAuthorization];
    _locationManager.delegate=self;
    if ([_locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)])
    {
        if(@available(iOS 9.0, *)) {
       
        [_locationManager setAllowsBackgroundLocationUpdates:YES];
        }
    }
   
    _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    _locationManager.distanceFilter = 500;
    _locationManager.pausesLocationUpdatesAutomatically=NO;
    
}
/// Starts location service using significant change location, if location service is successfully started handler returns status LocationPermissionSuccess. If location permission fail handler returns LocationPermissionFail. If phone usage is enabled handler returns LocationPermissionPhoneUsageEnable.

-(void)startSignificantLocation:(locationPermissionCustomCompletionBlock)handler
{  LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isOnPhoneUsage==YES)
    {
        handler(LocationPermissionPhoneUsageEnable);
    }
    else
    {
        BOOL isStart=[self startSignificantLocation];
        if (isStart==YES)
        {
            
            handler(LocationPermissionSuccess);
            
        }
        else
        {
            
            handler(LocationPermissionFail);
        }
    }
    
}

/// Starts location tracking using significant change location method
-(BOOL)startSignificantLocation
{
[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"significantLocationEnable"];
    BOOL isAuthorize= [self checkLocationPermission];
    //if loaction service authorization is successful then start location using significant change location
    if (isAuthorize==YES)
    {
        _locationManager=nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults]setValue:@"significant" forKey:@"location"];
        });
        [self locationManagerInit];
        [_locationManager startMonitoringSignificantLocationChanges];
    }
    
    return isAuthorize;
    
}

/// Called to stop location service. If location service successfully stops handler returns status 1 otherwise fail handler returns 2.

-(void)stopSignificantLocation:(void(^)(BOOL isStop))handler
{
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isSignificantLocation==YES)
    {
        permissions.isSignificantLocation=NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"significantLocationEnable"];
        });
    }
    
    
}


/// Called to start location service using standered location service.
-(void)startStanderedLocation
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults]setValue:@"standered" forKey:@"location"];
    });
    [_locationManager startUpdatingLocation];
    NSMutableArray *locations=[[NSMutableArray alloc]init];
    
    CLLocation *updateLocation=[[CLLocation alloc]initWithCoordinate:CLLocationCoordinate2DMake(_locationManager.location.coordinate.latitude, _locationManager.location.coordinate.longitude) altitude:_locationManager.location.altitude horizontalAccuracy:_locationManager.location.horizontalAccuracy verticalAccuracy:_locationManager.location.verticalAccuracy timestamp:[NSDate date]];
    [locations addObject:updateLocation];
    
    
    [self checkLocationExistsOrNotInDataBase:locations locationTime:0 startDate:[NSDate date] endDate:[[NSDate date]dateByAddingTimeInterval:60] numberOfDays:0];
    
    
}

-(BOOL)checkLocationPermission
{
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    
    BOOL isAuthorize=NO;
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        isAuthorize=NO;
        //If location service not enabled then show location permission alert on view
        
        
    } else
    {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted)
        {
            isAuthorize=NO;
            if (permissions.isOnPhoneUsage==YES || permissions.isSignificantLocation == YES)
            {
                [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"location"];
            }
            
            
        }
        else
        {
            isAuthorize=YES;
            if (permissions.isOnPhoneUsage==YES)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSUserDefaults standardUserDefaults]setValue:@"standered" forKey:@"location"];
                });
            }
            else if (permissions.isSignificantLocation==YES)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSUserDefaults standardUserDefaults]setValue:@"significant" forKey:@"location"];
                });
            }
        
        }
    }
    
    return isAuthorize;
}

#pragma mark -Significant Location
/** Gets location updates when the user changes their location (sometimes gets triggered at same place) like Latitude, Longitude, Horizontal Accuracy, Vertical Accuracy, TimeStamp,Speed. Can be called even if the app is closed by the user. */
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    LocationNameAndTime *locationType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    
    if (locationType.isSignificantLocation==YES)
    {
        NSData *lastlocationData=[[NSUserDefaults standardUserDefaults]objectForKey:@"lastLocation"];
        
        NSArray *lastlocations=[NSKeyedUnarchiver unarchiveObjectWithData:lastlocationData];
        
        NSMutableArray *updateLocation=[self updateLocatinTimeStamp:locations];
        
        
        [self saveCurrentLocationInNSUserDefault:updateLocation];
        
        if (lastlocationData)
        {
            
            [self findLocationTimeInterval:lastlocations];
        }
        else
        {
            
            [self findLocationTimeInterval:updateLocation];
        }
    }
}

/// Saves Current location in NSUserDefaults to find last and current location time interval difference.
-(BOOL)saveCurrentLocationInNSUserDefault:(NSMutableArray *)locations
{
    NSData *currentlocationData=[NSKeyedArchiver archivedDataWithRootObject:locations];
    [[NSUserDefaults standardUserDefaults]setObject:currentlocationData forKey:@"lastLocation"];
    return YES;
    
}

///Updates location timeStamp at the time of installation and when app moves from background to foreground
-(NSMutableArray *)updateLocatinTimeStamp:(NSArray *)location
{
    NSMutableArray *locations=[[NSMutableArray alloc]init];
    
    CLLocation *lastLocation=[location lastObject];
    CLLocation *updateLocation=[[CLLocation alloc]initWithCoordinate:CLLocationCoordinate2DMake(lastLocation.coordinate.latitude, lastLocation.coordinate.longitude) altitude:lastLocation.altitude horizontalAccuracy:lastLocation.horizontalAccuracy verticalAccuracy:lastLocation.verticalAccuracy timestamp:[NSDate date]];
    [locations addObject:updateLocation];
    
    return locations;
}

/// Updates last location time stamp, using last stored location when the app moves from background to foreground
-(void)backgroundToForgroundLocationUpdate
{
    //[self checkLocationPermission];
    LocationNameAndTime *locationType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (locationType.isSignificantLocation==YES)
    {
        
        NSData *lastlocationData=[[NSUserDefaults standardUserDefaults]objectForKey:@"lastLocation"];
        NSArray *lastlocations=[NSKeyedUnarchiver unarchiveObjectWithData:lastlocationData];
        
        if (lastlocationData)
        {
            //L14
            NSMutableArray *updateLocation=[self updateLocatinTimeStamp:lastlocations];
            
            //L13
            [self saveCurrentLocationInNSUserDefault:updateLocation];
            
            if (lastlocations!=nil && lastlocations.count>0)
            {
                //L5
                [self findLocationTimeInterval:lastlocations];
            }
            else
            {
                //L5
                [self findLocationTimeInterval:updateLocation];
            }
            
        }
    }
    
}

///Finds the number of days that for which place time needs to be updated in case significant location isn't triggered for multiple days (Worst case scenario, normally significant location gets triggered every few hours. )
-(void)findLocationTimeInterval:(NSArray *)locations
{
    //last inserted location date
    CLLocation *lastLocation=[locations lastObject];
    NSDate *lastLocationDate=lastLocation.timestamp;
    NSDate *currentDate=[NSDate date];
    NSDateComponents *components;
    NSInteger numberOfDay=0;
    LocationNameAndTime *LocationNameAndTime;
    if (lastLocationDate)
    {
        
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        //L10
        NSDate* midnightLastNight = [self midNightOfLastNight:lastLocationDate];
        
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:midnightLastNight
                                            toDate:currentDate
                                           options:0];
        numberOfDay=[components day];
        
        [LocationNameAndTime setNumberOfDay:@(numberOfDay)];
    }
    
    
    [self findLocationDayandTime:numberOfDay locations:locations];
    
}

/// Gets last midnight using previous date (Used to split the place time data between 2 days)
-(NSDate *)midNightOfLastNight :(NSDate *)date
{
    
    NSCalendar *gregorian1 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateComponents = [gregorian1 components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    
    NSDate* findMidNightDate = [gregorian1 dateFromComponents:dateComponents];
    return findMidNightDate;
}
/// Gets next day's midnight using passed date (Used to split the place time data between 2 days)
-(NSDate *)nextMidNight:(NSDate *)date
{
    
    NSCalendar *const calendar = NSCalendar.currentCalendar;
    NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *const components = [calendar components:preservedComponents fromDate:date];
    NSDate *const normalizedDate = [calendar dateFromComponents:components];
    return normalizedDate;
}

/// Finds Location day and time- if location has not changed from N number of days then find n number of location days and time (Worse case condition, generally significant location triggers few times in a day) It also will manage fitness & sleep data
-(void)findLocationDayandTime:(NSInteger )numberOfDay locations:(NSArray *)locations
{
    CLLocation *location=[locations lastObject];
    NSInteger addTime=0;
    NSDate *date=[NSDate date];
    if (numberOfDay>0)
    {
        for (int i=0; i<=numberOfDay; i++)
        {
            if (i==0)
            {
                //calculate  last location time from  Last MidNight
                NSDate *NextDate= [location.timestamp dateByAddingTimeInterval:1*24*60*60];
                
                NSDate *nextMidNight=[self nextMidNight:NextDate];
                addTime=[nextMidNight timeIntervalSinceDate:location.timestamp];
                
                
                
                [self checkLocationExistsOrNotInDataBase:locations locationTime:addTime startDate:location.timestamp endDate:[nextMidNight dateByAddingTimeInterval:-60] numberOfDays:numberOfDay];
                
                //Call Activity Manager to find Fitness Data
                [[ActivityManager sharedFitnessActivityManager]getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:location.timestamp] endDate:nextMidNight];
                [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:location.timestamp] endDate:nextMidNight];
                //
                
            }
            else
            {
                
                if (i==numberOfDay)
                {
                    // Calculates location time from midnight to now
                    NSDate *NextDate= [NSDate date];
                    
                    NSDate *lastMidNight=[self midNightOfLastNight:NextDate];
                    addTime=[date timeIntervalSinceDate:lastMidNight];
                    
                    [self checkLocationExistsOrNotInDataBase:locations locationTime:addTime startDate:lastMidNight endDate:date numberOfDays:numberOfDay];
                    
                    //Calls Activity Manager to find Fitness Data
                    [[ActivityManager sharedFitnessActivityManager]getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:date];
                    [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:date];
                    
                    //Call sleep manager to get sleep data
                    [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:NextDate toEndTime:NextDate];
                    
                }
                else
                {
                    //Calculates location time from last midnight to tomorrow midnight
                    NSDate *lastDate= [location.timestamp dateByAddingTimeInterval:i*24*60*60];
                    NSDate *lastMidNight=[self midNightOfLastNight:lastDate];
                    
                    //mid night of tomorrow
                    NSDate *NextDate= [location.timestamp dateByAddingTimeInterval:(i+1)*24*60*60];
                    NSDate *nextMidNight=[self nextMidNight:NextDate];
                    addTime=[nextMidNight timeIntervalSinceDate:lastMidNight];
                    
                    [self checkLocationExistsOrNotInDataBase:locations locationTime:addTime startDate:lastMidNight endDate:[nextMidNight dateByAddingTimeInterval:-60] numberOfDays:numberOfDay];
                    
                    //Calls Activity Manager to find Fitness Data
                    [[ActivityManager sharedFitnessActivityManager]getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:nextMidNight];
                    [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:nextMidNight];
                    
                    //Call sleep manager to get sleep data
                    [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:lastMidNight toEndTime:nextMidNight];
                    
                }
                
            }
            
        }
        
    }
    else
    {
        if (locations)
        {
            //Todays location time
            addTime=[date timeIntervalSinceDate:location.timestamp];
            
            
            [self checkLocationExistsOrNotInDataBase:locations locationTime:addTime startDate:location.timestamp endDate:date numberOfDays:numberOfDay];
            
            //Calls Activity Manager to find Fitness Data
            [[ActivityManager sharedFitnessActivityManager]getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:location.timestamp] endDate:date ];
            
            [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:location.timestamp] endDate:date ];
            //
            //Call sleep manager to get sleep data
            [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:date toEndTime:date];
            
        }
        
    }
    
    
}

/// Checks if location exists or not in database using location latitude and longitude, pass locationTime And Current date of location. If location does not exists in database then find place name using reverse geocoding.
-(void)checkLocationExistsOrNotInDataBase:(NSArray *)locations locationTime:(NSInteger)locationTime startDate:(NSDate *)startDate endDate:(NSDate *)endDate numberOfDays:(NSInteger)numberofDays
{
    
    CLLocation *location=[locations lastObject];
    //select place name from database for checking place exist or not .
    LocationNameAndTime *locationName=[[InstantDataBase sharedInstantDataBase]selectPlaceName:location.coordinate.latitude logitude:location.coordinate.longitude];
    
    if (locationName.placename.count>0 && ![locationName.placename containsObject:@"unknown"])
    {
        
        [self insertPlacesDataInDataBase:location locationTime:locationTime placeName:[locationName.placename firstObject] startDate:startDate endDate:endDate];
        
    }
    else
    {
        // Getting Location Name from ReverseGeocoding
        if (numberofDays>0)
        {
            [self insertPlacesDataInDataBase:location locationTime:locationTime placeName:@"unknown" startDate:startDate endDate:endDate];
        }
        else
        {
            
            [self getLocationNameFromlatLong:location withCallBackHandler:^(NSString *placeName)
             {
                 if (![placeName isEqualToString:@" "])
                 {
                     
                     [self insertPlacesDataInDataBase:location locationTime:locationTime placeName:placeName startDate:startDate endDate:endDate];
                     
                     
                     
                 }
             }];
        }
        
    }
    
    
}


/// Gets location name using reverse geocoding and returns callbackHandler with location name
-(void)getLocationNameFromlatLong:(CLLocation *)location withCallBackHandler:(void(^)(NSString *placeName))placeName
{
    
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         NSString *placename;
         if (error)
         {
             
             placename=@"unknown";
             
         }
         else
         {
             CLPlacemark  *placemark = [placemarks lastObject];
             NSString *strret=[NSString stringWithFormat:@"%@",placemark.thoroughfare];
             if ([strret isEqualToString:@"(null)"])
             {
                 
                 placename = [NSString stringWithFormat:@"%@",placemark.subLocality];
                 NSString *undesired = @"(null)";
                 NSString *desired   = @" ";
                 placename = [placename stringByReplacingOccurrencesOfString:undesired
                                                                  withString:desired];
             }
             else
             {
                 placename = [NSString stringWithFormat:@"%@,%@",
                              placemark.thoroughfare,placemark.subLocality];
                 NSString *undesired = @"(null)";
                 NSString *desired   = @" ";
                 placename = [placename stringByReplacingOccurrencesOfString:undesired
                                                                  withString:desired];
                 
             }
             
         }
         
         placeName(placename);
         
     }];
    
    
}

/// Inserts and updates place name,time,latitude,longitude,date,timestamp into places table of database.
-(void)insertPlacesDataInDataBase:(CLLocation *)location locationTime:(NSInteger)locationTime placeName:(NSString *)placeName startDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    __block NSInteger placetime=locationTime;
    __block NSString *currentDate= [[InstantDataBase sharedInstantDataBase] date:startDate];
    
    LocationNameAndTime *locationType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    [[InstantDataBase sharedInstantDataBase]selectLastLocationFromDataBase:^(NSMutableDictionary *lastLocationRecord)
     {
         NSString *latitudes;
         NSString *longitudes;
         if (lastLocationRecord.count>0)
         {
             
             latitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:[[lastLocationRecord valueForKey:@"lat"] doubleValue]]];
             
             longitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:[[lastLocationRecord valueForKey:@"long"] doubleValue]]];
             
             NSDate *lastDate=[lastLocationRecord valueForKey:@"enddate"];
             
             //check is date in today for update location
             
             //BOOL today = [[NSCalendar currentCalendar] isDateInToday:lastDate];
             BOOL today=NO;
             if (locationType.isSignificantLocation==YES)
             {
                 today = [[NSCalendar currentCalendar] isDate:lastDate inSameDayAsDate:[endDate dateByAddingTimeInterval:-60]];
             }
             else if (locationType.isOnPhoneUsage==YES)
             {
                 today = [[NSCalendar currentCalendar] isDate:lastDate inSameDayAsDate:endDate ];
                 
             }
             
             
             
             if (today==NO)
             {
                 currentDate =[[InstantDataBase sharedInstantDataBase] date:endDate];
             }
             
             if ([latitudes isEqualToString:[self cutNumberInto4DecimalPoint:location.coordinate.latitude]] &&[longitudes isEqualToString:[self cutNumberInto4DecimalPoint:location.coordinate.longitude]] && today==YES)
             {
                 //Update place time into place table into database
                 NSInteger placeId=[[lastLocationRecord valueForKey:@"placeid"] integerValue];
                 NSInteger lastPlaceTime=[[lastLocationRecord valueForKey:@"placetime"] integerValue];
                 
                 if (locationType.isSignificantLocation==YES)
                 {
                     
                     placetime=locationTime+lastPlaceTime;
                 }
                 else
                 {
                     placetime=lastPlaceTime+60;
                 }
                 
                 [ [InstantDataBase sharedInstantDataBase]updateIntoPlaceDatabase:placeId currentDate:currentDate placeName:placeName endTimeStamp:endDate placeTime:placetime];
                 
             }
             else
             {
                 
                 //insert location into placetable into database
                 if (locationType.isSignificantLocation==NO)
                 {
                     placetime=60;
                 }
                 
                 
                 
                 
                 [[InstantDataBase sharedInstantDataBase]insertInToPlaceDatabase:currentDate latitude:location.coordinate.latitude longitude:location.coordinate.longitude placeName:placeName startTimeStamp:startDate endTimeStamp:endDate placeTime:placetime];
             }
             
         }
         else
         {
             //insert location into placetable into database
             if (locationType.isSignificantLocation==NO)
             {
                 placetime=60;
             }
             
             [[InstantDataBase sharedInstantDataBase]insertInToPlaceDatabase:currentDate latitude:location.coordinate.latitude longitude:location.coordinate.longitude placeName:placeName startTimeStamp:startDate endTimeStamp:endDate placeTime:placetime];
         }
         
         
         
         
         
         
     }];
    
    
    
    
}


-(NSString *)cutNumberInto4DecimalPoint:(double)number
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    [formatter setMaximumFractionDigits:4];
    NSString *numberString = [formatter stringFromNumber:@(number)];
    NSString *finalNumberString=[NSString stringWithFormat:@"%@",numberString];
    return finalNumberString;
    
}


#pragma mark -Standered Location


@end

