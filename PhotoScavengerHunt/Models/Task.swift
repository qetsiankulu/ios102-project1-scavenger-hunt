//
//  Task.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/15/22.
//

import UIKit
import CoreLocation

class Task {
    let title: String
    let description: String
    var image: UIImage?
    var imageLocation: CLLocation?
    var isComplete: Bool {
        image != nil
    }

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }

    func set(_ image: UIImage, with location: CLLocation) {
        self.image = image
        self.imageLocation = location
    }
}

extension Task {
    static var mockedTasks: [Task] {
        return [
            Task(title: "Your favorite gaming spot",
                 description: "Where do you go to play video games?"),
            Task(title: "Your favorite waterfront view ",
                 description: "Where do you want to go when you want to be close to the Pacific Ocean?"),
            Task(title: "Your favorite tropical view ",
                 description: "Where do you go when you want to escape to an exotic paradise?"),
            Task(title: "Your favorite new travel destination", description: "Where is a new place you traveled to?")
            
        ]
    }
}
