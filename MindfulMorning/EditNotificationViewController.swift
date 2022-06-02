//
//  EditNotificationViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 4/17/22.
//

import UIKit
import CoreData

class EditNotificationViewController: UIViewController {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var delete: UIButton!
    
    var date: String?
    var num: Int?
    var curr_user: String!
    var remove_id: Int!
    var update: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = date
    }
    
    @IBAction func deleteTask() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<Notifications> = Notifications.fetchRequest()
        let usernamePredicate = NSPredicate(format: "username = %@", curr_user)
        let textPredicate = NSPredicate(format: "text = %@", date!)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [usernamePredicate, textPredicate])
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            remove_id = results[0].value(forKey: "id") as! Int
            managedContext.delete(results[0])
            try managedContext.save()
        }
        catch let error as NSError {
        print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(remove_id)])
        
        update?()
        
        navigationController?.popViewController(animated: true)
    }
}
