//
//  Calendar.swift
//  Pattonville School District App
//
//  Created by Developer on 11/8/16.
//  Copyright © 2017 Pattonville School District. All rights reserved.
//

import UIKit
import MXLCalendarManager

class Calendar{
    
    static var instance: Calendar = Calendar()
    
    var allEvents: [Event]
    var allEventsDictionary: [Date:[Event]]
    
    var pinnedEvents: [Event]
    var pinnedEventsDictionary: [Date:[Event]]
    
    let fileURL: NSURL = {
        let directories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let document = directories.first!
        
        return document.appendingPathComponent("event.archive") as NSURL
        
    }()
    
    init(){
        
        allEvents = []
        allEventsDictionary = [:]
        
        pinnedEvents = []
        pinnedEventsDictionary = [:]
        
        readFromFile()

    }
    
    
    /// appends dates to the list and dictionary
    ///
    /// - mxlCalendar: an MXLCalendar calendar to pull dates from
    /// - school: the schools the event belongs to
    
    func appendDates(mxlCalendar: MXLCalendar, school: School){
        
        for event in mxlCalendar.events{
            
            let theEvent = Event(mxlEvent: (event as! MXLCalendarEvent), school: school)
            
            if pinnedEvents.contains(theEvent){
                theEvent.setPinned()
            }
            
            if !allEvents.contains(theEvent){
                addDate(event: theEvent)
            }
            
        }

    }
    
    func appendDates(dates: [Event]){
        
        for event in dates{
            if pinnedEvents.contains(event){
                event.setPinned()
            }
            
            if !allEvents.contains(event){
                addDate(event: event)
            }
        }
        
    }
    
    /// adds a date to to the dates list array
    /// - event: the event to add to the list
    /// - returns: the event that was added
    
    private func addDate(event: Event){
        allEvents.append(event)
        allEventsDictionary = addEventToDictionary(dict: allEventsDictionary, event: event)
    }
    
    
    func pinEvent(event: Event){
        
        if !pinnedEvents.contains(event){
            pinnedEvents.append(event)
            pinnedEventsDictionary = addEventToDictionary(dict: pinnedEventsDictionary, event: event)
            
            print(pinnedEvents.count)
            
        }
        
    }
    
    func unPinEvent(event: Event){
        
        pinnedEvents = pinnedEvents.filter({
            return $0 != event
        })
        
        pinnedEventsDictionary = removeEventFromDictionary(list: pinnedEvents, event: event)
        
    }
    
    func getIndexOfEvent(event: Event) -> Int{
        return pinnedEvents.index(of: event)!
    }
    
    
    private func addEventToDictionary(dict: [Date:[Event]], event: Event) -> [Date:[Event]]{
        
        var dictionary = dict
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        
        let theDateString = dateFormatter.string(from: event.date!)
        let theDate = dateFormatter.date(from: theDateString)
        
        if dictionary.keys.contains(theDate!){
            dictionary[theDate!]?.append(event)
        }else{
            dictionary[theDate!] = [event]
        }
        
        return dictionary

    }
    
    private func removeEventFromDictionary(list: [Event], event: Event) -> [Date: [Event]]{

        var dict = [Date: [Event]]()
        
        for event in list{
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd"
            
            let theDateString = dateFormatter.string(from: event.date!)
            let theDate = dateFormatter.date(from: theDateString)
            
            if dict.keys.contains(theDate!){
                
                dict[theDate!]?.append(event)
                
            }else{
                dict[theDate!] = [event]
            }
        }
        
        return dict
        
    }
    
    
    /// Gets the events from the dates list that are for a given date
    /// - date: the date to look for
    /// - returns: an array of events that occur on the specified date
    
    func eventsForDate(date: Date) -> [Event]{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        
        let theDateString = dateFormatter.string(from: date)
        let theDate = dateFormatter.date(from: theDateString)
        
        var eventsList = [Event]()
        
        if allEventsDictionary.keys.contains(theDate!){
            eventsList = allEventsDictionary[theDate!]!
        }
        
        return eventsList
        
    }
    
    func getInBackground(completionHandler: (() -> Void)?){
        
        let parser = CalendarParser()
        
        parser.getEventsInBackground(completionHandler: {
            
            let success = self.saveToFile()
            
            if success{
                UserDefaults.standard.set(Date(), forKey: "lastCalendarUpdate")
            }
            
            completionHandler?()
        })
        
    }
    
    
    func getEvents(completionHandler: (() -> Void)?){
        
        let mostRecentSave = UserDefaults.standard.object(forKey: "lastCalendarUpdate") as! Date
        print("RECENT: \(mostRecentSave)")
        print("CURRENT: \(Date())")
        
        
        var dateComponent = DateComponents()
        dateComponent.weekOfYear = -1
        
        let lastHour = NSCalendar(calendarIdentifier: .gregorian)?.date(byAdding: dateComponent, to: Date(), options: [])
        
        
        if mostRecentSave < lastHour! || (!readFromFile() || allEvents.count == 0){
        
            getInBackground(completionHandler: {
                completionHandler?()
            })
            
        }
        
    }
    
    func saveToFile() -> Bool{
        print("Saved to file \(fileURL.path!)")
        return NSKeyedArchiver.archiveRootObject(allEvents, toFile: fileURL.path!)
    }
    
    func readFromFile() -> Bool{
        if let archived = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path!) as? [Event]{
            print("FROM ARCHIVED")
            
            if allEvents.count < 1{
                appendDates(dates: archived)
            }
            
            return true
        }
        return false
    }
    
    /// Whether or not a given date has any events
    ///
    /// - date: the date to look at
    /// - returns: Whether or not a given date has any events
    func hasEvents(for date: Date) -> Bool{
        return eventsForDate(date: date).count > 0
    }
    
    ///Resets the events list and events dictionary to empty
    func resetEvents(){
        allEvents = []
        allEventsDictionary = [:]
    }
    
    
}
