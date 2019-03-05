//
//  CreateWallet.swift
//  WalletDemo
//
//  Created by neosoft on 2019/03/05.
//  Copyright © 2019 neosoft. All rights reserved.
//

import UIKit

class CreateWalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var walletTableView:UITableView?
    var wallets = ["monaアカウントを見る", "xrpアカウントを見る"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        walletTableView?.delegate = self
        walletTableView?.dataSource = self
    }
    
    @IBAction func createMona() {
        
    }
    
    @IBAction func createXRP() {
        
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel!.text = wallets[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
}
