//
//  Train.swift
//  MTAPRO
//
//  Created by Student on 4/29/26.
//

import Foundation

class Train: Identifiable {
    var name: Character
    var trainLine: String
    var direction: String
    var id = UUID()
    
    init(name: Character, trainLine: String, direction: String) {
        self.name = name
        self.trainLine = trainLine
        self.direction = direction
    }
}

class TrainLine: Identifiable {
    var name: String
    var id: UUID = UUID()
    var line: TrainLineType
    
    init(name: String, line: TrainLineType) {
        self.name = name
        self.line = line
    }
}

class Stations: Identifiable {
    var name: String
    var line: TrainLineType
    var stopNumber: Int
    
    init(name: String, line: TrainLineType, stopNumber: Int) {
        self.name = name
        self.line = line
        self.stopNumber = stopNumber
    }
}

enum TrainLineType {
    case A
    case C
    case E
    case B
    case D
    case F
    case M
    case N
    case R
    case Q
    case W
    case J
    case Z
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case L
    case G
    
}
