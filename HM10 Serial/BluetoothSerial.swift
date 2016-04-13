//
//  BluetoothSerial.swift (originally DZBluetoothSerialHandler.swift)
//  HM10 Serial
//
//  Created by Alex on 09-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  IMPORTANT: Don't forget to set the variable 'writeType' or else the whole thing might not work.
//

import UIKit
import CoreBluetooth

/// Global serial handler, don't forget to initialize it with init(delgate:)
var serial: BluetoothSerial!

// Delegate functions
protocol BluetoothSerialDelegate {
    // ** Required **
    
    /// Called when de state of the CBCentralManager changes (e.g. when bluetooth is turned on/off)
    func serialDidChangeState(newState: CBCentralManagerState)
    
    /// Called when a peripheral disconnected
    func serialDidDisconnect(peripheral: CBPeripheral, error: NSError?)
    
    // ** Optionals **
    
    /// Called when a message is received
    func serialDidReceiveString(message: String)
    
    /// Called when a message is received
    func serialDidReceiveBytes(bytes: [UInt8])
    
    /// Called when a message is received
    func serialDidReceiveData(data: NSData)
    
    /// Called when the RSSI of the connected peripheral is read
    func serialDidReadRSSI(rssi: NSNumber)
    
    /// Called when a new peripheral is discovered while scanning. Also gives the RSSI (signal strength)
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?)
    
    /// Called when a peripheral is connected (but not yet ready for cummunication)
    func serialDidConnect(peripheral: CBPeripheral)
    
    /// Called when a pending connection failed
    func serialDidFailToConnect(peripheral: CBPeripheral, error: NSError?)

    /// Called when a peripheral is ready for communication
    func serialIsReady(peripheral: CBPeripheral)
}

// Make some of the delegate functions optional
extension BluetoothSerialDelegate {
    func serialDidReceiveString(message: String) {}
    func serialDidReceiveBytes(bytes: [UInt8]) {}
    func serialDidReceiveData(data: NSData) {}
    func serialDidReadRSSI(rssi: NSNumber) {}
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnect(peripheral: CBPeripheral) {}
    func serialDidFailToConnect(peripheral: CBPeripheral, error: NSError?) {}
    func serialIsReady(peripheral: CBPeripheral) {}
}


final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
//MARK: Variables
    
    /// The delegate object the BluetoothDelegate methods will be called upon
    var delegate: BluetoothSerialDelegate!
    
    /// The CBCentralManager this bluetooth serial handler uses for... well, everything really
    var centralManager: CBCentralManager!
    
    /// The peripheral we're trying to connect to (nil if none)
    var pendingPeripheral: CBPeripheral?
    
    /// The connected peripheral (nil if none is connected)
    var connectedPeripheral: CBPeripheral?

    /// The characteristic 0xFFE1 we need to write to, of the connectedPeripheral
    weak var writeCharacteristic: CBCharacteristic?
    
    /// The state of the bluetooth manager (use this to determine whether it is on or off or disabled etc)
    var state: CBCentralManagerState { get { return centralManager.state } }
    
    /// Whether this serial is ready to send and receive data
    var isReady: Bool {
        get {
            return centralManager.state == .PoweredOn &&
                   connectedPeripheral != nil &&
                   writeCharacteristic != nil
        }
    }
    
    /// Whether to write to the HM10 with or without response.
    /// Legit HM10 modules (from JNHuaMao) require 'Write without Response',
    /// while fake modules (e.g. from Bolutek) require 'Write with Response'.
    var writeType: CBCharacteristicWriteType = .WithoutResponse
    
    
//MARK: functions
    
    /// Always use this to initialize an instance
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func startScan() {
        guard centralManager.state == .PoweredOn else { return }
        
        // start scanning for peripherals with correct service UUID
        let uuid = CBUUID(string: "FFE0")
        centralManager.scanForPeripheralsWithServices([uuid], options: nil)
        
        // retrieve peripherals that are already connected
        // see this stackoverflow question http://stackoverflow.com/questions/13286487
        let peripherals = centralManager.retrieveConnectedPeripheralsWithServices([uuid])
        for peripheral in peripherals {
            delegate.serialDidDiscoverPeripheral(peripheral, RSSI: nil)
        }
    }
    
    /// Stop scanning for peripherals
    func stopScan() {
        centralManager.stopScan()
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(peripheral: CBPeripheral) {
        pendingPeripheral = peripheral
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    /// Disconnect from the connected peripheral or stop connecting to it
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p) //TODO: Test whether its neccesary to set p to nil
        }
    }
    
    /// The didReadRSSI delegate function will be called after calling this function
    func readRSSI() {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }
    
    /// Send a string to the device
    func sendMessageToDevice(message: String) {
        guard isReady else { return }
        
        if let data = message.dataUsingEncoding(NSUTF8StringEncoding) {
            connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
        }
    }
    
    /// Send an array of bytes to the device
    func sendBytesToDevice(bytes: [UInt8]) {
        guard isReady else { return }
        
        let data = NSData(bytes: bytes, length: bytes.count)
        connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
    }
    
    /// Send data to the device
    func sendDataToDevice(data: NSData) {
        guard isReady else { return }
        
        connectedPeripheral!.writeValue(data, forCharacteristic: writeCharacteristic!, type: writeType)
    }
    
    
//MARK: CBCentralManagerDelegate functions

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // just send it to the delegate
        delegate.serialDidDiscoverPeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        // set some stuff right
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // send it to the delegate
        delegate.serialDidConnect(peripheral)

        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the 0xFFE1 characteristic of this service
        // Subscribe to it & create a weak reference to it (for writing later on), 
        // and then we're ready for communication

        peripheral.discoverServices([CBUUID(string: "FFE0")])
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connectedPeripheral = nil
        pendingPeripheral = nil

        // send it to the delegate
        delegate.serialDidDisconnect(peripheral, error: error)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        pendingPeripheral = nil

        // just send it to the delegate
        delegate.serialDidFailToConnect(peripheral, error: error)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        // note that "didDisconnectPeripheral" won't be called if BLE is turned off while connected
        connectedPeripheral = nil
        pendingPeripheral = nil

        // send it to the delegate
        delegate.serialDidChangeState(central.state)
    }
    
    
//MARK: CBPeripheralDelegate functions
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        // discover the 0xFFE1 characteristic for all services (though there should only be one)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        // check whether the characteristic we're looking for (0xFFE1) is present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.UUID == CBUUID(string: "FFE1") {
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
                // keep a reference to this characteristic so we can write to it
                writeCharacteristic = characteristic
                
                // notify the delegate we're ready for communication
                delegate.serialIsReady(peripheral)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        // notify the delegate in different ways
        // if you don't use one of these, just comment it (for optimum efficiency :])
        let data = characteristic.value
        guard data != nil else { return }
        
        // first the data
        delegate.serialDidReceiveData(data!)
        
        // then the string
        if let str = String(data: data!, encoding: NSUTF8StringEncoding) {
            delegate.serialDidReceiveString(str)
        } else {
            //print("Received an invalid string!") uncomment for debugging
        }
        
        // now the bytes array
        var bytes = [UInt8](count: data!.length / sizeof(UInt8), repeatedValue: 0)
        data!.getBytes(&bytes, length: data!.length)
        delegate.serialDidReceiveBytes(bytes)
    }
    
    func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        delegate.serialDidReadRSSI(RSSI)
    }
}