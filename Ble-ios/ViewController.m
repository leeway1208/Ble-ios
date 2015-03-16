//
//  ViewController.m
//  Ble-ios
//
//  Created by liwei wang on 16/3/15.
//  Copyright (c) 2015 liwei wang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong,nonatomic) CBCentralManager *central;
@property (copy,nonatomic) NSString *targetPeripheral;
@property (strong,nonatomic) NSMutableArray *discoveredPeripherals;
@property (strong,nonatomic) NSMutableArray *discoveredPeripheralsRssi;

@property (strong,nonatomic) CBPeripheral *connectedPeripheral;
@property (strong,nonatomic) CBUUID *deviceInfoUUID;

@property (nonatomic,strong) UITableView * beaconTableView;
@property (nonatomic,strong) UILabel * hintLabel;

@property (nonatomic,strong) UILabel * tableTitleLabel;
@property (nonatomic,strong) UILabel * tableCenterLabel;
@property (nonatomic,strong) UILabel * tableRssiLabel;
@end
#pragma mark - view methods
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor colorWithRed:0.925 green:0.925   blue:0.925  alpha:1.0f];
    self.central = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    self.discoveredPeripherals = [NSMutableArray new];
    self.discoveredPeripheralsRssi = [NSMutableArray new];
    
    self.deviceInfoUUID = [CBUUID UUIDWithString:@"0x2000"];
    
    [self loadWidget];
   
}

-(void) loadWidget{
    _beaconTableView=[[UITableView alloc] initWithFrame:self.view.bounds];
    _beaconTableView.dataSource = self;
    _beaconTableView.delegate = self;
    _beaconTableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].applicationFrame.size.width, [UIScreen mainScreen].applicationFrame.size.height- 130);
    //_beaconTableView.scrollEnabled = NO;;
    //_beaconTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_beaconTableView];
    
    
    _hintLabel = [[UILabel alloc]initWithFrame:CGRectMake([UIScreen mainScreen].applicationFrame.size.width/2 - 60,[UIScreen mainScreen].applicationFrame.size.height - 100 , [UIScreen mainScreen].applicationFrame.size.width, 30 )];
    [self.view addSubview:_hintLabel];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.hintLabel.text=@"Not connected";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - UITableViewDataSource methods
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)atableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}



-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoveredPeripherals.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier=@"cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    CBPeripheral *peripheral=(CBPeripheral *)self.discoveredPeripherals[indexPath.row];
    NSNumber *RSSI = (NSNumber *)self.discoveredPeripheralsRssi[indexPath.row];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        //        cell.tag = indexPath.row;
        
        
        
        
        /**
         *  important things (name and uuid)
         */
        //beacon name
        _tableTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, self.view.frame.size.width-30, 20)];
        _tableTitleLabel.text = peripheral.name;
        [cell addSubview:_tableTitleLabel];
        //beacon id
        _tableCenterLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 25, self.view.frame.size.width-30, 60)];
        _tableCenterLabel.numberOfLines = 2;
        _tableCenterLabel.text = peripheral.identifier.UUIDString;
        [cell addSubview:_tableCenterLabel];
        //beacon rssi
        
        _tableRssiLabel = [[UILabel alloc]initWithFrame:CGRectMake( self.view.frame.size.width - 40 , 25, self.view.frame.size.width-30, 20)];
        NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc] init];
        _tableRssiLabel.text =  [numberFormatter stringFromNumber:RSSI];;
        [cell addSubview:_tableRssiLabel];
      
        
    }

    
 
    


    
    if ([peripheral.identifier.UUIDString isEqualToString:self.targetPeripheral]) {
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
    
    return cell;
    
}

#pragma mark - UITableViewDelegate methods;

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *targetPeripheral=(CBPeripheral *)self.discoveredPeripherals[indexPath.row];
    if (![self.targetPeripheral isEqualToString:targetPeripheral.identifier.UUIDString]) {
        if (self.connectedPeripheral) {
            [self.central cancelPeripheralConnection:self.connectedPeripheral];
        }
        self.targetPeripheral=targetPeripheral.identifier.UUIDString;
        [tableView reloadData];
        [self.central connectPeripheral:targetPeripheral options:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    
}

#pragma mark - CBCentralManager Delegate methods
/*
 * Invoked whenever the central manager's state is updated.
 */
-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSString * state = nil;
    
    switch (central.state) {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"work";
            [self startScan];
            break;
        case CBCentralManagerStateUnknown:
            state = @"State Unknown";
            break;
        default:
            break;
            
   
    }
    
     NSLog(@"Central manager state: %@", state);
}

/**
 *  step two
 *
 *  @param central           <#central description#>
 *  @param peripheral        <#peripheral description#>
 *  @param advertisementData <#advertisementData description#>
 *  @param RSSI              <#RSSI description#>
 */
-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered peripheral %@ (%@)",peripheral.name,peripheral.identifier.UUIDString);
    if (![self.discoveredPeripherals containsObject:peripheral] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.discoveredPeripherals addObject:peripheral];
            [self.discoveredPeripheralsRssi addObject:RSSI];
            [self.beaconTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.discoveredPeripherals.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        });
    }
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    self.connectedPeripheral=peripheral;
    NSLog(@"Connected to %@(%@)",peripheral.name,peripheral.identifier.UUIDString);
    peripheral.delegate=self;
    
    [self stopScan];
    //[peripheral discoverServices:@[firstServiceUUID, secondServiceUUID]];
    //[peripheral discoverServices:@[self.deviceInfoUUID]];
    [peripheral discoverServices:nil];
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from peripheral");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hintLabel.text=@"Not connected";
    });
    UIApplication *app=[UIApplication sharedApplication];
    if (app.applicationState == UIApplicationStateBackground) {
        NSLog(@"We are in the background");
        UIUserNotificationSettings *notifySettings=[[UIApplication sharedApplication] currentUserNotificationSettings];
        if ((notifySettings.types & UIUserNotificationTypeAlert)!=0) {
            UILocalNotification *notification=[UILocalNotification new];
            notification.alertBody=@"Disconnected";
            [app presentLocalNotificationNow:notification];
        }
    }
    if ([self.targetPeripheral isEqualToString:peripheral.identifier.UUIDString]) {
        NSLog(@"Retrying");
        [self.central connectPeripheral:peripheral options:nil];
    }
}

#pragma mark - CBPeripheralManager delegate methods
/**
 *  get the services from the beacon
 *
 *  @param peripheral <#peripheral description#>
 *  @param error      <#error description#>
 */
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        //NSLog(@"Discovered service %@",service.description);
        NSLog(@"Discovered service %@",service.UUID);

        if ([service.UUID isEqual:self.deviceInfoUUID]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

/**
 *  when you find the services from beacon, you can do there.
 *
 *  @param peripheral <#peripheral description#>
 *  @param service    <#service description#>
 *  @param error      <#error description#>
 */
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // when there occurs the error
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    
    for (CBCharacteristic *characteristic in service.characteristics ) {
        NSLog(@"Discovered characteristic %@(%@)",characteristic.description,characteristic.UUID.UUIDString);
        if ([characteristic.UUID.UUIDString isEqualToString:@"2005"]) {
            //[peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

/**
 *  when read the data from the didDiscoverCharacteristicsForService. this method will be updated.
 *
 *  @param peripheral     <#peripheral description#>
 *  @param characteristic <#characteristic description#>
 *  @param error          <#error description#>
 */
-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *manf=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hintLabel.text=manf;
    });
    UIApplication *app=[UIApplication sharedApplication];
    if (app.applicationState == UIApplicationStateBackground) {
        NSLog(@"We are in the background");
        UIUserNotificationSettings *notifySettings=[[UIApplication sharedApplication] currentUserNotificationSettings];
        if ((notifySettings.types & UIUserNotificationTypeAlert)!=0) {
            UILocalNotification *notification=[UILocalNotification new];
            notification.alertBody=[NSString stringWithFormat:@"Connected to peripheral from %@",manf];
            [app presentLocalNotificationNow:notification];
        }
    }
    
}



#pragma mark - scan mothods
/**
 *  step one
 */
-(void) startScan {
    NSLog(@"Starting scan");
    
    // scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFE0"]]  (make your own device)
    [self.central scanForPeripheralsWithServices:nil options:nil];
}

-(void) stopScan{
     NSLog(@"Stop scan");
    
    [self.central stopScan];
}

#pragma mark - disconnect mothods
-(void) disConnect:(CBPeripheral *) peripheral{
    [self.central cancelPeripheralConnection:peripheral];
}


@end
