//
//  PreferencesTableViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit

class PreferencesTableViewController: UITableViewController {
    
//MARK: Variables
    
    var selectedMessageOption: MessageOption!
    var selectedReceivedMessageOption: ReceivedMessageOption!


//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get current prefs
        selectedMessageOption = MessageOption(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("MessageOption"))
        selectedReceivedMessageOption = ReceivedMessageOption(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("ReceivedMessageOption"))
        
        // set checkmarks
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedMessageOption.rawValue, inSection: 0))?.accessoryType = UITableViewCellAccessoryType.Checkmark
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedReceivedMessageOption.rawValue, inSection: 1))?.accessoryType = .Checkmark
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
        // is it for the selectedMessageOption or for the selectedReceivedMessageOption? (section 0 or 1 resp.)
        if indexPath.section == 0 {
            
            // first clear the old checkmark
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))?.accessoryType = .None
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))?.accessoryType = .None
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))?.accessoryType = .None
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0))?.accessoryType = .None
            
            // get the newly selected option
            let selectedCell = indexPath.row
            selectedMessageOption = MessageOption(rawValue: selectedCell)

            // set new checkmark
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedCell, inSection: 0))?.accessoryType = UITableViewCellAccessoryType.Checkmark
            
            // and finally .. save it
            NSUserDefaults.standardUserDefaults().setInteger(selectedCell, forKey: "MessageOption")
            
        } else if indexPath.section == 1 {
            
            // first, clear the old checkmark
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))?.accessoryType = .None
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 1))?.accessoryType = .None
            
            // get the newly selected option
            let selectedCell = indexPath.row
            selectedReceivedMessageOption = ReceivedMessageOption(rawValue: selectedCell)

            // set new checkmark
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedCell, inSection: 1))?.accessoryType = UITableViewCellAccessoryType.Checkmark
            
            // save it
            NSUserDefaults.standardUserDefaults().setInteger(selectedCell, forKey: "ReceivedMessageOption")

        }
        
        // deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // prevent the checkmarks from disappearing when they are scrolled out of screen and then back in
        if indexPath.section == 0 && indexPath.row == selectedMessageOption.rawValue {
            cell.accessoryType = .Checkmark
        } else  if indexPath.section == 1 && indexPath.row == selectedReceivedMessageOption.rawValue {
            cell.accessoryType = .Checkmark
        }
    }
    
    
//MARK: IBActions

    @IBAction func done(sender: AnyObject) {
        // dismissssssss
        dismissViewControllerAnimated(true, completion: nil)
    }
}
