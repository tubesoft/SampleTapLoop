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
    
    let blue:UIImage = UIImage(named:"colorCirclesBlue")!
    let green:UIImage = UIImage(named:"colorCirclesGreen")!
    let orange:UIImage = UIImage(named:"colorCirclesOrange")!
    let pink:UIImage = UIImage(named:"colorCirclesPink")!
    let purple:UIImage = UIImage(named:"colorCirclesPurple")!
    let blueDark:UIImage = UIImage(named:"colorCirclesBlueDark")!
    let greenDark:UIImage = UIImage(named:"colorCirclesGreenDark")!
    let orangeDark:UIImage = UIImage(named:"colorCirclesOrangeDark")!
    let pinkDark:UIImage = UIImage(named:"colorCirclesPinkDark")!
    let purpleDark:UIImage = UIImage(named:"colorCirclesPurpleDark")!
    var audioPlayer: AVAudioPlayer!
    var audioPlayerBlue: AVAudioPlayer!
    var audioPlayerGreen: AVAudioPlayer!
    var audioPlayerOrange: AVAudioPlayer!
    var audioPlayerPink: AVAudioPlayer!
    var audioPlayerPurple: AVAudioPlayer!
    let fileManager = FileManager()
    var fileName: String = ""
    var filePath: NSURL?
    
    var timerRecording: Timer!
    var cntRecording: Int = 0
    var timerPlaying: Timer!
    var cntPlaying: Int = 0
    var isRecording: Bool = false
    var arraySoundTiming: NSMutableArray = NSMutableArray(array: [])
    
    var cntLoop: Int = 0
    
    var intervalVal: Double = 0.1
    
    var paths: [NSURL] = []
    let colors: [String] = ["Blue", "Green", "Orange", "Pink", "Purple"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        for color in colors {
            let name = color + ".caf"
            let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask) as [URL]
            let dirURL = urls[0]
            paths.append(dirURL.appendingPathComponent(name) as NSURL)
        }
        do{
            audioPlayerBlue = try AVAudioPlayer(contentsOf: paths[0] as URL)
            audioPlayerGreen = try AVAudioPlayer(contentsOf: paths[1] as URL)
            audioPlayerOrange = try AVAudioPlayer(contentsOf: paths[2] as URL)
            audioPlayerPink = try AVAudioPlayer(contentsOf: paths[3] as URL)
            audioPlayerPurple = try AVAudioPlayer(contentsOf: paths[4] as URL)
        }
        catch let error {
            print("AVAudioPlayer error:", error)
        }
        
        btnStopRecording.isEnabled = false
        switchSampling.isOn = false
        switchRecording.isOn = false
        btnStop.isEnabled = false
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
    }
    
    func startRacordingTimer() {
        arraySoundTiming = NSMutableArray(array: [])
        //タイマーオン
        timerRecording = Timer.scheduledTimer(
            timeInterval: 0.1,
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
        timerRecording.fire()
    }
    
    func updateRecording(t: Timer) {
        if cntRecording >= 1000 { //10秒経ったら強制終了
            timerRecording.invalidate()
            btnPlay.isEnabled = true
            btnStop.isEnabled = true
            switchRecording.isEnabled = true
            switchSampling.isEnabled = true
            btnStopRecording.isEnabled = false
        }
        cntRecording = cntRecording + 1
        lblTime.text = NSString(format: "%d", cntRecording) as String
    }

    @IBAction func stopPlaying(_ sender: Any) {
        timerPlaying.invalidate()
        btnPlay.isEnabled = true
        btnStop.isEnabled = false
        switchRecording.isEnabled = true
        switchSampling.isEnabled = true
        cntLoop = 0
        cntPlaying = 0
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
        
        //        cntPlaying = 0
        //        cntLoop = 0
        timerPlaying.fire()
    }
    
    func updatePlaying(t: Timer) {
        if arraySoundTiming.count != 0 {
            let token: [Int] = arraySoundTiming.object(at: cntLoop) as! [Int]
            let timing: Int = token[1]
            let colorNum: Int = token[0]
            
            if cntPlaying == timing {
                switch colorNum {
                case 0:
                    do{
                        audioPlayerBlue = try AVAudioPlayer(contentsOf: paths[0] as URL)
                        audioPlayerBlue.play()
                    }
                    catch let error {
                        print("AVAudioPlayer error:", error)
                    }
                case 1:
                    do{
                        audioPlayerGreen = try AVAudioPlayer(contentsOf: paths[1] as URL)
                        audioPlayerGreen.play()
                    }
                    catch let error {
                        print("AVAudioPlayer error:", error)
                    }
                case 2:
                    do{
                        audioPlayerOrange = try AVAudioPlayer(contentsOf: paths[2] as URL)
                        audioPlayerOrange.play()
                    }
                    catch let error {
                        print("AVAudioPlayer error:", error)
                    }
                    
                case 3:
                    do{
                        audioPlayerPink = try AVAudioPlayer(contentsOf: paths[3] as URL)
                        audioPlayerPink.play()
                    }
                    catch let error {
                        print("AVAudioPlayer error:", error)
                    }
                case 4:
                    do{
                        audioPlayerPurple = try AVAudioPlayer(contentsOf: paths[4] as URL)
                        audioPlayerPurple.play()
                    }
                    catch let error {
                        print("AVAudioPlayer error:", error)
                    }
                default: break
                }
                if cntLoop < arraySoundTiming.count - 1 {
                    cntLoop = cntLoop + 1
                }
            }
            if cntPlaying >= cntRecording {
                cntPlaying = 0
                cntLoop = 0
            }
            cntPlaying = cntPlaying + 1
        }
        lblTime.text = NSString(format: "%d", cntPlaying) as String
    }
    
    func moveToSampling(colorStr: String) {
        let targetViewController:SamplingViewController = self.storyboard!.instantiateViewController( withIdentifier: "sampling" ) as! SamplingViewController
        targetViewController.valueAccessor = colorStr
        
        self.present( targetViewController, animated: true, completion: nil)
    }
    
    @IBAction func touchDownBlue(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[0])
        } else {
            if switchRecording.isOn {
                if !isRecording {
                    startRacordingTimer()
                    isRecording = true
                }
                let token: [Int] = [0, cntRecording]
                arraySoundTiming.add(token)
            }
            
            do{
                audioPlayerBlue = try AVAudioPlayer(contentsOf: paths[0] as URL)
                audioPlayerBlue.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
        }
    }
    @IBAction func touchDownGreen(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[1])
        } else {
            if switchRecording.isOn {
                if !isRecording {
                    startRacordingTimer()
                    isRecording = true
                }
                let token: [Int] = [1, cntRecording]
                arraySoundTiming.add(token)
            }

            do{
                audioPlayerGreen = try AVAudioPlayer(contentsOf: paths[1] as URL)
                audioPlayerGreen.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
        }
    }
    @IBAction func touchDownOrange(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[2])
        } else {
            if switchRecording.isOn {
                if !isRecording {
                    startRacordingTimer()
                    isRecording = true
                }
                let token: [Int] = [2, cntRecording]
                arraySoundTiming.add(token)
            }

            do{
                audioPlayerOrange = try AVAudioPlayer(contentsOf: paths[2] as URL)
                audioPlayerOrange.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
        }
    }
    @IBAction func touchDownPink(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[3])
        } else {
            if switchRecording.isOn {
                if !isRecording {
                    startRacordingTimer()
                    isRecording = true
                }
                let token: [Int] = [3, cntRecording]
                arraySoundTiming.add(token)
            }

            do{
                audioPlayerPink = try AVAudioPlayer(contentsOf: paths[3] as URL)
                audioPlayerPink.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
        }
    }
    @IBAction func touchDownPurple(_ sender: Any) {
        if switchSampling.isOn {
            moveToSampling(colorStr: colors[4])
        } else {
            if switchRecording.isOn {
                if !isRecording {
                    startRacordingTimer()
                    isRecording = true
                }
                let token: [Int] = [4, cntRecording]
                arraySoundTiming.add(token)
            }

            do{
                audioPlayerPurple = try AVAudioPlayer(contentsOf: paths[4] as URL)
                audioPlayerPurple.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        lblSliderVal.text = NSString(format: "%.0F", sliderSpeed.value*200) as String
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        intervalVal = Double((1-sliderSpeed.value)*0.2)
        if timerPlaying != nil {
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

