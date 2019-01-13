//
//  ViewController.swift
//  monawallet
//
//  Created by Chen Yonghui on 2019/1/11.
//  Copyright © 2019 udspj. All rights reserved.
//

import UIKit
import BRCore

private let lastBlockHeightKey = "LastBlockHeightKey"
private let progressUpdateInterval: TimeInterval = 0.5
private let updateDebounceInterval: TimeInterval = 0.4

class ViewController: UIViewController {
    fileprivate let store = Store()
    fileprivate var walletManager: WalletManager?
    private var didInitWallet = false
    
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var balanceLabel: UILabel!
    
    @IBOutlet var syncStateLabel: UILabel!
    @IBOutlet var syncProgressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        DispatchQueue.walletQueue.async {
            guardProtected(queue: DispatchQueue.walletQueue) {
                self.initWallet()
            }
        }
    }
    
    private func initWallet() {
        self.walletManager = try? WalletManager(store: self.store, dbPath: nil)
        
        let _ = self.walletManager?.wallet //attempt to initialize wallet
        DispatchQueue.main.async {
            self.didInitWallet = true
            self.didInitWalletManager()
            
        }
    }
    
    private func didInitWalletManager() {
        guard let walletManager = walletManager else { assert(false, "WalletManager should exist!"); return }
        
        addWalletObservers()
        
        if UIApplication.shared.applicationState != .background {
            if walletManager.noWallet {
                createWallet()
            } else {
                DispatchQueue.walletQueue.async {
                    walletManager.peerManager?.connect()
                }
                let add = self.walletManager?.wallet?.receiveAddress
                print("wallet address:\(add!)")
                addressLabel.text = self.walletManager?.wallet?.receiveAddress;
            }
        }
    }
    
    
    private func createWallet() {
        let phrase = self.walletManager?.setRandomSeedPhrase();
        print("phrase \(phrase!)")
        DispatchQueue.walletQueue.async {
            self.walletManager?.peerManager?.connect()
            
            DispatchQueue.main.async {
                self.didCreateOrRecoverWallet()
            }
        }
    }
    
    private func didCreateOrRecoverWallet()
    {
        let receiveAddress = self.walletManager?.wallet?.receiveAddress;

        print("address: \(receiveAddress!)")
        addressLabel.text = receiveAddress
        
    }
    
    
    private func SetSyncProgess(progress: Double, timestamp: UInt32)
    {
        //update UI
        syncProgressView.progress = Float(progress)
        
    }
    
    func setTransactions(transactions: [Transaction])  {
        //update UI
        print("transactions")
        let rate = Rate.init(code: "CNY", name: "RMB", rate: 9)
        
        for tx in transactions {
            let attributedText = tx.descriptionString(isBtcSwapped: false, rate: rate, maxDigits: 8)

            let address = String(format: tx.direction.addressTextFormat, tx.toAddress ?? "")
            let status = tx.status
//            comment.text = transaction.comment
            let availability = tx.shouldDisplayAvailableToSpend ? S.Transaction.available : ""
            print("\(attributedText.string) \(address) \(status) \(availability)")
        }
    }
    
    private func showReceived(amount: UInt64) {
        print("received: \(amount)")
    }


    private func addWalletObservers()
    {
        NotificationCenter.default.addObserver(forName: .WalletBalanceChangedNotification, object: nil, queue: nil, using: { note in
            self.updateBalance()
            self.requestTxUpdate()
        })
        
        NotificationCenter.default.addObserver(forName: .WalletTxStatusUpdateNotification, object: nil, queue: nil, using: {note in
            self.requestTxUpdate()
        })
        
        NotificationCenter.default.addObserver(forName: .WalletSyncStartedNotification, object: nil, queue: nil, using: {note in
            self.onSyncStart()
        })
        
        NotificationCenter.default.addObserver(forName: .WalletSyncStoppedNotification, object: nil, queue: nil, using: {note in
            self.onSyncStop(notification: note)
        })
    }
    
    private func requestTxUpdate() {
        if updateTimer == nil {
            updateTimer = Timer.scheduledTimer(timeInterval: updateDebounceInterval, target: self, selector: #selector(updateTransactions), userInfo: nil, repeats: false)
        }
    }
    
    @objc private func updateTransactions() {
        updateTimer?.invalidate()
        updateTimer = nil
        DispatchQueue.walletQueue.async {
            guard let txRefs = self.walletManager?.wallet?.transactions else { return }
            let transactions = self.makeTransactionViewModels(transactions: txRefs, walletManager: self.walletManager!,  rate: nil)

            if transactions.count > 0 {
                DispatchQueue.main.async {
                    self.setTransactions(transactions: transactions)
                }
            }
        }
    }
    
    func makeTransactionViewModels(transactions: [BRTxRef?], walletManager: WalletManager, rate: Rate?) -> [Transaction] {
        
        let t = transactions.flatMap{ $0 }.sorted {
            if $0.pointee.timestamp == 0 {
                return true
            } else if $1.pointee.timestamp == 0 {
                return false
            } else {
                return $0.pointee.timestamp > $1.pointee.timestamp
            }
            }
        return t.flatMap {
            return Transaction($0, walletManager: walletManager, rate: rate)
        }
    }
    
    
    
    private var updateTimer: Timer?
    private var progressTimer: Timer?
    private let defaults = UserDefaults.standard
    var walletState = WalletState.initial

    private var lastBlockHeight: UInt32 {
        set {
            defaults.set(newValue, forKey: lastBlockHeightKey)
        }
        get {
            return UInt32(defaults.integer(forKey: lastBlockHeightKey))
        }
    }
    
    private func updateBalance() {
        DispatchQueue.walletQueue.async {
            guard let newBalance = self.walletManager?.wallet?.balance else { return }
            DispatchQueue.main.async {
                self.checkForReceived(newBalance: newBalance)
                self.walletState.balance = newBalance
                self.balanceLabel.text = String(newBalance)
            }
        }
    }
    
    private func checkForReceived(newBalance: UInt64) {
        if let oldBalance = walletState.balance {
            if newBalance > oldBalance {
                if walletState.syncState == .success {
                    self.showReceived(amount: newBalance - oldBalance)
                }
            }
        }
    }
    
    
    @objc private func updateProgress() {
        DispatchQueue.walletQueue.async {
            guard let progress = self.walletManager?.peerManager?.syncProgress(fromStartHeight: self.lastBlockHeight), let timestamp = self.walletManager?.peerManager?.lastBlockTimestamp else { return }
            DispatchQueue.main.async {
                self.SetSyncProgess(progress: progress, timestamp: timestamp)
            }
        }
        self.updateBalance()
    }
    
    private func onSyncStart() {

        progressTimer = Timer.scheduledTimer(timeInterval: progressUpdateInterval, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
        walletState.syncState = .syncing
        syncStateLabel.text = "Syncing"
        startActivity()
    }
    
    private func onSyncStop(notification: Notification) {
        
        if notification.userInfo != nil {
            guard let code = notification.userInfo?["errorCode"] else { return }
            guard let message = notification.userInfo?["errorDescription"] else { return }
            walletState.syncState = .connecting
            syncStateLabel.text = "Sync Connecting"
            endActivity()
            print("error code:\(code) message:\(message)")
            return
        }
        
        if let height = self.walletManager?.peerManager?.lastBlockHeight {
            self.lastBlockHeight = height
        }
        progressTimer?.invalidate()
        progressTimer = nil
        walletState.syncState = .success
        syncStateLabel.text = "Sync Success"
        endActivity()
    }
    
    private func startActivity() {
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    private func endActivity() {
        UIApplication.shared.isIdleTimerDisabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    @IBAction func sendBtnClick() {
        let amount = 10000000
        let to = "mkniG9zf4gHhpygcukWp9RkTswmxDxEMfJ"
        self.walletManager?.spendingLimit = UInt64(100000000)
        var tx = self.walletManager?.wallet?.createTransaction(forAmount: UInt64(amount), toAddress: to)
        
        DispatchQueue.walletQueue.async { [weak self] in
            guard let myself = self else { assert(false, "myelf didn't exist"); return }

            if (myself.walletManager?.signTransaction(tx!, pin: ""))! {
                myself.walletManager?.peerManager?.publishTx(tx!, completion: { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
//                            completion(.publishFailure(error))
                            print("error \(error)")
                        } else {
//                            myself.setMetaData()
//                            completion(.success)
                        }
                    }
                })
                
                
            }
        }
        
        
    }
    
    func publishTx(tx:BRTxRef)  {
        
    }
}


enum SyncState {
    case syncing
    case connecting
    case success
}

struct WalletState {
    var isConnected: Bool
    var syncProgress: Double
    var syncState: SyncState
    var balance: UInt64?
//    let transactions: [Transaction]
    var lastBlockTimestamp: UInt32
    var name: String
    var creationDate: Date
    var isRescanning: Bool
    
    static var initial: WalletState {
        return WalletState(isConnected: false, syncProgress: 0.0, syncState: .success, balance: nil, lastBlockTimestamp: 0, name: S.AccountHeader.defaultWalletName, creationDate: Date(), isRescanning: false)
    }
}
