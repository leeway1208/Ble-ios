//
//  ViewController.h
//  Ble-ios
//
//  Created by liwei wang on 16/3/15.
//  Copyright (c) 2015 liwei wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,CBCentralManagerDelegate,CBPeripheralDelegate>


@end

