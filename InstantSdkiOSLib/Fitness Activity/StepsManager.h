//
//  StepsManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 10/10/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>

typedef NS_ENUM(NSUInteger, StepsHealthKitPermission)
{
    ///Steps HealthKit permission fail
    StepsHealthKitPermissionFail ,
    ///Steps HealthKit permission successfully
    StepsHealthKitPermissionSuccess  ,
    
};

typedef NS_ENUM(NSUInteger, StepsFitBitPermission)
{
    ///Steps HealthKit permission fail
    StepsFitBitPermissionFail ,
    ///Steps HealthKit permission successfully
    StepsFitBitPermissionSuccess  ,
    
};


@interface StepsManager : NSObject<NSURLSessionDelegate>
{
    __block NSNumber *totalSteps;
}
/*!
 * @discussion Creates steps manager singletone class. It has all steps related information like steps and date. It can be accessed anywhere in application.
 */

+(StepsManager *)sharedStepsManager;
@property(strong,nonatomic) CMPedometer *stepspedometer;
@property(nonatomic) HKAuthorizationStatus status;


/*!
 *@discussion Start steps tracking using healthkit.if healthkit tracking start successful handler returns StepsHealthKitPermissionSuccess otherwise handler returns StepsHealthKitPermissionFail.
 */
-(void)startHealthKitActivityTracking:(void(^)(StepsHealthKitPermission))handler;

/*!
 *@discussion stop steps tracking using healthkit.if healthkit tracking stop successful handler returns Yes otherwise handler returns No.
 */
-(void)stopHealthKitActivityTracking:(void(^)(BOOL isStop))handler;


/*!
 *@discussion Start steps tracking using fitbit.if fitbit tracking start successful handler returns StepsFitBitPermissionSuccess otherwise handler returns StepsFitBitPermissionFail.
 */
-(void)startFitBitActivityTracking:(void(^)(StepsFitBitPermission))handler;

/*!
 *@discussion stop steps tracking using fitbit.if fitbit tracking stop successful handler returns Yes otherwise handler returns No.
 */
-(void)stopFitBitActivityTracking:(void(^)(BOOL isStop))handler;



/*!
 * @discussion Getting the total number of steps for today using CoreMotion framework CMPedometer object passing start date  (last mid night date) and end date (current date) and total steps are stored into LocationNameAndTime database
 * @param date last midnight DateAndTime.
 * @param endDate current DateAndTime.
 
 */

-(void)getFitnessDataFromCoreMotionStartDate:(NSDate *)date endDate:(NSDate *)endDate;

/*!
 * @discussion Getting the total number of steps for today using CoreMotion framework CMPedometer object passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */

-(void)getStepsFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;



/*!
 * @discussion Getting the step count for today using healthKit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */

-(void)getStepsFromHealthKitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;

/*!
 * @discussion Getting the step count for today using FitBit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */
-(void)getStepsFromFitBitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;


/*!
 * @discussion getting n number of days of fitness and insert n number of fitness activity data into fitness table
 
 
 */
-(void)findNNumberOfDaysOfFitnessData;


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



@end

