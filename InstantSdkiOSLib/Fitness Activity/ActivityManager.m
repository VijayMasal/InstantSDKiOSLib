//
//  ActivityManager.m
//  InstantSDK
//
//  Created by Emberify_Vijay on 02/09/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 10/09/17

#import "ActivityManager.h"
#import "LocationNameAndTime.h"
#import <HealthKit/HealthKit.h>
#import "StepsManager.h"

@implementation ActivityManager
static ActivityManager *sharedFitnessActivityManager=nil;


///Creates activity manager singletone class. It has all fitness related information like walking, running,travelling, stationary, cycling, steps and date. It can be accessed anywhere in the application.
+(ActivityManager *)sharedFitnessActivityManager
{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedFitnessActivityManager=[[ActivityManager alloc]init];
    });
    return sharedFitnessActivityManager;
}

/// Initializes all activity related object using CoreMotion Framework
-(id)init
{
    
    if (self=[super init])
    {
        _motionActivity=[[CMMotionActivityManager alloc]init];
        self.stepspedometer=[[CMPedometer alloc]init];
    }
    
    return self;
}


/// Start fitness tracking using coremotion.if fintess tracking start successful handler returns FitnessActivityPermissionSuccess otherwise handler returns  FitnessActivityPermissionFail.

-(void)startCoreMotionActivityTracking:(FitnessCustomCompletionBlock)handler
{
    [[NSUserDefaults standardUserDefaults] setValue:@"default" forKey:@"activtiy"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"activitydate"];
    [[NSUserDefaults standardUserDefaults]setValue:[self midNightOfLastNight:[NSDate date]] forKey:@"customeactivtiydate"];
    
    
    LocationNameAndTime *activityType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (activityType.isDefaultActivity==YES)
    {
        
        NSMutableDictionary *lastActivityDict=[[InstantDataBase sharedInstantDataBase]selectLastActivityFromFitness];
        
        NSDate *starttime=[self nextMidNight:[NSDate date]];
        NSDate *lastEndtime=[lastActivityDict valueForKey:@"endtime"];
        
        if (lastEndtime)
        {
            starttime=lastEndtime;
        }
        
        //Get activity like steps count, walking, travelling, running, cycling from coremotion framework
        if (activityType.isCustomeActivity==NO)
        {
            [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:starttime endDate:[NSDate date]];
        }
        
        
        [self getWalkRunTravelCycleFromStartDate:starttime endDate:[NSDate date] withCallBackHandeler:^(BOOL isActivity)
         {
             if (isActivity==YES)
             {
                 handler(FitnessActivityPermissionSuccess);
             }
             else
             {
                 handler(FitnessActivityPermissionFail);
             }
         }];
        
    }
    
}

-(void)stopCoreMotionActivityTracking:(void(^)(BOOL isStop))handler
{
    
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"activtiy"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"activitydate"];
    handler(YES);
    
}

///Get all fitness activity using coremotion framework CMMotionActivityManager and steps using CMPedometer passing startdate and enddate. Called on significant location changes (also called through LocationManager on app open)
//-(void)getFitnessDataFromCoreMotionStartDate
-(void)getFitnessDataFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
{
    //gets selected activtiy type like HealthKit, FitBit, CoreMotion
    LocationNameAndTime *activityType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (activityType.isDefaultActivity==YES)
    {
        
        //Get activity like steps count, walking, travelling, running, cycling from coremotion framework
        dispatch_async(dispatch_get_main_queue(), ^()
                       {
        //NSDate *endDate=[NSDate date];
        [_motionActivity queryActivityStartingFromDate:startDate toDate:endDate toQueue:[NSOperationQueue new] withHandler:^(NSArray * activities, NSError *  error)
         {
          
                 if (activities)
                 {
                     
                     //get all activity time
                     [self findAllFtinessActivityTime:activities endDate:[NSDate date] toQueue:[NSOperationQueue new] withCallBackHandler:^(BOOL isParseActivityTIme)
                      {
                          
                      }];
                   
                 }
            
         }];   });
        
    }
}



///Gets walking, running, travelling, cycling data from CMMotionActivityManager and passes it to findAllFtinessActivityTime with activity info array and steps count
-(void)getWalkRunTravelCycleFromStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandeler:(void(^)(BOOL isActivity))activityData;
{
    _motionActivity=[[CMMotionActivityManager alloc]init];
    [_motionActivity queryActivityStartingFromDate:startDate toDate:endDate toQueue:[NSOperationQueue new] withHandler:^(NSArray * activities, NSError *  error)
     {
         
         
         if (error)
         {
             
             
             if (error.code==CMErrorMotionActivityNotAuthorized || error.code==CMErrorMotionActivityNotEntitled || error.code==CMErrorMotionActivityNotAvailable)
             {
                 
               activityData(NO);
             }
           
         }
         else
         {
             if (activities)
             {
                 
                 //get all activity time
                 [self findAllFtinessActivityTime:activities endDate:[NSDate date] toQueue:[NSOperationQueue new] withCallBackHandler:^(BOOL isParseActivityTIme)
                  {
                      
                  }];
                 activityData(YES);
                 
             }
         }
         
         
     }];
    
}

///After getting fitness activity using CMMotionActivityManage and CMMpedometer calculates each activity time (like walktime, runtime, traveltime, stationarytime, cycletime, steps count) from passed CMMotionActivity array and totalSteps and currentDate, if activity is not present then insert all activity time 0 for particular date in fitness table.if parsing activity time callback send Yes otherwise No .
-(void )findAllFtinessActivityTime:(NSArray<CMMotionActivity *>*)activity  endDate:(NSDate *)currentDate toQueue:(NSOperationQueue *)toQueue withCallBackHandler:(void(^)(BOOL isParseActivityTIme))block
{
    // NSMutableDictionary *activityDict=[[NSMutableDictionary alloc]init];
    NSMutableArray *dateArray=[[NSMutableArray alloc]init];
    NSMutableArray *walkingArray=[[NSMutableArray alloc]init];
    NSMutableArray *runningArray=[[NSMutableArray alloc]init];
    NSMutableArray *travellingArray=[[NSMutableArray alloc]init];
    NSMutableArray *statinaryArray=[[NSMutableArray alloc]init];
    NSMutableArray *unknownArray=[[NSMutableArray alloc]init];
    NSMutableArray *confidenceArray=[[NSMutableArray alloc]init];
    NSMutableArray *cyclingArray=[[NSMutableArray alloc]init];
    NSDate *startDate,*endDate;
    
    
    
    if (activity.count>0)
    {
        dateArray=[activity valueForKey:@"startDate"];
        walkingArray=[activity valueForKey:@"walking"];
        travellingArray=[activity valueForKey:@"automotive"];
        statinaryArray=[activity valueForKey:@"stationary"];
        runningArray=[activity valueForKey:@"running"];
        unknownArray=[activity valueForKey:@"unknown"];
        confidenceArray=[activity valueForKey:@"confidence"];
        cyclingArray = [activity valueForKey:@"cycling"];
        for (int i=0; i<[statinaryArray count]-1; i++)
        {
            
            startDate=[dateArray objectAtIndex:i];
            endDate=[dateArray objectAtIndex:i+1];
            
            int confidence=[[confidenceArray objectAtIndex:i]intValue];
            
            //Gets walking time using last and current date timeinterval
            int lastWalkingindex=[[walkingArray objectAtIndex:i] intValue];
            int currentWalkingIndex=[[walkingArray objectAtIndex:i+1] intValue];
            if (lastWalkingindex==1 && currentWalkingIndex==0 &&confidence !=0 )
            {
                
                NSInteger walkTime=[endDate timeIntervalSinceDate:startDate];
                
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Walking" activityTime:walkTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData)
                 {
                     
                 }];
                
            }
            else if (lastWalkingindex==1 && currentWalkingIndex==1  )
            {
                NSInteger walkTime=[endDate timeIntervalSinceDate:startDate];
                
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Walking" activityTime:walkTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData)
                 {
                     
                 }];
                
                
            }
            
            //Gets running time using last and current date timeinterval
            int lastRunningIndex=[[runningArray objectAtIndex:i] intValue];
            int currentRunningIndex=[[runningArray objectAtIndex:i+1] intValue];
            if (lastRunningIndex==1 && currentRunningIndex==0 &&confidence!=0 )
            {
                NSInteger runTime=[endDate timeIntervalSinceDate:startDate];
                
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Running" activityTime:runTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
            }
            else if (lastRunningIndex==1 && currentRunningIndex==1)
            {
                NSInteger runTime=[endDate timeIntervalSinceDate:startDate];
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Running" activityTime:runTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
                
            }
            
            //Gets travelling time using last and current date timeinterval
            int lastTravellingIndex=[[travellingArray objectAtIndex:i] intValue];
            int currentTravellingIndex=[[travellingArray objectAtIndex:i+1] intValue];
            if (lastTravellingIndex==1 && currentTravellingIndex==0 &&confidence ==2 )
            {
                NSInteger travelTime=[endDate timeIntervalSinceDate:startDate];
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Travel" activityTime:travelTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
                
            }
            else if (lastTravellingIndex==1 && currentTravellingIndex==1 &&confidence ==2 )
            {
                
                NSInteger travelTime=[endDate timeIntervalSinceDate:startDate];
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Travel" activityTime:travelTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
                
            }
            //Gets cycling time using last and current date timeinterval
            int lastCyclingIndex=[[cyclingArray objectAtIndex:i] intValue];
            int  currentCyclingIndex =[[cyclingArray objectAtIndex:i+1] intValue];
            if (lastCyclingIndex==1 && currentCyclingIndex==0 &&confidence!=0 )
            {
                NSInteger cycleTime=[endDate timeIntervalSinceDate:startDate];
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Cycling" activityTime:cycleTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
                
            }
            
            else if (lastCyclingIndex==1 && currentCyclingIndex==1)
            {
                NSInteger cycleTime=[endDate timeIntervalSinceDate:startDate];
                [[InstantDataBase sharedInstantDataBase]insertFitnessDataActivity:@"Cycling" activityTime:cycleTime steps:0 startTime:startDate endTime:endDate withCallBackHandler:^(BOOL isInsertData) {
                    
                }];
                
            }
            
            
            
        }
       
        
        
        
    }
    
    
}



-(void)findNNumberOfDaysOfFitnessData
{
    NSDateComponents *components;
    NSInteger numberOfDay=0;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSMutableDictionary *lastActivityDict=[[InstantDataBase sharedInstantDataBase]selectLastActivityFromFitness];
    
    NSDate *lastActivityDate=[self midNightOfLastNight:[NSDate date]];
    NSDate *lastEndtime= (NSDate *)[lastActivityDict valueForKey:@"endtime"];
    
    if (lastEndtime)
    {
        lastActivityDate=lastEndtime;
    }
    else
    {
        lastActivityDate= (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"activitydate"];
    }
    
    //    //L10
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
            if (i==0)
            {
                //calculate  last location time from  Last MidNight
                NSDate *NextDate= [lastActivityDate dateByAddingTimeInterval:1*24*60*60];
                
                NSDate *nextMidNight=[self nextMidNight:NextDate];
                
                //Call Activity Manager to find Fitness Data
                [self getFitnessDataFromCoreMotionStartDate:lastActivityDate endDate:nextMidNight];
                //
                
            }
            else
            {
                
                if (i==numberOfDay)
                {
                    // Calculates location time from midnight to now
                    NSDate *NextDate= [NSDate date];
                    
                    NSDate *lastMidNight=[self midNightOfLastNight:NextDate];
                    //Calls Activity Manager to find Fitness Data
                    [self getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:[NSDate date]];
                    
                }
                else
                {
                    //Calculates location time from last midnight to tomorrow midnight
                    NSDate *lastDate= [lastActivityDate dateByAddingTimeInterval:i*24*60*60];
                    NSDate *lastMidNight=[self midNightOfLastNight:lastDate];
                    
                    //mid night of tomorrow
                    NSDate *NextDate= [lastActivityDate dateByAddingTimeInterval:(i+1)*24*60*60];
                    NSDate *nextMidNight=[self nextMidNight:NextDate];
                    
                    
                    //Calls Activity Manager to find Fitness Data
                    [self getFitnessDataFromCoreMotionStartDate:lastMidNight endDate:nextMidNight];
                    
                    
                    
                }
                
            }
            
        }
        
        
        
    }
    else
    {
        //Calls Activity Manager to find Fitness Data
        [self getFitnessDataFromCoreMotionStartDate:lastActivityDate endDate:[NSDate date]];
    }
    
    //[[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"activitydate"];
    
    
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
@end

