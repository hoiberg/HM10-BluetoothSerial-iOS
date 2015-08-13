//
//  ConnectViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectViewController: UIViewController, DZBluetoothSerialDelegate {
    
//MARK: IBOutlets
    
    @IBOutlet weak var smallLabel: UILabel!
    @IBOutlet weak var bigLabel: UILabel!
    @IBOutlet weak var abortButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
//MARK: Variables
    
    /// Pretty self-explainatory isn't it?
    var selectedPeripheral: CBPeripheral!
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // don't give the user the option to go back! (It's a trap!)
        navigationItem.setHidesBackButton(true, animated: false)
        
        // set us as the delegate and try to connect
        serial.delegate = self
        serial.connectToPeripheral(selectedPeripheral)
        
        // UI stuff
        smallLabel.text = "Connecting to"
        bigLabel.text = selectedPeripheral.name
        activityIndicator.startAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerIsReady(peripheral: CBPeripheral) {
        // proceed to the next view
        performSegueWithIdentifier("connected", sender: self)
    }
    
    func serialHandlerDidConnect(peripheral: CBPeripheral) {
        // it is connected but not yet ready
        smallLabel.text = "Fetching data from"
    }
    
    func serialHandlerDidFailToConnect(peripheral: CBPeripheral, error: NSError) {
        // tell the user we couldn't connect
        activityIndicator.stopAnimating()
        smallLabel.text = "Connection failed"
        smallLabel.textColor = UIColor.redColor()
        bigLabel.text = ""
        abortButton.titleLabel!.text = "Close"
    }
    
    func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError) {
        // tell the user it has disconnected while connecting
        activityIndicator.stopAnimating()
        smallLabel.text = "Disconnected"
        smallLabel.textColor = UIColor.redColor()
        bigLabel.text = ""
        abortButton.titleLabel!.text = "Close"
    }
    
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        if newState != .PoweredOn {
            // bluetooth has been turned off while we were trying to establish a connection
            activityIndicator.stopAnimating()
            smallLabel.text = "Bluetooth disabled"
            smallLabel.textColor = UIColor.redColor()
            bigLabel.text = ""
            abortButton.titleLabel!.text = "Close"
        }
    }
    
    @IBAction func abort(sender: AnyObject) {
        // stop scanning and go back to the first screen
        serial.cancelPeripheralConnection(selectedPeripheral)
        NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
        dismissViewControllerAnimated(true, completion: nil)
    }



}
