//
//  ViewController.swift
//  GameSet
//
//  Created by Boris V on 02.12.2017.
//  Copyright © 2017 GRIAL. All rights reserved.
//
import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private var gameSet = GameSet()
    
    @IBOutlet var cardButtons: [UIButton]! {
        didSet {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                button.layer.cornerRadius = 8.0
                button.layer.borderWidth = 5.0
            }
        }
    }
    
    @IBAction func touchCard(_ sender: UIButton) {
        if let buttonIndex = cardButtons.index(of: sender) {
            gameSet.chooseCard(at: buttonIndex)
            updateViewFromModel()
        }
    }
    
    private var audioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewFromModel()
        do
        {
            let audioPath = Bundle.main.path(forResource: "1", ofType: ".mp3")
            try audioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath!))
        }
        catch
        {
            //ERROR
        }
    }
    
    @IBOutlet weak var score: UILabel!
    
    private let symbols = [ "▲","◼︎","●"]
    private let colors = [ #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), #colorLiteral(red: 0.5791940689, green: 0.1280144453, blue: 0.5726861358, alpha: 1), #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1) ]
    private let alphas:[CGFloat] = [1, 1, 0.3]
    private let strokeWidths:[CGFloat] = [10,0,-10]
    
    private func updateViewFromModel() {
        currentDeck.setTitle("\(gameSet.cards.count)" + "➙3", for: .normal)
        for index in cardButtons.indices {
            let button = cardButtons[index]
            if index < gameSet.visibleCards.count {
                let card = gameSet.visibleCards[index]
                let symbol = String(repeating: symbols[card.symbol.rawValue], count: card.number.rawValue+1)
                button.backgroundColor = .white
                let attributes: [NSAttributedStringKey : Any] = [
                    .foregroundColor : colors[card.color.rawValue].withAlphaComponent(alphas[card.fill.rawValue]),
                    .strokeWidth : strokeWidths[card.fill.rawValue]
                ]
                button.setAttributedTitle( NSAttributedString (string: symbol, attributes: attributes), for: .normal)
                button.isEnabled = true
                if !gameSet.selectedCards.contains(card) {
                    button.layer.borderColor = UIColor.clear.cgColor
                } else {
                    if gameSet.selectedCards.count == gameSet.flop {
                        button.isEnabled = false
                        if gameSet.match {
                            button.layer.borderColor = UIColor.green.cgColor
                        } else {
                            button.layer.borderColor = UIColor.red.cgColor
                        }
                    } else {
                        button.layer.borderColor = UIColor.orange.cgColor
                    }
                }
            } else {
                button.setAttributedTitle(nil, for: .normal)
                button.backgroundColor = .clear
                button.layer.borderColor = UIColor.clear.cgColor
                button.isEnabled = false
            }
        }
        score.text =  gameSet.scoreOfPlayer
        if gameSet.cards.isEmpty || gameSet.visibleCards.count == cardButtons.count && !gameSet.match ||
            gameSet.iphoneVsPlayer == "👀" {
            currentDeck.isEnabled = false // блокировка кнопки more3cards
        } else {
            currentDeck.isEnabled = true // отмена блокировки кнопки more3cards
        }
        if iphoneOrDango.isEnabled {
            allSetsOrTimer.text = gameSet.iphoneVsPlayer
        }
        if gameSet.playWith { // призовая игра с iPhone
            iphoneOrDango.setTitle("📲", for: .normal)
        }
    }
    
    @IBOutlet weak var currentDeck: UIButton!
    @IBAction func more3cards() {
        if !gameSet.match { //  не выбран сет
            gameSet.addCards(few: gameSet.flop)
        } else {
            gameSet.addFlopNowSet()
        }
        updateViewFromModel()
    }
    
    @IBAction func newGame() {
        gameSet = GameSet()
        iphoneOrDango.setTitle("🍡", for: .normal)
        iphoneScoreOrHints.text = ""
        iphoneOrDango.isEnabled = true
        updateViewFromModel()
        timer.invalidate()
        audioPlayer.stop()
        numberIntervals = 0
    }
    //++++++++++++++++++++++Extra Credit+++++++++++++++++++++++++++++
    @IBOutlet weak var allSetsOrTimer: UILabel!
    @IBOutlet weak var iphoneOrDango: UIButton!
    @IBOutlet weak var iphoneScoreOrHints: UILabel!
    
    lazy private var delay = gameSet.iphonePlayStart() // задатчик интервала в сек
    private var numberIntervals = 0
    private var timer = Timer()
    
    @IBAction func iphoneOrHanami() {
        if gameSet.playWith || gameSet.hint == true { // режим призовой игры
            iphoneOrDango.isEnabled = false
            if gameSet.iphoneVsPlayer == "🤺" { // к старту призовой игры
                delay = gameSet.iphonePlayStart()
            }
            if !gameSet.match {
                // включение таймера, когда сет не выбран
                timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delay), repeats: true) {
                    [weak self] time in self?.counterIntervals()
                }
            } else {
                gameSet.hintSet()
                // включение таймера после удаления сета
                timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(delay), repeats: true) {
                    [weak self] time in self?.counterIntervals()
                }
            }
        }
        if gameSet.hint != true { // режим "Соло"
            gameSet.hintSet()
        }
        updateViewFromModel()
        iphoneScoreOrHints.text = "\(gameSet.numberOfHints)"
    }
    
    private var timeIndicator = 0
    private let lengthInterval = 16 // длительность интервала (в delay)
    private let countdown = "█▇▆▅▄▃▂▁"
    
    private func counterIntervals() { // счётчик интервалов
        let index = countdown.index(countdown.startIndex, offsetBy: timeIndicator)
        if !gameSet.playWith {
            numberIntervals += 1
            if numberIntervals%lengthInterval == 0 {
                timeIndicator += 1
            }
            allSetsOrTimer.text = String(countdown[index])
            audioPlayer.play()
        } else {
            allSetsOrTimer.text = gameSet.iphoneVsPlayer
            numberIntervals = countdown.count*lengthInterval
        }
        if numberIntervals == countdown.count*lengthInterval {
            timer.invalidate()
            gameSet.hintSet()
            if gameSet.iphoneVsPlayer != "🏁" {
                iphoneOrDango.isEnabled = true // отмена блокировки кнопки 📲
            }
            updateViewFromModel()
            audioPlayer.stop()
            numberIntervals = 0
            timeIndicator = 0
        }
    }
}














