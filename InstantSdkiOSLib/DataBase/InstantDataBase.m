//
//  InstantDataBase.m
//  SingletoneDemo
//
//  Created by Vijay on 21/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import "InstantDataBase.h"
#import <UIKit/UIKit.h>
#import "LocationManager.h"
#import "SleepManager.h"
#import "ActivityManager.h"
#import "StepsManager.h"
#import "DeviceUsageManager.h"
#import <sqlite3.h>
@implementation InstantDataBase
static  sqlite3 *instantDB;
static InstantDataBase* sharedInstantDataBase=nil;
+(instancetype)sharedInstantDataBase
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstantDataBase = [[InstantDataBase alloc] init];
    });
    
    return sharedInstantDataBase;
}

- (id)init {
    if (self==[super init])
    {
        _locationModel=[[LocationNameAndTime alloc]init];
        [_locationModel setFitnessActivity:[NSArray arrayWithObjects:@"Walking",@"Running",@"Travelling",@"Steps",@"Cycling", nil]];
        _placeRecordArray=[[NSMutableArray alloc]init];
        [self createDataBase];
    }
    return self;
}

-(LocationNameAndTime *)checkPermissionFlags
{
    
    NSString *sleepOptionName=[[NSUserDefaults standardUserDefaults]valueForKey:@"sleep"];
    if (sleepOptionName)
    {
        _locationModel.isSleep=YES;
    }
    else
    {
        _locationModel.isSleep=NO;
    }
    if ([sleepOptionName isEqualToString:@"default"])
    {
        _locationModel.isDefaultSleep=YES;
        _locationModel.isHealthKitSleep=NO;
        _locationModel.isFitBitSleep=NO;
    }
    else if ([sleepOptionName isEqualToString:@"healthkit"])
    {
        _locationModel.isDefaultSleep=NO;
        _locationModel.isFitBitSleep=NO;
        _locationModel.isHealthKitSleep=YES;
        
    }
    else if ([sleepOptionName isEqualToString:@"fitbit"])
    {
        _locationModel.isDefaultSleep=NO;
        _locationModel.isHealthKitSleep=NO;
        _locationModel.isFitBitSleep=YES;
    }
    
    
    NSString *activityType=[[NSUserDefaults standardUserDefaults]valueForKey:@"activtiy"];
    if (activityType)
    {
        _locationModel.isActivity=YES;
    }
    else
    {
        _locationModel.isActivity=NO;
    }
    
    if ([activityType isEqualToString:@"default"])
    {
        _locationModel.isDefaultActivity=YES;
    }
    else
    {
        _locationModel.isDefaultActivity=NO;
    }
    
    NSString *customeactivtiy=[[NSUserDefaults standardUserDefaults]valueForKey:@"customeactivtiy"];
    if (customeactivtiy)
    {
        _locationModel.isCustomeActivity=YES;
    }
    else{
        _locationModel.isCustomeActivity=NO;
        _locationModel.isFitBitActivity=NO;
        _locationModel.isHealthKitActivity=NO;
        
    }
    if ([customeactivtiy isEqualToString:@"healthkit"])
    {
        _locationModel.isFitBitActivity=NO;
        _locationModel.isHealthKitActivity=YES;
        
    }
    else if ([customeactivtiy isEqualToString:@"fitbit"])
    {
        _locationModel.isFitBitActivity=YES;
        _locationModel.isHealthKitActivity=NO;
        
    }
    
    NSString *isLocation=[[NSUserDefaults standardUserDefaults]valueForKey:@"location"];
    if ([isLocation isEqualToString:@"significant"])
    {
        _locationModel.isSignificantLocation=YES;
        _locationModel.isOnPhoneUsage=NO;
    }
    else if ([isLocation isEqualToString:@"standered"])
    {
        _locationModel.isOnPhoneUsage=YES;
        _locationModel.isSignificantLocation=NO;
        
    }
    else
    {
        _locationModel.isOnPhoneUsage=NO;
        _locationModel.isSignificantLocation=NO;
    }
    
    return _locationModel;
}



/*
 *@discussion Checks all feature flags
 */
-(LocationNameAndTime *)checkFeatureEnableFlags
{
    BOOL phoneUsageFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"phoneUsageEnable"];
    if (phoneUsageFeature==YES)
    {
        _locationModel.isPhoneUsageFeature=YES;
    }
    else
    {
        _locationModel.isPhoneUsageFeature=NO;
    }
    BOOL significantLocationFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"significantLocationEnable"];
    if (significantLocationFeature==YES)
    {
        _locationModel.isSignificantLocationFeature=YES;
    }
    else
    {
        _locationModel.isSignificantLocationFeature=NO;
    }
    BOOL defaultActivityFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"defaultActivityEnable"];
    if (defaultActivityFeature==YES)
    {
        _locationModel.isDefaultActivityFeature=YES;
    }
    else
    {
        _locationModel.isDefaultActivityFeature=NO;
    }
    BOOL healthkitActivityFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"healthActivityEnable"];
    if (healthkitActivityFeature==YES)
    {
        _locationModel.isHealthKitActivityFeature=YES;
    }
    else
    {
        _locationModel.isHealthKitActivityFeature=NO;
    }
    BOOL fitbitActivityFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"fitbitActivityEnable"];
    if (fitbitActivityFeature==YES)
    {
        _locationModel.isFitBitActivityFeature=YES;
    }
    else
    {
        _locationModel.isFitBitActivityFeature=NO;
    }
    BOOL defaultSleepFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"defaultSleepEnable"];
    if (defaultSleepFeature==YES)
    {
        _locationModel.isDefaultSleepFeature=YES;
    }
    else
    {
        _locationModel.isDefaultSleepFeature=NO;
    }
    
    BOOL healthKitSleepFeature=[[NSUserDefaults standardUserDefaults]boolForKey:@"healthkitSleepEnable"];
    if (healthKitSleepFeature==YES)
    {
        _locationModel.isHealthKitSleepFeature=YES;
    }
    else
    {
      _locationModel.isHealthKitSleepFeature=NO;
    }
    return _locationModel;
}

/// Get sqlite file path form document directory
-(NSString *)getDocumentpath
{
    NSArray *documentArray=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path=[documentArray objectAtIndex:0];
    NSString *dataBaseFilePath=[path stringByAppendingPathComponent:@"instantDB.sqlite"];
    return dataBaseFilePath;
}
///Gets formated date like MMM dd,YYYY from date
-(NSString *)date:(NSDate *)date
{
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    //[dateformate setDateFormat:@"MMM dd,YYYY"];
     [dateformate setDateFormat:@"yyyy-MM-dd"];
    NSString *todayDate=[dateformate stringFromDate:date];
    return todayDate;
}

///Gets day using date
-(NSString *)day:(NSDate *)date;
{
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateformate setDateFormat:@"EEEE"];
    NSString *day=[dateformate stringFromDate:date];
    return day;
}

///Checks if the sqlite database is open or not
-(BOOL)opneDataBase
{
    NSString *dataBasePath=[self getDocumentpath];
    sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
    if (sqlite3_open_v2([dataBasePath UTF8String], &instantDB,SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FILEPROTECTION_NONE | SQLITE_OPEN_FULLMUTEX, NULL)==SQLITE_OK)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


///Creates Data base file in document directory
-(BOOL)createDataBase
{
    NSFileManager *filemanager=[NSFileManager defaultManager];
    NSString *dataBasePath=[self getDocumentpath];
    BOOL exist=[filemanager fileExistsAtPath:dataBasePath];
    
    if (exist == YES)
    {
        [self opneDataBase];
    }
    else
    {
        BOOL isOpenDataBase = [self opneDataBase];
        if (isOpenDataBase==YES)
        {
            //creates place table in database if create return YES otherwise NO
           [self createPlaceTableInDatabase];
            //create steps table
            [self createStepsTable];
            //create fitness table in database if create return YES otherwise NO
            [self creteFitnessTableInDatabase];
           [self creteSleepTableInDatabase];
           [self createDeviceUsageTableInDatabase];
            
        }
    }
    
    return exist;
}

/// Creates places table in database file, if successful return YES otherwise NO
-(BOOL)createPlaceTableInDatabase
{
    BOOL isCreatePlaceTable;
    char *error;
    const char *sql="CREATE TABLE IF NOT EXISTS Places(id INTEGER PRIMARY KEY AUTOINCREMENT,lat TEXT,long TEXT,time INTEGER,date TEXT,place TEXT ,starttime DATETIME,endtime DATETIME)";
    if (sqlite3_exec(instantDB, sql, NULL, NULL, &error)!=SQLITE_OK)
    {
        isCreatePlaceTable=NO;
    }
    else
    {
        isCreatePlaceTable=YES;
    }
    
    return isCreatePlaceTable;
}

///Creates fitness table in database file if successful return YES otherwise NO
-(BOOL)creteFitnessTableInDatabase
{
    BOOL isCreateFitnessTable;
    char *error;
    const char *sql="CREATE TABLE IF NOT EXISTS Fitness(id INTEGER PRIMARY KEY AUTOINCREMENT,activity TEXT,time INTEGER,steps INTEGER,starttime DateTime,endtime DateTime)";
    if (sqlite3_exec(instantDB, sql, NULL, NULL, &error)!=SQLITE_OK)
    {
        isCreateFitnessTable=NO;
    }
    else
    {
        isCreateFitnessTable=YES;
    }
    
    return isCreateFitnessTable;
}


///Creates sleep table in database file if successful return YES otherwise NO
-(BOOL)creteSleepTableInDatabase
{
    BOOL isCreateFitnessTable;
    char *error;
    const char *sql="CREATE TABLE IF NOT EXISTS Sleep(id INTEGER PRIMARY KEY AUTOINCREMENT,date TEXT,totalsleeptime INTEGER,sleeptime DateTime,wokeuptime DateTime,inbetweenduration INTEGER,countforinbetween INTEGER,zerosleep INTEGER)";
    if (sqlite3_exec(instantDB, sql, NULL, NULL, &error)!=SQLITE_OK)
    {
        isCreateFitnessTable=NO;
    }
    else
    {
        isCreateFitnessTable=YES;
    }
    
    return isCreateFitnessTable;
}

-(NSString *)cutNumberInto4DecimalPoint:(double)number
{
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setRoundingMode:NSNumberFormatterRoundFloor];
    [formatter setMaximumFractionDigits:4];
    NSString *numberString = [formatter stringFromNumber:@(number)];
    NSString *percent=@"%";
    NSString *finalNumberString=[NSString stringWithFormat:@"%@%@",numberString,percent];
    return finalNumberString;
    
}

#pragma mark -Location Database Methods
/// Select Place name from data base  using latitude and Longitude, to check if geocoding is needed or not
-(LocationNameAndTime *)selectPlaceName:(double)latitude logitude:(double)longitude
{
    NSString *latitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:latitude]];
    NSString *longitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:longitude]];
    
    NSMutableArray *placeNameArray=[[NSMutableArray alloc]init];
    NSString *querySQL = [NSString stringWithFormat:@"select place from Places where lat LIKE '%@' and long LIKE '%@' ",latitudes,longitudes];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSString *placeName=[NSString stringWithUTF8String:( const char *)sqlite3_column_text(statement, 0)];
            [placeNameArray addObject:placeName];
        }
        sqlite3_finalize(statement);
        
    }
    
    [_locationModel setPlacename:[placeNameArray mutableCopy]];
    
    return _locationModel;
    
}

/// Select placeid and placetime from database using current date, placename, latitude and longitude. It checks if the place already exists in the database.
-(LocationNameAndTime *)selectPlaceIDAndTime:(NSString *)currentDate placeName:(NSString *)name latitude:(double)latitude longitude:(double)longitude
{
    NSString *latitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:latitude]];
    NSString *longitudes=[NSString stringWithFormat:@"%@",[self cutNumberInto4DecimalPoint:longitude]];
    NSMutableArray *idArray=[[NSMutableArray alloc]init];
    NSMutableArray *timeArray=[[NSMutableArray alloc]init];
    
    NSString *querySQL = [NSString stringWithFormat:@"select id,time from Places where date='%@' and place='%@' and lat LIKE '%@' and long LIKE '%@' ",currentDate,name,latitudes,longitudes];
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSInteger placeid=sqlite3_column_int(statement, 0);
            
            [idArray addObject:@(placeid)];
            
            NSInteger placeTime=sqlite3_column_int(statement, 1);
            [timeArray addObject:@(placeTime)];
        }
        sqlite3_finalize(statement);
    }
    
    [_locationModel setPlaceIds:[idArray mutableCopy]];
    [_locationModel setPlaceTimes:[timeArray mutableCopy]];
    return _locationModel;
}

/// Select all dates from place table of database
-(LocationNameAndTime *)selectAllDatesFromPlaceTable
{
    NSMutableArray *placeDateArray=[[NSMutableArray alloc]init];
    NSString *querySQL1 = [NSString stringWithFormat:@"SELECT  distinct date FROM places order by date desc"];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL1 UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSString *placeDates=[NSString stringWithUTF8String:( const char *)sqlite3_column_text(statement, 0)];
            [placeDateArray addObject:placeDates];
        }
        sqlite3_finalize(statement);
    }
    
    [_locationModel setPlacesAllDates:[placeDateArray mutableCopy]];
    return _locationModel;
}

/// Select last location record from place table and handler returns location dictionary if last lat , long is same then update last  location time otherwise insert new record in place table.

-(void)selectLastLocationFromDataBase:(void(^)(NSMutableDictionary *lastLocationRecord))handler
{
    NSMutableDictionary *locationRecordDict=[[NSMutableDictionary alloc]init];
    NSString *selectQuery=[NSString stringWithFormat:@"select *from places order by id desc limit 1"];
    sqlite3_stmt *statement =nil;
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while(sqlite3_step(statement)==SQLITE_ROW)
        {
            NSInteger placeid=sqlite3_column_int(statement, 0);
            [locationRecordDict setValue:@(placeid) forKey:@"placeid"];
            
            NSString *lat=[NSString stringWithUTF8String: (const char *)sqlite3_column_text(statement, 1)];
            [locationRecordDict setValue:lat forKey:@"lat"];
            NSString *longitude=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
            [locationRecordDict setValue:longitude forKey:@"long"];
            
            NSInteger placetime=sqlite3_column_int(statement, 3);
            [locationRecordDict setValue:@(placetime) forKey:@"placetime"];
            
            NSString *address=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
            [locationRecordDict setValue:address forKey:@"address"];
            
            
            NSString *startDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 6)];
            
            
            [locationRecordDict setValue:[self convertStringIntoDate:startDate] forKey:@"startdate"];
            
            NSString *endDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)];
            
            
            [locationRecordDict setValue:[self convertStringIntoDate:endDate] forKey:@"enddate"];
            
            
            
        }
        sqlite3_finalize(statement);
        
        handler(locationRecordDict);
        
        
    }
    
    
    
}

-(NSDate *)convertStringIntoDate:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}

-(NSString *)convertDateIntoISO8601:(NSString  *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *iso8601String = [dateFormatter stringFromDate:date];
    return iso8601String;
    
}

-(NSDate *)convertISO8601TODate:(NSString *)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    NSString *iso8601String = [dateFormatter stringFromDate:date];
    NSDate *iso86ConvertedDate = [dateFormatter dateFromString:iso8601String];
    return iso86ConvertedDate;
    
}

-(NSString *)convertDateTOISO8601:(NSDate *)date
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *iso8601String = [dateFormatter stringFromDate:date];
    return iso8601String;
}

/// Inserts placename,latitude,longitude,place time,start timestamp,end timestamp into place table in database. Adds new places to the database.
-(BOOL)insertInToPlaceDatabase:(NSString *)currentDate latitude:(double)latitude longitude:(double)longitude placeName:(NSString *)placeName startTimeStamp:(NSDate *)startTimeStamp endTimeStamp:(NSDate *)endTimeStamp placeTime:(NSInteger)placeTime;
{
    BOOL isInsert=NO;
    NSString *latitudes=[NSString stringWithFormat:@"%f",latitude];
    NSString *longitudes=[NSString stringWithFormat:@"%f",longitude];
    NSString *insertSQL = [NSString stringWithFormat:
                           @"INSERT INTO Places (lat,long,time,date,place,starttime,endtime)VALUES(\"%@\",\"%@\",%ld,\"%@\",\"%@\",\"%@\",\"%@\")",latitudes ,longitudes ,(long)placeTime,currentDate,placeName,startTimeStamp,endTimeStamp];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [insertSQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
            isInsert=YES;
        }
        sqlite3_finalize(statement);
    }
    return isInsert;
}

/// Updates placename,place time,end timestamp into place table in database using place id. Updates the time of an already existing place.
-(BOOL)updateIntoPlaceDatabase:(NSInteger)placeID currentDate:(NSString *)currentDate  placeName:(NSString *)placeName endTimeStamp:(NSDate *)endTimeStamp placeTime:(NSInteger)placeTime;
{
    BOOL isUpdate=NO;
    NSString *updateSQL = [NSString stringWithFormat:@"UPDATE Places SET  time = %ld ,place ='%@',endtime='%@' WHERE id = %ld ",(long)placeTime,placeName,endTimeStamp ,(long)placeID];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [updateSQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
         
            isUpdate=YES;
            
        }
        sqlite3_finalize(statement);
    }
    
    return isUpdate;
}

///After parsing all activity times  inserts activity name, activity time, steps, start time and end time into fitness table.
-(void)insertFitnessDataActivity:(NSString *)activity activityTime:(NSInteger )activityTime steps:(NSInteger)steps startTime:(NSDate *)startTime endTime:(NSDate * )endTime  withCallBackHandler:(void(^)(BOOL isInsertData))isInsertBlock;
{
    
    NSString *insertSQL;
    //Fitness insert query
    
    insertSQL = [NSString stringWithFormat:
                 @"INSERT INTO fitness (activity,time,steps,starttime,endtime)VALUES(\"%@\",%ld,%ld,\"%@\",\"%@\")",activity,(long)activityTime,(long)steps,startTime,endTime];
    
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [insertSQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
            isInsertBlock(YES);
        }
        sqlite3_finalize(statement);
    }
    
}


/// Select last activty from fitness table for parsing activity record from core motion using last actvity start time.

-(NSMutableDictionary *)selectLastActivityFromFitness
{
    NSMutableDictionary *fitnessActivityDict=[[NSMutableDictionary alloc]init];
    
    NSString *selectQuery=[NSString stringWithFormat:@"select *from Fitness order by endtime desc limit 1"];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_ROW)
        {
            
            NSInteger activityId=sqlite3_column_int(statement, 0);
            [fitnessActivityDict setValue:@(activityId) forKey:@"id"];
            
            NSString *activity=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
            [fitnessActivityDict setValue:activity forKey:@"activityname"];
            
            NSInteger activityTime=sqlite3_column_int(statement, 2);
            [fitnessActivityDict setValue:@(activityTime) forKey:@"activitytime"];
            
            NSInteger stepsCount=sqlite3_column_int(statement, 3);
            [fitnessActivityDict setValue:@(stepsCount) forKey:@"steps"];
            
            NSString *startDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
            [fitnessActivityDict setValue:[self convertStringIntoDate:startDate] forKey:@"starttime"];
            
            NSString *endDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
            [fitnessActivityDict setValue:[self convertStringIntoDate:endDate] forKey:@"endtime"];
        }
        sqlite3_finalize(statement);
        
    }
    
    return fitnessActivityDict;
    
}

/// Selects all dates of fitness activity from fitness table to check if a new date entry needs to be created
-(LocationNameAndTime *)selectAllDatesOfFitness
{
    NSMutableArray *allDatesArray=[[NSMutableArray alloc]init];
    NSString *querySQL = [NSString stringWithFormat:@"select date from  fitness"];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            
            NSString *date=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
            [allDatesArray addObject:date];
        }
        sqlite3_finalize(statement);
        
    }
    
    [_locationModel setFitnessActivityAllDates:[allDatesArray mutableCopy]];
    return _locationModel;
}
#pragma mark -Sleep
///Get sleep start time from passing date and time and returns date to parse sleep data from start time
-(NSDate *)sleepStartTime:(NSDate *)startTime
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    //To set Starting time...
    NSDateComponents *components = [gregorian components: NSUIntegerMax fromDate: startTime];
    [components setDay:components.day-1];
    [components setHour: 19];
    [components setMinute: 00];
    [components setSecond: 00];
    NSDate *startingTime = [gregorian dateFromComponents: components];
    return startingTime;
}

///Get sleep end time from passing date and time and returns date to parse sleep data up to end time.
-(NSDate *)sleepEndTime:(NSDate *)endTime
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
    NSDateComponents *components1 = [gregorian components: NSUIntegerMax fromDate: endTime];
    [components1 setDay:components1.day];
    [components1 setHour:11];
    [components1 setMinute:00];
    [components1 setSecond:00];
    NSDate *endingTime = [gregorian dateFromComponents:components1];
    return endingTime;
    
}


///Get after sleep time of last night insert or update into sleep table of database after successful insert or update it returns YES otherwise NO.sleepData is a dictionary to set sleep date, sleeptotaltime, sleeptime, wokeuptime, durationinbetween, countinbetween, zerosleep.data insert or update successfully it returns YES otherwise NO.


-(void)insertOrUpdateSleepData:(NSMutableDictionary *)sleepData withCallBackhandler:(void(^)(BOOL isInsert))sleepInsert
{
    BOOL isSleep=NO;
    
    LocationNameAndTime *sleepDates=[self selectAllDatesOfSleep];
    NSString *insertSQL;
    if ([sleepDates.sleepAllDates containsObject:sleepData[@"date"]])
    {
        
        insertSQL = [NSString stringWithFormat:@"UPDATE sleep SET totalsleeptime = %d,sleeptime = '%@',wokeuptime = '%@',inbetweenduration= %d,countforinbetween = %d,zerosleep = %d WHERE date = '%@'",
                     [sleepData[@"totalSleepTime"] intValue] ,sleepData[@"sleepTime"],sleepData[@"wokeUpTime"] ,[sleepData[@"inBetweenDuration"] intValue],[sleepData[@"countForInBetween"] intValue],[sleepData[@"zeroSleep"] intValue],sleepData[@"date"]];
    }
    else
    {
        insertSQL=[NSString stringWithFormat:@"insert into sleep(date, totalsleeptime, sleeptime, wokeuptime, inbetweenduration, countforinbetween, zerosleep) values (\"%@\", \"%d\", \"%@\", \"%@\", \"%d\" ,\"%d\", \"%d\")",sleepData[@"date"], [sleepData[@"totalSleepTime"] intValue], sleepData[@"sleepTime"], sleepData[@"wokeUpTime"], [sleepData[@"inBetweenDuration"] intValue], [sleepData[@"countForInBetween"] intValue], [sleepData[@"zeroSleep"] intValue]];
    }
    
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [insertSQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
            isSleep=YES;
            sleepInsert(isSleep);
        }
        sqlite3_finalize(statement);
    }
    
}



/// Get all sleep dates from fitness table for identify that date is exists or not in database if current date exists in database then update sleep record of that date otherwise insert record of that date into database.return all sleep dates into LocationNameAndTime.

-(LocationNameAndTime *)selectAllDatesOfSleep
{
    NSMutableArray *dateArray=[[NSMutableArray alloc]init];
    NSString *selectQuery=[NSString stringWithFormat:@"select date from sleep"];
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSString *sleepdate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
            [dateArray addObject:sleepdate];
        }
        sqlite3_finalize(statement);
    }
    
    if (dateArray.count>0)
    {
        [_locationModel setSleepAllDates:[dateArray mutableCopy]];
    }
    
    return _locationModel;
}


/// Gets all sleep data from sleep table and show sleep total time, sleepAt and wokeUpAt on UI.param fromDate .param toDate .return all sleep data into dictionary.

-(NSMutableDictionary *)selectAllSleepDataFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSMutableArray *sleepDictArray=[[NSMutableArray alloc]init];
    NSMutableArray *sleepDateArray=[[NSMutableArray alloc]init];
    NSMutableArray *totalSleepTimeArray=[[NSMutableArray alloc]init];
    NSMutableArray *SleepAtArray=[[NSMutableArray alloc]init];
    NSMutableArray *WokeUpAtArray=[[NSMutableArray alloc]init];
    NSMutableArray *inBetweenDurationArray=[[NSMutableArray alloc]init];
    NSMutableArray *countInBetweenArray=[[NSMutableArray alloc]init];
    NSMutableArray *zeroSleepArray=[[NSMutableArray alloc]init];
    NSString *selectQuery=[NSString stringWithFormat:@"select *from Sleep where (sleeptime between '%@' and '%@')  or (wokeuptime >='%@' and sleeptime <= '%@')  order by  wokeuptime asc",fromDate,toDate,fromDate,toDate];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSMutableDictionary *sleepDict=[[NSMutableDictionary alloc]init];
            NSString *sleepDate=[NSString stringWithUTF8String:( const char *)sqlite3_column_text(statement, 1)];
            [sleepDateArray addObject:sleepDate];
            
            int sleepTotalTime=sqlite3_column_int(statement, 2);
            [totalSleepTimeArray addObject:@(sleepTotalTime)];
            
            NSString *sleepAt=[NSString stringWithUTF8String:( const char *)sqlite3_column_text(statement, 3)];
            
            [SleepAtArray addObject:[self convertDateIntoISO8601:sleepAt]];
            [sleepDict setValue:[self convertDateIntoISO8601:sleepAt] forKey:@"startedAt"];
            
            NSString *wokeUpAt=[NSString stringWithUTF8String:( const char *)sqlite3_column_text(statement, 4)];
            [WokeUpAtArray addObject:[self convertDateIntoISO8601:wokeUpAt]];
            [sleepDict setValue:[self convertDateIntoISO8601:wokeUpAt] forKey:@"endedAt"];
            
            int inBetweenDuration=sqlite3_column_int(statement, 5);
            [inBetweenDurationArray addObject:@(inBetweenDuration)];
            
            int countInBetween=sqlite3_column_int(statement, 6);
            [countInBetweenArray addObject:@(countInBetween)];
            
            int zeroSleep=sqlite3_column_int(statement, 7);
            [zeroSleepArray addObject:@(zeroSleep)];
            
            [sleepDictArray addObject:sleepDict];
        }
        sqlite3_finalize(statement);
        
    }
    _locationModel=[self checkPermissionFlags];
    NSMutableDictionary *finalDict=[[NSMutableDictionary alloc]init];
    [finalDict setValue:[NSNumber numberWithBool:_locationModel.isSleep] forKey:@"trackingIsEnabled"];
    if (sleepDictArray.count>0)
    {
        [finalDict setValue:sleepDictArray forKey:@"events"];
    }
    
    [_locationModel setSleepDate:sleepDateArray];
    [_locationModel setTotalSleepTime:totalSleepTimeArray];
    [_locationModel setSleepAt:SleepAtArray];
    [_locationModel setWokeUpAt:WokeUpAtArray];
    [_locationModel setInBetweenDuration:inBetweenDurationArray];
    [_locationModel setCountInBetween:countInBetweenArray];
    [_locationModel setZeroSleep:zeroSleepArray];
    return finalDict;
}



///Get fitBit permission for parsing steps count and sleep time.


-(void)fitBitPermissions:(void(^)(BOOL fitBitPermission))PermissionHandler
{

    #if __IPHONE_OS_VERSION_MAX_ALLOWED < 10000
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.fitbit.com/oauth2/authorize?response_type=token&client_id=228LXP&redirect_uri=http%3A%2F%2Femberify.com%2Ffitbit1.html&scope=activity%20profile%20sleep&expires_in=604800"]];
        
#else
       
        
         [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"http://www.fitbit.com/oauth2/authorize?response_type=token&client_id=228LXP&redirect_uri=http%3A%2F%2Femberify.com%2Ffitbit1.html&scope=activity%20profile%20sleep&expires_in=604800"] options:@{} completionHandler:nil];
#endif
    
    PermissionHandler(YES);
}


#pragma mark -Device Usage
/// Create device usage table with columns id, minute, unlock, date, day into instantDB.sqlite.if create device usage table into database handler returns YES otherwise NO.

-(BOOL)createDeviceUsageTableInDatabase;
{
    BOOL iscreate=NO;
    char *error;
    const char *sql="CREATE TABLE IF NOT EXISTS DeviceUsage(id INTEGER PRIMARY KEY AUTOINCREMENT,time INTEGER,starttime DateTime,endtime DateTime,isunlock INTEGER)";
    if (sqlite3_exec(instantDB, sql, NULL, NULL, &error)!=SQLITE_OK)
    {
        iscreate=NO;
    }
    else
    {
        iscreate=YES;
    }
    
    return YES;
}

/// Get all device usage dates in LocationNameAndTime handler from DeviceUsage table for identify that date is exists or not in database if current date exists in database then update device usage record of that date otherwise insert record of that date into database.

-(void)selectDatesFromDeviceUsage:(void(^)(LocationNameAndTime *deviceusageDate))handler
{
    NSMutableArray *dateArray=[[NSMutableArray alloc]init];
    NSString *selectQeuery=[NSString stringWithFormat:@"select date from DeviceUsage"];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [selectQeuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSString *dateStr=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
            [dateArray addObject:dateStr];
        }
        sqlite3_finalize(statement);
    }
    [_locationModel setDeviceUsageAllDates:dateArray];
    handler(_locationModel);
    
    
}


///Get today's device usage time and unlock count using passed date  into handler for update today's device time and unlock counts into device usage table.todayDate is todays date

-(void)selectTodayDeviceUsageMinutesAndUnlocksForDate:(NSString *)todayDate withcallbackHandler:(void(^)(int minute,int unlock))handler
{
    int minute=0,unlock=0;
    NSString *selectQuery=[NSString stringWithFormat:@"Select minute,unlock from DeviceUsage where date='%@'",todayDate];
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_ROW)
        {
            minute =sqlite3_column_int(statement, 0);
            unlock =sqlite3_column_int(statement, 1);
            
        }
        sqlite3_finalize(statement);
        
    }
    
    handler(minute,unlock);
    
}



/// Insert devices usage minutes, unlock count, date and day into devices usage table.if insert record successfully into device usage table handler returns Yes otherwise No.minute passed device usage time in minutes.startTime unlock start time.endTime unlock end time.isUnlock is identifier to insert or update start time and endtime.queryIdentifier passed insert or update for insert or update record into device usage.
-(void)insertIntoDeviceUsageTime:(int)minute startTime:(NSDate *)startTime endTime:(NSDate *)endTime isUnlock:(int)isUnlock lastRecordId:(int)lastId queryIdentifier:(NSString *)queryIdentifier withCallbackHandler:(void(^)(BOOL isInsert))handler
{
    NSString *query;
    
    if ([queryIdentifier isEqualToString:@"insert"])
    {
        query=[NSString stringWithFormat:
               @"INSERT INTO DeviceUsage (time,starttime,endtime,isunlock)VALUES(%d,\"%@\",\"%@\",%d)",minute,startTime,endTime,isUnlock];
    }
    else
    {
        query=[NSString stringWithFormat:@"UPDATE DeviceUsage SET time = %d,endtime='%@',isunlock = %d WHERE id = %d",
               minute ,endTime,isUnlock,lastId];
        
    }
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [query UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
            handler(YES);
        }
        sqlite3_finalize(statement);
    }
    
    
}


/// Get all records like device time, device unlock count, date and day from device usage table for updating UI.
-(NSMutableDictionary *)selectAllDataFromDeviceTimeFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate ;
{
    NSMutableArray *deviceUsageIdArray=[[NSMutableArray alloc]init];
    NSMutableArray *startTimeArray=[[NSMutableArray alloc]init];
    NSMutableArray *endTimeArray=[[NSMutableArray alloc]init];
    NSMutableArray *startAndEndTimeArray=[[NSMutableArray alloc]init];
    
    NSString *selectQuery=[NSString stringWithFormat:@"select *from DeviceUsage where (starttime between  '%@' and  '%@') or  (endtime >='%@' and starttime <= '%@')  ",fromDate,toDate,fromDate,toDate];
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSMutableDictionary *dict=[[NSMutableDictionary alloc]init];
            int deviceUsageId=sqlite3_column_int(statement, 0);
            [deviceUsageIdArray addObject:@(deviceUsageId)];
            
            NSString *startTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
            [startTimeArray addObject:[self convertDateIntoISO8601:startTime]];
            [dict setValue:[self convertDateIntoISO8601:startTime] forKey:@"startedAt"];
            
            NSString *endTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
            [endTimeArray addObject:[self convertDateIntoISO8601:endTime]];
            [dict setValue:[self convertDateIntoISO8601:endTime] forKey:@"endedAt"];
            [startAndEndTimeArray addObject:dict];
        }
        sqlite3_finalize(statement);
    }
    _locationModel=[self checkPermissionFlags];
    NSMutableDictionary *finalDict=[[NSMutableDictionary alloc]init];
    [finalDict setValue:[NSNumber numberWithBool:_locationModel.isOnPhoneUsage] forKey:@"trackingIsEnabled"];
    if (startAndEndTimeArray.count>0)
    {
        [finalDict setValue:startAndEndTimeArray forKey:@"events"];
    }
    [_locationModel setDeviceUsageId:[deviceUsageIdArray mutableCopy]];
    [_locationModel setDeviceUsageEndTime:[endTimeArray mutableCopy]];
    [_locationModel setDeviceUsageStartTime:[startTimeArray mutableCopy]];
    
    return finalDict;
}

/// Select last record of device usage for update or insert new record start time and end time into device usage table of database after selecting last record handler returns last record dictionary.
-(void)selectDeviceUsageLastRecord:(void(^)(NSMutableDictionary *deviceUsageLastRecord))handler
{
    NSMutableDictionary *deviceUsageRecordDict=[[NSMutableDictionary alloc]init];
    NSString *selectQuery=[NSString stringWithFormat:@"select *from DeviceUsage order by id desc limit 1"];
    sqlite3_stmt *statement =nil;
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while(sqlite3_step(statement)==SQLITE_ROW)
        {
            NSInteger devivceUsageId=sqlite3_column_int(statement, 0);
            [deviceUsageRecordDict setValue:@(devivceUsageId) forKey:@"id"];
            
            NSInteger deviceUsageTime=sqlite3_column_int(statement, 1);
            [deviceUsageRecordDict setValue:@(deviceUsageTime) forKey:@"time"];
            
            NSString *startDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
            
            [deviceUsageRecordDict setValue:[self convertStringIntoDate:startDate] forKey:@"startdate"];
            
            NSString *endDate=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 3)];
            
            [deviceUsageRecordDict setValue:[self convertStringIntoDate:endDate] forKey:@"enddate"];
            
            NSInteger isUnlock=sqlite3_column_int(statement, 4);
            [deviceUsageRecordDict setValue:@(isUnlock) forKey:@"isunlock"];
            
            
        }
        sqlite3_finalize(statement);
        
        handler(deviceUsageRecordDict);
        
        
    }
    
}


#pragma mark -Delete Records form database;
/// delete database table records from selected date to yesterday.

-(void)deleteTrackedData:(NSDate *)fromDate toDate:(NSDate *)toDate withCallBackHandler:(void(^)(BOOL isDelete))handler
{
    NSArray *tableNameArray=[NSArray arrayWithObjects:@"DeviceUsage",@"Places",@"Fitness",@"Steps" ,@"Sleep", nil];
    //NSString *StartDate=[NSString stringWithFormat:@"%@",[self date:date]];
    
    for (int i=0; i<tableNameArray.count; i++)
    {
        NSString *tableName=[tableNameArray objectAtIndex:i];
        
        
        NSString *phoneDeleteQuelry;
        if ([tableName isEqualToString:@"Steps"])
        {
            NSDate *firstdate=[self midNightOfLastNight:fromDate];
            BOOL isToday=[[NSCalendar currentCalendar]isDateInToday:toDate];
            NSDate *lastDate;
            if (isToday==YES)
            {
                lastDate= [toDate dateByAddingTimeInterval:-1*24*60*60];
            }
            else
            {
                lastDate=toDate;
            }
            
            phoneDeleteQuelry=[NSString stringWithFormat:@"delete from %@ where (starttime >='%@' AND endtime <='%@') or (endtime >'%@' and starttime <= '%@')",tableName,firstdate,lastDate,firstdate,lastDate];
        }
        else if ([tableName isEqualToString:@"Sleep"])
        {
            phoneDeleteQuelry=[NSString stringWithFormat:@"delete from %@ where (sleeptime between '%@' AND '%@') or  (wokeuptime >='%@' and sleeptime <= '%@')",tableName,fromDate,toDate,fromDate,toDate];
        }
        else
        {
            phoneDeleteQuelry=[NSString stringWithFormat:@"delete from %@ where (starttime between '%@' AND '%@') or  (endtime >='%@' and starttime <= '%@')",tableName,fromDate,toDate,fromDate,toDate];
        }
        
        
        sqlite3_stmt *phoneStatement=nil;
        if (sqlite3_prepare_v2(instantDB, [phoneDeleteQuelry UTF8String], -1, &phoneStatement, NULL)==SQLITE_OK)
        {
            if (sqlite3_step(phoneStatement)==SQLITE_DONE)
            {
                
                [self insertCurrentRecordAfterDeleteRecordsFromDatabase:tableName];
                if ([tableName isEqualToString:@"Sleep"])
                {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"sleepdate"];
                    BOOL  isToday=[[NSCalendar currentCalendar]isDate:toDate inSameDayAsDate:[NSDate date]];
                    if (isToday==YES)
                    {
                        
                        [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdelete"];
                    }
                }
                
            }
            sqlite3_finalize(phoneStatement);
        }
        
        
    }
    
    handler(YES);
    
    
}

/// Clear database and NSUserDefault after logout.
-(void)clearDatabaseAndUserDefaultAfterLogout:(void(^)(BOOL isClear))handler
{
    
    NSArray *tableNameArray=[NSArray arrayWithObjects:@"DeviceUsage",@"Places",@"Fitness",@"Steps" ,@"Sleep", nil];
    
    for (int i=0; i<tableNameArray.count; i++)
    {
        NSString *tableName=[tableNameArray objectAtIndex:i];
        
        NSString *phoneDeleteQuelry=[NSString stringWithFormat:@"delete from %@",tableName];
        
        sqlite3_stmt *phoneStatement=nil;
        if (sqlite3_prepare_v2(instantDB, [phoneDeleteQuelry UTF8String], -1, &phoneStatement, NULL)==SQLITE_OK)
        {
            if (sqlite3_step(phoneStatement)==SQLITE_DONE)
            {
                
            }
            sqlite3_finalize(phoneStatement);
        }
        
    }
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"customeactivtiydate"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"activitydate"];
    //[[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"lastLocation"];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"lastLocation"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdate"];
    [[NSUserDefaults standardUserDefaults]setValue:[NSDate date] forKey:@"sleepdelete"];
    
    handler(YES);
    
}


///After delete records from database insert current time record into database for updateing record after deleted record time.
-(void)insertCurrentRecordAfterDeleteRecordsFromDatabase:(NSString *)tableName
{
    _locationModel=[self checkPermissionFlags];
    if ([tableName isEqualToString:@"DeviceUsage"])
    {
        if (_locationModel.isOnPhoneUsage==YES)
        {
      
        [self insertIntoDeviceUsageTime:0 startTime:[NSDate date] endTime:[[NSDate date]dateByAddingTimeInterval:01] isUnlock:1 lastRecordId:0 queryIdentifier:@"insert" withCallbackHandler:^(BOOL isInsert) {
            
        }];
        }
    }
    else if ([tableName isEqualToString:@"Places"])
    {
        
        if (_locationModel.isSignificantLocation==YES)
        {
            NSData *lastlocationData=[[NSUserDefaults standardUserDefaults]objectForKey:@"lastLocation"];
            
            NSArray *lastlocations=[NSKeyedUnarchiver unarchiveObjectWithData:lastlocationData];
            
            NSMutableArray *updateLocation=[[LocationManager sharedLocationManager] updateLocatinTimeStamp:lastlocations];
            [[LocationManager sharedLocationManager]saveCurrentLocationInNSUserDefault:updateLocation];
            
        }
        
        if (_locationModel.isOnPhoneUsage==YES || _locationModel.isSignificantLocation==YES)
        {
             [self insertInToPlaceDatabase:[self date:[NSDate date]] latitude:[LocationManager sharedLocationManager].locationManager.location.coordinate.latitude longitude:[LocationManager sharedLocationManager].locationManager.location.coordinate.longitude placeName:@"unknown" startTimeStamp:[NSDate date] endTimeStamp:[[NSDate date]dateByAddingTimeInterval:01] placeTime:0];
        }
       
        
        
    }
    else if ([tableName isEqualToString:@"Fitness"])
    {
        if (_locationModel.isDefaultActivity==YES)
        {
            [self insertFitnessDataActivity:@"Walking" activityTime:1 steps:0 startTime:[NSDate date] endTime:[[NSDate date]dateByAddingTimeInterval:01] withCallBackHandler:^(BOOL isInsertData) {
                
            }];
        }
       
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


#pragma mark -Steps Method

/// create steps table in instantdata base.if steps table creates successfully it returns Yes otherwise No.

-(BOOL)createStepsTable
{
    
    BOOL isCreateStepsTable=NO;
    char *error;
    const char *sql="CREATE TABLE IF NOT EXISTS Steps(id INTEGER PRIMARY KEY AUTOINCREMENT,steps INTEGER,starttime DateTime,endtime DateTime,date TEXT)";
    if (sqlite3_exec(instantDB, sql, NULL, NULL, &error)!=SQLITE_OK)
    {
        isCreateStepsTable=NO;
    }
    else
    {
        isCreateStepsTable=YES;
    }
    
    return isCreateStepsTable;
    
}

/// select all dates from steps table for checking current date is exists or not in steps table.if current date is steps table then update steps in steps table otherwise insert steps in table

-(LocationNameAndTime *)selectAllDateOfSteps
{
    NSMutableArray *allDatesArray=[[NSMutableArray alloc]init];
    NSString *querySQL = [NSString stringWithFormat:@"select date from  Steps"];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            
            NSString *date=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
            [allDatesArray addObject:date];
        }
        sqlite3_finalize(statement);
        
    }
    [_locationModel setStepsAllDates:[allDatesArray mutableCopy]];
    return _locationModel;
}

///Insert or update steps count, start time, end time into steps table.if record insert or update successfully into steps table handler returns Yes otherwise No.steps total steps count.startDate get steps start time.endDate gets steps end date.date gets date string.queryStatus gets query is insert or updates.

-(void)insertOrUpdateSteps:(NSInteger)steps startDate:(NSDate *)startDate endDate:(NSDate *)endDate date:(NSString *)date queryStatus:(NSString *)queryStatus withCallBackHandler:(void(^)(BOOL isInsert))handler;
{
    
    NSString *insertSQL;
    
    if ([queryStatus isEqualToString:@"insert"])
    {
        
        //steps insert query
        
        insertSQL = [NSString stringWithFormat:
                     @"INSERT INTO Steps (steps,starttime,endtime,date)VALUES(%ld,\"%@\",\"%@\",\"%@\")",(long)steps,startDate,endDate,date];
    }
    else
    {
        ///steps update query
        insertSQL = [NSString stringWithFormat:@"UPDATE Steps SET steps = %ld,endtime = '%@' WHERE date = '%@'",
                     (long)steps ,endDate,date];
        
    }
    
    
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [insertSQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        if (sqlite3_step(statement)==SQLITE_DONE)
        {
            
            //select walktime,runtime,traveltime,stationarytime,cycletime and steps from fitness table
            // [self selectFitnessActivityData];
            handler(YES);
        }
        sqlite3_finalize(statement);
    }
}


/// Selects all data from steps table for showing on UI.fromDate pass start date to retrive data.param toDate pass end date to retrive data.return all steps data into dictionary.
-(NSMutableArray *)selectStepsDataFromStepsTableFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSMutableArray *stepsDictArray=[[NSMutableArray alloc]init];
    NSMutableArray *stepsArray=[[NSMutableArray alloc]init];
    NSMutableArray *dateArray=[[NSMutableArray alloc]init];
    
    NSString *querySQL=[NSString stringWithFormat:@"select *from steps where starttime >= '%@' and starttime <'%@'order by  endtime asc",[self midNightOfLastNight:fromDate],[self midNightOfLastNight:[toDate dateByAddingTimeInterval:86400*1]]];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSMutableDictionary *stepsDict=[[NSMutableDictionary alloc]init];
            NSInteger stepsCount=sqlite3_column_int(statement, 1);
            [stepsArray addObject:@(stepsCount)];
            
            NSString *date=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
            [dateArray addObject:date];
            
            [stepsDict setValue:date forKey:@"date"];
            [stepsDict setValue:[NSNumber numberWithInteger:stepsCount] forKey:@"stepCount"];
            [stepsDictArray addObject:stepsDict];
            
        }
        sqlite3_finalize(statement);
        
    }
    
    [_locationModel setStepsArray:[stepsArray mutableCopy]];
    [_locationModel setStepsDateArray:[dateArray mutableCopy]];
    return stepsDictArray;
    
}

#pragma mark -fetchTrackedData
/// select all record of database from given fromDate to toDate.after selecting record convert into NSData and handler returns data for show result on UI.fromDate pass start date to retrive data.toDate pass end date to retrive data.

-(void)fetchTrackedData:(NSDate *)fromDate toDate:(NSDate *)toDate withCallBackHandler:(void(^)(NSString *jsonString , NSError *error))handler
{
    _locationModel=[self checkPermissionFlags];
    NSMutableDictionary *finalDict=[[NSMutableDictionary alloc]init];
    NSMutableDictionary *phoneUsageDict=[self selectAllDataFromDeviceTimeFromDate:fromDate toDate:toDate ];
    NSMutableDictionary *locationDict=[self selectAllPlacesDataFromPlaceTableFromDate:fromDate toDate:toDate ];
    NSMutableDictionary *fitnessDict=[self selectFitnessActivityDataFromDate:fromDate toDate:toDate];
    if (_locationModel.isActivity==NO)
    {
        
        [fitnessDict setValue:[NSNumber numberWithBool:_locationModel.isCustomeActivity] forKey:@"trackingIsEnabled"];
    }
    else
    {
        [fitnessDict setValue:[NSNumber numberWithBool:_locationModel.isActivity] forKey:@"trackingIsEnabled"];
    }
    
    NSMutableArray *stepsArray=[self selectStepsDataFromStepsTableFromDate:fromDate toDate:toDate];
    if (stepsArray.count>0)
    {
        [fitnessDict setValue:stepsArray forKey:@"totals"];
    }
    
    NSMutableDictionary *sleepDict=[self selectAllSleepDataFromDate:fromDate toDate:toDate];
    if (fitnessDict) {
        [finalDict setValue:fitnessDict forKey:@"Fitness"];
    }
    if (sleepDict)
    {
        [finalDict setValue:sleepDict forKey:@"Sleep"];
    }
    
    if (locationDict) {
        [finalDict setValue:locationDict forKey:@"Location"];
    }
    
    if (phoneUsageDict) {
        [finalDict setValue:phoneUsageDict forKey:@"PhoneUsage"];
    }
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:finalDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    
    if (! jsonData) {
        handler(nil,error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        handler(jsonString,error);
    }
    
}

/// Select all location names, time, latitude,longitude and date from places table using selectDistinctTwoDecimalLatLongFromPlaceTable method to display this data on the UI
-(NSMutableDictionary *)selectAllPlacesDataFromPlaceTableFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSMutableArray *locationDictArray=[[NSMutableArray alloc]init];
    NSMutableArray *latArray=[[NSMutableArray alloc]init];
    NSMutableArray *longArray=[[NSMutableArray alloc]init];
    NSMutableArray *placeNameArray=[[NSMutableArray alloc]init];
    NSMutableArray *startTimeArray=[[NSMutableArray alloc]init];
    NSMutableArray *endTimeArray=[[NSMutableArray alloc]init];
    
    
    NSString *selectQuery=[NSString stringWithFormat:@"select *from Places where (starttime between '%@' and '%@' ) or (endtime >='%@' and starttime <= '%@') ",fromDate,toDate,fromDate,toDate];
    sqlite3_stmt *statement=nil;
    
    if (sqlite3_prepare_v2(instantDB, [selectQuery UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSMutableDictionary *locationDict=[[NSMutableDictionary alloc]init];
            NSMutableDictionary *coordinatesDict=[[NSMutableDictionary alloc]init];
            NSString *lat=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
            [latArray addObject:lat];
            [coordinatesDict setValue:lat forKey:@"latitude"];
            NSString *longitude=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
            [longArray addObject:longitude];
            [coordinatesDict setValue:longitude forKey:@"longitude"];
            [locationDict setValue:coordinatesDict forKey:@"coordinates"];
            NSString *placeName=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
            [placeNameArray addObject:placeName];
            [locationDict setValue:placeName forKey:@"name"];
            NSString *startTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 6)];
            [startTimeArray addObject:[self convertDateIntoISO8601:startTime]];
            [locationDict setValue:[self convertDateIntoISO8601:startTime] forKey:@"arrivedAt"];
            
            NSString *endTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 7)];
            [endTimeArray addObject:[self convertDateIntoISO8601:endTime]];
            [locationDict setValue:[self convertDateIntoISO8601:endTime] forKey:@"departedAt"];
            [locationDictArray addObject:locationDict];
        }
        sqlite3_finalize(statement);
    }
    
    _locationModel=[self checkPermissionFlags];
    NSMutableDictionary *finalDict=[[NSMutableDictionary alloc]init];
    if (_locationModel.isSignificantLocation==NO)
    {
        [finalDict setValue:[NSNumber numberWithBool:_locationModel.isOnPhoneUsage] forKey:@"trackingIsEnabled"];
    }
    else
    {
        [finalDict setValue:[NSNumber numberWithBool:_locationModel.isSignificantLocation] forKey:@"trackingIsEnabled"];
    }
    if (locationDictArray.count>0)
    {
        [finalDict setValue:locationDictArray forKey:@"events"];
    }
    
    [_locationModel setPlaceLatitude:[latArray mutableCopy]];
    [_locationModel setPlaceLongitude:[longArray mutableCopy]];
    [_locationModel setPlaceSelectName:[placeNameArray mutableCopy]];
    [_locationModel setPlaceEndTime:[endTimeArray mutableCopy]];
    [_locationModel setPlaceStartTime:[startTimeArray mutableCopy]];
    
    
    return finalDict;
    
}

/// Selects walktime,runtime,traveltime,stationarytime,cyclingtime,steps and date from fitness table to returns into LocationNameAndTime to dislay on the UI
-(NSMutableDictionary *)selectFitnessActivityDataFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
    NSMutableArray *fitnessActivityDictArray=[[NSMutableArray alloc]init];
    NSMutableArray *activityArray=[[NSMutableArray alloc]init];
    NSMutableArray *startTimeArray=[[NSMutableArray alloc]init];
    NSMutableArray *endTimeArray=[[NSMutableArray alloc]init];
    NSString *querySQL=[NSString stringWithFormat:@"select *from fitness where (starttime between '%@' and '%@') or (endtime >='%@' and starttime <= '%@' )order by  endtime asc ",fromDate,toDate,fromDate,toDate];
    sqlite3_stmt *statement=nil;
    if (sqlite3_prepare_v2(instantDB, [querySQL UTF8String], -1, &statement, NULL)==SQLITE_OK)
    {
        
        while (sqlite3_step(statement)==SQLITE_ROW)
        {
            NSMutableDictionary *fitnessActivityDict=[[NSMutableDictionary alloc]init];
            NSString *activityName=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
            [activityArray addObject:activityName];
            
            NSString *startTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 4)];
            [startTimeArray addObject:[self convertDateIntoISO8601:startTime]];
            
            
            NSString *endTime=[NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 5)];
            [endTimeArray addObject:[self convertDateIntoISO8601:endTime]];
            
            [fitnessActivityDict setValue:activityName forKey:@"activity"];
            [fitnessActivityDict setValue:[self convertDateIntoISO8601:startTime] forKey:@"startedAt"];
            [fitnessActivityDict setValue:[self convertDateIntoISO8601:endTime] forKey:@"endedAt"];
            [fitnessActivityDictArray addObject:fitnessActivityDict];
            
        }
        sqlite3_finalize(statement);
    }
    
    _locationModel=[self checkPermissionFlags];
    NSMutableDictionary *finalDict=[[NSMutableDictionary alloc]init];
    
    if (fitnessActivityDictArray.count>0)
    {
        [finalDict setValue:fitnessActivityDictArray forKey:@"events"];
    }
    
    
    [_locationModel setFitnessActivityName:[activityArray mutableCopy]];
    [_locationModel setFitnessActivityEndTime:[endTimeArray mutableCopy]];
    [_locationModel setFitnessActivityStartTime:[startTimeArray mutableCopy]];
    
    return finalDict;
    
}

/// App moves from background to foreground updates all database tables.

-(void)applicationMovesBackgroundToForeground
{
    /// App moves from background to foreground updates location time using stored location and after that updates nsuser dafault location.
    LocationNameAndTime *permissions=[self checkFeatureEnableFlags];
    if (permissions.isSignificantLocationFeature==NO)
    {
        if (permissions.isDefaultSleepFeature==YES || permissions.isHealthKitSleepFeature==YES)
        {
            [[SleepManager sharedSleepManager]checkSleepPermission:^(BOOL isSleepPermission)
             {
                 if (isSleepPermission==YES)
                 {
                     [[SleepManager sharedSleepManager] getNNumberOfSleepData];
                 }
             }];
        }
        
        if (permissions.isDefaultActivityFeature == YES)
        {
            [[ActivityManager sharedFitnessActivityManager]checkActivityPermision:^(BOOL activityPermission) {
                if (activityPermission==YES)
                {
                    [[ActivityManager sharedFitnessActivityManager]findNNumberOfDaysOfFitnessData];
                    if (permissions.isHealthKitActivityFeature==NO && permissions.isFitBitActivityFeature == NO)
                    {
                        [[StepsManager sharedStepsManager]findNNumberOfDaysOfFitnessData];
                    }
                }
            }];
        }
        
        if (permissions.isHealthKitActivityFeature == YES || permissions.isFitBitActivityFeature == YES) {
            [[StepsManager sharedStepsManager]checkStpsPermission:^(BOOL stepsPermission) {
                if (stepsPermission==YES)
                {
                    [[StepsManager sharedStepsManager]findNNumberOfDaysOfFitnessData];
                }
            }];
        }
        
    }
    
    
    if (permissions.isSignificantLocationFeature==YES)
    {
        
        if (permissions.isSignificantLocation==YES)
        {
            [[LocationManager sharedLocationManager]backgroundToForgroundLocationUpdate];
        }
        
    }
    
    
}

/// Get fitbit token for fetching data from fitbit.
-(void)FitBitOpenUrl:(NSURL *)url
{
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if([[UIApplication sharedApplication] canOpenURL:url]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *urlString = [NSString stringWithFormat:@"%@", url];
            if ([urlString containsString:@"access_token"])
            {
                NSArray *arr = [urlString componentsSeparatedByString:@"="];
                NSString *accessToken = arr[1];
                NSString *user_id = arr[2];
                NSString *finalAccessToken = [accessToken substringToIndex:[accessToken length]-8];
                NSRange range = NSMakeRange(0, 6);
                NSString *finalUser_id = [user_id substringWithRange:range];
                //Store Fitbit Access Token into NSUserDefaults
                [[NSUserDefaults standardUserDefaults]setObject:finalAccessToken forKey:@"fitBitAccessToken"];
                //Store Fitbit User Id into NSUserDefaults
                [[NSUserDefaults standardUserDefaults]setObject:finalUser_id forKey:@"fitBitUserId"];
                if (permissions.isActivity==YES)
                {
                    [[StepsManager sharedStepsManager]getFitnessDataFromCoreMotionStartDate:[NSDate date] endDate:[NSDate date]];
                }
                
                if (permissions.isSleep==YES)
                {
                    [[SleepManager sharedSleepManager] getSleepOptionAndFindSleepDataFromStartTime:[NSDate date] toEndTime:[NSDate date]];
                }
            }
            
        });
    }
    
    
    
}

/// close database when application will terminate.

-(void)callOnapplicationWillTerminate
{
    LocationNameAndTime *permissions=[[InstantDataBase sharedInstantDataBase]checkPermissionFlags];
    if (permissions.isOnPhoneUsage==YES)
    {
        [[DeviceUsageManager sharedDeviceUsage]applicationTerminate];
    }
    
    sqlite3_close(instantDB);
 
}

@end

