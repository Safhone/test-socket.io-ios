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
    var dic = Dictionary<String, AnyObject>()
    
    var socket = SocketIOClient(socketURL: URL(string: "http://127.0.0.1:9090")!, config:[.log(false), .forceWebsockets(true), .nsp("/vote")])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        questionAnswerTableView.delegate           = self
        questionAnswerTableView.dataSource         = self
        questionAnswerTableView.tableFooterView    = UIView()
        questionAnswerTableView.estimatedRowHeight = 100
        questionAnswerTableView.rowHeight          = UITableView.automaticDimension
        questionAnswerTableView.separatorInset     = .zero
        
        fetchData()
        
        socket.connect()
        
        socket.on(clientEvent: .connect) { data, ack in
            print("Connected to Socket server")
            self.statusLabel.text = "Socket server: Connected"
            self.statusLabel.textColor = UIColor.blue
        }

        socket.on("disconnect") { data, ack in
            print("Disconnected from Socket server")
            self.statusLabel.text = "Socket server: Not Connected"
            self.statusLabel.textColor = UIColor.red
        }
        
        socket.on("onVote") { (data, ack) in
            self.dic = data.first as! [String : AnyObject]
            self.questionAnswerTableView.reloadData()
        }
        
    }
    
    @objc private func voteAction() {
        if let cell = self.questionAnswerTableView.indexPathForSelectedRow {
            self.tableView(self.questionAnswerTableView, didDeselectRowAt: cell)
            let answers = dic["answers"] as! NSArray
            var answer = answers[cell.row] as! Dictionary<String, AnyObject>
            
            let body = [
                "ANSWER_UUID" : answer["answer_uuid"]
            ] as [String : AnyObject]
            
            insertData(body: body)
        }
    }
    
    private func insertData(body: [String : AnyObject]) {
        API.shared.fetch(url: "http://localhost:8080/api/insert-vote", body: body) { (response) in
            switch response {
            case .success(_): break
            case .error(_): break
            }
        }
    }
    
    private func fetchData() {
        API.shared.fetch(url: "http://localhost:8080/api/find-question-answer", body: [:]) { (response) in
            switch response {
            case .success(let data):
                self.dic = data.object(forKey: "DATA") as! Dictionary<String, AnyObject>
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
            return dic["answers"]!.count
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
            questionCell.questionLabel.text = dic["question"] as? String
            questionCell.isUserInteractionEnabled = false
            return questionCell
        case 1:
            let answerCell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath) as! AnswerTableViewCell
            let answers = dic["answers"] as! NSArray
            var answer = answers[indexPath.row] as! Dictionary<String, AnyObject>
            answerCell.voteLabel.text = answer["count_vote"] as? String
            answerCell.answerLabel.text = answer["answer"] as? String
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
        return UITableView.automaticDimension > 60 ? UITableView.automaticDimension : 60
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
