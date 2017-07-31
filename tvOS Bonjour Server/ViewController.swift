//
//  ViewController.swift
//  tvOS Bonjour Server
//
//  Created by Alexandre  Vassinievski on 28/07/17.
//  Copyright © 2017 Alexandre  Vassinievski. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bounjourHandler()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func bounjourHandler(){
        
        BonjourTCPServer.sharedInstance.dataReceivedCallback = {(data) in
            
            print(data)
            
            self.textView.text = data
            
        }
    }
    
}

