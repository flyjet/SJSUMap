//
//  buildingItem.h
//  SJSUMap
//
//  Created by Qi Cao on 11/9/15.
//  Copyright (c) 2015 cmpe. All rights reserved.
//


@interface buildingItem : NSObject

@property (strong, nonatomic) NSString *name;// name of building
@property (strong, nonatomic) NSString *name_abb;   // building abbreviation name
@property (strong, nonatomic) NSString *address;  // building address
@property (strong, nonatomic) NSString *imageFile; // image of building
@property (strong, nonatomic) NSString *distance;  //Walking distance
@property (strong, nonatomic) NSString *time; //Walking distance
@property (strong, nonatomic) NSString *destinations;  //the value of it be destinations
@property double x;  //center of building point
@property double y;  //center of building point

@end
