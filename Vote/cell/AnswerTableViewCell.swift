//
//  AnswerTableViewCell.swift
//  Vote
//
//  Created by Safhone on 9/13/18.
//  Copyright © 2018 KOSIGN. All rights reserved.
//

import UIKit

class AnswerTableViewCell: UITableViewCell {

    @IBOutlet weak var voteLabel    : UILabel!
    @IBOutlet weak var answerLabel  : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
