//
//  ScannerViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

final class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BluetoothSerialDelegate {

//MARK: IBOutlets
    
    @IBOutlet weak var tryAgainButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
//MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    /// Progress hud shown
    var progressHUD: MBProgressHUD?
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tryAgainButton is only enabled when we've stopped scanning
        tryAgainButton.enabled = false

        // remove extra seperator insets (looks better imho)
        tableView.tableFooterView = UIView(frame: CGRectZero)

        // tell the delegate to notificate US instead of the previous view if something happens
        serial.delegate = self
        
        if serial.state != .PoweredOn {
            title = "Bluetooth not turned on"
            return
        }
        
        // start scanning and schedule the time out
        serial.startScan()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Should be called 10s after we've begun scanning
    func scanTimeOut() {
        // timeout has occurred, stop scanning and give the user the option to try again
        serial.stopScan()
        tryAgainButton.enabled = true
        title = "Done scanning"
    }
    
    /// Should be called 10s after we've begun connecting
    func connectTimeOut() {
        
        // don't if we've already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
        
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 2)
    }
    
    
//MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // return a cell with the peripheral name as text in the label
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let label = cell.viewWithTag(1) as! UILabel!
        label.text = peripherals[indexPath.row].peripheral.name
        return cell
    }
    
    
//MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        serial.stopScan()
        selectedPeripheral = peripherals[indexPath.row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressHUD!.labelText = "Connecting"
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.connectTimeOut), userInfo: nil, repeats: false)
    }
    
    
//MARK: BluetoothSerialDelegate
    
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append(peripheral: peripheral, RSSI: theRSSI)
        peripherals.sortInPlace { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidFailToConnect(peripheral: CBPeripheral, error: NSError?) {
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        tryAgainButton.enabled = true
                
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 1.0)
    }
    
    func serialDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        tryAgainButton.enabled = true
        
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 1.0)

    }
    
    func serialIsReady(peripheral: CBPeripheral) {
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func serialDidChangeState(newState: CBCentralManagerState) {
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        if newState != .PoweredOn {
            NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    

//MARK: IBActions
    
    @IBAction func cancel(sender: AnyObject) {
        // go back
        serial.stopScan()
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func tryAgain(sender: AnyObject) {
        // empty array an start again
        peripherals = []
        tableView.reloadData()
        tryAgainButton.enabled = false
        title = "Scanning ..."
        serial.startScan()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    
}
