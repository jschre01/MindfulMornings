//
//  ViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 2/7/22.
//

import UIKit
import UserNotifications
import CoreData

class PreferencesViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var datePicker: UIDatePicker!
    
    var alarms_unfiltered: [NSManagedObject] = []
    var alarms = [String]()
    var curr_user: String!
    var date: Date!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Alarms"
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(didTapAdd))
        
        updateTasks()

    }
    
    func updateTasks() {
        alarms.removeAll()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<Notifications> = Notifications.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username = %@", curr_user)
        
        do {
            alarms_unfiltered = try managedContext.fetch(fetchRequest)
            for alarm in alarms_unfiltered {
                alarms.append(alarm.value(forKey: "text") as! String)
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }
    
    @objc func didTapAdd() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "notification") as!
        NotificationViewController
        vc.title = "Create Notification"
        vc.curr_user = curr_user
        vc.update = {
            DispatchQueue.main.async {
                self.updateTasks()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleDateSelection() {
        date = datePicker?.date
    }

}

extension PreferencesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "edit") as! EditNotificationViewController
        vc.date = alarms[indexPath.row]
        vc.title = "Edit Notification"
        vc.curr_user = curr_user
        vc.update = {
            DispatchQueue.main.async {
                self.updateTasks()
            }
        }
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

extension PreferencesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = alarms[indexPath.row]
        
        return cell
    }
}

