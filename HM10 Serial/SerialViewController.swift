//
//  SerialViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore

/// The option to add a \n or \r or \r\n to the end of the send message
enum MessageOption: Int {
    case NoLineEnding = 0
    case Newline = 1
    case CarriageReturn = 2
    case CarriageReturnAndNewline = 3
}

/// The option to add a \n to the end of the received message (to make it more readable)
enum ReceivedMessageOption: Int {
    case Nothing = 0
    case Newline = 1
}

class SerialViewController: UIViewController, UITextFieldDelegate, DZBluetoothSerialDelegate {

//MARK: IBOutlets
    
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    /// used to move the textField up when the keyboard is present
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!


//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init serial
        serial = DZBluetoothSerialHandler(delegate: self)
        
        // UI
        mainTextView.text = ""
        reloadView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadView"), name: "reloadStartViewController", object: nil)
        
        // we want to be notified when the keyboard is shown (so we can move the textField up)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        // to dismiss the keyboard if the user taps outside the textField while editing
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // style the bottom UIView
        bottomView.layer.masksToBounds = false
        bottomView.layer.shadowOffset = CGSizeMake(0, -1)
        bottomView.layer.shadowRadius = 0
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowColor = UIColor.grayColor().CGColor
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // animate the text field to stay above the keyboard
        var info = notification.userInfo!
        var value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        var keyboardFrame = value.CGRectValue()
        
        //TODO: Not animating properly
        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
            }, completion: { Bool -> Void in
            self.textViewScrollToBottom()
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // bring the text field back down..
        UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.bottomConstraint.constant = 0
        }, completion: nil)

    }
    
    func reloadView() {
        
        // in case we're the visible view again
        serial.delegate = self
        
        if serial.connectedPeripheral == nil {
            navItem.title = "Bluetooth Serial"
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
        } else {
            navItem.title = serial.connectedPeripheral!.name
            barButton.title = "Disconnect"
            barButton.tintColor = UIColor.redColor()
        }
    }
    
    func textViewScrollToBottom() {
        var range = NSMakeRange(NSString(string: mainTextView.text).length - 1, 1)
        mainTextView.scrollRangeToVisible(range)
    }
    

//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidReceiveMessage(message: String) {
        // add the received text to the textView, optionally with a line break at the end
        mainTextView.text! += serial.read()
        let pref = NSUserDefaults.standardUserDefaults().integerForKey("ReceivedMessageOption")
        if pref == ReceivedMessageOption.Newline.rawValue { mainTextView.text! += "\n" }
        textViewScrollToBottom()
    }
    
    func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Disconnected"
        hud.hide(true, afterDelay: 1.0)
    }
    
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        if newState != .PoweredOn {
            let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = "Bluetooth turned off"
            hud.hide(true, afterDelay: 1.0)
        }
    }
    
    
//MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if serial.connectedPeripheral == nil {
            
            let alert = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { action -> Void in self.dismissViewControllerAnimated(true, completion: nil) }))
            presentViewController(alert, animated: true, completion: nil)
            messageField.resignFirstResponder()
            return true
        }
        
        // send the message to the bluetooth device
        // but fist, add optionally a line break or carriage return (or both) to the message
        let pref = NSUserDefaults.standardUserDefaults().integerForKey("MessageOption")
        var msg = messageField.text!
        switch pref {
        case MessageOption.Newline.rawValue:
            msg += "\n"
        case MessageOption.CarriageReturn.rawValue:
            msg += "\r"
        case MessageOption.CarriageReturnAndNewline.rawValue:
            msg += "\r\n"
        default:
            msg += ""
        }
        
        // send the message and clear the textfield
        serial.sendMessageToDevice(msg)
        messageField.text = ""
        return true
    }
    
    func dismissKeyboard() {
        messageField.resignFirstResponder()
    }
    
    
//MARK: IBActions

    @IBAction func barButtonPressed(sender: AnyObject) {
        if serial.connectedPeripheral == nil {
            performSegueWithIdentifier("ShowScanner", sender: self)
        } else {
            serial.disconnect()
            reloadView()
        }
        
    }

}
