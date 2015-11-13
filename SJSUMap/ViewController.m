//
//  ViewController.m
//  SJSUMap
//
//  Created by Qi Cao on 11/8/15.
//  Copyright (c) 2015 cmpe. All rights reserved.
//

#import "ViewController.h"
#import "buildingItem.h"

@interface ViewController ()


@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIImageView *currentDot;

@property (strong, nonatomic) IBOutlet UIButton *highlight;

@property (strong, nonatomic) NSArray *builds;
@property (strong, nonatomic) buildingItem *KL;
@property (strong, nonatomic) buildingItem *EB;
@property (strong, nonatomic) buildingItem *YUH;
@property (strong, nonatomic) buildingItem *SU;
@property (strong, nonatomic) buildingItem *BBC;
@property (strong, nonatomic) buildingItem *SPG;

@property int centeredBuildNo;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableData *responseData;

@property (strong, nonatomic) NSString *origins;  //from current location to originis value;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //image zoom in and out scale
    _scrollView.maximumZoomScale = 2;
    _scrollView.minimumZoomScale = 0.5;
    _scrollView.contentSize = CGSizeMake(_imageView.frame.size.width + 300, _imageView.frame.size.height +300);
    _scrollView.delegate = self;
    
    _imageView.frame = CGRectMake(0, 0, _imageView.image.size.width, _imageView.image.size.height);
    
    
    //enable user interaction
    _imageView.userInteractionEnabled = YES;
    
    //Create and initialize one tap gesture
    UITapGestureRecognizer *tapSingleRecognizer = [[UITapGestureRecognizer alloc]
                            initWithTarget:self action:@selector(handleSingleTap:)];
    tapSingleRecognizer.delegate = self;
    tapSingleRecognizer.numberOfTapsRequired = 1;
    
    //enable gesture recognizer
    [_imageView addGestureRecognizer:tapSingleRecognizer];
    
    
    //Initialize Building data
    _KL = [buildingItem new];
    _EB = [buildingItem new];
    _YUH = [buildingItem new];
    _SU = [buildingItem new];
    _BBC = [buildingItem new];
    _SPG = [buildingItem new];
    self.builds = [NSArray arrayWithObjects:_KL,_EB,_YUH,_SU,_BBC,_SPG, nil];
    [self initBuildingDetails: self.builds];
    
    //init the searchBar delegate
    [self.searchBar setDelegate:self];
    //==================TODO=======
    //searchBar is not lock on the screen, need fix it
    
    
    //assign MyLocationViewController as the delegate object.
    //get current location
 
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager requestAlwaysAuthorization];
    [_locationManager requestWhenInUseAuthorization];
    [_locationManager startUpdatingLocation];

    
    //init currentDot
    [_imageView addSubview:self.currentDot];
    //[self.currentDot setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    //init respneseData for NSURLConnection
    _responseData = [[NSMutableData alloc] init];
    _origins = [[NSString alloc] init];
    
    //init highlight view
    _highlight =[UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    _highlight.alpha = 0.3;
    _highlight.backgroundColor = [UIColor redColor];
    
    //connect the button click method with button target attribue
    [_highlight addTarget:self action:@selector(highlightClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [_imageView addSubview: self.highlight];
    
    _centeredBuildNo = -1;
    
}

- (IBAction)highlightClicked:(id)sender {

    //handle highlight button to disappear and show build details
    
    _highlight.alpha = 0;
    buildingItem *b = [buildingItem new];
    
    b = [_builds objectAtIndex:_centeredBuildNo];
    NSLog(@"Highlight button clicked,distance %@",b.distance);
    NSLog(@"Highlight button clicked,time %@",b.time);
    
    if(b.distance == (id)[NSNull null] || b.distance.length == 0 || b.time == (id)[NSNull null] || b.time.length == 0){
        [self calculateDistanceAndTime:_centeredBuildNo];
        
    }else{
        [self showBuildingDetails:_centeredBuildNo];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Image Zoom in and Out
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}


#pragma mark - CLLocationManagerDelegate
//get current location fail
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error"
                               message:@"Failed to get current location"
                               delegate:nil
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil];
    [errorAlert show];
}

//get current location done
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        
        double curLong = currentLocation.coordinate.longitude;
        double curLat = currentLocation.coordinate.latitude;
        
        //conver longitude and latitude to X,Y
        double tlLong, tlLat, brLong, brLat;
        tlLong = -121.886478;
        tlLat = 37.338800;
        brLong = -121.876243;
        brLat = 37.331361;
        
        double x, y;
        x = 580 * (fabs(curLong - tlLong))/ (brLong - tlLong);
        y = 580 - 580 * (fabs(curLat - brLat))/(tlLat - brLat);
        
        NSLog(@"current location @x = %f y = %f", x, y );
        //set the currentDot postion
        [_currentDot setFrame:CGRectMake(x, y,self.currentDot.frame.size.width, self.currentDot.frame.size.height )];
        
        //From the current location to origins value for using the Google Maps Distance Matrix API
        NSString *lat = [[NSNumber numberWithDouble:curLat] stringValue];
        NSString *longi = [[NSNumber numberWithDouble:curLong] stringValue];
        _origins = [NSString stringWithFormat:@"%@,%@", lat, longi];
    }
    
    //after get current location, then stop location Manager

    [_locationManager stopUpdatingLocation];
}



#pragma mark - Responding to gestures
//In response to one tap gesture
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    
    NSLog(@"One tap detected.");
    CGPoint point = [recognizer locationInView:self.imageView];
    //NSLog(@"x = %f y = %f", point.x, point.y );
    
    [self isClickOnBuilding: point];
}


#pragma mark - Responding to SearchBar
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchText = searchBar.text;
    NSLog(@"User searched for: %@", searchText);
    
    Boolean isBuildName = false;
    buildingItem *build = [buildingItem new];
    
    for(int i = 0; i< 6; i++){
        
        build = [_builds objectAtIndex:i];
        if( [searchText isEqualToString: build.name] || [searchText isEqualToString: build.name_abb]){
            isBuildName= true;
            
            //imageView zoom level back to 100%
            self.scrollView.zoomScale = 1.0;
            
            //center the searched building
            [self moveBuildingCenter : build.name];
            break;
            
        }else{
            isBuildName = false;
        }
    }
    if(!isBuildName){
        UIAlertView *noSearchBuilding = [
                [UIAlertView alloc] initWithTitle:@"Sorry, can not find it."
                                          message:nil
                                         delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles: nil];
        [noSearchBuilding show];
    }
}


//Highlight and center the building when user search for it

-(void)moveBuildingCenter:(NSString *) building{
    
    buildingItem *b = [buildingItem new];
    
    double centerX = _scrollView.center.x;
    double centerY = _scrollView.center.y- 90;
    
    for(int i =0; i<6; i++){
        b = [_builds objectAtIndex:i];
        if ([building isEqualToString: b.name ]) {
            
            NSLog(@"You get search result for building %@", b.name);
            
            //move the imageView to show building in center
            CGPoint offset = CGPointMake(b.x - centerX, b.y -centerY);
            _scrollView.contentOffset = offset;
            
            /*
            [_imageView setFrame: CGRectMake(centerX - b.x, centerY - b.y,
                                             _imageView.frame.size.height, _imageView.frame.size.width)]; 
             NSLog(@"building location  %f", b.x);
             NSLog(@"building location  %f", b.y);*/
            
            
            //set the highlight to the searched building
             _highlight.alpha = 0.3;
            [_highlight setFrame: CGRectMake(b.x -50, b.y -50, 100,100)];
            _highlight.layer.cornerRadius = _highlight.bounds.size.width / 2.0;
            
             _centeredBuildNo = i;
            break;
        }
    }
}


#pragma mark
//tap on building or not
-(void)isClickOnBuilding:(CGPoint )point{
    
    double x = point.x;
    double y = point.y;
    int buildNo  = -1;
    NSLog(@"x = %f y = %f", x, y );
    if(x >= _KL.x -30 && x <= _KL.x +30  && y >= _KL.y -30 && y <= _KL.y +30){
        buildNo =  0;
    }else if (x >= _EB.x -30 && x <= _EB.x +30  && y >= _EB.y -30 && y <= _EB.y +30){
        buildNo =  1;
    }else if(x >= _YUH.x -30 && x <= _YUH.x +30  && y >= _YUH.y -30 && y <= _YUH.y +30){
        buildNo =  2;
    }else if(x >= _SU.x -30 && x <= _SU.x +30  && y >= _SU.y -30 && y <= _SU.y +30){
        buildNo =  3;
    }else if(x >= _BBC.x -30 && x <= _BBC.x +30  && y >= _BBC.y -30 && y <= _BBC.y +30){
        buildNo =  4;
    }else if(x >= _SPG.x -30 && x <= _SPG.x +30  && y >= _SPG.y -30 && y <= _SPG.y +30){
        buildNo =  5;
    }
    
    if(buildNo >= 0){
        [self calculateDistanceAndTime:buildNo];
        
    }else{
         NSLog(@"tap outside of building");
    }
}


#pragma mark - NSURLRequest to calculate distance and time

-(void)calculateDistanceAndTime:(int)buildId{
    
    buildingItem *build = [buildingItem new];
    build = [_builds objectAtIndex:buildId];
    
    NSString *destinations = build.destinations;
    NSString *pre = @"https://maps.googleapis.com/maps/api/distancematrix/json?origins=";
    NSString *mid = @"&destinations=";
    NSString *end = @"&mode=walking";
    
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@", pre, _origins, mid, destinations, end];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSLog(@"new string %@", url);
    
    //send request to Google Maps Distance Matrix API
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


#pragma mark -  NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse");
    [_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    NSLog(@"NSURLRequest connected and did finish loading.");
    
    //Parse data from Json
    [self parseDataFromJson:_responseData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request is failed
    NSLog(@"NSURLRequest connecion failed");
}


-(void)parseDataFromJson:(NSMutableData *)responseData{
    
    NSError* error;
    NSDictionary * json = [NSJSONSerialization
                           JSONObjectWithData:responseData
                           options:kNilOptions
                           error:&error];
    
    NSArray *rows = [json objectForKey:@"rows"];
    NSArray *elements =[(NSDictionary*)[rows objectAtIndex:0] objectForKey:@"elements"] ;
    
    NSDictionary *distance =[(NSDictionary*)[elements objectAtIndex:0] objectForKey:@"distance"];
    NSString *distanceValue = [distance objectForKey:@"text"];
    
    NSDictionary *duration =[(NSDictionary*)[elements objectAtIndex:0] objectForKey:@"duration"];
    NSString *durationValue = [duration objectForKey:@"text"];
    
    NSString *destination = [[json objectForKey:@"destination_addresses"] objectAtIndex:0];
    
    //check the parse data is for which build and update building distnace and time
    int buildNo = -1;
    
    if([destination isEqualToString: @"150 E San Fernando St, San Jose, CA 95112, USA"]){
        _KL.distance = distanceValue;
        _KL.time = durationValue;
        buildNo = 0;
    }else if([destination isEqualToString: @"1 Washington Square, San Jose, CA 95112, USA"]){
        _EB.distance = distanceValue;
        _EB.time = durationValue;
        buildNo = 1;
    }else if([destination isEqualToString: @"159-179 Paseo de San Carlos, San Jose, CA 95112, USA"]){
        _YUH.distance = distanceValue;
        _YUH.time = durationValue;
        buildNo =2;
    }else if([destination isEqualToString: @"290 S 7th St, San Jose, CA 95112, USA"]){
        _SU.distance = distanceValue;
        _SU.time = durationValue;
        buildNo =3;
    }else if([destination isEqualToString: @"178-172 S 9th St, San Jose, CA 95112, USA"]){
        _BBC.distance = distanceValue;
        _BBC.time = durationValue;
        buildNo =4;
    }else if([destination isEqualToString: @"330 S 7th St, San Jose, CA 95112, USA"]){
        _SPG.distance = distanceValue;
        _SPG.time = durationValue;
        buildNo =5;
    }
    
    //show building details information
    
    if(buildNo >= 0 && buildNo <=5){
        [self showBuildingDetails:buildNo];
    }
}

#pragma mark - show detail information of building

-(void)showBuildingDetails:(int)buildId{
    
    buildingItem *build = [buildingItem new];
    build = [_builds objectAtIndex:buildId];

    //show details of building, name, address, photo
    
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    UIImage *image= [UIImage imageNamed:build.imageFile];
    
    imageView.contentMode = UIViewContentModeCenter;
    [imageView setImage:image];
    
    //Message show address, distance, and time
    NSString *m1 = @"From your current location to here, distance is ";
    NSString *m2 = @"By walking, you need ";
    NSString *messageValue = [NSString stringWithFormat:@"%@\n\n%@%@\n%@%@", build.address,m1, build.distance, m2, build.time];
    
    // UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"King Library"
    UIAlertView *addressView = [[UIAlertView alloc] initWithTitle:build.name
                                                        message:messageValue
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
    [addressView setValue:imageView forKey:@"accessoryView"];
    [addressView show];
}



//hard code for six buildings information
-(void)initBuildingDetails:(NSArray *) buildings{
    buildingItem *b1 = [buildingItem new];
    b1 = [buildings objectAtIndex:0];
    b1.name = @"King Library";
    b1.name_abb = @"KL";
    b1.address = @"Dr. Martin Luther King, Jr. Library, 150 East San Fernando Street, San Jose, CA 95112";
    b1.imageFile = @"kl.png";
    b1.x = 56.00;
    b1.y = 259.00;
    b1.destinations = @"150+East+San+Fernando+Street%2C+San+Jose%2C+CA+95112";
    
    buildingItem *b2 = [buildingItem new];
    b2 = [buildings objectAtIndex:1];
    b2.name_abb = @"EB";
    b2.name = @"Engineering Building";
    b2.address = @"San José State University Charles W. Davidson College of Engineering, 1 Washington Square, San Jose, CA 95112";
    b2.imageFile = @"eb.png";
    b2.x = 276.00;
    b2.y = 138.00;
    b2.destinations = @"1+Washington+Square%2C+San+Jose%2C+CA+95112";
    
    buildingItem *b3 = [buildingItem new];
    b3 = [buildings objectAtIndex:2];
    b3.name = @"Yoshihiro Uchida Hall";
    b3.name_abb = @"YUH";
    b3.address = @"Yoshihiro Uchida Hall, San Jose, CA 95112";
    b3.imageFile = @"yuh.png";
    b3.x = 136.00;
    b3.y = 416.00;
    b3.destinations = @"37.333609,-121.883829";;
    
    
    buildingItem *b4 = [buildingItem new];
    b4 = [buildings objectAtIndex:3];
    b4.name = @"Student Union";
    b4.name_abb = @"SU";
    b4.address = @"Student Union Building, San Jose, CA 95112";
    b4.imageFile = @"su.png";
    b4.x = 308.00;
    b4.y = 206.00;
    b4.destinations = @"37.336319,-121.881405";
    
    
    buildingItem *b5 = [buildingItem new];
    b5 = [buildings objectAtIndex:4];
    b5.name = @"Boccardo Business Complex";
    b5.name_abb = @"BBC";
    b5.address = @"Boccardo Business Complex, San Jose, CA 95112";
    b5.imageFile = @"bbc.png";
    b5.x = 467.00;
    b5.y = 178.00;
    b5.destinations = @"37.336541,-121.878774";
    
    buildingItem *b6 = [buildingItem new];
    b6 = [buildings objectAtIndex:5];
    b6.name = @"South Parking Garage";
    b6.name_abb = @"SPG";
    b6.address = @"San Jose State University South Garage, 330 South 7th Street, San Jose, CA 95112";
    b6.imageFile = @"spg.png";
    b6.x = 328.00;
    b6.y = 468.00;
    b6.destinations = @"330+South+7th+Street%2C+San+Jose%2C+CA+95112";
}



@end
