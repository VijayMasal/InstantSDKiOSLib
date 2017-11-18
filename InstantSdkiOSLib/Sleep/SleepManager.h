//
//  SleepManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 18/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>
#import "LocationNameAndTime.h"

typedef NS_ENUM(NSUInteger, SleepPermission)
{
    ///Sleep permission fail
    SleepPermissionFail = 0,
    ///Sleep permission successfully
    SleepPermissionSuccess = 1,
    ///Sleep Healthkit on
    SleepPermissionHealthKitEnable =2,
  
};

typedef NS_ENUM(NSUInteger, HealthKitSleepPermission)
{
    ///Sleep permission fail
    HealthKitSleepPermissionFail = 0,
    ///Sleep permission successfully
    HealthKitSleepPermissionSuccess = 1,
    ///Sleep Healthkit on
    HealthKitSleepPermissionDefultSleepEnable =2,
 
};

@interface SleepManager : NSObject<NSURLSessionDelegate>
/*!
 * @discussion Creates sleep manager singletone class. It has all sleep related information. It can be accessed anywhere in application.
 */
+(SleepManager *)sharedSleepManager;
@property(strong,nonatomic)CMMotionActivityManager *sleepActivity;
@property(strong,nonatomic)NSDateFormatter *dateFormatter;
@property(strong,nonatomic) HKHealthStore *healthStore;


/*!
 * @discussion Starts sleep tracking using CoreMotion Framework. If it starts sleep tracking successfully handler returns SleepPermissionSuccess otherwise handler returns SleepPermissionFail. If healthkit is on then returns SleepPermissionHealthKitEnable
 
 */
typedef void (^DefaultSleepPermissionCustomCompletionBlock)(SleepPermission defaultSleepPermission);
-(void)startCoreMotionSleepTracking:(DefaultSleepPermissionCustomCompletionBlock)handler;

/*!
 * @discussion Stops sleep tracking using CoreMotion Framework. If stop sleep tracking successfully handler returns Yes otherwise handler returns No.
 
 */
-(void)stopCoreMotionSleepTracking:(void(^)(BOOL isStop))handler;

/*!
 * @discussion Starts sleep tracking using HealthKit Framework. If sleep tracking starts successfully handler returns SleepPermissionSuccess. If permission fails handler returns SleepPermissionFail. If Default sleep is enabled handler returns SleepPermissionDefaultEnable
 
 */
typedef void (^HealthKitSleepPermissionCustomCompletionBlock)(HealthKitSleepPermission healthkitSleepPermission);
-(void)startHealthKitSleepTracking:(HealthKitSleepPermissionCustomCompletionBlock)handler;

/*!
 * @discussion Stops sleep tracking using HealthKit. If sleep tracking stops successfully handler returns Yes otherwise handler returns No.
 
 */
-(void)stopHealthKitSleepTracking:(void(^)(BOOL isStop))handler;

/*!
 * @discussion Gets sleep data from CoreMotion framework using passed start time and end time. If get sleep data array then returns YES otherwise NO
 * @param startTime passing sleep start date and time.
 * @param endTime passing sleep end date and time.
 */
-(void)getSleepDataUsingCoreMotionFromStartTime:(NSDate *)startTime toEndTime:(NSDate *)endTime withCallBack:(void(^)(BOOL  isSleepData))sleepActivity;


/*!
 * @discussion Gets sleep time from sleep data using passed start time and end time. Inserts and update sleep record in sleep table. If sleep time is calculated successfully returns YES otherwise NO.
 * @param startTime passing sleep start date and time.
 * @param endTime passing sleep end date and time.
 */
-(void)getSleepTimeFromSleepData:(NSArray *)sleepData startTime:(NSDate *)startTime endTime:(NSDate *)endTime toQueue:(NSOperationQueue *)sleepQueue withComplitionHandler:(void(^)(BOOL isGetSleepTime))sleepTime;


/*!
 * @discussion Enables sleep option and parses sleep data of selected date.
 * @param startTime passing sleep start date and time.
 * @param toEndTime passing sleep end date and time.
 */
-(void)getSleepOptionAndFindSleepDataFromStartTime:(NSDate *)startTime toEndTime:(NSDate *)toEndTime;

/*!
 * @discussion Creates dictionary of date, total sleep time, sleepAt, wokeUpAt, inBetweenDuration, countInBetween, zeroSleep for inserting or update into sleep table of database.
 * @param date passing sleep date.
 * @param totalSleepTime passing total sleep time.
 * @param sleepAtTime passing sleepAt time.
 * @param wokeUpAtTime passing wokeUpAt time.
 * @param inBetweenDuration passing sleep inBetween time.
 * @param countInBetween passing inBetween wakeup count.
 */
-(void)storeDataInDictionaryDate:(NSString *)date totalSleepTime:(int )totalSleepTime sleepAtTime:(NSDate *)sleepAtTime wokeUpAtTime:(NSDate *)wokeUpAtTime inBetweenDuration:(int)inBetweenDuration countInBetween:(int)countInBetween zeroSleep:(int)zeroSleep withCallBackHandler:(void(^)(BOOL isStore))storeHandler;

#pragma mark -HealthKit

/*!
 * @discussion Gets healthkit permission for parsing sleep data from healthkit.
 */
-(void)healthKitPermission:(void(^)(BOOL healthKitPermission))permissionHandler;


/*!
 * @discussion Gets sleep data from healthKit framework using passed start time and end time. If sleep data array exists then returns YES otherwise NO
 * @param startTime passing sleep start date and time.
 * @param endTime passing sleep end date and time.
 */
-(void)getSleepDataUsingHealthKit:(NSDate *)startTime toEndTime:(NSDate *)endTime withCallBack:(void(^)(BOOL  isSleepData))healthKitSleepActivity;


#pragma mark -FitBit
/*!
 * @discussion Gets sleep data from FitBit framework using passed start time. If get sleep data array then returns YES otherwise NO
 * @param startTime passing sleep start date and time.
 */
-(void)getSleepDataUsingFitBit:(NSDate *)startTime  withCallBack:(void(^)(BOOL  isSleepData))FitBitSleepActivity;

/*!
 * @discussion Gets n number of days of sleep and insert n number of sleep  data into sleep table
 
 */
-(void)getNNumberOfSleepData;


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

/*
 *@discussion Checks Sleep Permission
 */

-(void)checkSleepPermission:(void(^)(BOOL isSleepPermission))handler;

@end


