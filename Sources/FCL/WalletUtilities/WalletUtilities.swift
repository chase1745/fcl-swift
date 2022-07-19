//
//  WalletUtilities.swift
//  
//
//  Created by Andrew Wang on 2022/7/11.
//

import FlowSDK

public enum WalletUtilities {
    
    public static func encodeAccountProof(
        address: String,
        nonce: String,
        appIdentifier: String,
        includeDomainTag: Bool
    ) -> String {
        let accountProofData: RLPEncodable = [
            appIdentifier,
            Data(hex: String(address.dropFirst(2))),
            Data(hex: nonce),
        ]
        if includeDomainTag {
            return (DomainTag.accountProof.rightPaddedData + accountProofData.rlpData).toHexString()
        } else {
            return accountProofData.rlpData.toHexString()
        }
    }
    
}