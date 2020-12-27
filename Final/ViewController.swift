//
//  ViewController.swift
//  Final
//
//  Created by Sultan Isakov on 12/18/20.
//

import UIKit

struct Response: Codable{
    var originalWord: String
    var translation: String
}

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var list: UITableView!
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var AddButton: UIButton!
    @IBOutlet weak var ShowButton: UIButton!
    
    var words = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        list.delegate = self
        list.dataSource = self
        input.delegate = self

    }
    
    @IBAction func AddWord(_ sender: Any) {
        if input.text != "" {
            words.append(input.text!)
            self.list.reloadData()
            input.text = ""
        }

        input.resignFirstResponder()
    }
    
    
    @IBAction func ShowFullMsg(_ sender: Any) {
        let group = DispatchGroup()
        var localWords = [String]()
        for element in self.words {
            let val = UserDefaults.standard.object(forKey:element) as? String
            print(element)
            if val == nil {
                group.enter()
                getTranslation(element) { (success, error, translation) in
                    print("Succ english")
                    group.leave()
                    if !success {
                        DispatchQueue.main.async {
                            self.words.remove(at: self.words.firstIndex(of: element)!)
                            self.list.reloadData()
                        }
                        return
                    }
                    print("Success")
                    UserDefaults.standard.set(translation, forKey: element)
                    localWords.append(translation!)
                }
                
            }else{
                localWords.append(val!)
            }
        }
        print("words")
        print(localWords)
        group.notify(queue: .main) {
            self.showAlert("Translation", localWords.joined(separator: " "))
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        cell.textLabel?.text = words[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedWord = words[indexPath.row]
        let translation = UserDefaults.standard.object(forKey:selectedWord) as? String
        if (translation != nil) {
            print("Translation From UserDefaults")
            DispatchQueue.main.async {
                self.showAlert("Translation", translation!)
            }
        }
        else{
            print(type(of: selectedWord))
            getTranslation(selectedWord) { (success, error, translation) in
                if !success{
                    DispatchQueue.main.async {
                        self.words.remove(at: indexPath.row)
                        self.list.deleteRows(at: [indexPath], with: .automatic)
                    }
                    return
                }
            
                UserDefaults.standard.set(translation, forKey: selectedWord)
                DispatchQueue.main.async {
                    self.showAlert("Translation", translation!)
                }
                return
            }
        }
    }
}


extension ViewController {
    
    func showAlert(_ title: String, _ text: String){
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if input.text != "" {
            words.append(input.text!)
            self.list.reloadData()
            input.text = ""
        }
        input.resignFirstResponder()
        return true
    }
    
    func getTranslation(_ word: String!, completion:@escaping (_ success:Bool,_ error:Error?, _ _data: String?)->Void) -> () {
        if let url = URL(string: "https://aucatranslator.azurewebsites.net/api/v1/wordtranslation/?word=\(word!)") {

            let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                let status = (response as! HTTPURLResponse).statusCode
                if error != nil || status == 404  {
                    return completion(false, nil, nil)
                }
                
                if let data = data {
                    if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
                        return completion(true, nil, decodedResponse.translation)
                    }
                }
                
            })
            task.resume()
        } else{
            return
        }
    }
}
    
