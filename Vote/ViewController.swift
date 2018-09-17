//
//  ViewController.swift
//  Vote
//
//  Created by Safhone on 9/13/18.
//  Copyright © 2018 KOSIGN. All rights reserved.
//

import UIKit
import SocketIO

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var questionAnswerTableView: UITableView!
    var dic = [Dictionary<String, String>]()
    
    var socket = SocketIOClient(socketURL: URL(string: "http://127.0.0.1:9090")!, config:[.log(false), .forceWebsockets(true), .nsp("/vote")])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetch()
        
        self.questionAnswerTableView.delegate           = self
        self.questionAnswerTableView.dataSource         = self
        self.questionAnswerTableView.tableFooterView    = UIView()
        self.questionAnswerTableView.estimatedRowHeight = 100
        self.questionAnswerTableView.rowHeight          = UITableViewAutomaticDimension
        self.questionAnswerTableView.separatorInset     = .zero
        
        socket.connect()
        
        socket.on(clientEvent: .connect) { data, ack in
            print("Connected to Socket server")
            self.statusLabel.text = "Connected"
            self.statusLabel.textColor = UIColor.blue
        }

        socket.on("disconnect") { data, ack in
            print("Disconnected from Socket server")
            self.statusLabel.text = "Not Connected"
            self.statusLabel.textColor = UIColor.red
        }
        
        socket.on("onVote") { (data, ack) in
            self.dic = data.first as! [Dictionary<String, String>]
            self.questionAnswerTableView.reloadData()
        }
        
    }
    
    @objc func voteAction() {
        let cell = self.questionAnswerTableView.indexPathForSelectedRow
        print("===============", dic[(cell?.row)!]["answerUUID"]!)
        let body = [
            "ANSWER_UUID" : dic[(cell?.row)!]["answerUUID"] ?? ""
        ]
        
        API.shared.fetch(url: "http://localhost:8080/api/insert-vote", body: body as [String : AnyObject], method: "POST") { (response) in
            switch response {
            case .success(_):
                self.tableView(self.questionAnswerTableView, didDeselectRowAt: cell!)
            case .error(_): break
            }
        }
    }
    
    func fetch() {
        API.shared.fetch(url: "http://localhost:8080/api/find-question-answer", body: [:], method: "POST") { (response) in
            switch response {
            case .success(let data):
                self.dic = data.object(forKey: "data") as! Array<Dictionary<String, String>>
                
                DispatchQueue.main.async {
                    self.questionAnswerTableView.reloadData()
                }
                
            case .error(_): break
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dic.count == 0 { return 0 }
        switch section {
        case 0:
            return 1
        case 1:
            return dic.count
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0:
            let questionCell = tableView.dequeueReusableCell(withIdentifier: "questionCell", for: indexPath) as! QuestionTableViewCell
            questionCell.questionLabel.text = dic[0]["question"]
            questionCell.isUserInteractionEnabled = false
            return questionCell
        case 1:
            let answerCell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableViewCell
            answerCell.voteLabel.text = dic[indexPath.row]["countVote"]
            answerCell.answerLabel.text = dic[indexPath.row]["answer"]
            return answerCell
        case 2:
            let voteCell = tableView.dequeueReusableCell(withIdentifier: "voteCell", for: indexPath) as! VoteTableViewCell
            voteCell.voteButton.addTarget(self, action: #selector(voteAction), for: .touchUpInside)
            return voteCell
        default:
            return UITableViewCell()
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension > 60 ? UITableViewAutomaticDimension : 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.section == 1 {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            DispatchQueue.main.async {
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            }
            
        }
        
    }
    
}
