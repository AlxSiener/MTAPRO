//
//  Train.swift
//  MTAPRO
//
//  Created by Student on 4/29/26.
//

class Train {
    var name: Character
    var trainLine: String
    var direction: String
    
    init(name: Character, trainLine: String, direction: String) {
        self.name = name
        self.trainLine = trainLine
        self.direction = direction
    }
}

enum TrainLine {
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
