//
//  InstantDataBase.h
//  SingletoneDemo
//
//  Created by Vijay on 21/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "LocationNameAndTime.h"


static NSString * const placenamekey=@"placename";
/*!
 * @discussion InstantDataBase is singletone class that can be accessed anywhere in application. In InstantDataBase class a database file is created in document directory and also a placeTable and FitnessTable is created in the database, getting database path, checking if the database exists or not, checking if the database open or not, InstantDataBase class inserts and selects place data and also returns all location infromation to LocationNameAndTime. InstantDataBase class is also doing selection and insertion operations on fitness table of the database.
 
 */
@interface InstantDataBase : NSObject
{
    sqlite3 *instantDB;
    
}
@property(strong,nonatomic)LocationNameAndTime *locationModel;
@property(strong,nonatomic)NSMutableArray *placeRecordArray;

+(instancetype)sharedInstantDataBase;

/*
 *@discussion Checks all permissions flags
 */
-(LocationNameAndTime *)checkPermissionFlags;

/*
 *@discussion Checks all feature flags
 */
-(LocationNameAndTime *)checkFeatureEnableFlags;

-(BOOL)createDataBase;

-(BOOL)opneDataBase;

-(NSString *)date:(NSDate *)date;

-(NSString *)day:(NSDate *)date;


/*!
 * @discussion Creates places table with columns id, lat, long, time, placename and date into instantDB.sqlite.if create places table into database returns YES otherwise NO.
 */

-(BOOL)createPlaceTableInDatabase;


#pragma mark- Location(L)

/*!
 * @discussion  Selects placename from placetable using latitude and longitude to check if the place already exists or not in the database.
 * @param latitude Current location latitude.
 * @param longitude Curernt location longitude.
 
 * @return  placename in LocationNameAndTime.
 */
-(LocationNameAndTime *)selectPlaceName:(double)latitude logitude:(double)longitude;
/*!
 * @discussion Checks if the place exists in the datbase, update place time into database, select placeid and placetime from database.
 * @param currentDate .
 * @param name Place name.
 * @param latitude Current location latitude.
 * @param longitude Current location longitude.
 * @return Placeid and placetime in LocationNameAndTime.
 */
-(LocationNameAndTime *)selectPlaceIDAndTime:(NSString *)currentDate placeName:(NSString *)name latitude:(double)latitude longitude:(double)longitude;
/*!
 * @discussion Selects all dates from placetable of database for getting placetime, placename, latitude, longitude, timestamp from place table.
 * @return all dates in LocationNameAndTime.
 */
-(LocationNameAndTime *)selectAllDatesFromPlaceTable;

/*!
 * @discussion Called on location update to insert placename, time, latitude, longitude, timeStamp and date into placetable of database.
 * @param currentDate .
 * @param latitude .
 * @param longitude .
 * @param placeName .
 * @param startTimeStamp .
 * @param endTimeStamp .
 * @param placeTime Time being spent at a place.
 * @return YES OR NO For the insertion is successful.
 */

-(BOOL)insertInToPlaceDatabase:(NSString *)currentDate latitude:(double)latitude longitude:(double)longitude placeName:(NSString *)placeName startTimeStamp:(NSDate *)startTimeStamp endTimeStamp:(NSDate *)endTimeStamp placeTime:(NSInteger)placeTime;
/*!
 * @discussion Called on location update to add time to the place
 * @param placeID .
 * @param currentDate .
 * @param placeName .
 * @param endTimeStamp for getting location end time.
 * @param placeTime Time being spent at a place.
 * @return YES OR NO For Successful Insertion.
 */
-(BOOL)updateIntoPlaceDatabase:(NSInteger)placeID currentDate:(NSString *)currentDate  placeName:(NSString *)placeName endTimeStamp:(NSDate *)endTimeStamp placeTime:(NSInteger)placeTime;

/*!
 *@discussion Selects all location names, time, latitude,longitude and date from places table using selectDistinctTwoDecimalLatLongFromPlaceTable method to display this data on the UI
 * @param fromDate .
 * @param toDate .
 * @return location data dictionary.
 */
-(NSMutableDictionary *)selectAllPlacesDataFromPlaceTableFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate ;

/*!
 * Selects last location record from place table and handler returns location dictionary if last lat , long is same then update last  location time otherwise insert new record in place table.
 */
-(void)selectLastLocationFromDataBase:(void(^)(NSMutableDictionary *lastLocationRecord))handler;



#pragma mark -Fitness Activity(F)
/*!
 * @discussion Create Fitness table with columns id, date, walking, travelling, running, stationary, cycling and steps into instantDB.sqlite.if create fitness table into database returns YES otherwise NO.
 */
-(BOOL)creteFitnessTableInDatabase;

/*!
 * @discussion Inserts fitness activity name, time, steps count, start time and end time into fitness table of database.if data  insert successfully into fitness table it sned callbackhandler Yes otherwise No.
 * @param activity gets activity name(like walk,run,travel,cycling) .
 * @param activityTime gets activity time .
 * @param steps gets total steps count .
 * @param startTime gets activity starttime .
 * @param endTime gets activity ends time .
 
 
 */

-(void)insertFitnessDataActivity:(NSString *)activity activityTime:(NSInteger )activityTime steps:(NSInteger)steps startTime:(NSDate *)startTime endTime:(NSDate * )endTime  withCallBackHandler:(void(^)(BOOL isInsertData))isInsertBlock;


/*!
 * @discussion Inserts record into fitness table select fitness activity like walktime, traveltime, runtime, stationarytime, cycletime, steps count from fitness table and returns fitness activity info into LocationNameAndTime.
 * @return walktime, runtime, traveltime, stationarytime, cycletime, steps count and date into LocationNameAndTime.
 */

-(NSMutableDictionary *)selectFitnessActivityDataFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

/*!
 * @discussion Selects all dates to identify date exists or not into fitness table if date exists into fitness table then update fitness activity like walktime ,runtime, traveltime, stationarytime, cycletime and steps for that date otherwise insert fitness activity for that date into fitness table.
 
 
 * @return all fitness activity like walktime, runtime, traveltime, stationarytime, cycletime, steps count and date into LocationNameAndTime for updating UI.
 */

-(LocationNameAndTime *)selectAllDatesOfFitness;

/*!
 * Selects last activty from fitness table for parsing activity record from core motion using last actvity start time.
 */
-(NSMutableDictionary *)selectLastActivityFromFitness;


#pragma mark -Sleep

/*!
 * @discussion Creates sleep table with columns id, date, totalsleeptime, sleeptime, wokeuptime, inbetweenduration, countforduration and zerosleep into instantDB.sqlite.if create sleep table into database returns YES otherwise NO.
 */
-(BOOL)creteSleepTableInDatabase;

/*!
 * @discussion Gets sleep start time form passing date and time.
 * @param startTime passing sleep start date and time.
 * @return date as an sleep start time.
 */

-(NSDate *)sleepStartTime:(NSDate *)startTime;


/*!
 * @discussion Gets end time from passing date.
 * @param endTime passing sleep end date and time.
 * @return date as an sleep end time.
 */


-(NSDate *)sleepEndTime:(NSDate *)endTime;

/*!
 * @discussion Gets sleep time of last night insert or update into sleep table of database after successful insert or update it returns YES otherwise NO.
 * @param sleepData is a dictionary to set sleep date, sleeptotaltime, sleeptime, wokeuptime, durationinbetween, countinbetween, zerosleep.
 
 */

-(void)insertOrUpdateSleepData:(NSMutableDictionary *)sleepData withCallBackhandler:(void(^)(BOOL isInsert))sleepInsert;

/*!
 * @discussion Gets all sleep dates from sleep table for identify that date is exists or not in database if current date exists in database then update sleep record of that date otherwise insert record of that date into database.
 * @return all sleep dates into LocationNameAndTime.
 */
-(LocationNameAndTime *)selectAllDatesOfSleep;


/*!
 * @discussion Gets all sleep data from sleep table and show sleep total time, sleepAt and wokeUpAt on UI.
 * @param fromDate .
 * @param toDate .
 * @return all sleep data into dictionary.
 */
-(NSMutableDictionary *)selectAllSleepDataFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

/*!
 * @discussion Gets fitBit permission for parsing steps count and sleep time.
 
 */
-(void)fitBitPermissions:(void(^)(BOOL fitBitPermission))PermissionHandler;

#pragma mark -Device Usage

/*!
 * @discussion Creates device usage table with columns id, minute, unlock, date, day into instantDB.sqlite. If create device usage table into database handler returns YES otherwise NO.
 */
-(BOOL)createDeviceUsageTableInDatabase;

/*!
 * @discussion Gets all device usage dates in LocationNameAndTime handler from DeviceUsage table for identify that date is exists or not in database if current date exists in database then update device usage record of that date otherwise insert record of that date into database.
 
 */
-(void)selectDatesFromDeviceUsage:(void(^)(LocationNameAndTime *deviceusageDate))handler;


/*!
 * @discussion Gets today's device usage time and unlock count using passed date into handler for update today's device time and unlock counts into device usage table.
 
 * @param todayDate is todays date
 */
-(void)selectTodayDeviceUsageMinutesAndUnlocksForDate:(NSString *)todayDate withcallbackHandler:(void(^)(int minute,int unlock))handler;

/*!
 * @discussion Inserts devices usage minutes, unlock count, date and day into devices usage table.if insert record successfully into device usage table handler returns Yes otherwise No.
 
 @param minute passed device usage time in minutes.
 @param startTime unlock start time.
 @param endTime unlock end time.
 @param isUnlock is identifier to insert or update start time and endtime.
 @param queryIdentifier passed insert or update for insert or update record into device usage.
 */
-(void)insertIntoDeviceUsageTime:(int)minute startTime:(NSDate *)startTime endTime:(NSDate *)endTime isUnlock:(int)isUnlock lastRecordId:(int)lastId queryIdentifier:(NSString *)queryIdentifier withCallbackHandler:(void(^)(BOOL isInsert))handler;

/*!
 * @discussion Gets all records like device time, device unlock count, date and day from device usage table for updating UI.
 @param fromDate pass start date to retrive data.
 @param toDate pass end date to retrive data.
 * @return all device usage data into dictionary.
 */
-(NSMutableDictionary *)selectAllDataFromDeviceTimeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate ;

/*!
 * @discussion Selects last record of device usage for update or insert new record start time and end time into device usage table of database after selecting last record handler returns last record dictionary.
 */
-(void)selectDeviceUsageLastRecord:(void(^)(NSMutableDictionary *deviceUsageLastRecord))handler;

#pragma mark -Steps methods

/*!
 *  Creates steps table in instantdata base, if steps table creates successfully it returns Yes otherwise No.
 */
-(BOOL)createStepsTable;

/*!
 *  Selects all dates from steps table for checking current date is exists or not in steps table. If current date is steps table then update steps in steps table otherwise insert steps in table
 */
-(LocationNameAndTime *)selectAllDateOfSteps;

/*!
 * Inserts or update steps count, start time, end time into steps table. If record insert or update successfully into steps table handler returns Yes otherwise No.
 @param steps total steps count.
 @param startDate get steps start time.
 @param endDate gets steps end date.
 @param date gets date string.
 @param queryStatus gets query is insert or updates.
 */
-(void)insertOrUpdateSteps:(NSInteger)steps startDate:(NSDate *)startDate endDate:(NSDate *)endDate date:(NSString *)date queryStatus:(NSString *)queryStatus withCallBackHandler:(void(^)(BOOL isInsert))handler;

/*!
 *  Selects all data from steps table for displaying it
 *  @param fromDate pass start date to retrive data.
 *  @param toDate pass end date to retrive data.
 *  @return all steps data into array.
 */
-(NSMutableArray *)selectStepsDataFromStepsTableFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;

#pragma mark -Delete Records form database;
/*!
 * @discussion deletes database table records from given fromDate to toDate.
 */
-(void)deleteTrackedData:(NSDate *)fromDate toDate:(NSDate *)toDate withCallBackHandler:(void(^)(BOOL isDelete))handler;

/*!
 * @discussion Clear database and NSUserDefault after logout.
 */
-(void)clearDatabaseAndUserDefaultAfterLogout:(void(^)(BOOL isClear))handler;


#pragma mark -fetchTrackedData
/*!
 * @discussion Selects all record of database from given fromDate to toDate.after selecting record convert into jsonSting and handler returns data for show result on UI.
 @param fromDate pass start date to retrive data.
 @param toDate pass end date to retrive data.
 */
-(void)fetchTrackedData:(NSDate *)fromDate toDate:(NSDate *)toDate withCallBackHandler:(void(^)(NSString *jsonString , NSError *error))handler;

/*!
 *@discussion App moves from background to foreground and updates all database tables.
 */
-(void)applicationMovesBackgroundToForeground;

/*!
 *@discussion Closes database when application will terminate.
 */
-(void)callOnapplicationWillTerminate;

/*!
 * @discussion Gets fitbit token for fetching data from fitbit.
 */
-(void)FitBitOpenUrl:(NSURL *)url;


@end

