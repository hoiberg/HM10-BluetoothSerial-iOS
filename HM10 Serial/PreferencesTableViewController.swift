//
//  PreferencesTableViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit

final class PreferencesTableViewController: UITableViewController {
    
//MARK: Variables
    
    var selectedMessageOption: MessageOption!
    var selectedReceivedMessageOption: ReceivedMessageOption!
    var writeWithResponse = false


//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get current prefs
        selectedMessageOption = MessageOption(rawValue: UserDefaults.standard.integer(forKey: MessageOptionKey))
        selectedReceivedMessageOption = ReceivedMessageOption(rawValue: UserDefaults.standard.integer(forKey: ReceivedMessageOptionKey))
        writeWithResponse = UserDefaults.standard.bool(forKey: WriteWithResponseKey)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        // is it for the selectedMessageOption or for the selectedReceivedMessageOption? (section 0 or 1 resp.)
        if (indexPath as NSIndexPath).section == 0 {
            
            // first clear the old checkmark
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .none
            tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.accessoryType = .none
            tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.accessoryType = .none
            tableView.cellForRow(at: IndexPath(row: 3, section: 0))?.accessoryType = .none
            
            // get the newly selected option
            let selectedCell = (indexPath as NSIndexPath).row
            selectedMessageOption = MessageOption(rawValue: selectedCell)

            // set new checkmark
            tableView.cellForRow(at: IndexPath(row: selectedCell, section: 0))?.accessoryType = UITableViewCellAccessoryType.checkmark
            
            // and finally .. save it
            UserDefaults.standard.set(selectedCell, forKey: MessageOptionKey)
            
        } else if (indexPath as NSIndexPath).section == 1 {
            
            // first, clear the old checkmark
            tableView.cellForRow(at: IndexPath(row: 0, section: 1))?.accessoryType = .none
            tableView.cellForRow(at: IndexPath(row: 1, section: 1))?.accessoryType = .none
            
            // get the newly selected option
            let selectedCell = (indexPath as NSIndexPath).row
            selectedReceivedMessageOption = ReceivedMessageOption(rawValue: selectedCell)

            // set new checkmark
            tableView.cellForRow(at: IndexPath(row: selectedCell, section: 1))?.accessoryType = UITableViewCellAccessoryType.checkmark
            
            // save it
            UserDefaults.standard.set(selectedCell, forKey: ReceivedMessageOptionKey)

        } else if (indexPath as NSIndexPath).section == 2 {
            
            // first, clear the old checkmark
            tableView.cellForRow(at: IndexPath(row: 0, section: 2))?.accessoryType = .none
            tableView.cellForRow(at: IndexPath(row: 1, section: 2))?.accessoryType = .none
            
            // get the newly selected option
            writeWithResponse = (indexPath as NSIndexPath).row == 0 ? false : true
            
            // set new checkmark
            tableView.cellForRow(at: IndexPath(row: (indexPath as NSIndexPath).row, section: 2))?.accessoryType = UITableViewCellAccessoryType.checkmark
            
            // save it
            UserDefaults.standard.set(writeWithResponse, forKey: WriteWithResponseKey)
            
            // set it
            serial.writeType = writeWithResponse ? .withResponse : .withoutResponse

        }
        
        // deselect row
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // prevent the checkmarks from disappearing when they are scrolled out of screen and then back in
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == selectedMessageOption.rawValue {
            cell.accessoryType = .checkmark
        } else  if (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).row == selectedReceivedMessageOption.rawValue {
            cell.accessoryType = .checkmark
        } else if (indexPath as NSIndexPath).section == 2 && (indexPath as NSIndexPath).row == (writeWithResponse ? 1 : 0) {
            cell.accessoryType = .checkmark
        }
    }
    
    
//MARK: IBActions

    @IBAction func done(_ sender: AnyObject) {
        // dismissssssss
        dismiss(animated: true, completion: nil)
    }
}
