//
//  CongratsViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 5/12/22.
//

import UIKit

class CongratsViewController: UIViewController {
    
    @IBOutlet var finish: UIButton!
    @IBOutlet var label: UILabel!
    
    var curr_user: String!
    var text: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = text
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    @IBAction func didTapContinue() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "welcome") as! WelcomeViewController
        vc.curr_user = curr_user
        vc.logged_in = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
