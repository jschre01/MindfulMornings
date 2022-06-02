//
//  HistoryViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 5/9/22.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var curr_user: String!
    var responses: [NSManagedObject] = []
    var dates: [Date] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        get_dates()
    }
    
    func get_dates() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest : NSFetchRequest<Response> = Response.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username = %@", curr_user)
        
        do {
            responses = try managedContext.fetch(fetchRequest)
            if !responses.isEmpty {
                for response in responses {
                    let d = response.value(forKey: "date") as? Date
                    if !dates.contains(d!) {
                        dates.append(d!)
                    }
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "response") as! ResponseViewController
        
        vc.curr_user = curr_user
        vc.date = dates[indexPath.row]
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        let date = formatter.string(from: dates[indexPath.row])
        cell.textLabel?.text = date
        return cell
    }
}
