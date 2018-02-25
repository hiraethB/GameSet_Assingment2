//
//  CardSet.swift
//  GameSet
//
//  Created by Boris V on 02.12.2017.
//  Copyright © 2017 GRIAL. All rights reserved.
//
import Foundation

struct CardSet: Equatable {

    static func==(lhs: CardSet, rhs: CardSet) -> Bool {
        return lhs.symbol == rhs.symbol && lhs.number == rhs.number && lhs.color == rhs.color && lhs.fill == rhs.fill
    }
    
    var symbol: Triplet
    var number: Triplet
    var color:  Triplet
    var fill:   Triplet

    enum Triplet: Int {
        case one, two, three
        static var all = [Triplet.one, .two, .three]
    }

    static func checkSet(cards: [CardSet]) -> Bool {
        let  sumMatrix = [
            cards.reduce(0, { $0 + $1.symbol.rawValue}),
            cards.reduce(0, { $0 + $1.number.rawValue}),
            cards.reduce(0, { $0 + $1.color.rawValue}),
            cards.reduce(0, { $0 + $1.fill.rawValue})
            ]
        return sumMatrix.reduce(true, { $0 && ($1 % 3 == 0)})
    }
}


