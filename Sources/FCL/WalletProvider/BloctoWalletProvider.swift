//
//  BloctoWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import FlowSDK
import BloctoSDK
import SwiftyJSON
import Cadence

public final class BloctoWalletProvider: WalletProvider {

    var bloctoFlowSDK: BloctoFlowSDK
    public let providerInfo: ProviderInfo = ProviderInfo(
        title: "Blocto",
        desc: nil,
        icon: URL(string: "https://fcl-discovery.onflow.org/images/blocto.png")
    )
    let bloctoAppIdentifier: String
    let isTestnet: Bool

    private var bloctoAppScheme: String {
        if isTestnet {
            return "blocto-staging://"
        } else {
            return "blocto://"
        }
    }

    /// Initial wallet provider
    /// - Parameters:
    ///   - bloctoAppIdentifier: identifier from app registered in blocto developer dashboard.
    ///        testnet dashboard: https://developers-staging.blocto.app/
    ///        mannet dashboard: https://developers.blocto.app/
    ///   - window: used for presenting webView if no Blocto app installed. If pass nil then we will get the top ViewContoller from keyWindow.
    ///   - testnet: indicate flow network to use.
    public init(
        bloctoAppIdentifier: String,
        window: UIWindow?,
        testnet: Bool
    ) throws {
        self.bloctoAppIdentifier = bloctoAppIdentifier
        guard let window = window ?? Self.getKeyWindow() else {
            throw FCLError.walletProviderInitFailed
        }
        self.isTestnet = testnet
        BloctoSDK.shared.initialize(
            with: bloctoAppIdentifier,
            window: window,
            logging: true,
            testnet: testnet
        )
        self.bloctoFlowSDK = BloctoSDK.shared.flow
    }

    /// Ask user to authanticate and get flow address along with account proof if provide accountProofData
    /// - Parameter accountProofData: AccountProofData used for proving a user controls an on-chain account, optional.
    public func authn(accountProofData: FCLAccountProofData?) async throws {
        if let bloctoAppSchemeURL = URL(string: bloctoAppScheme),
           await UIApplication.shared.canOpenURL(bloctoAppSchemeURL) {
            // blocto app installed
            try await setupUserByBloctoSDK(accountProofData)
        } else {
            // blocto app not install
            // TODO: imcomplete
        }
    }

    public func authz() async throws -> String {
        // TODO: implementation
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
//        BloctoSDK.
        return ""
    }

    public func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature] {
        // TODO: implementation
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
        return []
    }

    public func preAuthz() async throws {
        // TODO: implementation
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
    }

    // TODO: implementation
//    func openId() async throws -> JSON {}

    public func backChannelRPC() async throws {
        // TODO: implementation
    }

    private static func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter(\.isKeyWindow).first
    }

    private func topViewController(from window: UIWindow) -> UIViewController? {
        var topController: UIViewController?
        while let presentedViewController = window.rootViewController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

    private func setupUserByBloctoSDK(_ accountProofData: FCLAccountProofData?) async throws {
        let (address, accountProof): (String, AccountProofSignatureData?) = try await withCheckedThrowingContinuation { continuation in
            var bloctoAccountProofData: FlowAccountProofData?
            if let accountProofData = accountProofData {
                bloctoAccountProofData = FlowAccountProofData(
                    appId: accountProofData.appId,
                    nonce: accountProofData.nonce
                )
            }
            bloctoFlowSDK.authanticate(accountProofData: bloctoAccountProofData) { result in
                switch result {
                case let .success((address, accountProof)):
                    if let fclAccountProofData = accountProofData {
                        let fclAccountProofSignatures = accountProof.map {
                            FCLCompositeSignature(
                                address: $0.address,
                                keyId: $0.keyId,
                                signature: $0.signature
                            )
                        }
                        let accountProofSignatureData = AccountProofSignatureData(
                            address: Address(hexString: address),
                            nonce: fclAccountProofData.nonce,
                            signatures: fclAccountProofSignatures
                        )
                        continuation.resume(returning: (address, accountProofSignatureData))
                    } else {
                        continuation.resume(returning: (address, nil))
                    }
                case let .failure(error):
                    continuation.resume(throwing: FCLError.authnFailed(message: error.localizedDescription))
                }
            }
        }

        fcl.currentUser = User(
            address: Address(hexString: address),
            accountProof: accountProof,
            loggedIn: true,
            expiresAt: 0,
            services: []
        )
    }

}
