//
//  InitialQuestionViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 2/7/22.
//

import UIKit
import CoreData

class InitialQuestionViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var curr_user: String!
    var date: Date!
    var feelings = ["Refreshed 😋", "Excited 😆", "Content 😌",  "Euphoric 🤩", "Relieved 😅", "Strong 😤", "Hopeful 😇", "Silly 🤪", "Confused 🤔", "Withdrawn 😑", "Anxious 😣", "Stressed 😫", "Drained 😮‍💨", "Sad 😔", "Disappointed 😕", "Angry  😡", "Annoyed 🤨", "Frustrated 😩"]
    var questions = [[0, 3, 1], [6, 5, 2], [0, 3, 2], [3, 1, 6], [5, 1, 6], [1, 0, 2], [6, 5, 3], [2, 0, 3], [5, 4, 7], [3, 4, 6], [5, 7, 1], [4, 7, 2], [7, 0, 1], [5, 7, 2], [4, 3, 6], [7, 4, 0], [1, 4, 7], [4, 7, 5]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
}

extension InitialQuestionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Response", in: managedContext)!
        let response = NSManagedObject(entity: entity, insertInto: managedContext)
        
        response.setValue(date, forKey: "date")
        response.setValue("How are you feeling today?", forKey: "question")
        response.setValue(feelings[indexPath.row], forKey: "response")
        response.setValue(curr_user, forKey: "username")
        
        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "question") as! QuestionViewController
        
        vc.q_num_array = questions[indexPath.row]
        vc.question_num = 1
        vc.curr_user = curr_user
        vc.date = date
        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension InitialQuestionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feelings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = feelings[indexPath.row]
        return cell
    }
}
