//
//  LoginViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 4/29/22.
//

import UIKit
import CoreData
import CryptoKit
import UserNotifications

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var u_field: UITextField!
    @IBOutlet var p_field: UITextField!
    @IBOutlet var label: UILabel!
    @IBOutlet var login_b: UIButton!
    @IBOutlet var account_b: UIButton!
    
    var success: Bool = false
    var users: [NSManagedObject] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        u_field.returnKeyType = UIReturnKeyType.done
        u_field.delegate = self
        p_field.returnKeyType = UIReturnKeyType.done
        p_field.delegate = self
        label.text = ""
        
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func login() {
        guard let username = u_field.text, !username.isEmpty
        else {
            label.text = "Invalid username"
            return
        }
        guard let password = p_field.text, !password.isEmpty
        else{
            label.text = "Invalid password"
            return
        }
        
        let digest = SHA256.hash(data: Data(password.utf8))
        let hashed = digest.compactMap { String(format: "%02x", $0)}.joined()

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<User> = User.fetchRequest()
        let usernamePredicate = NSPredicate(format: "username = %@", username)
        let passwordPredicate = NSPredicate(format: "password = %@", hashed)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [usernamePredicate, passwordPredicate])
        
        do {
            users = try managedContext.fetch(fetchRequest)
            if users.isEmpty {
                label.text = "Username or password is incorrect"
            }
            else if users.count >= 2 {
                label.text = "Oops! Our database is messed up."
            }
            else{
                let fetchRequest2: NSFetchRequest<Notifications> = Notifications.fetchRequest()
                fetchRequest2.predicate = NSPredicate(format: "username = %@", username)
                let notifications = try managedContext.fetch(fetchRequest2)
                for notification in notifications {
                    let date = notification.value(forKey: "date") as! Date
                    let id = notification.value(forKey: "id") as! Int
                    scheduleNotification(date, identifier: id)
                }
                let vc = storyboard?.instantiateViewController(withIdentifier: "welcome") as! WelcomeViewController
                vc.logged_in = true
                vc.curr_user = username
                navigationController?.pushViewController(vc, animated: true)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
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
    
    @IBAction func create_account() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "account") as! AccountViewController
        vc.title = "Create a new account"
        navigationController?.pushViewController(vc, animated: true)
    }
}
