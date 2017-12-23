//
//  DeviceUsageManager.m
//  InstantSDK
//
//  Created by Emberify_Vijay on 23/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 12/11/17

#import "DeviceUsageManager.h"

#import "ActivityManager.h"
#import "SleepManager.h"
@implementation DeviceUsageManager
static DeviceUsageManager *sharedDeviceUsage=nil;
/// Creates device usage manager singletone class. That gives device usage time and unlock counts.

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


/// Starts device usage tracking. If deviceUsage tracking starts successfully handler returns status PhoneUsagePermissionSuccess, if it fails handler returns PhoneUsagePermissionFail. If passcode  is not enabled handler returns PhoneUsagePermissionPasscodeNotEnable.

-(void)startPhoneUsageTracking:(PhoneUsagePermissionCustomCompletionBlock)handler
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"phoneUsageEnable"];
    BOOL passcodeEnable=[self checkPasscodeState];
    if (passcodeEnable==YES)
    {
        //BOOL isStart=[self startTimer];
        [[LocationManager sharedLocationManager]startStanderedLocation];
        LocationPermission staus=[[LocationManager sharedLocationManager] locationPermissionCheck];
        
        if (staus==LocationPermissionSuccess)
        {
            [self startTimer];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLocation"];
            handler(PhoneUsagePermissionSuccess);
        }
        else if (staus==LocationPermissionNotDetermined)
        {
            
            handler(PhoneUsagePermissionLocationPermissionNotDetermined);
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

///Location manager delegate called when locaiton permission status updated
-(void)updateLocationPermissionStatus:(LocationPermission)status
{
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isOnPhoneUsage==YES)
    {
        if (status==LocationPermissionSuccess)
        {
            [self startTimer];
        }
    }
    
}

/// Starts timer for getting device usage time and unlock counts.
-(void)startTimer
{
    [self setNotificationObserverForDeviceState];
    // [[LocationManager sharedLocationManager]startStanderedLocation];
    //BOOL isAuthorize= [[LocationManager sharedLocationManager] checkLocationPermission];
    
    //    if (isAuthorize==YES)
    //    {
    
    _timer= [NSTimer scheduledTimerWithTimeInterval:60.0f
                                             target: self
                                           selector: @selector(methodFromTimer)
                                           userInfo: nil
                                            repeats: YES];
    //    }
    //
    //    return isAuthorize;
    
}

/// Stops device usage tracking. If deviceUsage tracking stops successfully handler returns status Yes, otherwise returns No.

-(void)stopPhoneUsageTracking:(void(^)(BOOL isStop))handler
{
    
    BOOL isStopPhoneUsage=[self stopTimer];
    
    if (isStopPhoneUsage ==YES)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"phoneUsageEnable"];
            [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"location"];
            
        });
        
        handler(YES);
    }
    else
    {
        handler(NO);
        
    }
    
}


/// Stops tracking device usage time

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
/// Checks device status for device lock or unlock.
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
    
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    kSecAccessControlUserPresence, &error);
    
    if (sacObject == NULL || error != NULL)
    {
        
        return;
    }
    
    // The operation fails if there is an item which needs authentication so the app uses
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



/// Selects all device usage dates and check ig current date exists in device usage table, if the current date exist into device usage date then select minutes and unlock count of that date. If device is unlocked then add 1 minute time into selected minutes otherwise add 1 count into selected device unlock count and update into device usage table otherwise insert minute, unlock, date and day into device usage table for today's date.
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

/// When the application is terminated, the device usage time and the unlock status is updated for better accuracy of start and end time of the next record is inserted into the device usage table.
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
        //Calls sleep manager to get sleep data
        [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:[NSDate date] toEndTime:[NSDate date]];
    }
    
    
    
}
@end

