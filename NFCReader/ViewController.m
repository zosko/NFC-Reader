//
//  ViewController.m
//  NFCReader
//
//  Created by Bosko Petreski on 4/3/18.
//  Copyright © 2018 Bosko Petreski. All rights reserved.
//

#import "ViewController.h"
#import "ACSBluetooth.h"

@import CoreBluetooth;

@interface ViewController () <CBCentralManagerDelegate, ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate>{
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;
    NSMutableArray *_peripherals;
    ABTBluetoothReaderManager *_bluetoothReaderManager;
    ABTBluetoothReader *_bluetoothReader;
    
    NSData *_masterKey;
    NSData *_commandApdu;
}

@end

@implementation ViewController

- (void)ABD_showError:(NSError *)error {
    NSLog(@"ERROR: %@ %@",[NSString stringWithFormat:@"Error %ld", (long)[error code]],[error localizedDescription]);
}
- (NSString *)ABD_stringFromCardStatus:(ABTBluetoothReaderCardStatus)cardStatus {
    NSString *string = nil;
    switch (cardStatus) {
            
        case ABTBluetoothReaderCardStatusUnknown:
            string = @"Unknown";
            break;
            
        case ABTBluetoothReaderCardStatusAbsent:
            string = @"Absent";
            break;
            
        case ABTBluetoothReaderCardStatusPresent:
            string = @"Present";
            break;
            
        case ABTBluetoothReaderCardStatusPowered:
            string = @"Powered";
            break;
            
        case ABTBluetoothReaderCardStatusPowerSavingMode:
            string = @"Power Saving Mode";
            break;
            
        default:
            string = @"Unknown";
            break;
    }
    
    
    if(cardStatus == ABTBluetoothReaderCardStatusPresent){
        [self onBtnADPU:nil];
    }
    
    
    return string;
}
- (NSString *)ABD_stringFromBatteryStatus:(ABTBluetoothReaderBatteryStatus)batteryStatus {
    
    NSString *string = nil;
    
    switch (batteryStatus) {
            
        case ABTBluetoothReaderBatteryStatusNone:
            string = @"No Battery";
            break;
            
        case ABTBluetoothReaderBatteryStatusFull:
            string = @"Full";
            break;
            
        case ABTBluetoothReaderBatteryStatusUsbPlugged:
            string = @"USB Plugged";
            break;
            
        default:
            string = @"Low";
            break;
    }
    
    return string;
}

#pragma mark - CentralManager
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    static BOOL firstRun = YES;
    NSString *message = nil;
    
    switch (central.state) {
            
        case CBManagerStateUnknown:
        case CBManagerStateResetting:
            message = @"The update is being started. Please wait until Bluetooth is ready.";
            break;
            
        case CBManagerStateUnsupported:
            message = @"This device does not support Bluetooth low energy.";
            break;
            
        case CBManagerStateUnauthorized:
            message = @"This app is not authorized to use Bluetooth low energy.";
            break;
            
        case CBManagerStatePoweredOff:
            if (!firstRun) {
                message = @"You must turn on Bluetooth in Settings in order to use the reader.";
            }
            break;
            
        default:
            break;
    }
   
    if (message != nil) {
        NSLog(@"Bluetooth: %@",message);
    }
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![_peripherals containsObject:peripheral]) {
        [_peripherals addObject:peripheral];
    }
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [_bluetoothReaderManager detectReaderWithPeripheral:peripheral];
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    }
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Information: The reader is disconnected successfully.");
    }
}

#pragma mark - BluetoothManager
- (void)bluetoothReaderManager:(ABTBluetoothReaderManager *)bluetoothReaderManager didDetectReader:(ABTBluetoothReader *)reader peripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
        
    } else {
        _bluetoothReader = reader;
        _bluetoothReader.delegate = self;
        [_bluetoothReader attachPeripheral:peripheral];
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAttachPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Information: The reader is attached to the peripheral successfully.");
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnDeviceInfo:(NSObject *)deviceInfo type:(ABTBluetoothReaderDeviceInfo)type error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        switch (type) {
            case ABTBluetoothReaderDeviceInfoSystemId:
                NSLog(@"system ID: %@",[ABDHex hexStringFromByteArray:(NSData *)deviceInfo]);
                break;
            case ABTBluetoothReaderDeviceInfoModelNumberString:
                NSLog(@"Model number: %@",(NSString *) deviceInfo);
                break;
            case ABTBluetoothReaderDeviceInfoSerialNumberString:
                NSLog(@"Serial number: %@",(NSString *) deviceInfo);
                break;
            case ABTBluetoothReaderDeviceInfoFirmwareRevisionString:
                NSLog(@"firmware revision: %@",(NSString *) deviceInfo);
                break;
            case ABTBluetoothReaderDeviceInfoHardwareRevisionString:
                NSLog(@"hardware revision: %@",(NSString *) deviceInfo);
                break;
            case ABTBluetoothReaderDeviceInfoManufacturerNameString:
                NSLog(@"manufacturer name: %@",(NSString *) deviceInfo);
                break;
            default:
                break;
        }
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAuthenticateWithError:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Information: The reader is authenticated successfully.");
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnAtr:(NSData *)atr error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"ATR String: %@",[ABDHex hexStringFromByteArray:atr]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didPowerOffCardWithError:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Card Status: %@",[self ABD_stringFromCardStatus:cardStatus]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnResponseApdu:(NSData *)apdu error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Response ADPU: %@",[ABDHex hexStringFromByteArray:apdu]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnEscapeResponse:(NSData *)response error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Escape response: %@",[ABDHex hexStringFromByteArray:response]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Status Card: %@",[self ABD_stringFromCardStatus:cardStatus]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeBatteryStatus:(ABTBluetoothReaderBatteryStatus)batteryStatus error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Battery status: %@",[self ABD_stringFromBatteryStatus:batteryStatus]);
    }
}
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeBatteryLevel:(NSUInteger)batteryLevel error:(NSError *)error {
    if (error != nil) {
        [self ABD_showError:error];
    } else {
        NSLog(@"Battery Level: %@",[NSString stringWithFormat:@"%lu%%", (unsigned long) batteryLevel]);
    }
}

#pragma mark - IBActions
-(void)stopSearchReader{
    [_centralManager stopScan];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Readers" message:@"Choose reader" preferredStyle:UIAlertControllerStyleAlert];
    for(CBPeripheral *periperal in _peripherals){
        UIAlertAction *action = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@",periperal.name] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self->_centralManager connectPeripheral:periperal options:nil];
        }];
        [alert addAction:action];
    }
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
-(IBAction)onBtnADPU:(id)sender{
    [_bluetoothReader transmitApdu:_commandApdu];
}
-(IBAction)onBtnScan:(id)sender{
    [_bluetoothReader detach];
    if (_peripheral != nil) {
        [_centralManager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
    }
    [_peripherals removeAllObjects];
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
    
    [self performSelector:@selector(stopSearchReader) withObject:nil afterDelay:2];
}
-(IBAction)onBtnGetInfo:(id)sender{
    // Get the device information.
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoSystemId];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoModelNumberString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoSerialNumberString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoFirmwareRevisionString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoHardwareRevisionString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoManufacturerNameString];
}
-(IBAction)onBtnAuth:(id)sender{
    [_bluetoothReader authenticateWithMasterKey:_masterKey];
}
-(IBAction)onBtnPoll:(id)sender{
    uint8_t command[] = { 0xE0, 0x00, 0x00, 0x40, 0x01 };
    [_bluetoothReader transmitEscapeCommand:command length:sizeof(command)];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _peripherals = [NSMutableArray array];
    _bluetoothReaderManager = [[ABTBluetoothReaderManager alloc] init];
    _bluetoothReaderManager.delegate = self;
    
    _masterKey = [ABDHex byteArrayFromHexString:@"41 43 52 31 32 35 35 55 2D 4A 31 20 41 75 74 68"];
    _commandApdu = [ABDHex byteArrayFromHexString:@"FF CA 00 00 04"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
