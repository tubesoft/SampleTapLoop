//
//  ViewController.swift
//  SampleTapLoop
//
//  Created by Takatomo INOUE on 2017/01/09.
//  Copyright © 2017年 Takatomo INOUE. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileAds

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
    @IBOutlet weak var progressLoop: UIProgressView!
    @IBOutlet weak var sliderSpeed: UISlider!
    @IBOutlet weak var lblSliderVal: UILabel!
    
    let fileManager = FileManager()
    var fileName: String = ""
    
    let session = AVAudioSession.sharedInstance()
    var engine: AVAudioEngine!
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
    
    var timerRecording: Timer?
    var cntRecording: Int = 0
    var timerPlaying: Timer?
    var cntPlaying: Int = 0
    var isRecording: Bool = false
    var arraySoundTiming: NSMutableArray = NSMutableArray(array: [])
    var tappedPadsAtTime: [Int] = [0,0,0,0,0,0]
    
    var intervalVal: Double = 0.02
    
    var paths: [URL] = []
    var pathPunch: URL!
    var dummyUrl: URL!
    let colors: [String] = ["Blue", "Green", "Orange", "Pink", "Purple"]
    var audioExists: [Bool] = [false, false, false, false, false]
    var punchExist = false
    var tappedColorNum: Int?
    var isGoingToSample = false
    var isComingBackFromSample = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // AdMob広告
        var admobView = GADBannerView()
        admobView = GADBannerView(adSize:kGADAdSizeBanner)
        admobView.frame.origin = CGPoint(
            x:(self.view.frame.size.width - admobView.frame.width)/2,
            y:self.view.frame.size.height - admobView.frame.height)
        admobView.frame.size = CGSize(width:admobView.frame.width, height:admobView.frame.height)
        
        admobView.adUnitID = "ca-app-pub-4143465099360561/4902418739"
        admobView.rootViewController = self
        admobView.load(GADRequest())
        self.view.addSubview(admobView)
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.handleInterruption),
                           name: AVAudioSession.interruptionNotification, object: nil)
        center.addObserver(self, selector: #selector(self.audioSessionRouteChanged),
                           name: AVAudioSession.routeChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(self.quitApp),
                           name: NSNotification.Name(rawValue: "QuitApp"), object: nil)
        center.addObserver(self, selector: #selector(self.comeBack),
                           name: NSNotification.Name(rawValue: "ComeBack"), object: nil)
        
        engine = AVAudioEngine()
        initEngine()
        
        progressLoop.frame.origin = CGPoint(
//            x:view.frame.size.width-view.frame.size.height/2-progressLoop.frame.size.height/2,
//            y:view.frame.size.height/2-progressLoop.frame.size.height/2)
            x: 0,
            y: 0)
        progressLoop.frame.size.width = view.frame.size.width
        let wider = CGAffineTransform(scaleX: 1.0, y: 12.0)
//        let rotate = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
//        let transform = wider.concatenating(rotate)
//        progressLoop.transform = transform
        progressLoop.transform = wider
        lblSliderVal.text = "100％"
        
        
        btnStopRecording.isEnabled = false
        switchSampling.isOn = false
        switchRecording.isOn = false
        btnStop.isEnabled = false
        if !audioExists[0] && !audioExists[1] &&
            !audioExists[2] && !audioExists[3] &&
            !audioExists[4] {
            switchRecording.isEnabled = false
        }
        if !punchExist {
            btnPlay.isEnabled = false
        } else {
            cntRecording = arraySoundTiming.count - 1
        }
        
        // AudioSession
        do {
            try session.setCategory(AVAudioSession.Category.soloAmbient)
//            try session.setCategory(AVAudioSession.Category.playback)  // サイレントでもなるが画面遷移から戻るとならなくなる
            try session.setActive(true)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
    }
    
    func initEngine() {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask) as [URL]
        let dirURL = urls[0]
        for color in colors {
            let name = color + ".caf"
            paths.append(dirURL.appendingPathComponent(name) as URL)
        }
        pathPunch = dirURL.appendingPathComponent("punchSheet.dat") as URL
        
        punchExist = fileManager.fileExists(atPath: pathPunch.path)
        
        if  punchExist {
            do {
                let codedData = try Data(contentsOf: pathPunch)
                arraySoundTiming = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(codedData) as! NSMutableArray
            } catch  {
                print("Punch Sheet Load Failed.")
            }
        }
        
        audioExists[0] = fileManager.fileExists(atPath: paths[0].path)
        audioExists[1] = fileManager.fileExists(atPath: paths[1].path)
        audioExists[2] = fileManager.fileExists(atPath: paths[2].path)
        audioExists[3] = fileManager.fileExists(atPath: paths[3].path)
        audioExists[4] = fileManager.fileExists(atPath: paths[4].path)
        let asset = NSDataAsset(name: "dummy")
        dummyUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("dummy.wav")
        try! asset!.data.write(to: dummyUrl)
        
        do{
            if audioExists[0] {
                audioFileBlue = try AVAudioFile(forReading: paths[0])
            } else {
                audioFileBlue = try AVAudioFile(forReading: dummyUrl)
            }
            if audioExists[1] {
                audioFileGreen = try AVAudioFile(forReading: paths[1])
            } else {
                audioFileGreen = try AVAudioFile(forReading: dummyUrl)
            }
            if audioExists[2] {
                audioFileOrange = try AVAudioFile(forReading: paths[2])
            } else {
                audioFileOrange = try AVAudioFile(forReading: dummyUrl)
            }
            if audioExists[3] {
                audioFilePink = try AVAudioFile(forReading: paths[3])
            } else {
                audioFilePink = try AVAudioFile(forReading: dummyUrl)
            }
            if audioExists[4] {
                audioFilePurple = try AVAudioFile(forReading: paths[4])
            } else {
                audioFilePurple = try AVAudioFile(forReading: dummyUrl)
            }
        } catch let error {
            print("AVAudioFile error", error)
        }
        engine!.attach(playerNodeBlue)
        engine!.connect(playerNodeBlue, to: engine!.mainMixerNode, format: audioFileBlue.processingFormat)
        engine!.attach(playerNodeGreen)
        engine!.connect(playerNodeGreen, to: engine!.mainMixerNode, format: audioFileGreen.processingFormat)
        engine!.attach(playerNodeOrange)
        engine!.connect(playerNodeOrange, to: engine!.mainMixerNode, format: audioFileOrange.processingFormat)
        engine!.attach(playerNodePink)
        engine!.connect(playerNodePink, to: engine!.mainMixerNode, format: audioFilePink.processingFormat)
        engine!.attach(playerNodePurple)
        engine!.connect(playerNodePurple, to: engine!.mainMixerNode, format: audioFilePurple.processingFormat)
        
        engine!.mainMixerNode.outputVolume = 1
        
        do {
            // エンジンを開始
            try engine!.start()
        } catch let error {
            print("engine!.start() error:", error)
        }
    }
    
    @IBAction func valueChengedSwitchSampling(_ sender: Any) {
        if switchSampling.isOn && switchRecording.isOn {
            switchRecording.isOn = false
        }
        if switchSampling.isOn || !punchExist {
            btnPlay.isEnabled = false
        } else {
            btnPlay.isEnabled = true
        }
    }
    
    @IBAction func valueChengedSwitchRecording(_ sender: Any) {
        if switchSampling.isOn && switchRecording.isOn {
            switchSampling.isOn = false
        }
        if switchRecording.isOn || !punchExist {
            btnPlay.isEnabled = false
        } else {
            btnPlay.isEnabled = true
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        //タイマーオフ
        timerRecording?.invalidate()
        btnPlay.isEnabled = true
        switchRecording.isEnabled = true
        switchRecording.isOn = false
        switchSampling.isEnabled = true
        btnStopRecording.isEnabled = false
        isRecording = false
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: arraySoundTiming, requiringSecureCoding: false)
            try data.write(to: pathPunch)
        } catch {
            print("Punch Sheet Save Failed.")
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
    }
    
    @objc func updateRecording(t: Timer) {
        if cntRecording >= 500 { //10秒経ったら強制終了
            timerRecording?.invalidate()
            btnPlay.isEnabled = true
            switchRecording.isEnabled = true
            switchSampling.isEnabled = true
            btnStopRecording.isEnabled = false
        }
        arraySoundTiming.add(tappedPadsAtTime)
        cntRecording = cntRecording + 1
        tappedPadsAtTime = [0,0,0,0,0,cntRecording]
        lblTime.text = NSString(format: "%.2f", Float(cntRecording)/50) as String
        progressLoop.progress = Float(cntRecording)/500
    }
    
    @IBAction func stopPlaying(_ sender: Any) {
        stopLoop()
    }
    
    func stopLoop() {
        timerPlaying?.invalidate()
        btnPlay.isEnabled = true
        btnStop.isEnabled = false
        switchRecording.isEnabled = true
        switchSampling.isEnabled = true
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
    }
    
    @objc func updatePlaying(t: Timer) {
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
            cntPlaying = 0
        }
        lblTime.text = NSString(format: "%.2f", Float(cntPlaying)/50) as String
        progressLoop.progress = Float(cntPlaying)/Float(cntRecording)
    }
    
    func moveToSampling(colorStr: String) {
        closingEngine()
        engine.inputNode.reset()
        AudioOutputUnitStop((engine.inputNode.audioUnit)!)
        AudioUnitUninitialize((engine.inputNode.audioUnit)!)
//        AudioComponentInstanceDispose((engine.inputNode?.audioUnit)!)
        switchSampling.isOn = false
        punchExist = fileManager.fileExists(atPath: pathPunch.path)
        if punchExist {
            btnPlay.isEnabled = true
        }
        isGoingToSample = true
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        } catch let error {
            print("AVAudioSession Error", error)
        }

        self.performSegue(withIdentifier: "ToSampling", sender: colorStr)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToSampling" {
            let samplingViewController = segue.destination as! SamplingViewController
            samplingViewController.txtColor = sender as? String
        }
    }
    
    @IBAction func returnToMain(segue: UIStoryboardSegue) {
        if segue.identifier == "unwindDone" {
            let tmpDirPath = NSTemporaryDirectory()
            let tmpPath = URL(fileURLWithPath: tmpDirPath + "/" + colors[tappedColorNum!] + ".caf")
            let tmpAudio = NSData(contentsOf: tmpPath)
            tmpAudio?.write(to: paths[tappedColorNum!], atomically: true)
        }
        isComingBackFromSample = true
        do {
            try session.setCategory(AVAudioSession.Category.soloAmbient)
        } catch let error {
            print("AVAudioSession Error", error)
        }
        audioFileUpdate()
        openingEngine()
    }
    
    @IBAction func touchDownBlue(_ sender: Any) {
        if switchSampling.isOn {
            tappedColorNum = 0
            moveToSampling(colorStr: colors[0])
        } else if engine!.isRunning && audioExists[0] {
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
            tappedColorNum = 1
            moveToSampling(colorStr: colors[1])
        } else if engine!.isRunning && audioExists[1] {
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
            tappedColorNum = 2
            moveToSampling(colorStr: colors[2])
        } else if engine!.isRunning && audioExists[2] {
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
            tappedColorNum = 3
            moveToSampling(colorStr: colors[3])
        } else if engine!.isRunning && audioExists[3] {
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
            tappedColorNum = 4
            moveToSampling(colorStr: colors[4])
        } else if engine!.isRunning && audioExists[4] {
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
        lblSliderVal.text = NSString(format: "%.0F％", sliderSpeed.value*200) as String
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        intervalVal = Double((1-sliderSpeed.value)*0.04)
        if timerPlaying != nil && !btnPlay.isEnabled {
            timerPlaying?.invalidate()
            play(interval: intervalVal)
        }
    }
    
    // 電話が来たとき
    @objc func handleInterruption(_ notification: Notification) {
        if !btnPlay.isEnabled {
            stopLoop()
        }
    }
    
    // ヘッドフォン抜き差ししたとき＋セッションが変わったときも呼び出される
    @objc func audioSessionRouteChanged(_ notification: Notification) {
        if !isGoingToSample {
            closingEngine()
            openingEngine()
        }
        if isComingBackFromSample {
            isGoingToSample = false
            isComingBackFromSample = false
        }
    }
    
    @objc func quitApp() {
        if !btnPlay.isEnabled {
            stopLoop()
        }
        closingEngine()
    }
    
    @objc func comeBack() {
        closingEngine()
        openingEngine()
    }
    
    func closingEngine() {
        engine!.disconnectNodeOutput(playerNodeBlue)
        engine!.disconnectNodeOutput(playerNodeGreen)
        engine!.disconnectNodeOutput(playerNodeOrange)
        engine!.disconnectNodeOutput(playerNodePink)
        engine!.disconnectNodeOutput(playerNodePurple)
        engine!.pause()
        engine!.stop()
    }
    
    func openingEngine() {
        engine!.connect(playerNodeBlue, to: engine!.mainMixerNode, format: audioFileBlue.processingFormat)
        engine!.connect(playerNodeGreen, to: engine!.mainMixerNode, format: audioFileGreen.processingFormat)
        engine!.connect(playerNodeOrange, to: engine!.mainMixerNode, format: audioFileOrange.processingFormat)
        engine!.connect(playerNodePink, to: engine!.mainMixerNode, format: audioFilePink.processingFormat)
        engine!.connect(playerNodePurple, to: engine!.mainMixerNode, format: audioFilePurple.processingFormat)
        engine.prepare()
        do {
            // エンジンを開始
            try engine!.start()
        } catch let error {
            print("engine!.start() error:", error)
        }
    }
    
    func audioFileUpdate() {
        do{
            if tappedColorNum == 0 {
                audioFileBlue = try AVAudioFile(forReading: paths[0])
                audioExists[0] = fileManager.fileExists(atPath: paths[0].path)
            }
            if tappedColorNum == 1 {
                audioFileGreen = try AVAudioFile(forReading: paths[1])
                audioExists[1] = fileManager.fileExists(atPath: paths[1].path)
            }
            if tappedColorNum == 2 {
                audioFileOrange = try AVAudioFile(forReading: paths[2])
                audioExists[2] = fileManager.fileExists(atPath: paths[2].path)
            }
            if tappedColorNum == 3 {
                audioFilePink = try AVAudioFile(forReading: paths[3])
                audioExists[3] = fileManager.fileExists(atPath: paths[3].path)
            }
            if tappedColorNum == 4 {
                audioFilePurple = try AVAudioFile(forReading: paths[4])
                audioExists[4] = fileManager.fileExists(atPath: paths[4].path)
            }
        } catch let error {
            print("AVAudioFile error", error)
        }
    }
    
}

