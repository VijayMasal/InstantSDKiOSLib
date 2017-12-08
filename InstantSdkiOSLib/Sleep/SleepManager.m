//
//  SleepManager.m
//  InstantSDK
//
//  Created by Emberify_Vijay on 18/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import "SleepManager.h"
#import "InstantDataBase.h"
#import <UIKit/UIKit.h>

@implementation SleepManager

static SleepManager *sharedSleepManager=nil;
///Creates sleep manager singletone class. It has all sleep related information. It can be accessed anywhere in application.
+(SleepManager *)sharedSleepManager
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedSleepManager=[[SleepManager alloc]init];
    });
    return sharedSleepManager;
    
    
}

-(id)init
{
    if (self=[super init])
    {
        _sleepActivity=[[CMMotionActivityManager alloc]init];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        _healthStore=[[HKHealthStore alloc]init];
    }
    return self;
}

///start sleep tracking using CoreMotion Framework. if start sleep tracking successfully handler returns SleepPermissionSuccess otherwise handler returns SleepPermissionFail.if healthkit is on then returns SleepPermissionHealthKitEnable

-(void)startCoreMotionSleepTracking:(DefaultSleepPermissionCustomCompletionBlock)handler
{
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaultSleepEnable"];
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isHealthKitSleep==NO || permissions.isSleep==NO)
    {
        
        [self getSleepDataUsingCoreMotionFromStartTime:[NSDate date] toEndTime:[NSDate date] withCallBack:^(BOOL isSleepData)
         {
             if (isSleepData==YES)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [[NSUserDefaults standardUserDefaults] setValue:@"default" forKey:@"sleep"];
                     [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdate"];
                 });
                 handler(SleepPermissionSuccess);
             }
             else
             {
                 [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleep"];
                 handler(SleepPermissionFail);
             }
         }];
    }
    else
    {
        handler(SleepPermissionHealthKitEnable);
    }
    
}


///stop sleep tracking using CoreMotion Framework. if stop sleep tracking successfully handler returns Yes otherwise handler returns No.

-(void)stopCoreMotionSleepTracking:(void(^)(BOOL isStop))handler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"defaultSleepEnable"];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleep"];
    });
    
    handler(YES);
}

/// start sleep tracking using HealthKit Framework. if start sleep tracking successfully handler returns SleepPermissionSuccess. if permission fail handler returns SleepPermissionFail.if Default sleep is enable handler returns SleepPermissionDefaultEnable

-(void)startHealthKitSleepTracking:(HealthKitSleepPermissionCustomCompletionBlock)handler
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"healthkitSleepEnable"];
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isDefaultSleep==NO || permissions.isSleep==NO)
    {
        [[SleepManager sharedSleepManager]healthKitPermission:^(BOOL healthKitPermission)
         {
             if (healthKitPermission==YES)
             {
                 
                 
                 [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:[NSDate date] toEndTime:[NSDate date]];
                 handler(HealthKitSleepPermissionSuccess);
             }
             else
             {
                 handler(HealthKitSleepPermissionFail);
             }
             
         }];
    }
    else
    {
        handler(HealthKitSleepPermissionDefultSleepEnable);
    }
    
}

/// stop sleep tracking using HealthKit. if stop sleep tracking successfully handler returns Yes otherwise handler returns No.

-(void)stopHealthKitSleepTracking:(void(^)(BOOL isStop))handler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"healthkitSleepEnable"];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleep"];
    });
    handler(YES);
    
}


///Get enable sleep option and pasrse sleep data of selected option. startTime passing sleep start date and time. toEndTime passing sleep end date and time.
-(void)getSleepOptionAndFindSleepDataFromStartTime:(NSDate *)startTime toEndTime:(NSDate *)toEndTime
{
    
    NSString *sleepOptionName=[[NSUserDefaults standardUserDefaults]valueForKey:@"sleep"];
    if ([sleepOptionName isEqualToString:@"default"])
    {
        
        
        [self getSleepDataUsingCoreMotionFromStartTime:startTime toEndTime:toEndTime withCallBack:^(BOOL isSleepData)
         {}];
    }
    else if ([sleepOptionName isEqualToString:@"healthkit"])
    {
        
        [[SleepManager sharedSleepManager]getSleepDataUsingHealthKit:[[InstantDataBase sharedInstantDataBase] sleepStartTime:startTime] toEndTime:[[InstantDataBase sharedInstantDataBase] sleepEndTime:toEndTime] withCallBack:^(BOOL isSleepData)
         {
         }];
        
        
    }
    else if ([sleepOptionName isEqualToString:@"fitbit"])
    {
        [[SleepManager sharedSleepManager]getSleepDataUsingFitBit:[[InstantDataBase sharedInstantDataBase] sleepStartTime:startTime] withCallBack:^(BOOL isSleepData)
         {
         }];
        
    }
    
}

///Get sleep data from CoreMotion framework using passed start time and end time.if get sleep data array then returns YES otherwise NO.startTime passing sleep start date and time.endTime passing sleep end date and time.

-(void)getSleepDataUsingCoreMotionFromStartTime:(NSDate *)startTime toEndTime:(NSDate *)endTime withCallBack:(void(^)(BOOL  isSleepData))sleepActivity
{
    dispatch_async(dispatch_get_main_queue(), ^()
                   {
    [_sleepActivity queryActivityStartingFromDate:[[InstantDataBase sharedInstantDataBase] sleepStartTime:startTime] toDate:[[InstantDataBase sharedInstantDataBase] sleepEndTime:endTime] toQueue:[NSOperationQueue new] withHandler:^(NSArray * sleepData, NSError *error)
     {
         __block  BOOL isPermission;
         
         if (error)
         {
             
             
             if (error.code==CMErrorMotionActivityNotAuthorized)
             {
                 isPermission=NO;
                 sleepActivity(isPermission);
             }
             
             if (error.code==CMErrorMotionActivityNotAvailable)
             {
                 isPermission=NO;
                 sleepActivity(isPermission);
             }
             
         }
         else
         {
             
             [self getSleepTimeFromSleepData:sleepData startTime:startTime endTime:endTime toQueue:[NSOperationQueue new]  withComplitionHandler:^(BOOL isGetSleepTime)
              {
                  if (isGetSleepTime==YES)
                  {
                      isPermission=YES;
                      sleepActivity(isPermission);
                  }
                  else
                  {
                      sleepActivity(isPermission);
                  }
                  
                  
              }];
             
         }
     }];
                   });
    
    
}



-(void)getSleepTimeFromSleepData:(NSArray *)sleepData startTime:(NSDate *)startTime endTime:(NSDate *)endTime toQueue:(NSOperationQueue *)sleepQueue withComplitionHandler:(void(^)(BOOL isGetSleepTime))sleepTime
{
    
    NSDate *startSleepDate,*tempDate;
    BOOL isSleepTimeSet = false, zeroSleep = false,notInBed = false;
    int TotalsleepTimeInSeconds = 0, inBetweenWokeUpDuration = 0, countForInBetweenDuration = 0;
    NSDate *SleepTime, *WokeUpTime, *previousStationaryTime;
    int    timeToFallAsleep = 0, inBetweenTime = 0;
    
    
    
    [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
    //  [[NSUserDefaults standardUserDefaults]setObject:nowSatrDate forKey:@"myDateKey"];
    
    
    if(sleepData!=nil && sleepData.count > 0)
    {
        
        startSleepDate=[[sleepData valueForKey:@"startDate"] firstObject];
        tempDate=[[sleepData valueForKey:@"startDate"] lastObject];
        NSArray *arrayForStartDate = [NSArray arrayWithArray:[sleepData valueForKey:@"startDate"]];
        NSArray *arrayForConfidence = [NSArray arrayWithArray:[sleepData valueForKey:@"confidence"]];
        NSArray *arrayForStationary = [NSArray arrayWithArray:[sleepData valueForKey:@"stationary"]];
        
        
        for(int i=0; i<[sleepData count]-1; i++)
        {
            
            if(!notInBed)
            {
                if(([sleepData objectAtIndex:i] == [sleepData lastObject]) && ([[arrayForStationary lastObject]intValue] == 1) && [[arrayForConfidence lastObject] intValue] == 2)
                {
                    ///Get difference between lastActivity Time and Ending Time...
                    int difference = [endTime timeIntervalSinceDate:[arrayForStartDate lastObject]];
                    
                    ///if difference is more than 2 hours then add in TotalsleepTimeInSeconds...
                    if(difference > 7200)
                    {
                        TotalsleepTimeInSeconds = TotalsleepTimeInSeconds + difference;
                        
                        if(isSleepTimeSet == 0)
                        {
                            
                            SleepTime = [[NSDate alloc]init];
                            SleepTime = [arrayForStartDate objectAtIndex:i];
                            isSleepTimeSet = 1;
                        }
                        
                        WokeUpTime = [[NSDate alloc]init];
                        WokeUpTime = [arrayForStartDate lastObject];
                    }
                    
                }
                else if([sleepData objectAtIndex:i] != [sleepData lastObject])
                {
                    NSDate *timeOfFirstActivity = [arrayForStartDate objectAtIndex:i];
                    NSDate *timeOfSecondActivity = [arrayForStartDate objectAtIndex:i+1];
                    
                    int stationary = [[arrayForStationary objectAtIndex:i]intValue];
                    int confidenceOfFirstActivity = [[arrayForConfidence objectAtIndex:i]intValue];
                    
                    int differenceInSeconds = [timeOfSecondActivity timeIntervalSinceDate:timeOfFirstActivity];
                    //NSLog(@"diff in Sconds: %d",differenceInSeconds);
                    
                    if((confidenceOfFirstActivity == 2) && (stationary == 1) && (differenceInSeconds > 7200) )
                    {
                        if(countForInBetweenDuration > 0)
                        {
                            inBetweenWokeUpDuration = inBetweenWokeUpDuration + [timeOfFirstActivity timeIntervalSinceDate:previousStationaryTime];
                        }
                        
                        
                        TotalsleepTimeInSeconds = TotalsleepTimeInSeconds + differenceInSeconds;
                        
                        if(isSleepTimeSet == 0)
                        {
                            
                            SleepTime = [[NSDate alloc]init];
                            SleepTime = [arrayForStartDate objectAtIndex:i];
                            isSleepTimeSet = 1;
                        }
                        
                        
                        previousStationaryTime = [[NSDate alloc]init];
                        previousStationaryTime = [arrayForStartDate objectAtIndex:i+1];
                        
                        countForInBetweenDuration = countForInBetweenDuration + 1;
                        
                        WokeUpTime = [[NSDate alloc]init];
                        WokeUpTime = [arrayForStartDate objectAtIndex:i+1];
                        
                    }
                    else if(previousStationaryTime != nil)
                    {
                        //Stop counter if difference between previousStatinaryTime and current activity time is greater than 30 min.
                        
                        differenceInSeconds = [timeOfFirstActivity timeIntervalSinceDate:previousStationaryTime];
                        
                        
                        if(differenceInSeconds > inBetweenTime)
                        {
                            notInBed = true;
                        }
                    }
                }
                
                
            }
            
            
        }
        
        ///If in case user didnt sleep..
        if(isSleepTimeSet == 0)
        {
            zeroSleep = 1;
            SleepTime = [[InstantDataBase sharedInstantDataBase] sleepStartTime:startTime];
            WokeUpTime = [[InstantDataBase sharedInstantDataBase] sleepStartTime:startTime];
        }
        [_dateFormatter setDateFormat:@"MMM dd,YYYY"];
        NSString *date = [_dateFormatter stringFromDate:[startTime dateByAddingTimeInterval:timeToFallAsleep]];
        
        [_dateFormatter setDateFormat:@"MMM dd,YYYY HH:mm:ss"];
        //NSString *sleepTimeInString = [_dateFormatter stringFromDate:SleepTime];
        //NSString *wokeUpTimeInString = [_dateFormatter stringFromDate:WokeUpTime];
        
        if(TotalsleepTimeInSeconds > 0)
        {
            TotalsleepTimeInSeconds = TotalsleepTimeInSeconds - timeToFallAsleep;
        }
        
        
        
        [self storeDataInDictionaryDate:date totalSleepTime:TotalsleepTimeInSeconds sleepAtTime:SleepTime wokeUpAtTime:WokeUpTime inBetweenDuration:inBetweenWokeUpDuration countInBetween:countForInBetweenDuration zeroSleep:zeroSleep withCallBackHandler:^(BOOL isStore)
         {
             sleepTime(isStore);
         }];
        
        
    }
    else
    {
        sleepTime(YES);
    }
    
    
    
    
}



///Store date, total sleep time, sleepAt, wokeUpAt, inBetweenDuration, countForInBetween, zeroSleep into dictionary for insert or update dictionary in sleep table of database.
-(void)storeDataInDictionaryDate:(NSString *)date totalSleepTime:(int )totalSleepTime sleepAtTime:(NSDate *)sleepAtTime wokeUpAtTime:(NSDate *)wokeUpAtTime inBetweenDuration:(int)inBetweenDuration countInBetween:(int)countInBetween zeroSleep:(int)zeroSleep withCallBackHandler:(void(^)(BOOL isStore))storeHandler
{
    NSMutableDictionary * sleepdic = [[NSMutableDictionary alloc]init];
    [sleepdic setValue:date forKey:@"date"];
    [sleepdic setValue:[NSNumber numberWithInt:totalSleepTime] forKey:@"totalSleepTime"];
    [sleepdic setValue:sleepAtTime forKey:@"sleepTime"];
    [sleepdic setValue:wokeUpAtTime forKey:@"wokeUpTime"];
    [sleepdic setValue:[NSNumber numberWithInt:inBetweenDuration] forKey:@"inBetweenDuration"];
    [sleepdic setValue:[NSNumber numberWithInt:countInBetween-1] forKey:@"countForInBetween"];
    [sleepdic setValue:[NSNumber numberWithInt:zeroSleep] forKey:@"zeroSleep"];
    
    //Insert or update sleep records date wise into sleep table of database
    
    [[InstantDataBase sharedInstantDataBase]insertOrUpdateSleepData:sleepdic withCallBackhandler:^(BOOL isInsert)
     {
         storeHandler(isInsert);
         
     }];
    
    
}

#pragma mark -HealthKit
/// Get healthkit permission for parsing sleep data from healthkit.

-(void)healthKitPermission:(void(^)(BOOL healthKitPermission))permissionHandler
{
    NSSet *readObjectTypes  = [NSSet setWithObjects:[HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],  nil];
    [_healthStore requestAuthorizationToShareTypes:nil
                                         readTypes:readObjectTypes
                                        completion:^(BOOL success, NSError *  error)
     {
        
         if (success==YES)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [[NSUserDefaults standardUserDefaults] setValue:@"healthkit" forKey:@"sleep"];
                 [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdate"];
             });
         }
         else
         {
             dispatch_async(dispatch_get_main_queue(), ^{
             [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleep"];
             });
         }
             permissionHandler(success);
        
        
         
     }];
    
}


/// Get sleep data from healthKit framework using passed start time and end time.if get sleep data array then returns YES otherwise NO. startTime passing sleep start date and time. endTime passing sleep end date and time.

-(void)getSleepDataUsingHealthKit:(NSDate *)startTime toEndTime:(NSDate *)endTime withCallBack:(void(^)(BOOL  isSleepData))healthKitSleepActivity
{
    BOOL  zeroSleep = false;
    int  inBetweenWokeUpDuration = 0, countForInBetweenDuration = 0;
    int    timeToFallAsleep = 0;
    HKSampleType *sampleType = [HKSampleType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startTime endDate:endTime options:HKQueryOptionNone];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:0 sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error)
                            {
                               
                                
                                double minutesSleepAggr = 0;
                                
                                if (results!=nil && results.count > 0)
                                {
                                    HKCategorySample *sample=[results firstObject];
                                    
                                    NSDate *hkstartTime=sample.startDate;
                                    NSDate *endTime=sample.endDate;
                                    NSTimeInterval distanceBetweenDates = [sample.endDate timeIntervalSinceDate:sample.startDate];
                                    double minutesBetweenDates = distanceBetweenDates;
                                    
                                    minutesSleepAggr += minutesBetweenDates;
                                    [_dateFormatter setDateFormat:@"MMM dd,YYYY"];
                                    
                                    NSString *date = [_dateFormatter stringFromDate:[hkstartTime dateByAddingTimeInterval:timeToFallAsleep]];
                                    
                                    [self storeDataInDictionaryDate:date totalSleepTime:minutesSleepAggr sleepAtTime:hkstartTime wokeUpAtTime:endTime inBetweenDuration:inBetweenWokeUpDuration countInBetween:countForInBetweenDuration zeroSleep:zeroSleep withCallBackHandler:^(BOOL isStore)
                                     {
                                         healthKitSleepActivity(isStore);
                                     }];
                                }
                                else
                                {
                                    NSDate *oneDaysAgo = [[self StartTime:endTime] dateByAddingTimeInterval:-1*24*60*60];
                                    
                                    [_dateFormatter setDateFormat:@"MMM dd,YYYY"];
                                    NSString *date = [_dateFormatter stringFromDate:oneDaysAgo];
                                    
                                    [self storeDataInDictionaryDate:date totalSleepTime:minutesSleepAggr sleepAtTime:startTime wokeUpAtTime:startTime inBetweenDuration:-1 countInBetween:0 zeroSleep:0 withCallBackHandler:^(BOOL isStore)
                                     {
                                         healthKitSleepActivity(isStore);
                                     }];
                                }
                                
                                
                            }];
    
    [_healthStore executeQuery:query];
    
}

#pragma mark -FitBit

/// Get sleep data from FitBit framework using passed start time.if get sleep data array then returns YES otherwise NO.param startTime passing sleep start date and time.

-(void)getSleepDataUsingFitBit:(NSDate *)startTime  withCallBack:(void(^)(BOOL  isSleepData))FitBitSleepActivity
{
    
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString *user_id = [[NSUserDefaults standardUserDefaults]valueForKey:@"fitBitUserId"];
    //NSDate *date = [NSDate date];
    // NSDate *yesterdayDate = [date dateByAddingTimeInterval:-1*24*60*60];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString *dateStr = [dateFormatter stringFromDate:[self StartTime:startTime]];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.fitbit.com/1/user/%@/sleep/date/%@.json",user_id, dateStr];
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults]valueForKey:@"fitBitAccessToken"];
    NSString *authHeaderStr = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    //Date Formatter for Sleep Display
    [dateFormatter setDateFormat:@"MMM dd,YYYY"];
    NSString *sleepDictDate = [dateFormatter stringFromDate:[self StartTime:startTime]];
    //Set Authorization Header
    [defaultConfigObject setHTTPAdditionalHeaders:@{@"Authorization" :authHeaderStr}];
    defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject];
    
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url completionHandler:^(NSData *data1, NSURLResponse *response, NSError *error)
                                       {
                                           
                                           //NSLog(@"Response=%@",response);
                                           if(error == nil)
                                           {
                                               NSMutableDictionary *sleepDataDict = [[NSMutableDictionary alloc]init];
                                               sleepDataDict = [NSJSONSerialization JSONObjectWithData:data1 options:kNilOptions error:nil];
                                               
                                               NSMutableDictionary *summaryDict = [[NSMutableDictionary alloc]init];
                                               summaryDict = [sleepDataDict valueForKey:@"summary"];
                                               if (summaryDict!=nil && summaryDict.count>0)
                                               {
                                                   NSString *strSleepMinute=[summaryDict valueForKey:@"totalMinutesAsleep"];
                                                   NSString *totalTimeInBed=[summaryDict valueForKey:@"totalTimeInBed"];
                                                   int totalMinutessleep = [strSleepMinute intValue];
                                                   
                                                   int totalMinutesAsleep =totalMinutessleep*60 ;
                                                   
                                                   int hour = [totalTimeInBed intValue] / 60;
                                                   int min = [totalTimeInBed intValue]  % 60;
                                                   
                                                   NSArray *sleepArray=[sleepDataDict objectForKey:@"sleep"];
                                                   if (sleepArray!=nil && sleepArray.count>0)
                                                   {
                                                       
                                                       
                                                       NSString *awakeinBetweenstr=[[sleepArray valueForKey:@"awakeCount"] objectAtIndex:0];
                                                       int awakeinBetween=[awakeinBetweenstr intValue];
                                                       
                                                       NSString *sleepTimeDate=[[sleepArray valueForKey:@"startTime"] objectAtIndex:0];
                                                       NSString *awakeMinString=[[sleepArray valueForKey:@"minutesAwake"] objectAtIndex:0];
                                                       
                                                       [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
                                                       
                                                       NSDate *sleepDate=[_dateFormatter dateFromString:sleepTimeDate];
                                                       [_dateFormatter setDateFormat:@"MMM dd,YYYY HH:mm:ss"];
                                                       
                                                       //NSString *startSleep=[_dateFormatter stringFromDate:sleepDate];
                                                       
                                                       
                                                       //
                                                       NSString *strCurrentDate;
                                                       NSString *strNewDate;
                                                       
                                                       NSDateFormatter *df =[[NSDateFormatter alloc]init];
                                                       [df setDateStyle:NSDateFormatterMediumStyle];
                                                       [df setTimeStyle:NSDateFormatterMediumStyle];
                                                       strCurrentDate = [df stringFromDate:sleepDate];
                            
                                                       //int hoursToAdd = 3;
                                                       NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                                                       NSDateComponents *components = [[NSDateComponents alloc] init];
                                                       [components setHour:hour];
                                                       [components setMinute:min];
                                                       NSDate *newDate= [calendar dateByAddingComponents:components toDate:sleepDate options:0];
                                                       [df setDateStyle:NSDateFormatterMediumStyle];
                                                       [df setTimeStyle:NSDateFormatterMediumStyle];
                                                       strNewDate = [df stringFromDate:newDate];
                                                     
                                                       [_dateFormatter setDateFormat:@"MMM dd,YYYY HH:mm:ss"];
                                                       
                                                       // NSString *wakeupSleep=[_dateFormatter stringFromDate:newDate];
                                                       ////
                                                       
                                                       [self storeDataInDictionaryDate:sleepDictDate totalSleepTime:totalMinutesAsleep sleepAtTime:sleepDate wokeUpAtTime:newDate inBetweenDuration:[awakeMinString intValue]*60 countInBetween:awakeinBetween zeroSleep:0 withCallBackHandler:^(BOOL isStore)
                                                        {
                                                            FitBitSleepActivity(isStore);
                                                        }];
                                                       
                                                       
                                                   }
                                                   else
                                                   {
                                                       
                                                       [self storeDataInDictionaryDate:sleepDictDate totalSleepTime:totalMinutesAsleep sleepAtTime:startTime wokeUpAtTime:startTime inBetweenDuration:0 countInBetween:0 zeroSleep:0 withCallBackHandler:^(BOOL isStore) {
                                                           FitBitSleepActivity(isStore);
                                                       }];
                                                   }
                                                   
                                                   
                                               }
                                               FitBitSleepActivity(YES);
                                               
                                           }
                                           else
                                           {
                                              
                                               FitBitSleepActivity(NO);
                                               
                                           }
                                           
                                       }];
    
    [dataTask resume];
    
    
}
/// getting n number of days of sleep and insert n number of sleep  data into sleep table

-(void)getNNumberOfSleepData
{
    
    NSDate *sleepDeleteDate= (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"sleepdelete"];
    BOOL  isTodayDelete=[[NSCalendar currentCalendar]isDate:sleepDeleteDate inSameDayAsDate:[NSDate date]];
    
    if (isTodayDelete==NO)
    {
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleepdelete"];
        NSDateComponents *components;
        NSInteger numberOfDay=0;
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        NSDate *lastActivityDate= (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"sleepdate"];
        //L10
        if (lastActivityDate==nil)
        {
            lastActivityDate=[NSDate date];
        }
        
        NSDate* midnightLastNight = [self midNightOfLastNight:lastActivityDate];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:midnightLastNight
                                            toDate:[NSDate date]
                                           options:0];
        numberOfDay=[components day];
        
        
        if (numberOfDay>0)
        {
            for (int i=0; i<=numberOfDay; i++)
            {
                if (i!=0)
                    
                {
                    
                    if (i==numberOfDay)
                    {
                        // Calculates location time from midnight to now
                        NSDate *NextDate= [NSDate date];
                        
                        //Calls Sleep Manager to find Fitness Data
                        [self getSleepOptionAndFindSleepDataFromStartTime:NextDate toEndTime:NextDate];
                        
                    }
                    else
                    {
                        //Calculates location time from last midnight to tomorrow midnight
                        NSDate *lastDate= [lastActivityDate dateByAddingTimeInterval:i*24*60*60];
                        NSDate *lastMidNight=[self midNightOfLastNight:lastDate];
                        
                        //Calls Sleep Manager to find Fitness Data
                        [self getSleepOptionAndFindSleepDataFromStartTime:lastMidNight toEndTime:lastMidNight];
                     
                    }
                    
                }
                
            }
            
            
            
        }
        else
        {
            //Calls Activity Manager to find Fitness Data
            [self getSleepOptionAndFindSleepDataFromStartTime:lastActivityDate toEndTime:[NSDate date]];
        }
        
        [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdate"];
    }
    
}

/// Getting last midnight using previous date (Used to split the place time data between 2 days)
-(NSDate *)midNightOfLastNight :(NSDate *)date
{
    
    NSCalendar *gregorian1 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateComponents = [gregorian1 components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    
    NSDate* findMidNightDate = [gregorian1 dateFromComponents:dateComponents];
    return findMidNightDate;
}
/// Getting next day's midnight using passed date (Used to split the place time data between 2 days)
-(NSDate *)nextMidNight:(NSDate *)date
{
    
    NSCalendar *const calendar = NSCalendar.currentCalendar;
    NSCalendarUnit const preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *const components = [calendar components:preservedComponents fromDate:date];
    NSDate *const normalizedDate = [calendar dateFromComponents:components];
    return normalizedDate;
}



-(NSDate *)StartTime:(NSDate *)startTime
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    //To set Starting time...
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: startTime];
    [components setDay:components.day];
    [components setHour: 19];
    [components setMinute: 00];
    [components setSecond: 00];
    NSDate *startingTime = [gregorian dateFromComponents: components];
    return startingTime;
}

/*
 *@discussion Checks Sleep Permission
 */
-(void)checkSleepPermission:(void(^)(BOOL isSleepPermission))handler
{
    NSString *sleepOptionName=[[NSUserDefaults standardUserDefaults]valueForKey:@"sleep"];
    if ([sleepOptionName isEqualToString:@"default"])
    {
        [_sleepActivity queryActivityStartingFromDate:[NSDate date] toDate:[NSDate date] toQueue:[NSOperationQueue new] withHandler:^(NSArray * activities, NSError *  error)
         {
             if (error)
             {
                 if (error.code==CMErrorMotionActivityNotAuthorized || error.code==CMErrorMotionActivityNotEntitled || error.code==CMErrorMotionActivityNotAvailable)
                 {
                     [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleep"];
                     handler(NO);
                 }
                 
             }
             else
             {
                 if (activities)
                 {
                     [[NSUserDefaults standardUserDefaults] setValue:@"default" forKey:@"sleep"];
                     handler(YES);
                 }
             }
         }];
        
    }
    else if ([sleepOptionName isEqualToString:@"healthkit"])
    {
        [self healthKitPermission:^(BOOL healthKitPermission)
        {
            if (healthKitPermission==YES)
            {
                handler(YES);
            }
            else
            {
                handler(NO);
            }
        }];
    }
}



@end
