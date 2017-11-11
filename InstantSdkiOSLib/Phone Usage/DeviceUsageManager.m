//
//  DeviceUsageManager.m
//  InstantSDK
//
//  Created by Emberify_Vijay on 23/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import "DeviceUsageManager.h"
#import "LocationManager.h"
#import "ActivityManager.h"
#import "SleepManager.h"
@implementation DeviceUsageManager
static DeviceUsageManager *sharedDeviceUsage=nil;
/// Create device usage manager singletone class. That gives device usage time and unlock counts.

+(DeviceUsageManager *)sharedDeviceUsage
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDeviceUsage=[[DeviceUsageManager alloc]init];
    });
    return sharedDeviceUsage;
}

-(id)init
{
    
    if (self==[super init])
    {
        timerQueue=(dispatch_queue_create("timerqueue", DISPATCH_QUEUE_SERIAL));
    }
    return self;
}

-(void)setNotificationObserverForDeviceState
{
    _notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note)
                          {
                              [self checkPasscodeState];
                          }];
}


/// Start device usage tracking.if deviceUsage tracking start successfully handler returns status 1, if its fail handler returns 0.if passcode not enable handler returns 2.


-(void)startPhoneUsageTracking:(PhoneUsageCustomCompletionBlock)handler;
{
    BOOL passcodeEnable=[self checkPasscodeState];
    if (passcodeEnable==YES)
    {
        BOOL isStart=[self startTimer];
        
        if (isStart==YES)
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLocation"];
            handler(PhoneUsagePermissionSuccess);
        }
        else
        {
            handler(PhoneUsagePermissionFail);
            
        }
    }
    else
    {
        handler(PhoneUsagePermissionPasscodeNotEnable);
    }
    
    
}


/// Start timer for getting device usage time and unlock counts.
-(BOOL)startTimer
{
    [self setNotificationObserverForDeviceState];
      [[LocationManager sharedLocationManager]startStanderedLocation];
    BOOL isAuthorize= [[LocationManager sharedLocationManager] checkLocationPermission];
    if (isAuthorize==YES)
    {

        _timer= [NSTimer scheduledTimerWithTimeInterval:60.0f
                                                 target: self
                                               selector: @selector(methodFromTimer)
                                               userInfo: nil
                                                repeats: YES];
    }
    
    return isAuthorize;
    
}

/// Stop device usage tracking.if deviceUsage tracking stop successfully handler returns status Yes, if its fail handler returns .

-(void)stopPhoneUsageTracking:(void(^)(BOOL isStop))handler
{
    BOOL isStopPhoneUsage=[self stopTimer];
    
    if (isStopPhoneUsage ==YES)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"location"];
        });
        
        handler(YES);
    }
    else
    {
        handler(NO);
        
    }
    
}


/// Stop tracking device usage time.

-(BOOL)stopTimer
{
    [_timer invalidate];
    _timer=nil;
    return YES;
}

-(void)methodFromTimer
{
    [[LocationManager sharedLocationManager]startStanderedLocation];
    [self deleteItemAsync];
}
///Check Device status for device lock or unlock.
- (BOOL)checkPasscodeState
{
    LNPasscodeStatus status = [UIDevice currentDevice].passcodeStatus;
    switch (status)
    {
        case LNPasscodeStatusEnabled:
            _isUnlock=NO;
            return YES;
            break;
            
        case LNPasscodeStatusDisabled:
            return NO;
            break;
            
        case LNPasscodeStatusUnknown:
        default:
            return NO;
            break;
    }
}

- (void)deleteItemAsync {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"SampleService"
                            };
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    
   [self keychainErrorToString:status];
    [self addItemAsync];
 
}
- (void)addItemAsync {
    CFErrorRef error = NULL;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    kSecAccessControlUserPresence, &error);
    
    if (sacObject == NULL || error != NULL)
    {
     
        return;
    }
    
    // we want the operation to fail if there is an item which needs authentication so we will use
    // kSecUseNoAuthenticationUI
    NSDictionary *attributes = @{
                                 (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                 (__bridge id)kSecAttrService: @"SampleService",
                                 (__bridge id)kSecValueData: [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding],
                                 (__bridge id)kSecUseNoAuthenticationUI: @YES,
                                 (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
                                 };
    
    //    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //    dispatch_async(timerQueue, ^{
    OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
    
    NSString *errorString = [self keychainErrorToString:status];
    NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];
    if ([message isEqualToString:@"SecItemAdd status: success"])
    {
     
        _isUnlock=NO;
        [self deviceUsageTime:_isUnlock];
        
        
    }
    else
    {
        if (_isUnlock==NO)
        {
            _isUnlock=YES;
            [self deviceUsageTime:_isUnlock];
            
        }
        
    }
    //    });
}


#pragma mark - Tools

- (NSString *)keychainErrorToString:(OSStatus)error
{
    NSString *message = [NSString stringWithFormat:@"%ld", (long)error];
    
    switch (error) {
        case errSecSuccess:
            message = @"success";
            break;
            
        case errSecDuplicateItem:
            message = @"error item already exists";
            break;
            
        case errSecItemNotFound :
            message = @"error item not found";
            break;
            
        case errSecAuthFailed:
            message = @"error item authentication failed";
            break;
            
        default:
            break;
    }
    
    return message;
}



///Select all device usage date and check current date is exist in device usage table if current date exist into device usage date then select minutes and unlock count of that date.if device is unlock then add 1 minute time into selected minutes otherwise add 1 count into selected device unlock count and update into device usage table otherwise insert minute, unlock, date and day into device usage table for today's date.
-(void)deviceUsageTime:(BOOL )isDeviceUnlock
{
    [[InstantDataBase sharedInstantDataBase]selectDeviceUsageLastRecord:^(NSMutableDictionary *deviceUsageLastRecord)
     {
         NSDate *lastDate;
         int isUnlock=0;
         int lastTime=0;
         int lastId=0;
         NSString *status;
         NSDate *startTime=[[NSDate date] dateByAddingTimeInterval:-60];
         NSDate *endTime=[NSDate date];
         BOOL isToday=NO;
         if (deviceUsageLastRecord.count>0)
         {
             lastId=[[deviceUsageLastRecord valueForKey:@"id"] intValue];
             lastDate=[deviceUsageLastRecord valueForKey:@"enddate"];
             lastTime=[[deviceUsageLastRecord valueForKey:@"time"] intValue];
             isUnlock=[[deviceUsageLastRecord valueForKey:@"isunlock"] intValue];
             startTime=[NSDate date];
             endTime=[[NSDate date] dateByAddingTimeInterval:60];
             isToday=[[NSCalendar currentCalendar]isDate:lastDate inSameDayAsDate:[NSDate date]];
         }
         if (isToday==YES && isUnlock==1)
         {
             status=@"update";
             if (isDeviceUnlock==NO)
             {
                 lastTime=lastTime+1;
                 endTime=[NSDate date];
             }
             else
             {
                 isUnlock=0;
                 endTime=[[NSDate date] dateByAddingTimeInterval:-60];
             }
             
             [[InstantDataBase sharedInstantDataBase]insertIntoDeviceUsageTime:lastTime startTime:[[NSDate date]dateByAddingTimeInterval:-60] endTime:endTime isUnlock:isUnlock lastRecordId:lastId queryIdentifier:status withCallbackHandler:^(BOOL isInsert) {
                 
             }];
         }
         else
         {
             [[InstantDataBase sharedInstantDataBase] insertIntoDeviceUsageTime:1 startTime:startTime endTime:endTime isUnlock:1 lastRecordId:0 queryIdentifier:@"insert" withCallbackHandler:^(BOOL isInsert) {
                 
             }];
         }
         
     }];
    
}

/// At application termination time update device usage time and isunlock status for better aacurate start and end time of next record into device usage table.
-(void)applicationTerminate
{
    [self deviceUsageTime:NO];
    
}

-(void)InsertFitnessAndSleepRecord
{
    
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    
    if (permissions.isActivity==YES)
    {
        //Calls Activity Manager to find Fitness Data
        //        [[ActivityManager sharedFitnessActivityManager]getFitnessDataFromCoreMotionStartDate:[[LocationManager sharedLocationManager]midNightOfLastNight:[NSDate date]] endDate:[NSDate date]];
    }
    
    if (permissions.isSleep==YES)
    {
        //Call sleep manager to get sleep data
        [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:[NSDate date] toEndTime:[NSDate date]];
    }
    
    
    
}
@end

