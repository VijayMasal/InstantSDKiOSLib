//
//  DeviceUsageManager.h
//  InstantSDK
//
//  Created by Emberify_Vijay on 23/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 13/11/17

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIDevice+PasscodeStatus.h"
#import "LocationNameAndTime.h"



typedef NS_ENUM(NSUInteger, PhoneUsagePermission)
{
    ///Failed phone usage tracking
    PhoneUsagePermissionFail=0,
    ///Phone usage tracking successful
    PhoneUsagePermissionSuccess =1,
   ///Passcode not enabled
    PhoneUsagePermissionPasscodeNotEnable =2
};



@interface DeviceUsageManager : NSObject

{
    dispatch_queue_t timerQueue;
    
}
/*!
 * @discussion Creates device usage manager singletone class. That gives device usage time and unlock counts.
 */
+(DeviceUsageManager *)sharedDeviceUsage;

@property(nonatomic)BOOL isUnlock;


@property(strong,nonatomic)NSTimer *timer;
@property(strong,nonatomic)id notificationToken;


/*!
 * @discussion Starts device usage tracking. If deviceUsage tracking starts successfully handler returns status PhoneUsagePermissionSuccess, if it fails handler returns PhoneUsagePermissionFail. If passcode not enable handler returns PhoneUsagePermissionPasscodeNotEnable.
 */
typedef void (^PhoneUsagePermissionCustomCompletionBlock)(PhoneUsagePermission phoneUsagePermission);
-(void)startPhoneUsageTracking:(PhoneUsagePermissionCustomCompletionBlock)handler;

/*!
 * @discussion Starts timer for getting device usage time and unlock counts.
 */
-(BOOL)startTimer;

/*!
 * @discussion Stops device usage tracking. If deviceUsage tracking stops successfully handler returns status YES, if its fail handler returns NO.
 */
-(void)stopPhoneUsageTracking:(void(^)(BOOL isStop))handler;

/*!
 * @discussion Stops tracking device usage time.
 */
-(BOOL)stopTimer;
/*!
 * @discussion Sets device passcode status when app coming in foreground method.
 */
-(void)setNotificationObserverForDeviceState;

/*!
 * @discussion Selects all device usage date and check current date is exist in device usage table if current date exists in device usage date then selects minutes and unlock count of that date. If device is unlocked then add 1 minute time into selected minutes otherwise add 1 count into selected device unlock count and update into device usage table otherwise insert minute, unlock, date and day into device usage table for today's date.
 */
-(void)deviceUsageTime:(BOOL )isDeviceUnlock;

/*!
 * @discussion When the app is terminated update device usage time and isunlock status for better accurate start and end time of next record into device usage table.
 */
-(void)applicationTerminate;


/*!
 * @discussion Inserts fitness activity and sleep data on app launch, app moves from backgorund to foreground and date change into fitness and sleep table.
 */
-(void)InsertFitnessAndSleepRecord;
@end



