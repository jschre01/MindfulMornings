//
//  AccountViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 4/29/22.
//

import UIKit
import CoreData
import CryptoKit

class AccountViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var u_field: UITextField!
    @IBOutlet var p_field: UITextField!
    @IBOutlet var label: UILabel!
    @IBOutlet var account_b: UIButton!
    
    var users: [NSManagedObject] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        
        u_field.returnKeyType = UIReturnKeyType.done
        u_field.delegate = self
        p_field.returnKeyType = UIReturnKeyType.done
        p_field.delegate = self
        label.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func create_account() {
        guard let username = u_field.text, !username.isEmpty
        else {
            label.text = "Username can't be empty"
            return
        }
        guard let password = p_field.text, !(password.count < 8)
        else{
            label.text = "Password must be at least 8 characters"
            return
        }
        
        let digest = SHA256.hash(data: Data(password.utf8))
        let hashed = digest.compactMap { String(format: "%02x", $0)}.joined()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username = %@", username)
        
        do {
            users = try managedContext.fetch(fetchRequest)
            if users.isEmpty {
                let entity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
                let user = NSManagedObject(entity: entity, insertInto: managedContext)
                let entity2 = NSEntityDescription.entity(forEntityName: "Key", in: managedContext)!
                let key = NSManagedObject(entity: entity2, insertInto: managedContext)
                let letters = "abcdef0123456789"
                let randomString = String((0..<64).map{ _ in letters.randomElement()! })
                let calendar = Calendar.current
                let new_date = calendar.date(byAdding: .day, value: -1, to: Date())
                
                user.setValue(username, forKey: "username")
                user.setValue(hashed, forKey: "password")
                user.setValue(0, forKey: "streak")
                user.setValue(new_date, forKey: "most_recent")
                key.setValue(username, forKey: "username")
                key.setValue(randomString, forKey: "key")
                
                do {
                    try managedContext.save()
                    navigationController?.popViewController(animated: true)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
            else{
                label.text = "Username already exists"
                return
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
