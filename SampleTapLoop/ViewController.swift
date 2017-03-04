//
//  ViewController.swift
//  SampleTapLoop
//
//  Created by Takatomo INOUE on 2017/01/09.
//  Copyright © 2017年 Takatomo INOUE. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var padBlue: UIButton!
    @IBOutlet weak var padGreen: UIButton!
    @IBOutlet weak var padOrange: UIButton!
    @IBOutlet weak var padPink: UIButton!
    @IBOutlet weak var padPurple: UIButton!
    @IBOutlet weak var switchRecording: UISwitch!
    @IBOutlet weak var switchSampling: UISwitch!
    @IBOutlet weak var btnStopRecording: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var sliderSpeed: UISlider!
    @IBOutlet weak var lblSliderVal: UILabel!
    
    let fileManager = FileManager()
    var fileName: String = ""
    
    let engine = AVAudioEngine()
    var playerNodeBlue = AVAudioPlayerNode()
    var playerNodeGreen = AVAudioPlayerNode()
    var playerNodeOrange = AVAudioPlayerNode()
    var playerNodePink = AVAudioPlayerNode()
    var playerNodePurple = AVAudioPlayerNode()
    var audioFileBlue: AVAudioFile!
    var audioFileGreen: AVAudioFile!
    var audioFileOrange: AVAudioFile!
    var audioFilePink: AVAudioFile!
    var audioFilePurple: AVAudioFile!
    
    var timerRecording: Timer!
    var cntRecording: Int = 0
    var timerPlaying: Timer!
    var cntPlaying: Int = 1
    var isRecording: Bool = false
    var arraySoundTiming: NSMutableArray = NSMutableArray(array: [])
    var tappedPadsAtTime: [Int] = [0,0,0,0,0,0]
    
    var intervalVal: Double = 0.02
    
    var paths: [URL] = []
    var pathPunch: URL!
    let colors: [String] = ["Blue", "Green", "Orange", "Pink", "Purple"]
    var audioExists: [Bool] = [false, false, false, false, false]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask) as [URL]
        let dirURL = urls[0]
        for color in colors {
            let name = color + ".caf"
            paths.append(dirURL.appendingPathComponent(name) as URL)
        }
        pathPunch = dirURL.appendingPathComponent("punchSheet.dat") as URL
        
        if  fileManager.fileExists(atPath: pathPunch.path){
            arraySoundTiming = NSKeyedUnarchiver.unarchiveObject(withFile: pathPunch.path) as! NSMutableArray
        }
        
        audioExists[0] = fileManager.fileExists(atPath: paths[0].path)
        audioExists[1] = fileManager.fileExists(atPath: paths[1].path)
        audioExists[2] = fileManager.fileExists(atPath: paths[2].path)
        audioExists[3] = fileManager.fileExists(atPath: paths[3].path)
        audioExists[4] = fileManager.fileExists(atPath: paths[4].path)
        
        do{
            if audioExists[0] {
                audioFileBlue = try AVAudioFile(forReading: paths[0])
                engine.attach(playerNodeBlue)
                engine.connect(playerNodeBlue, to: engine.mainMixerNode, format: audioFileBlue.processingFormat)
            }
            if audioExists[1] {
                audioFileGreen = try AVAudioFile(forReading: paths[1])
                engine.attach(playerNodeGreen)
                engine.connect(playerNodeGreen, to: engine.mainMixerNode, format: audioFileGreen.processingFormat)
            }
            if audioExists[2] {
                audioFileOrange = try AVAudioFile(forReading: paths[2])
                engine.attach(playerNodeOrange)
                engine.connect(playerNodeOrange, to: engine.mainMixerNode, format: audioFileOrange.processingFormat)
            }
            if audioExists[3] {
                audioFilePink = try AVAudioFile(forReading: paths[3])
                engine.attach(playerNodePink)
                engine.connect(playerNodePink, to: engine.mainMixerNode, format: audioFilePink.processingFormat)
            }
            if audioExists[4] {
                audioFilePurple = try AVAudioFile(forReading: paths[4])
                engine.attach(playerNodePurple)
                engine.connect(playerNodePurple, to: engine.mainMixerNode, format: audioFilePurple.processingFormat)
            }
        } catch let error {
            print("AVAudioFile error", error)
        }
        if audioExists[0] || audioExists[1] ||
            audioExists[2] || audioExists[3] ||
            audioExists[4] {
                do {
                    // エンジンを開始
                    try engine.start()
                } catch let error {
                    print("engine.start() error:", error)
                }
        }
        
        btnStopRecording.isEnabled = false
        switchSampling.isOn = false
        switchRecording.isOn = false
        btnStop.isEnabled = false
        if !fileManager.fileExists(atPath: pathPunch.path) {
            btnPlay.isEnabled = false
        } else {
            cntRecording = arraySoundTiming.count - 1
        }
    }
    
    @IBAction func valueChengedSwitchSampling(_ sender: Any) {
        if switchSampling.isOn && switchRecording.isOn {
            switchRecording.isOn = false
        }
    }
    
    @IBAction func valueChengedSwitchRecording(_ sender: Any) {
        if switchSampling.isOn && switchRecording.isOn {
            switchSampling.isOn = false
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        //タイマーオフ
        timerRecording.invalidate()
        btnPlay.isEnabled = true
        btnStop.isEnabled = true
        switchRecording.isEnabled = true
        switchRecording.isOn = false
        switchSampling.isEnabled = true
        btnStopRecording.isEnabled = false
        isRecording = false
        let success = NSKeyedArchiver.archiveRootObject(arraySoundTiming, toFile: pathPunch.path)
        if success {
            print("Punch Sheet has been saved.")
        }
    }
    
    func startRecordingTimer() {
        arraySoundTiming = NSMutableArray(array: [])
        //タイマーオン
        timerRecording = Timer.scheduledTimer(
            timeInterval: 0.02,
            target: self,
            selector: #selector(self.updateRecording),
            userInfo: nil,
            repeats: true
        )
        btnPlay.isEnabled = false
        btnStop.isEnabled = false
        switchRecording.isEnabled = false
        switchSampling.isEnabled = false
        btnStopRecording.isEnabled = true
        
        cntRecording = 0
        tappedPadsAtTime = [0,0,0,0,0,cntRecording]
        timerRecording.fire()
    }
    
    func updateRecording(t: Timer) {
        if cntRecording >= 5000 { //10秒経ったら強制終了
            timerRecording.invalidate()
            btnPlay.isEnabled = true
            btnStop.isEnabled = true
            switchRecording.isEnabled = true
            switchSampling.isEnabled = true
            btnStopRecording.isEnabled = false
        }
        arraySoundTiming.add(tappedPadsAtTime)
        cntRecording = cntRecording + 1
        tappedPadsAtTime = [0,0,0,0,0,cntRecording]
        lblTime.text = NSString(format: "%d", cntRecording) as String
    }

    @IBAction func stopPlaying(_ sender: Any) {
        timerPlaying.invalidate()
        btnPlay.isEnabled = true
        btnStop.isEnabled = false
        switchRecording.isEnabled = true
        switchSampling.isEnabled = true
        cntPlaying = 1
    }
    
    @IBAction func startPlaying(_ sender: Any) {
        play(interval: intervalVal)
    }
    
    func play(interval: Double) {
        //タイマーオン
        timerPlaying = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(self.updatePlaying),
            userInfo: nil,
            repeats: true
        )
        btnPlay.isEnabled = false
        btnStop.isEnabled = true
        switchRecording.isEnabled = false
        switchSampling.isEnabled = false
        
        timerPlaying.fire()
    }
    
    func updatePlaying(t: Timer) {
        let everytime: [Int] = arraySoundTiming.object(at: cntPlaying) as! [Int]
        if everytime[0] == 1 {
            if playerNodeBlue.isPlaying {
                playerNodeBlue.stop()
                playerNodeBlue.scheduleFile(audioFileBlue, at: nil, completionHandler: nil)
                playerNodeBlue.play()
            } else {
                playerNodeBlue.scheduleFile(audioFileBlue, at: nil, completionHandler: nil)
                playerNodeBlue.play()
            }
        }
        if everytime[1] == 1 {
            if playerNodeGreen.isPlaying {
                playerNodeGreen.stop()
                playerNodeGreen.scheduleFile(audioFileGreen, at: nil, completionHandler: nil)
                playerNodeGreen.play()
            } else {
                playerNodeGreen.scheduleFile(audioFileGreen, at: nil, completionHandler: nil)
                playerNodeGreen.play()
            }
        }
        if everytime[2] == 1 {
            if playerNodeOrange.isPlaying {
                playerNodeOrange.stop()
                playerNodeOrange.scheduleFile(audioFileOrange, at: nil, completionHandler: nil)
                playerNodeOrange.play()
            } else {
                playerNodeOrange.scheduleFile(audioFileOrange, at: nil, completionHandler: nil)
                playerNodeOrange.play()
            }

        }
        if everytime[3] == 1 {
            if playerNodePink.isPlaying {
                playerNodePink.stop()
                playerNodePink.scheduleFile(audioFilePink, at: nil, completionHandler: nil)
                playerNodePink.play()
            } else {
                playerNodePink.scheduleFile(audioFilePink, at: nil, completionHandler: nil)
                playerNodePink.play()
            }
        }
        if everytime[4] == 1 {
            if playerNodePurple.isPlaying {
                playerNodePurple.stop()
                playerNodePurple.scheduleFile(audioFilePurple, at: nil, completionHandler: nil)
                playerNodePurple.play()
            } else {
                playerNodePurple.scheduleFile(audioFilePurple, at: nil, completionHandler: nil)
                playerNodePurple.play()
            }
        }
        
        cntPlaying = cntPlaying + 1
        if cntPlaying >= cntRecording {
            cntPlaying = 1
        }
        lblTime.text = NSString(format: "%d", cntPlaying) as String
    }
    
    func moveToSampling(colorStr: String) {
        engine.stop()
        let targetViewController:SamplingViewController = self.storyboard!.instantiateViewController( withIdentifier: "sampling" ) as! SamplingViewController
        targetViewController.valueAccessor = colorStr
        
        self.present(targetViewController, animated: true, completion: nil)
    }
    
    @IBAction func touchDownBlue(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[0])
        } else if engine.isRunning && audioExists[0] {
            if switchRecording.isOn {
                if !isRecording {
                    startRecordingTimer()
                    isRecording = true
                }
                tappedPadsAtTime[0] = 1
            }
            
            if playerNodeBlue.isPlaying {
                playerNodeBlue.stop()
                playerNodeBlue.scheduleFile(audioFileBlue, at: nil, completionHandler: nil)
                playerNodeBlue.play()
            } else {
                playerNodeBlue.scheduleFile(audioFileBlue, at: nil, completionHandler: nil)
                playerNodeBlue.play()
            }
            
        }
    }
    @IBAction func touchDownGreen(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[1])
        } else if engine.isRunning && audioExists[1] {
            if switchRecording.isOn {
                if !isRecording {
                    startRecordingTimer()
                    isRecording = true
                }
                tappedPadsAtTime[1] = 1
            }
 
            if playerNodeGreen.isPlaying {
                playerNodeGreen.stop()
                playerNodeGreen.scheduleFile(audioFileGreen, at: nil, completionHandler: nil)
                playerNodeGreen.play()
            } else {
                playerNodeGreen.scheduleFile(audioFileGreen, at: nil, completionHandler: nil)
                playerNodeGreen.play()
            }
        }
    }
    @IBAction func touchDownOrange(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[2])
        } else if engine.isRunning && audioExists[2] {
            if switchRecording.isOn {
                if !isRecording {
                    startRecordingTimer()
                    isRecording = true
                }
                tappedPadsAtTime[2] = 1
            }

            if playerNodeOrange.isPlaying {
                playerNodeOrange.stop()
                playerNodeOrange.scheduleFile(audioFileOrange, at: nil, completionHandler: nil)
                playerNodeOrange.play()
            } else {
                playerNodeOrange.scheduleFile(audioFileOrange, at: nil, completionHandler: nil)
                playerNodeOrange.play()
            }
        }
    }
    @IBAction func touchDownPink(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[3])
        } else if engine.isRunning && audioExists[3] {
            if switchRecording.isOn {
                if !isRecording {
                    startRecordingTimer()
                    isRecording = true
                }
                tappedPadsAtTime[3] = 1
            }

            if playerNodePink.isPlaying {
                playerNodePink.stop()
                playerNodePink.scheduleFile(audioFilePink, at: nil, completionHandler: nil)
                playerNodePink.play()
            } else {
                playerNodePink.scheduleFile(audioFilePink, at: nil, completionHandler: nil)
                playerNodePink.play()
            }
        }
    }
    @IBAction func touchDownPurple(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[4])
        } else if engine.isRunning && audioExists[4] {
            if switchRecording.isOn {
                if !isRecording {
                    startRecordingTimer()
                    isRecording = true
                }
                tappedPadsAtTime[4] = 1
            }

            if playerNodePurple.isPlaying {
                playerNodePurple.stop()
                playerNodePurple.scheduleFile(audioFilePurple, at: nil, completionHandler: nil)
                playerNodePurple.play()
            } else {
                playerNodePurple.scheduleFile(audioFilePurple, at: nil, completionHandler: nil)
                playerNodePurple.play()
            }
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        lblSliderVal.text = NSString(format: "%.0F", sliderSpeed.value*200) as String
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        intervalVal = Double((1-sliderSpeed.value)*0.04)
        if timerPlaying != nil && !btnPlay.isEnabled {
            timerPlaying.invalidate()
            play(interval: intervalVal)
        }
    }
    
    
    @IBAction func touchUpBlue(_ sender: Any) {
    }
    @IBAction func touchUpGreen(_ sender: Any) {
    }
    @IBAction func touchUpOrange(_ sender: Any) {
    }
    @IBAction func touchUpPink(_ sender: Any) {
    }
    @IBAction func touchUpPurple(_ sender: Any) {
    }
    
}

