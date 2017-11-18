//
//  LocationNameAndTime.h
//  InstantSDK
//
//  Created by Vijay on 28/08/17.
//  Copyright © 2017 Emberify. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
 * @discussion LocationNameAndTime stores all location and fitness data. In the location part placename, placeIds, placeTimes, placesAllDates and placeRecord. The place record contains placename, placetime, latitude, longitude, timeStamp and place dates
 In fitness part have stored all dates, walktime,runtime,traveltime,stationarytime,cycletime,steps.
 LocationNameAndTime can be accsessed anywhere in application.
 
 */

@interface LocationNameAndTime : NSObject

#pragma mark-Location(L)
@property(nonatomic,copy)NSNumber *numberOfDay;
@property(nonatomic,copy)NSArray *placename;
@property(nonatomic,copy)NSArray *placeIds;
@property(nonatomic,copy)NSArray *placeTimes;
@property(nonatomic,copy)NSArray *placesAllDates;
@property(nonatomic ,copy)NSArray *placeLatitude;
@property(nonatomic ,copy)NSArray *placeLongitude;
@property(nonatomic ,copy)NSArray *placeSelectName;
@property(nonatomic ,copy)NSArray *placeStartTime;
@property(nonatomic ,copy)NSArray *placeEndTime;


#pragma mark -Fitness Activity (F)
@property(nonatomic,copy)NSNumber *totalSteps;
@property(nonatomic,copy)NSArray *fitnessActivityAllDates;
@property(nonatomic,copy)NSArray *activityDateArray;
@property(nonatomic,copy)NSArray *fitnessActivityName;
@property(nonatomic,copy)NSArray *fitnessActivityStartTime;
@property(nonatomic,copy)NSArray *fitnessActivityEndTime;
@property(nonatomic,copy)NSArray *stationaryArray;
@property(nonatomic,copy)NSArray *cyclingArray;
@property(nonatomic,copy)NSArray *fitnessActivity;


#pragma mark -Sleep
@property(nonatomic,copy)NSArray *sleepAllDates;
@property(nonatomic,copy)NSArray *totalSleepTime;
@property(nonatomic,copy)NSArray *sleepAt;
@property(nonatomic,copy)NSArray *wokeUpAt;
@property(nonatomic,copy)NSArray *sleepDate;
@property(nonatomic,copy)NSArray *inBetweenDuration;
@property(nonatomic,copy)NSArray *countInBetween;
@property(nonatomic,copy)NSArray *zeroSleep;


#pragma mark -Device Usage
@property(nonatomic,copy)NSArray *deviceUsageAllDates;
@property(nonatomic,copy)NSArray *deviceUsageId;
@property(nonatomic,copy)NSArray *deviceUsageStartTime;
@property(nonatomic,copy)NSArray *deviceUsageEndTime;


#pragma mark -Steps
@property(nonatomic,copy)NSArray *stepsAllDates;
@property(nonatomic,copy)NSArray *stepsArray;
@property(nonatomic,copy)NSArray *stepsStartTimeArray;
@property(nonatomic,copy)NSArray *stepsEndTimeArray;
@property(nonatomic,copy)NSArray *stepsDateArray;


#pragma mark -permissions flags
@property(nonatomic)BOOL isOnPhoneUsage;
@property(nonatomic)BOOL isSignificantLocation;
@property(nonatomic)BOOL isDefaultActivity;
@property(nonatomic)BOOL isHealthKitActivity;
@property(nonatomic)BOOL isFitBitActivity;
@property(nonatomic)BOOL isActivity;
@property(nonatomic)BOOL isCustomeActivity;
@property(nonatomic)BOOL isDefaultSleep;
@property(nonatomic)BOOL isHealthKitSleep;
@property(nonatomic)BOOL isFitBitSleep;
@property(nonatomic)BOOL isSleep;

#pragma mark -Feature enable flags
@property(nonatomic)BOOL isPhoneUsageFeature;
@property(nonatomic)BOOL isSignificantLocationFeature;
@property(nonatomic)BOOL isDefaultActivityFeature;
@property(nonatomic)BOOL isHealthKitActivityFeature;
@property(nonatomic)BOOL isFitBitActivityFeature;
@property(nonatomic)BOOL isDefaultSleepFeature;
@property(nonatomic)BOOL isHealthKitSleepFeature;


@end

