//
//  ScannerViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZBluetoothSerialDelegate {

   
//MARK: IBOutlets
    
    @IBOutlet weak var tryAgainButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
//MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tryAgainButton is only enabled when we've stopped scanning
        tryAgainButton.enabled = false

        // remove extra seperator insets (looks better imho)
        tableView.tableFooterView = UIView(frame: CGRectZero)

        // tell the delegate to notificate US instead of the previous view if something happens
        serial.delegate = self
        
        // start scanning and schedule the time out
        serial.scanForPeripherals()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "scanTimeOut", userInfo: nil, repeats: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Should be called 10s after we've begun scanning
    func scanTimeOut() {
        // timeout has occurred, stop scanning and give the user the option to try again
        serial.stopScanning()
        tryAgainButton.enabled = true
        title = "Done scanning"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "connect" {
            // pas the selected peripheral on to the next view
            var connectViewC = segue.destinationViewController as! ConnectViewController
            connectViewC.selectedPeripheral = selectedPeripheral
        }
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
        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        let label = cell.viewWithTag(1) as! UILabel!
        label.text = peripherals[indexPath.row].peripheral.name
        return cell
    }
    
    
//MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        serial.stopScanning()
        selectedPeripheral = peripherals[indexPath.row].peripheral
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("connect", sender: self)
    }
    
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        peripherals.append(peripheral: peripheral, RSSI: RSSI.floatValue)
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        if newState != .PoweredOn {
            // NOOOO the bluetooth has been disabled.. Let's go back to the main view
            NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    

//MARK: IBActions
    @IBAction func cancel(sender: AnyObject) {
        // go back
        NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func tryAgain(sender: AnyObject) {
        // empty array an start again
        peripherals = []
        tableView.reloadData()
        tryAgainButton.enabled = false
        title = "Scanning ..."
        serial.scanForPeripherals()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "scanTimeOut", userInfo: nil, repeats: false)
    }
    
}
