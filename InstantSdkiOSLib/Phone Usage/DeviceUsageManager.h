//
//  DeviceUsageManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 23/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIDevice+PasscodeStatus.h"
#import "LocationNameAndTime.h"


typedef NS_ENUM(NSUInteger, PhoneUsagePermission)
{
    ///Failed phone usage tracking
    PhoneUsagePermissionFail=0,
    ///phone usage tracking successfully
    PhoneUsagePermissionSuccess =1,
   ///Passcode not enable
    PhoneUsagePermissionPasscodeNotEnable =2
};


@interface DeviceUsageManager : NSObject

{
    dispatch_queue_t timerQueue;
    
}
/*!
 * @discussion Create device usage manager singletone class. That gives device usage time and unlock counts.
 */
+(DeviceUsageManager *)sharedDeviceUsage;

@property(nonatomic)BOOL isUnlock;


@property(strong,nonatomic)NSTimer *timer;
@property(strong,nonatomic)id notificationToken;

/*!
 * @discussion Start device usage tracking.if deviceUsage tracking start successfully handler returns status 1, if its fail handler returns 0.if passcode not enable handler returns 2.
 */
-(void)startPhoneUsageTracking:(void(^)(PhoneUsagePermission))handler;
/*!
 * @discussion Start timer for getting device usage time and unlock counts.
 */
-(BOOL)startTimer;

/*!
 * @discussion Stop device usage tracking.if deviceUsage tracking stop successfully handler returns status 1, if its fail handler returns 0.
 */
-(void)stopPhoneUsageTracking:(void(^)(BOOL isStop))handler;

/*!
 * @discussion Stop tracking device usage time.
 */
-(BOOL)stopTimer;
/*!
 * @discussion Set device passcode status when app coming in foreground method.
 */
-(void)setNotificationObserverForDeviceState;

/*!
 * @discussion Select all device usage date and check current date is exist in device usage table if current date exist into device usage date then select minutes and unlock count of that date.if device is unlock then add 1 minute time into selected minutes otherwise add 1 count into selected device unlock count and update into device usage table otherwise insert minute, unlock, date and day into device usage table for today's date.
 */
-(void)deviceUsageTime:(BOOL )isDeviceUnlock;

/*!
 * @discussion At application termination time update device usage time and isunlock status for better aacurate start and end time of next record into device usage table.
 */
-(void)applicationTerminate;


/*!
 * @discussion insert fitness activity and sleep data on app launch, app moves from backgorund to foreground and date change into fitness and sleep table.
 */
-(void)InsertFitnessAndSleepRecord;
@end



