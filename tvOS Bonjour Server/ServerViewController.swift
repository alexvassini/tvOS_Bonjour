//
//  ServerViewController.swift
//  tvOS Bonjour Server
//
//  Created by BEPID on 03/08/17.
//  Copyright © 2017 Alexandre  Vassinievski. All rights reserved.
//

import UIKit

class ServerViewController: UIViewController {

    @IBOutlet weak var messageView: MessageField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bounjourHandler()

        // Do any additional setup after loading the view.
    }

    
    func bounjourHandler(){
        
        BonjourTCPServer.sharedInstance.dataReceivedCallback = {(data) in
            
            print(data)
            
            self.messageView.text = data
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
