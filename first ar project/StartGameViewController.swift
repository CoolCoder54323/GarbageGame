//
//  StartGameViewController.swift
//  first ar project
//
//  Created by Nicholas Dixon on 1/7/18.
//  Copyright © 2018 Nicholas Dixon. All rights reserved.
//

import UIKit

class StartGameViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.setTitle("Start!", for: .normal)
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

