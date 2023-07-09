//
//  GemsManager.swift
//  Musicos
//
//  Created by mac on 01/12/2020.
//  Copyright © 2020 Nicolas Klarsfeld. All rights reserved.
//

import Foundation
import KeychainAccess

enum GemsManagerError: Error {
    case insufficientFunds(coinsNeeded: Int)
    case invalidKey(key: String)
}

class GemsManager {
    let keychain = Keychain(service: "m6yQpvRTffyizPODLSfi6awxZNToq4xuDGS1WPtRgPE")
    
    func setGems(_ n: Int) {
        keychain[globalVar.userId] = String(n)
    }
    
    func getGems() throws -> Int {
        if let s = keychain[globalVar.userId] {
            return Int(s)!
        } else {
            throw GemsManagerError.invalidKey(key: globalVar.userId)
        }
    }
    
    func addGems(_ n: Int) throws {
        if (n < 0) {
            try! subGems(-n)
        }
        if let s = keychain[globalVar.userId] {
            keychain[globalVar.userId] = String(Int(s)! + n)
        } else {
            throw GemsManagerError.invalidKey(key: globalVar.userId)
        }
    }
    
    func subGems(_ n: Int) throws {
        if (n < 0) {
            try! addGems(-n)
        }
        if let s = keychain[globalVar.userId] {
            let currentGems = Int(s)!
            if currentGems < n {
                throw GemsManagerError.insufficientFunds(coinsNeeded: n - currentGems)
            } else {
                keychain[globalVar.userId] = String(currentGems - n)
            }
        } else {
            throw GemsManagerError.invalidKey(key: globalVar.userId)
        }
    }
    
    func setVariable(_ key: String, _ value: String){
        keychain[key] = value
    }
    
    func getVariable(_ key: String) -> String? {
        return keychain[key]
    }
}
