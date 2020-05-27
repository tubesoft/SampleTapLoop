//
//  InfoViewController.swift
//  SampleTapLoop
//
//  Created by Takatomo Inoue on 5/26/20.
//  Copyright © 2020 Takatomo INOUE. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = NSLocalizedString("InfoText", comment: "")
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
