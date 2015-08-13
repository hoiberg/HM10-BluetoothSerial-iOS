//
//  StartViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

class StartViewController: UIViewController, DZBluetoothSerialDelegate {
    
//MARK: IBOutlet
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init global serial handler
        serial = DZBluetoothSerialHandler(delegate: self)
        
        // notification used when the modal view is going to be dismissed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadState", name: "reloadStartViewController", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reloadState() {
        
        // set delegate to self in case this view is presented again..
        serial.delegate = self
        
        // now work out what whe have to show the user
        scanButton.enabled = false
        
        switch serial.state {
        case .PoweredOn:
            scanButton.enabled = true
            statusLabel.text = "Not connected"
        case .Unknown:
            statusLabel.text = "Bluetooth not working!"
        case .Resetting:
            statusLabel.text = "Bluetooth loading ..."
        case .Unsupported:
            statusLabel.text = "Bluetooth unsupported!"
        case .Unauthorized:
            statusLabel.text = "Bluetooth not authorized"
        case .PoweredOff:
            statusLabel.text = "Bluetooth turned off"
        }
    }
    
    
//MARK: DZBluetoothSerialHandlerDelegate
    
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        reloadState()
    }
    
}
