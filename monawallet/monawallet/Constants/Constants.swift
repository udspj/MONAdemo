//
//  Constants.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-24.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

let π: CGFloat = .pi

struct Padding {
    subscript(multiplier: Int) -> CGFloat {
        get {
            return CGFloat(multiplier) * 8.0
        }
    }
}

struct C {
    static let padding = Padding()
    struct Sizes {
        static let buttonHeight: CGFloat = 48.0
        static let headerHeight: CGFloat = 48.0
        static let largeHeaderHeight: CGFloat = 220.0
        static let logoAspectRatio: CGFloat = 125.0/417.0
    }
    static var defaultTintColor: UIColor = {
        return UIView().tintColor
    }()
    static let animationDuration: TimeInterval = 0.3
    static let secondsInDay: TimeInterval = 86400
    static let maxMoney: UInt64 = 105120000*100000000
    static let satoshis: UInt64 = 100000000
    static let walletQueue = "jp.pronama.walletqueue"
    static let btcCurrencyCode = "MONA"
    static let null = "(null)"
    static let maxMemoLength = 250
    static let feedbackEmail = "support@monawallet.net"
    static let reviewLink = "https://itunes.apple.com/app/monawallet/id1343235820?action=write-review"
    static var standardPort: Int {
        return E.isTestnet ? 19403 : 9401
    }
}

struct AppVersion {
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    static let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    static let string = "v." + versionNumber! + " (\(buildNumber!))"
}
