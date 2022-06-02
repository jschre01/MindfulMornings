//
//  NotificationViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 4/16/22.
//

import UIKit
import UserNotifications
import CoreData

class NotificationViewController: UIViewController {
    
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var save: UIButton!
    
    var update: (() -> Void)?
    var date: Date!
    var id: Int!
    var ids: [NSManagedObject] = []
    var curr_user: String!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker?.datePickerMode = .time
        datePicker?.preferredDatePickerStyle = .wheels
        datePicker?.addTarget(self, action: #selector(handleDateSelection), for: .valueChanged)
    }
    
    func scheduleNotification(_ date: Date, identifier: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        var content = UNMutableNotificationContent()
        content.title = "Good morning!"
        content.body = "Click open to check in with yourself!"
        content.interruptionLevel = UNNotificationInterruptionLevel.critical
        content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: 0.8)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute],from: date), repeats: true)
        
        let request = UNNotificationRequest(identifier: String(identifier), content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error)
            } else {
                print("success")
            }
        }
    }
    
    @IBAction func didTapSave() {
        date = datePicker?.date
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        var text = ""
        
        if date != nil {
            text = dateFormatter.string(from: date)
        }
        else {
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<Nid> = Nid.fetchRequest()
        let entity2 = NSEntityDescription.entity(forEntityName: "Nid", in: managedContext)!
        let nid = NSManagedObject(entity: entity2, insertInto: managedContext)
        
        do {
            ids = try managedContext.fetch(fetchRequest)
            if ids.isEmpty {
                id = 0
                nid.setValue(id, forKey: "id")
            }
            else {
                id = ids[0].value(forKey: "id") as! Int + 1
                ids[0].setValue(id, forKey: "id")
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "Notifications", in: managedContext)!
        let notifications = NSManagedObject(entity: entity, insertInto: managedContext)
        
        scheduleNotification(self.date, identifier: id)

        notifications.setValue(curr_user, forKey: "username")
        notifications.setValue(id, forKey: "id")
        notifications.setValue(text, forKey: "text")
        notifications.setValue(self.date, forKey: "date")

        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        update?()
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleDateSelection() {
        date = datePicker?.date
    }
}
