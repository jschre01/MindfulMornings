//
//  ResponseViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 5/9/22.
//

import UIKit
import CoreData
import CryptoKit

class ResponseViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var curr_user: String!
    var date: Date!
    var responses: [NSManagedObject] = []
    var answers: [String] = []
    var k: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    
        get_answers()
    }
    
    func get_answers(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest2 : NSFetchRequest<Key> = Key.fetchRequest()
        fetchRequest2.predicate = NSPredicate(format: "username = %@", curr_user)
        
        do {
            let keys = try managedContext.fetch(fetchRequest2)
            for key in keys {
                k = key.value(forKey: "key") as? String
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return
        }
        
        let fetchRequest : NSFetchRequest<Response> = Response.fetchRequest()
        let usernamePredicate = NSPredicate(format: "username = %@", curr_user)
        let datePredicate = NSPredicate(format: "date = %@", date! as CVarArg)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [usernamePredicate, datePredicate])
        
        do {
            responses = try managedContext.fetch(fetchRequest)
            if !responses.isEmpty {
                for response in responses {
                    let q = response.value(forKey: "question") as? String
                    if q == "How are you feeling today?"{
                        answers.append(response.value(forKey: "response") as! String)
                    }
                }
                let key = SymmetricKey(data: Data(hexString: k)!)
                for response in responses {
                    let q = response.value(forKey: "question") as? String
                    if q != "How are you feeling today?"{
                        answers.append(response.value(forKey: "question") as! String)
                        let cipher = response.value(forKey: "response") as! String
                        let cipher_data = Data(hexString: cipher)
                        let sealedBox = try! ChaChaPoly.SealedBox(combined: cipher_data!)
                        let combinedData = sealedBox.combined
                        let _ = try! ChaChaPoly.SealedBox(combined: combinedData)
                        let decryptedData = try! ChaChaPoly.open(sealedBox, using: key)
                        let answer = String(data: decryptedData, encoding: .utf8)
                        answers.append(answer!)
                    }
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}

extension ResponseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return
    }
}

extension ResponseViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return answers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = answers[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        return cell
    }
}
