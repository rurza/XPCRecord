//
//  AppDelegate.swift
//  XPCRecordUIAgent
//
//  Created by Adam Różyński on 14/08/2024.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var server = Server()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        server.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

