//
//  ActivityManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 02/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "LocationManager.h"

typedef NS_ENUM(NSUInteger, FitnessActivityPermission)
{
    ///Fitness activity permission fail
    FitnessActivityPermissionFail = 0,
    ///Fitness activity permission successfully
    FitnessActivityPermissionSuccess = 1 ,
    
};

@interface ActivityManager : NSObject<NSURLSessionDelegate>
{
    __block NSNumber *totalSteps;
}
/*!
 * @discussion Creates activity manager singletone class. It has all fitness related information like walking, running,travelling, stationary, cycling, steps and date. It can be accessed anywhere in application.
 */

+(ActivityManager *)sharedFitnessActivityManager;

@property(strong,nonatomic)CMMotionActivityManager *motionActivity;
@property(strong,nonatomic) CMPedometer *stepspedometer;

/*!
 *@discussion Starts fitness tracking using coremotion. If fintess tracking starts successful handler returns FitnessActivityPermissionSuccess otherwise handler returns  FitnessActivityPermissionFail.
 */
typedef void (^FitnessPermissionCustomCompletionBlock)(FitnessActivityPermission fitnessPermission);
-(void)startCoreMotionActivityTracking:(FitnessPermissionCustomCompletionBlock)handler;

/*!
 *@discussion Stops fitness tracking using coremotion. If fintess tracking stops successful handler returns Yes otherwise handler returns No.
 */
-(void)stopCoreMotionActivityTracking:(void(^)(BOOL isStop))handler;


/*!
 * @discussion Gets walking, running, travelling, cycling from coremotion framework and inserts it into fitness activity table of database.
 * @param startDate last midnight DateAndTime.
 * @param endDate current DateAndTime.
 */

-(void)getFitnessDataFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
//-(void)getFitnessDataFromCoreMotionStartDate;
/*!
 * @discussion Parses date, walktime, traveltime, runtime, cycletime from CMMotionActivity.totalFSteps used for total number of steps and endDate is used if activity is not present then insert all activity time 0 for perticular date in fitnesstable.if parsing activity time callback send Yes otherwise No .
 * @param activity Activity contains all activity info as an array.
 * @param currentDate have current date.
 */

-(void)findAllFtinessActivityTime:(NSArray<CMMotionActivity *>*)activity  endDate:(NSDate *)currentDate toQueue:(NSOperationQueue *)toQueue withCallBackHandler:(void(^)(BOOL isParseActivityTIme))block;



/*!
 * @discussion Gets n number of days of fitness and insert n number of fitness activity data into fitness table
 
 
 */
-(void)findNNumberOfDaysOfFitnessData;


/*!
 * @discussion Finds the last midnight using passed date.
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
 *@discussion Check activity permissions using core motion
 */
-(void)checkActivityPermision:(void(^)(BOOL activityPermission))handler;


@end



