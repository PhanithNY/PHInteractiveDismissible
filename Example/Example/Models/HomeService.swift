//
//  HomeService.swift
//  Example
//
//  Created by Codex on 13/7/26.
//

import Foundation

enum HomeService: CaseIterable {
  case accounts
  case topUp
  case payBills
  case transfer

  var title: String {
    switch self {
    case .accounts: "Accounts"
    case .topUp: "Top Up"
    case .payBills: "Pay Bills"
    case .transfer: "Transfer"
    }
  }

  var symbolName: String {
    switch self {
    case .accounts: "tray"
    case .topUp: "iphone.and.arrow.forward"
    case .payBills: "doc.text"
    case .transfer: "arrow.up"
    }
  }

  var subtitle: String {
    switch self {
    case .accounts:
      "See your balances, recent activity, and account details in one place."
    case .topUp:
      "Add credit to your phone instantly from any eligible account."
    case .payBills:
      "Pay utilities and everyday bills without leaving the app."
    case .transfer:
      "Send money securely to your contacts or another bank account."
    }
  }

  var actionTitle: String {
    switch self {
    case .accounts: "View accounts"
    case .topUp: "Start top up"
    case .payBills: "Choose a biller"
    case .transfer: "Make a transfer"
    }
  }

  var highlights: [(title: String, subtitle: String, symbolName: String)] {
    switch self {
    case .accounts:
      [
        ("Everyday account", "Available balance and activity", "creditcard"),
        ("Savings", "Goals and interest summary", "banknote"),
        ("Statements", "Download recent statements", "doc.text")
      ]
    case .topUp:
      [
        ("My number", "Top up your saved mobile number", "person.crop.circle"),
        ("Another number", "Send credit to friends or family", "person.2"),
        ("Recent top ups", "Repeat a previous payment", "clock.arrow.circlepath")
      ]
    case .payBills:
      [
        ("Utilities", "Electricity and water", "bolt"),
        ("Internet & TV", "Home and entertainment services", "wifi"),
        ("Recent billers", "Quickly pay saved providers", "clock.arrow.circlepath")
      ]
    case .transfer:
      [
        ("Atlas account", "Transfer between your accounts", "arrow.left.arrow.right"),
        ("Local bank", "Send to another bank", "building.columns"),
        ("Saved recipients", "Pay someone you know", "person.2")
      ]
    }
  }
}
