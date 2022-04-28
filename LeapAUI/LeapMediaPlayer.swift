//
//  LeapMediaPlayer.swift
//  LeapSDK
//
//  Created by Ajay S on 23/12/21.
//  Copyright © 2021 Aravind GS. All rights reserved.
//

import Foundation
import AVFoundation

protocol LeapMediaPlayerDelegate: AnyObject {
    func audioDidFinishPlaying()
    func audioDecodeErrorDidOccur()
    func speechSynthesizerDidFinishUtterance()
    func speechSynthesizerDidCancelUtterance()
    func audioDidStartPlaying()
    func audioDidStopPlaying()
}

class LeapMediaPlayer: NSObject {
    
    weak var delegate: LeapMediaPlayerDelegate?
    
    var audioPlayer: AVAudioPlayer?
    var utterance: AVSpeechUtterance?
    var synthesizer: AVSpeechSynthesizer?
    
    var currentAudioCompletionStatus: Bool?
    
    override init() {
        super.init()
    }
    
    func playAudio(filePath: URL) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            self.audioPlayer = try AVAudioPlayer(contentsOf: filePath)
            self.audioPlayer?.delegate = self
            self.audioPlayer?.play()
            if self.audioPlayer?.isPlaying ?? false {
               DispatchQueue.main.async {
                self.delegate?.audioDidStartPlaying()
               }
            }
        } catch let error {
            print(error.localizedDescription)
            delegate?.audioDecodeErrorDidOccur()
        }
    }
    
    func tryTTS(text: String, code: String) {
        utterance = AVSpeechUtterance(string: text)
        utterance?.voice = AVSpeechSynthesisVoice(language: code)
        utterance?.rate = 0.5
        self.synthesizer = AVSpeechSynthesizer()
        self.synthesizer?.delegate = self
        guard let utterance = utterance else { return }
        synthesizer?.speak(utterance)
        DispatchQueue.main.async {
            self.delegate?.audioDidStartPlaying()
        }
    }
    
    func stopAudio() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        self.synthesizer?.stopSpeaking(at: AVSpeechBoundary.immediate)
        self.utterance = nil
        self.synthesizer = nil
        DispatchQueue.main.async {
            self.delegate?.audioDidStopPlaying()
        }
    }
}

extension LeapMediaPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentAudioCompletionStatus = true
        delegate?.audioDidFinishPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        currentAudioCompletionStatus = true
        delegate?.audioDecodeErrorDidOccur()
    }
}

extension LeapMediaPlayer: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentAudioCompletionStatus = true
        delegate?.speechSynthesizerDidFinishUtterance()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        currentAudioCompletionStatus = true
        delegate?.speechSynthesizerDidCancelUtterance()
    }
}
