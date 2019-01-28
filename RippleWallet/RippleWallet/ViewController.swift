//
//  ViewController.swift
//  RippleWallet
//
//  Created by Chen Yonghui on 2019/1/20.
//  Copyright © 2019 udspj. All rights reserved.
//

import UIKit

import CryptoSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        Ripple.RunTest()
        generateAddress()
        recoverAddress()
    }
    
    func generateAddress() {
        let seed = Ripple.GenerateSeed()
        let secret = Ripple.EncodeSeed(seed!, method: KeyType.secp256k1)
        let keypair = KeyPair.deriveKeypair(seed: seed!);
        let address = Ripple.GetRippleAddress(Data(hex: keypair.publicKey))
        print("generate ripple account: \n  secret:\(secret)\n  address:\(address)")
    }
    
    func recoverAddress()  {
        let secret = "ssTdSmKzF4g8Gu7FTmiiiByMxynJ3"
        let seed = Ripple.DecodeSeed(secret)
        let keypair = KeyPair.deriveKeypair(seed: seed);
        let address = Ripple.GetRippleAddress(Data(hex: keypair.publicKey))
        print("recover ripple account: \n  secret:\(secret)\n  address:\(address)")
    }
}

enum KeyType {
    case secp256k1
    case ed25519
}

struct KeyPair {
    
    public let privateKey : String
    public let publicKey : String
    
    public init(pri:String, pub:String) {
        privateKey = pri
        publicKey = pub
    }
    
    static let curveOrder = BInt(hex: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")!

    public static func deriveKeypair(seed:Data) -> KeyPair {
        let prefix = "00";
        let pk = derivePrivateKey(seed)
        let _privateKey = prefix + pk.toHexString().uppercased()
        let _publicKey = Crypto.generatePublicKey(data: pk, compressed: true).toHexString().uppercased()
        
        return KeyPair(pri: _privateKey, pub:_publicKey)
    }
    
    static func deriveScalar(_ bytes:Data, _ discrim: UInt32?) -> Data {
        
        for i in 0...0xFFFFFFFF {
            var buf = bytes
            if discrim != nil {
                var d = discrim!
                buf = buf + Data(bytes: &d, count: MemoryLayout<UInt32>.size)
            }
            var seq:UInt32 = UInt32(i);
            buf = buf + Data(bytes: &seq, count: MemoryLayout<UInt32>.size)
            
            let halfSha512 = buf.sha512()[0..<32]
            let privKey = BInt(data:halfSha512)
            
            if privKey > 0 &&  privKey < curveOrder {
                return halfSha512
            }
        }
        
        return Data()
    }
    
    static func derivePrivateKey(_ seed:Data) -> Data {
        let privateGen = deriveScalar(seed, nil)
        // if root { return privateGen }
        
        let publicGen = Crypto.generatePublicKey(data: privateGen, compressed: true)
        let accountIndex : UInt32 = 0
        let key = (BInt(data: deriveScalar(publicGen, accountIndex)) + BInt(data: privateGen)) % curveOrder
        
        return key.data
    }
}

class Ripple {
    // MARK: Seed
    public static func GenerateSeed() -> Data? {
        
        let bytesCount = 16
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        if status == errSecSuccess {
            return Data(bytes: randomBytes)
        }
        return nil
    }
    
    public static func DecodeSeed(_ sec : String) -> Data {
        let data = sec.base58DecodedData!;
        switch data.first {
        case 33: // secp256k1
            return data.dropLast(4).dropFirst()
        case 1: // ed25519
            return data.dropLast(4).dropFirst(3)
        default:
            return data
        }
    }
    
    public static func EncodeSeed(_ seed : Data, method : KeyType) -> String {
        var version = Data([33]) //0x21
        if method == .ed25519 {
            version = Data([0x01, 0xE1, 0x4B])
        }
        
        let payload = version + seed
        let checksum = payload.doubleSHA256.prefix(4)
        let address = Base58.encode(payload + checksum)
        return address
    }
    
    // MARK: - Public Key
    
    public static func GetRippleAddress(_ publicKey:Data) -> String {
        let prefix = Data([0x00])
        let accountId = RIPEMD160.hash(publicKey.sha256())
        
        let payload = prefix + accountId
        let checksum = payload.doubleSHA256.prefix(4)
        let address = Base58.encode(payload + checksum)
        
        return address
    }
    
    // MARK: Test
    
    public static func RunTest() {
        TestRippleAddress()
        RippleAddressCodecTest()
        TestPublicKey()
    }
    
    // tests
    static func TestRippleAddress()  {
        
        let add1 = GetRippleAddress(Data(hex: "0xED9434799226374926EDA3B54B1B461B4ABF7237962EAE18528FEA67595397FA32"))
        guard add1 == "rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBhmN" else {
            fatalError()
        }
        
        let add2 = GetRippleAddress(Data(hex: "0303E20EC6B4A39A629815AE02C0A1393B9225E3B890CAE45B59F42FA29BE9668D"))
        guard add2 == "rnBFvgZphmN39GWzUJeUitaP22Fr9be75H" else {
            fatalError()
        }
        
    }
    
    static func RippleAddressCodecTest() {
        /*
         > api.decodeSeed('sEdTM1uX8pu2do5XvTnutH6HsouMaM2')
         { version: [ 1, 225, 75 ],
         bytes: [ 76, 58, 29, 33, 63, 189, 251, 20, 199, 194, 141, 96, 148, 105, 179, 65 ],
         type: 'ed25519' }
         */
        
        //        print("sEdTM1uX8pu2do5XvTnutH6HsouMaM2")
        let seed1 = DecodeSeed("sEdTM1uX8pu2do5XvTnutH6HsouMaM2")
        //        print(seed1.bytes)
        guard EncodeSeed(seed1, method: .ed25519) == "sEdTM1uX8pu2do5XvTnutH6HsouMaM2" else {fatalError()}
        
        /*
         > api.decodeSeed('sn259rEFXrQrWyx3Q7XneWcwV6dfL')
         { version: 33,
         bytes: [ 207, 45, 227, 120, 251, 221, 126, 46, 232, 125, 72, 109, 251, 90, 123, 255 ],
         type: 'secp256k1' }
         */
        //        print("sn259rEFXrQrWyx3Q7XneWcwV6dfL")
        let seed2 = DecodeSeed("sn259rEFXrQrWyx3Q7XneWcwV6dfL")
        //        print(seed2.bytes)
        guard EncodeSeed(seed2, method: .secp256k1) == "sn259rEFXrQrWyx3Q7XneWcwV6dfL" else {fatalError()}
    }
    
    static func TestPublicKey()
    {
        //Secret: ssTdSmKzF4g8Gu7FTmiiiByMxynJ3
        
        //keypair
        // privateKey 00D5F6E04F396A35FDABBF2CE8658141153C1EA042B83DFF0EBD6C8303F87C209B
        // publicKey 0231A2C027EA4F2856CD50A11E08351400465AB51DDDA726FCA6B86915C8ADA058
        
        //Address: r3Tn1Gdvc329aDhFdtUVBuRJGPYhg7sV4u
        let seed = DecodeSeed("ssTdSmKzF4g8Gu7FTmiiiByMxynJ3")
        
        // keypair
        let keypair = KeyPair.deriveKeypair(seed: seed)
        print(keypair.privateKey)
        print(keypair.publicKey)
        
        let addr = GetRippleAddress(Data(hex: keypair.publicKey))
        print(addr)
    }
}

