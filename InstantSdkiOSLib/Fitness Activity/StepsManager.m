//
//  StepsManager.m
//  InstantSDK
//
//  Created by Emberify_Vijay on 10/10/17.
//  Copyright © 2017 Emberify. All rights reserved.
//  Reviewed on 12/11/17

#import "StepsManager.h"
#import <HealthKit/HealthKit.h>
#import "LocationNameAndTime.h"
#import "InstantDataBase.h"
#import <UIKit/UIKit.h>
@implementation StepsManager
static StepsManager *sharedStepsManager=nil;


///Creates Steps manager singletone class. It has all Steps related information like  steps and date. It can be accessed anywhere in the application.
+(StepsManager *)sharedStepsManager
{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedStepsManager=[[StepsManager alloc]init];
    });
    return sharedStepsManager;
}

/// Initializes all Steps related object using CoreMotion Framework
-(id)init
{
    
    if (self=[super init])
    {
        
        self.stepspedometer=[[CMPedometer alloc]init];
       
    }
    
    return self;
}

/// Start steps tracking using healthkit. If healthkit tracking starts successful handler returns StepsHealthKitPermissionSuccess otherwise handler returns StepsHealthKitPermissionFail.
-(void)startHealthKitActivityTracking:(stepsPermissionCustomCompletionBlock)handler
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"healthActivityEnable"];
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isFitBitActivity==NO || permissions.isCustomeActivity==NO)
    {
        
        [self healthKitPermission:^(BOOL healthKitPermission)
         {
             if (healthKitPermission==YES)
             {
                 ///check healthkit before enable or not
                 BOOL isHealthkitOpenFirstTime=[[NSUserDefaults standardUserDefaults]boolForKey:@"openHealthkitFirtTime"];
                 
                 if (isHealthkitOpenFirstTime==NO)
                 {
                     ///if health kit enable first time after installation of app then add last week healthkit data into database
                     [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"openHealthkitFirtTime"];
                     NSDate *lastWeekStartDate=[[NSDate date]dateByAddingTimeInterval:-7*24*60*60];
                     [[NSUserDefaults standardUserDefaults]setValue:[self midNightOfLastNight:lastWeekStartDate] forKey:@"customeactivtiydate"];
                     [self findNNumberOfDaysOfFitnessData];
                     
                 }
                 else
                 {
                     [[NSUserDefaults standardUserDefaults]setValue:[self midNightOfLastNight:[NSDate date]] forKey:@"customeactivtiydate"];
                     [self getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:[NSDate date]] endDate:[NSDate date]];
                 }
                 permissions.isHealthKitActivity=YES;
                 handler(StepsHealthKitPermissionSuccess);
             }
             else
             {
                 permissions.isHealthKitActivity=NO;
                 handler(StepsHealthKitPermissionFail);
             }
             
         }];
        
        
    }
    else
    {
        permissions.isHealthKitActivity=NO;
        handler(StepsHealthKitPermissionFitbitEnable);
        
    }
        
    
}


/// Stops steps tracking using healthkit. If healthkit tracking stops successful handler returns Yes otherwise handler returns No.
-(void)stopHealthKitActivityTracking:(void(^)(BOOL isStop))handler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"healthActivityEnable"];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"customeactivtiy"];
    });
    handler(YES);
}


/// Starts steps tracking using fitbit. If fitbit tracking start successful handler returns StepsFitBitPermissionSuccess otherwise handler returns StepsFitBitPermissionFail. IMP: The redirect URL and client ID need to be changed here.

-(void)startFitBitActivityTracking:(stepFitBitPermissionCustomCompletionBlock)handler
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fitbitActivityEnable"];
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isHealthKitActivity==NO || permissions.isCustomeActivity==NO)
    {
        if (@available(iOS 9.0, *)) {
           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.fitbit.com/oauth2/authorize?response_type=token&client_id=228LXP&redirect_uri=http%3A%2F%2Femberify.com%2Ffitbit1.html&scope=activity%20profile%20sleep&expires_in=604800"]];
            
        }
        else
        {
         
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://www.fitbit.com/oauth2/authorize?response_type=token&client_id=228LXP&redirect_uri=http%3A%2F%2Femberify.com%2Ffitbit1.html&scope=activity%20profile%20sleep&expires_in=604800"] options:@{} completionHandler:nil];
        }
        
        
        
        [[NSUserDefaults standardUserDefaults]setValue:[self midNightOfLastNight:[NSDate date]] forKey:@"customeactivtiydate"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] setValue:@"fitbit" forKey:@"customeactivtiy"];
        });
        permissions.isFitBitActivity=YES;
        
        handler(StepsFitBitPermissionSuccess);
        
    }
    else
    {
        
        handler(StepsFitBitPermissionHealthKitEnable);
    }
    
}

/// Stops steps tracking using fitbit.if fitbit tracking stop successful handler returns Yes otherwise handler returns No.

-(void)stopFitBitActivityTracking:(void(^)(BOOL isStop))handler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"fitbitActivityEnable"];
         [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"customeactivtiy"];
    });
    
    handler(YES);
}



///Get all fitness activity using coremotion framework CMMotionActivityManager and steps using CMPedometer passing startdate and enddate. Called on significant location changes (also called through LocationManager on app open)
-(void)getFitnessDataFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    
    
    
    //gets selected activtiy type like HealthKit, FitBit, CoreMotion
    LocationNameAndTime *activityType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    activityType=[[InstantDataBase sharedInstantDataBase]selectAllDateOfSteps];
    
    if (activityType.isHealthKitActivity==YES)
    {
        //Gets activity like steps count, walking, travelling, running, cycling from healthkit framework
        [self getStepsFromHealthKitStartDate:startDate endDate:endDate withCallBackHandler:^(NSInteger stepsCount)
         {
             if ([activityType.stepsAllDates containsObject:[[InstantDataBase sharedInstantDataBase]date:startDate]])
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"update" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             else
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"insert" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             
         }];
        
    }
    else if (activityType.isFitBitActivity==YES)
    {
        //Gets activity like steps count, walking, travelling, running, cycling from fitbit
        [self getStepsFromFitBitStartDate:startDate endDate:endDate withCallBackHandler:^(NSInteger stepsCount)
         {
             if ([activityType.stepsAllDates containsObject:[[InstantDataBase sharedInstantDataBase]date:startDate]])
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"update" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             else
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"insert" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             
             
         }];
    }
    else if (activityType.isDefaultActivity==YES)
    {
        //Gets activity like steps count, walking, travelling, running, cycling from coremotion framework
        [self getStepsFromCoreMotionStartDate:startDate endDate:endDate withCallBackHandler:^(NSInteger stepsCount)
         {
             if ([activityType.stepsAllDates containsObject:[[InstantDataBase sharedInstantDataBase]date:startDate]])
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"update" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             else
             {
                 [[InstantDataBase sharedInstantDataBase]insertOrUpdateSteps:stepsCount startDate:startDate endDate:endDate date:[[InstantDataBase sharedInstantDataBase]date:startDate] queryStatus:@"insert" withCallBackHandler:^(BOOL isInsert)
                  {
                      
                  }];
             }
             
             
         }];
    }
    
    
    
}

///Gets the total number of steps for today using CoreMotion framework CMPedometer object passing start date  (last mid night date) and end date (current date & time). Total steps are inserted into steps table.
-(void)getStepsFromCoreMotionStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler;

{
    
    totalSteps=0;
    
    [self.stepspedometer queryPedometerDataFromDate:startDate toDate:endDate withHandler:^(CMPedometerData *pedometerData, NSError *error)
     {
         if (error)
         {
             activityHandler([totalSteps integerValue]);
         }
         else
         {
             if (pedometerData!=nil)
             {
                 
                 totalSteps=pedometerData.numberOfSteps  ;
                 
                 activityHandler([totalSteps integerValue]);
             }
         }
         
         
     }];
    
}


///Gets the step count for today using healthKit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps that are inserted into steps table of database.
-(void)getStepsFromHealthKitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler
{
    totalSteps=0;
    HKHealthStore *healthStore = [[HKHealthStore alloc] init];
    // Use the sample type for step count
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // HKAuthorizationStatus status = [healthStore authorizationStatusForType:sampleType];
    
    
    // Creates a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Creates a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                NSInteger totalFSteps=0;
                                                                if(!error && results)
                                                                {
                                                                    
                                                                    for(HKQuantitySample *samples in results)
                                                                    {
                                                                        HKQuantity  *quantity=samples.quantity;
                                                                        NSString *string=[NSString stringWithFormat:@"%@",quantity];
                                                                        NSString *newString1 = [string stringByReplacingOccurrencesOfString:@" count" withString:@""];
                                                                        
                                                                        NSInteger count=[newString1 integerValue];
                                                                        totalFSteps=totalFSteps+count;
                                                                        
                                                                    }
                                                                    totalSteps=[NSNumber numberWithInteger:totalFSteps];
                                                                    activityHandler([totalSteps integerValue]);
                                                                }
                                                                else
                                                                {
                                                                    totalSteps=[NSNumber numberWithInteger:totalFSteps];
                                                                    activityHandler([totalSteps integerValue]);
                                                                }
                                                                
                                                                
                                                                
                                                            }];
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
    
    
    
}



///Gets the step count for today using FitBit passing start date  (last mid night date) and end date (current date) and total steps are stored into totalSteps that are insert into steps table of instant database.
-(void)getStepsFromFitBitStartDate:(NSDate *)startDate endDate:(NSDate *)endDate withCallBackHandler:(void(^)(NSInteger stepsCount))activityHandler
{
    
    totalSteps=0;
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    NSString *user_id = [[NSUserDefaults standardUserDefaults]valueForKey:@"fitBitUserId"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStr = [dateFormatter stringFromDate:startDate];
    //Recent Activity Type - Bicycling
    NSString *urlString = [NSString stringWithFormat:@"https://api.fitbit.com/1/user/%@/activities/date/%@.json", user_id,dateStr];
    
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults]valueForKey:@"fitBitAccessToken"];
    NSString *authHeaderStr = [NSString stringWithFormat:@"Bearer %@", accessToken];
    
    //Sets Authorization Header
    [defaultConfigObject setHTTPAdditionalHeaders:@{@"Authorization" :authHeaderStr}];
    defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject];
    
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        
                                                        //NSLog(@"Response=%@",response);
                                                        if(error == nil)
                                                        {
                                                            
                                                            NSDictionary *mainDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                                                           
                                                            totalSteps=[NSNumber numberWithInteger:[[[mainDict objectForKey:@"summary"] objectForKey:@"steps"] integerValue]] ;
                                                            activityHandler([totalSteps integerValue]);
                                                            
                                                        }
                                                        else
                                                        {
                                                           
                                                            activityHandler([totalSteps integerValue]);
                                                            
                                                        }
                                                        
                                                    }];
    
    [dataTask resume];
    
    
    
}


-(void)findNNumberOfDaysOfFitnessData
{
    NSDateComponents *components;
    NSInteger numberOfDay=0;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *lastActivityDate;
    
    
    
    lastActivityDate= (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"customeactivtiydate"];
    
    
    
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
                [self getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:lastActivityDate] endDate:nextMidNight];
                //
                
            }
            else
            {
                
                if (i==numberOfDay)
                {
                    //Calculates location time from midnight to now
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
        [self getFitnessDataFromCoreMotionStartDate:[self midNightOfLastNight:lastActivityDate] endDate:[NSDate date]];
    }
    
    
    [[NSUserDefaults standardUserDefaults]setValue:[self midNightOfLastNight:[NSDate date]] forKey:@"customeactivtiydate"];
    
    
}



/// Gets last midnight using previous date (Used to split the place time data between 2 days)
-(NSDate *)midNightOfLastNight :(NSDate *)date
{
    
    NSCalendar *gregorian1 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateComponents = [gregorian1 components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    
    NSDate* findMidNightDate = [gregorian1 dateFromComponents:dateComponents];
    return findMidNightDate;
}
/// Gets next day's midnight using passed date (Used to split the place time data between 2 days)
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
 *@discussion Checks permission of steps
 */
-(void)checkStpsPermission:(void(^)(BOOL stepsPermission))handler
{
    LocationNameAndTime *activityType=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    
    if (activityType.isHealthKitActivity==YES)
    {
        [self healthKitPermission:^(BOOL healthKitPermission) {
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
    else if (activityType.isFitBitActivity==YES)
    {
        handler(YES);
    }
    
}


/// Get healthkit permission for parsing steps data from healthkit.

-(void)healthKitPermission:(void(^)(BOOL healthKitPermission))permissionHandler
{
    HKHealthStore *healthStore=[[HKHealthStore alloc]init];
    if ([HKHealthStore isHealthDataAvailable] == YES)
    {
        NSSet *readObjectTypes  = [NSSet setWithObjects:[HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],  nil];
        
        [healthStore requestAuthorizationToShareTypes:nil
                                            readTypes:readObjectTypes
                                           completion:^(BOOL success, NSError *  error)
         {
             if (success==YES)
             {
                 
                 [[NSUserDefaults standardUserDefaults] setValue:@"healthkit" forKey:@"customeactivtiy"];
                 
                
             }
             else
             {
                 [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"customeactivtiy"];
             }
             permissionHandler(success);
             
             
             
         }];
    }
    else
    {
        permissionHandler(NO);
    }
    
}


@end

