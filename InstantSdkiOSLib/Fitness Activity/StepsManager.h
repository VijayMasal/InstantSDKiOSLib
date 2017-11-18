//
//  StepsManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 10/10/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>

typedef NS_ENUM(NSUInteger, StepsHealthKitPermission)
{
    ///Steps HealthKit permission fail
    StepsHealthKitPermissionFail = 0,
    ///Steps HealthKit permission successfully
    StepsHealthKitPermissionSuccess = 1 ,
    ///Ftibit enable
    StepsHealthKitPermissionFitbitEnable = 2
    
};

typedef NS_ENUM(NSUInteger, StepsFitBitPermission)
{
    ///Steps HealthKit permission fail
    StepsFitBitPermissionFail =0,
    ///Steps HealthKit permission successfully
    StepsFitBitPermissionSuccess =1 ,
    ///Healthkit is enable
    StepsFitBitPermissionHealthKitEnable = 2
    
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
 *@discussion Starts steps tracking using healthkit.if healthkit tracking start successful handler returns StepsHealthKitPermissionSuccess otherwise handler returns StepsHealthKitPermissionFail.
 */
typedef void (^stepsPermissionCustomCompletionBlock)(StepsHealthKitPermission stepHealthkitPermission);
-(void)startHealthKitActivityTracking:(stepsPermissionCustomCompletionBlock)handler;

/*!
 *@discussion Stops steps tracking using healthkit. If healthkit tracking stops successfully handler returns Yes otherwise handler returns No.
 */
-(void)stopHealthKitActivityTracking:(void(^)(BOOL isStop))handler;


/*!
 *@discussion Starts steps tracking using fitbit. If fitbit tracking start successful handler returns StepsFitBitPermissionSuccess otherwise handler returns StepsFitBitPermissionFail.
 */
typedef void (^stepFitBitPermissionCustomCompletionBlock)(StepsFitBitPermission stepFitBitPermission);
-(void)startFitBitActivityTracking:(stepFitBitPermissionCustomCompletionBlock)handler;

/*!
 *@discussion Stops steps tracking using fitbit. If fitbit tracking stop successful handler returns Yes otherwise handler returns No.
 */
-(void)stopFitBitActivityTracking:(void(^)(BOOL isStop))handler;



/*!
 * @discussion Gets the total number of steps for today using CoreMotion framework CMPedometer object passing start date (last mid night date) and end date (current date) and total steps are stored into LocationNameAndTime database
 * @param date last midnight DateAndTime.
 * @param endDate current DateAndTime.
 
 */

-(void)getFitnessDataFromCoreMotionStartDate:(NSDate *)date endDate:(NSDate *)endDate;

/*!
 * @discussion Gets the total number of steps for today using CoreMotion framework CMPedometer object passing start date (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */

-(void)getStepsFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;



/*!
 * @discussion Gets the step count for today using healthKit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */

-(void)getStepsFromHealthKitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;

/*!
 * @discussion Gets the step count for today using FitBit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps.
 * @param startDate last midnight date and time.
 * @param endDate current date and time.
 */
-(void)getStepsFromFitBitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;


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
 *@discussion Checks permission of steps
 */
-(void)checkStpsPermission:(void(^)(BOOL stepsPermission))handler;

/*!
 * @discussion Gets healthkit permission for parsing Steps data from healthkit.
 */
-(void)healthKitPermission:(void(^)(BOOL healthKitPermission))permissionHandler;

@end

