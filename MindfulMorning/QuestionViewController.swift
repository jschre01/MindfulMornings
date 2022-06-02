//
//  QuestionViewController.swift
//  MindfulMorning
//
//  Created by Jonathan Schreiber on 2/7/22.
//

import UIKit
import AVFoundation
import Speech
import CoreData
import CryptoKit

class QuestionViewController: UIViewController, AVAudioRecorderDelegate, UITextViewDelegate {
    
    @IBOutlet var label: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var text: UITextView!
    
    var q_num: Int?
    var q_num_array: [Int]?
    var question_num: Int?
    var question: String?
    var answered: Bool = false
    var meditation: Bool = false
    var recorded: Bool = false
    var curr_user: String!
    var date: Date!
    var streak: Int!
    var spoken: String = ""
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var questions = ["What is an idea that is taking up space in your mind?", "What is something that you are proud of?", "What is a dream you've had?", "What is a hope or dream for your life?", "What is a frustration you've been experiencing?", "What's on your mind?", "What are you looking forward to?", "What is something you would like to let go of?", "What is a fear you are experiencing", "What is something you are grateful for?"]
    var k: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.text.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        if q_num == nil {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest : NSFetchRequest<User> = User.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username = %@", curr_user)
            
            do {
                let users = try managedContext.fetch(fetchRequest)
                let user = users[0]
                if user.value(forKey: "question_1") != nil {
                    if user.value(forKey: "question_2") != nil {
                        for q in q_num_array! {
                            if ((questions[q] != user.value(forKey: "question_1") as! String) && (questions[q] != user.value(forKey: "question_2") as! String)) {
                                q_num = q
                                break
                            }
                        }
                    }
                    else {
                        for q in q_num_array! {
                            if (questions[q] != user.value(forKey: "question_1") as! String) {
                                q_num = q
                                break
                            }
                        }
                    }
                }
                else {
                    q_num = q_num_array![0]
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                return
            }
        }
        
        question = questions[q_num!]
        label.text = question
        
        recordingSession = AVAudioSession.sharedInstance()
        text.delegate = self
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() {
                [unowned self] allowed in DispatchQueue.main.async {
                    if allowed {
                        print("Accepted")
                    } else {}
                    }
                }
            }
        catch {
        }
        
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
                DispatchQueue.main.async {
                    if authStatus == .authorized {
                        print("Good to go!")
                    } else {
                        print("Transcription permission was declined.")
                    }
                }
            }

        let _ = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(question_complete), userInfo: nil, repeats: false)
    }
    
    func save() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Response", in: managedContext)!
        let response = NSManagedObject(entity: entity, insertInto: managedContext)
        let fetchRequest : NSFetchRequest<Key> = Key.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "username = %@", curr_user)
        
        if question_num == 1 {
            let fetchRequest2 : NSFetchRequest<User> = User.fetchRequest()
            fetchRequest2.predicate = NSPredicate(format: "username = %@", curr_user)
            
            do {
                let users = try managedContext.fetch(fetchRequest2)
                for user in users {
                    user.setValue(user.value(forKey: "question_1"), forKey: "question_2")
                    user.setValue(questions[q_num!], forKey: "question_1")
                    streak = find_streak(curr: user.value(forKey: "streak") as! Int, prev: user.value(forKey: "most_recent") as! Date, date: date)
                    user.setValue(date, forKey: "most_recent")
                    user.setValue(streak, forKey: "streak")
                }
            }
            catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                return
            }
        }
        
        do {
            let keys = try managedContext.fetch(fetchRequest)
            for key in keys {
                k = key.value(forKey: "key") as? String
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return
        }
        
        let key = SymmetricKey(data: Data(hexString: k)!)
        
        if !text.text.isEmpty {
            let cipher_data = try! ChaChaPoly.seal(Data(text.text.utf8), using: key).combined
            let cipher = cipher_data.hexEncodedString()
            
            response.setValue(date, forKey: "date")
            response.setValue(questions[q_num!], forKey: "question")
            response.setValue(cipher, forKey: "response")
            response.setValue(curr_user, forKey: "username")
        }
        
        if recorded {
            speech_to_text(url: getDocumentsDirectory().appendingPathComponent("recording.m4a"), key: key)
        }
        
        do {
            try managedContext.save()
            print("Saved successfully")
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func find_streak(curr: Int, prev: Date, date: Date) -> Int {
        let calendar = Calendar.current
        let new_date = calendar.date(byAdding: .day, value: 1, to: prev)
        let unitFlags: Set<Calendar.Component> = [.day, .month, .year]
        let components_1 = calendar.dateComponents(unitFlags, from: new_date!)
        let components_2 = calendar.dateComponents(unitFlags, from: date)
        let components_3 = calendar.dateComponents(unitFlags, from: prev)
        if components_1 == components_2 {
            return curr + 1
        }
        else if components_2 == components_3 {
            return curr
        }
        else{
            return 1
        }
    }
    
    func speech_to_text(url: URL, key: SymmetricKey) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error: \(error)")
                return
            }
            if result.isFinal {
                let bestResult = result.bestTranscription.formattedString
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Response", in: managedContext)!
                let response = NSManagedObject(entity: entity, insertInto: managedContext)
                
                let cipher_data = try! ChaChaPoly.seal(Data((bestResult).utf8), using: key).combined
                let cipher = cipher_data.hexEncodedString()
                
                response.setValue(date, forKey: "date")
                response.setValue(questions[q_num!], forKey: "question")
                response.setValue(cipher, forKey: "response")
                response.setValue(curr_user, forKey: "username")
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 1 {
            if textView.text[String.Index(encodedOffset: (textView.text.count - 1))] == "\n" {
                question_complete()
            }
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            button.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            button.setTitle("Tap to Re-Record", for: .normal)
            recorded = true
            question_complete()
        }
        else {
            displayAlert(title: "Oops!", message: "Recording failed")
            button.setTitle("Tap to Record", for: .normal)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func displayAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func nextQuestion(_ sender: Any){
        if answered {
            save()
            
            if question_num != 3 {
                let vc = storyboard?.instantiateViewController(withIdentifier: "question") as! QuestionViewController
                
                vc.q_num = 7+question_num!
                vc.question_num = question_num! + 1
                vc.curr_user = curr_user
                vc.date = date
                vc.streak = streak
                
                navigationController?.pushViewController(vc, animated: true)
            }
            else {
                let vc = storyboard?.instantiateViewController(withIdentifier: "congrats") as! CongratsViewController
                vc.curr_user = curr_user
                vc.text = "Congrats! You have now checked in with yourself \(streak!) days in a row. Have a great day!"
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            displayAlert(title: "Oops!", message: "You must type a response, record a response, or reflect for 30 seconds before continuing")
        }
    }
    
    @IBAction func record(_ sender: Any) {
        if audioRecorder == nil {
            startRecording()
        }
        else {
            finishRecording(success: true)
        }
    }
    
    @IBAction func playback(_ sender: Any) {
        let path = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }
        catch{
            displayAlert(title: "Oops!", message: "No audio to play!")
        }
    }

    @objc func tapDone(sender: Any) {
        question_complete()
        self.view.endEditing(true)
    }
    
    @objc func question_complete() {
        answered = true
        nextButton.setTitle("Continue", for: .normal)
    }
}
