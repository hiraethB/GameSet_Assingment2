//
//  GameSet.swift
//  GameSet
//
//  Created by Boris V on 02.12.2017.
//  Copyright © 2017 GRIAL. All rights reserved.
//
import Foundation

struct GameSet {
    
    private(set) var cards = [CardSet]()
    //========Const=======
    private let order = 12
    let flop = 3
    private let award = 10
    //====================
    init() {
        startDeck()
    }
    
    private mutating func startDeck() {
        for symbol in CardSet.Triplet.all {
            for number in CardSet.Triplet.all {
                for color in CardSet.Triplet.all {
                    for fill in CardSet.Triplet.all {
                        cards.append(CardSet(symbol: symbol, number: number, color: color, fill: fill))
                    }
                }
            }
        }
        addCards(few: order)
    }
    
    private(set) var visibleCards = [CardSet]()
    private(set) var selectedCards = [CardSet]()
    
    private var penalty: Int {
        return abs(visibleCards.count - order) * 3
    }
    
    var match: Bool {
        guard selectedCards.count == flop else { return false}
        return CardSet.checkSet(cards: selectedCards)
    }
    
    private var max = 0
    
    mutating func chooseCard(at index: Int) {
        guard limit == " " else { return }
        let card = visibleCards[index]
        if !selectedCards.contains(card) {
            if selectedCards.count == flop {
                if match {
                    addFlopNowSet()
                } else {
                    if hintSets.count != 0 {
                        max -= penalty + 3 // -3,-12,-21,-30,-39
                    }
                }
                selectedCards.removeAll()
            }
            selectedCards += [card]
            // автоматическое удаление сета при призовой игре
            if hint == true, match {
                addFlopNowSet()
            }
        } else {
            if selectedCards.count != flop {
                selectedCards.remove(elements: [card])
                if hintSets.count != 0 {
                    max -= 1
                }
            }
        }
    }
    
    mutating func addFlopNowSet() {
        max += award
        visibleCards.remove(elements: selectedCards)
        selectedCards.removeAll()
        if !cards.isEmpty, visibleCards.count < order {
            addCards(few: flop)
        }
        boundPrize()
    }
    
    var scoreOfPlayer: String {
        return prize + "\(max)"
    }
    
    mutating func addCards( few: Int) {
        let hintsCount = hintSets.count
        let count = selectedCards.count + penalty
        for _ in 1...few {
            visibleCards.append(draw())
        }
        if selectedCards.count == flop, !match {
            if hintsCount != 0 {
                max -= count
            } else {
                selectedCards.removeAll()
            }
        }
        if hintsCount != 0 {
            max -= penalty  // -9,-18,-27,-36
        }
        print(hintSets)
    }
    
    private mutating func draw() -> CardSet {
        return cards.remove(at: cards.count.arc4random)
    }
    //++++++++++++++++++++++Extra Credit++++++++++++++++++++++++++
    var hintSets: [[Int]] {
        var hints = [[Int]]()
        for i in 0..<visibleCards.count {
            for j in (i+1)..<visibleCards.count {
                for k in (j+1)..<visibleCards.count {
                    let cards = [visibleCards[i], visibleCards[j], visibleCards[k]]
                    if CardSet.checkSet(cards: cards) {
                        hints.append([i,j,k])
                    }
                }
            }
        }
        return hints
    }
    //--------------призовая игра---------------------
    private var limit = " "
    private var prize = " "
    
    private mutating func boundPrize() { // повторение/окончание призовой игры
        if playWith {
            if max < numberOfHints { // победа iPhone
                limit = "🏁"
                prize = " "
            } else {
                limit = "🤺"
            }
        }
    }
    
    var iphoneVsPlayer : String {
        guard hint != true, !playWith else { return limit } // призовая игра
        guard hint != false else {return "(\(hintSets.count))"} // флаг подсказки "соло"
        return " "
    }
    
    var playWith: Bool { // флаг призовой игры
        guard cards.isEmpty, hintSets.count == 0 || visibleCards.count < 6,
            hint == nil &&  max > 179 || // при "сольной" игре
                hint == true && max >= numberOfHints // при призовой игр
            else { return false }
        return true
    }
    
    mutating func iphonePlayStart() -> Double {
        selectedCards.removeAll()
        if max == 260 {
            max = 2*max
            prize = "🎖"
        } else {
            if max > 229 {
                max += max/5
                prize = "🏅"
            } else {
                prize = "🏆"
            }
        }
        visibleCards.removeAll()
        cards.removeAll()
        let timePrize = Double(max)/1000
        startDeck()
        max = 0
        numberOfHints = 0
        hint = true
        limit = " "
        return timePrize
    }
    
    private(set) var hint: Bool? //флаг использования подсказки или призовой игры
    private(set) var numberOfHints = 0
    
    mutating func hintSet() { // подсказка случайного сета
        if hint == true { // Переключение режима игры с "Соло" на "Призовая"
            if match {
                limit = " "
                numberOfHints += award
                visibleCards.remove(elements: selectedCards)
                selectedCards.removeAll()
                if !cards.isEmpty, visibleCards.count < order {
                    for _ in 1...flop {
                        visibleCards.append(draw())
                    }
                    print(hintSets) // Отладка
                }
                boundPrize() // окончание/начало призовой игры
            } else {
                if hintSets.count == 0 {
                    // Если не обнаружен сет, то добавить карт
                    while hintSets.count == 0 && !cards.isEmpty {
                        for _ in 1...flop {
                            visibleCards.append(draw())
                        }
                        print(hintSets) // Отладка
                    }
                }
                seachSet ()
                boundPrize()
                if !playWith {
                    limit = "👀"
                }
            }
            //------------------------------------------------
        } else {
            // ============ игра "Соло" =========================
            hint = false // флаг подсказки при игре "соло"
            guard hintSets.count != 0 else { return}
            guard !match  else { return }
            numberOfHints += 1
            if selectedCards.count == flop, !match {
                max -= penalty + award + flop
            } else {
                max -= selectedCards.count + award
            }
            seachSet ()
        }
    }
    
    private mutating func seachSet () {
        selectedCards.removeAll()
        if hintSets.count != 0 {
            let randomIndex = hintSets.count.arc4random
            for index in 0..<flop {
                selectedCards.append(visibleCards[hintSets[randomIndex][index]])
            }
        }
    }
}

extension Int {
    var arc4random: Int {
        guard self > 0 else { return 0}
        return Int(arc4random_uniform(UInt32(self)))
    }
}

extension Array where Element : Equatable {
    mutating func remove(elements: [Element]){
        self = self.filter { !elements.contains($0) }
    }
}

