//
//  ViewController.swift
//  Transcribe
//
//  Created by Allen White on 2/13/17.
//  Copyright © 2017 Allen White. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioRecorderDelegate {

	@IBOutlet weak var recordingLabel: UILabel!
	var audioRecorder: AVAudioRecorder?
	var recordedFileURL : URL!
	var timer: Timer!
	var audioPlayer : AVAudioPlayer?
	@IBOutlet weak var transcribedAudioLabel: UILabel!
	var lastSecond : [Double]!
	let interval = 100 //th of a second
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		checkPermissions()
	}

	@IBAction func recordButtonClicked(_ sender: UIButton) {
//		guard audioRecorder != nil else {
//			recordAudio()
//			sender.setTitle("STOP", for: .normal)
//			return
//		}
//		if (audioRecorder?.isRecording)! {
//			audioRecorder?.stop()
//			sender.setTitle("RECORD", for: .normal)
//			print("Stop")
//		}else{
//			recordAudio()
//			sender.setTitle("STOP", for: .normal)
//			print("Record")
//		}
//		^^^ uncomment above for start / stop capability ^^^
		recordAudio()
		sender.setTitle("...", for: .normal)
		sender.isEnabled = false
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func checkPermissions(){
		let recAuthorised = AVAudioSession.sharedInstance().recordPermission() == .granted
		if !recAuthorised{
			requestRecordPermissions()
		}
		
		let transcribeAuthorised = SFSpeechRecognizer.authorizationStatus() == .authorized
		if !transcribeAuthorised{
			requestTranscribePermissions()
		}
	}

	func requestRecordPermissions(){
		AVAudioSession.sharedInstance().requestRecordPermission(){[unowned self] allowed in
			if allowed{
				// great
				print("yea verily")
			}else{
				// tell the user how f*cking stupid they are
				print("you fool")
			}
		}
	}
	
	func requestTranscribePermissions(){
		SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
			if authStatus == .authorized{
				// good to go
				print("yea verily")
			}else{
				// tell the user how f*cking stupid they are
				print("you fool")
			}
		}
	}
	
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		self.recordingLabel.alpha = 0
		if !flag{
			// fail
			print("\(#line) error")
		}else{
			// pass
			print("\(#line) did finish")
//			playAudio()
			transcribeAudio()
		}
	}
	
	
	
	func recordAudio(){
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		recordedFileURL = paths.first?.appendingPathComponent("temp.mp4")
		if FileManager.default.fileExists(atPath: recordedFileURL.absoluteString){
			do{
				try FileManager.default.removeItem(atPath: recordedFileURL.absoluteString)
			}catch{
				// something
				print("\(#line) error")
			}
		}
		
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
			try session.setActive(true)
			let settings = [
				AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
				AVSampleRateKey: 44100,
				AVNumberOfChannelsKey: 1,
				AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
			] as [String : Any]
			audioRecorder = try AVAudioRecorder(url: recordedFileURL, settings: settings)
			audioRecorder?.isMeteringEnabled = true
			audioRecorder?.delegate = self
			audioRecorder?.record()
			self.recordingLabel.alpha = 1
			timer = Timer.scheduledTimer(timeInterval: (1.0 / Double(interval)), target: self, selector: #selector(listenToRecording), userInfo: nil, repeats: true)
			
			print("\(#line) yesss .isRecording::: \(audioRecorder?.isRecording)")
		}catch{
			// booga booga booga
			print("\(#line) error")
		}
	}
	
	func playAudio(){
		// audio players only live as long as their scope, thats why its a class variable
		do{
			audioPlayer = try AVAudioPlayer(contentsOf: recordedFileURL)
			audioPlayer?.play()
		}catch{
			// uh oh
			print("\(#line) error")
		}
	}
	
	func transcribeAudio(){
		let recogniser = SFSpeechRecognizer()
		let request = SFSpeechURLRecognitionRequest(url: recordedFileURL)
		recogniser?.recognitionTask(with: request){ [unowned self] (result, error) in
			guard let result = result else{
				print("\(#line) error")
				return
			}
			let text = result.bestTranscription.formattedString
			self.transcribedAudioLabel.text = text
			if result.isFinal {
				let text = result.bestTranscription.formattedString
				self.transcribedAudioLabel.text = text
				self.readAudio()
			}
			
		}
	}
	
	func readAudio(){
		let utterance = AVSpeechUtterance(string: self.transcribedAudioLabel.text!)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
		utterance.rate = 0.5
		
		let synthesizer = AVSpeechSynthesizer()
		synthesizer.speak(utterance)
	}

	func listenToRecording() {
		if lastSecond == nil {
			lastSecond =  [Double](repeating: 1.0, count: interval)
		}
		if (audioRecorder?.isRecording)! {
			audioRecorder?.updateMeters()
			let peakPower = Double((audioRecorder?.averagePower(forChannel: 0))!)
			let ALPHA = 0.05;
			let peakPowerForChannel = pow(10, (ALPHA * peakPower))
			print("power: \(peakPowerForChannel)")
			lastSecond.remove(at: 0)
			lastSecond.append(peakPowerForChannel)
			if lastSecond.average < 0.05 { // values range from 0 to 1
				audioRecorder?.stop()
				self.recordingLabel.alpha = 0
				timer.invalidate()
				print("Stop")
				// turn that button back on here
				lastSecond =  [Double](repeating: 1.0, count: interval)
			}
		}
	}
	
}


extension Array where Element: FloatingPoint {
	/// Returns the sum of all elements in the array
	var total: Element {
		return reduce(0, +)
	}
	/// Returns the average of all elements in the array
	var average: Element {
		return isEmpty ? 0 : total / Element(count)
	}
}

