//
//  main.swift
//  icalswift
//
//  Created by Sergei A. Fedorov on 23.04.2020.
//  Copyright © 2020 Sergei A. Fedorov. All rights reserved.
//

import Foundation
import Foundation.NSFileHandle
import Darwin.C.stdlib
import EventKit

func zoomMeetingFromText(text: String) -> (match: Bool, url: String) {
    let re = try! NSRegularExpression(pattern: #"https://([^\s\"'<]*zoom.us)/j/(\w+)([^\s\"'<]*)"#, options: [.anchorsMatchLines])
    let pwd_re = try! NSRegularExpression(pattern: #"pwd=(\w+)"#, options: [])

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let match = re.firstMatch(in: text, options: [], range: range)

    if match == nil {
        return (false, "")
    }

    let m = match!

    let host = text[Range(m.range(at: 1), in: text)!]
    let meeting_id = text[Range(m.range(at: 2), in: text)!]
    var zoom_url = "zoommtg://" + host + "/join?confno=" + meeting_id + "&zc=0&stype=100";

    let line_tail_range = Range(m.range(at: 3), in: text)
    if let lr = line_tail_range {
        let match = pwd_re.firstMatch(in: text, options: [], range: NSRange(lr, in:text))
        if let pm = match {
            zoom_url = zoom_url + "&pwd=" + text[Range(pm.range(at: 1), in: text)!]
        }
    }

    return (true, zoom_url)
}

do {
    let store = EKEventStore()
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
        NSLog("Authorized")
        break
    case .restricted:
        NSLog("Access resticted")
        exit(1)
    case .denied:
        NSLog("Access denied")
        exit(1)
    case .notDetermined:
        let group = DispatchGroup()
        group.enter()
        store.requestAccess(to: .event) { (granted: Bool, NSError) in
            if granted {
                NSLog("Granted")
            } else {
                NSLog("No access granted")
                exit(1)
            }
            group.leave()
        }
        group.wait()

        break

    @unknown default:
        break
    }
    let cal = Calendar.current

    let now = Date()
    var diff = DateComponents()
    diff.hour = -3
    let today = cal.date(byAdding: diff, to: now)

    diff.hour = 0
    diff.day = 1
    let tomorrow = cal.date(byAdding: diff, to: today!)

    diff.day = 0
    diff.minute = 5
    let soon = cal.date(byAdding: diff, to: now)

    let calendars = store.calendars(for: .event)

    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    NSLog("Events in range " + formatter.string(from: today!) + " - " + formatter.string(from: tomorrow!))

    let predicate: NSPredicate? = store.predicateForEvents(withStart: today!, end: tomorrow!, calendars:calendars)

    let events : [EKEvent] = store.events(matching: predicate!)
    var current = events.filter({ $0.startDate < soon! && now < $0.endDate})
    current.sort(by: { $0.startDate > $1.startDate })

    for event in current {
        if event.isAllDay {
            continue
        }

        NSLog((event.title ?? "<no title>") + " <" + formatter.string(from: event.startDate) + ">")

        if event.location ?? "" != "" {
            NSLog("Location:")
            NSLog(event.location!)

            let result = zoomMeetingFromText(text: event.location!)
            if result.match {
                print(result.url)
                exit(0)
            }
        }

        if event.notes ?? "" != "" {
            NSLog("Notes:")
            NSLog(event.notes!)

            let result = zoomMeetingFromText(text: event.notes!)
            if result.match {
                print(result.url)
                exit(0)
            }
        }
    }
}

