//
//  WelcomeViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 4/16/22.
//

import UIKit
import UserNotifications
import CoreData
import CoreMedia
import CoreAudio

class WelcomeViewController: UIViewController {
    
    @IBOutlet var start: UIButton!
    @IBOutlet var preferences: UIButton!
    @IBOutlet var history: UIButton!
    @IBOutlet var logout: UIButton!
    @IBOutlet var delete: UIButton!
    
    var logged_in: Bool = false
    var curr_user: String!
    var users: [NSManagedObject] = []
    var responses: [NSManagedObject] = []
    var keys: [NSManagedObject] = []
    var notifications: [NSManagedObject] = []
    var remove_id: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if logged_in {
            self.title = "Welcome to Mindful Morning, " + curr_user
            self.navigationItem.setHidesBackButton(true, animated: true)
            UNUserNotificationCenter.current().requestAuthorization(options: [.criticalAlert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error")
                }
            }
        }
        else {
            let vc = storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
            vc.title = "Welcome to Mindful Morning"
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func didTapStart() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "initial") as!
        InitialQuestionViewController
        vc.title = "How are you feeling today?"
        vc.curr_user = curr_user
        let date = Date()
        vc.date = date
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapPreferences() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "preference") as! PreferencesViewController
        vc.curr_user = curr_user
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapHistory() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "history") as! HistoryViewController
        vc.curr_user = curr_user
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func didTapLogout() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<Notifications> = Notifications.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username = %@", curr_user)
        
        do {
            notifications = try managedContext.fetch(fetchRequest)
            for notification in notifications {
                remove_id = (notification.value(forKey: "id") as! Int)
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(remove_id)])
            }
            try managedContext.save()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        logged_in = false
        self.viewDidLoad()
    }
    
    @IBAction func didTapDelete() {
        let deleteAlert = UIAlertController(title: "Are you sure you want to delete your account?", message: "This action cannot be undone. All data will be lost.", preferredStyle: UIAlertController.Style.alert)

        deleteAlert.addAction(UIAlertAction(title: "Yes, delete my account", style: .default, handler: { (action: UIAlertAction!) in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest : NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username = %@", self.curr_user)
            
            do {
                self.users = try managedContext.fetch(fetchRequest)
                for user in self.users {
                    managedContext.delete(user)
                }
                try managedContext.save()
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            
            let fetchRequest2 : NSFetchRequest<Response> = Response.fetchRequest()
            fetchRequest2.predicate = NSPredicate(format: "username = %@", self.curr_user)
            
            do {
                self.responses = try managedContext.fetch(fetchRequest2)
                for response in self.responses {
                    managedContext.delete(response)
                }
                try managedContext.save()

            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            
            let fetchRequest3 : NSFetchRequest<Key> = Key.fetchRequest()
            fetchRequest3.predicate = NSPredicate(format: "username = %@", self.curr_user)
            
            do {
                self.keys = try managedContext.fetch(fetchRequest3)
                for response in self.responses {
                    managedContext.delete(response)
                }
                try managedContext.save()

            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            
            let fetchRequest4 : NSFetchRequest<Notifications> = Notifications.fetchRequest()
            fetchRequest4.predicate = NSPredicate(format: "username = %@", self.curr_user)
            
            do {
                self.notifications = try managedContext.fetch(fetchRequest4)
                for notification in self.notifications {
                    managedContext.delete(notification)
                }
                try managedContext.save()

            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
     
            self.logged_in = false
            self.viewDidLoad()
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "No, don't delete my account", style: .cancel, handler: { (action: UIAlertAction!) in
            return
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }
}
