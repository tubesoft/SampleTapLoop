//
//  samplingViewController.swift
//  SampleTapLoop
//
//  Created by Takatomo INOUE on 2017/01/11.
//  Copyright © 2017年 Takatomo INOUE. All rights reserved.
//

import UIKit
import AVFoundation

class SamplingViewController: UIViewController {
    var txtColor: String?
    
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnRec: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var lblColor: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    var timer: Timer?
    var cnt: Int = 0
    let fileManager = FileManager()
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var audioFileSpare: NSData!
    var fileName: String = ""
    var filePath: URL?
    var filePathTmp: URL?
    var isRecorded = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblColor.text = NSLocalizedString(txtColor!, comment: "")
        btnDone.isEnabled = false
        btnPlay.isEnabled = false
        // 保存する場所: tmpフォルダにファイル名"xxxxx.caf"で保存
        let tmpDirPath = NSTemporaryDirectory()
        filePathTmp = URL(fileURLWithPath: tmpDirPath + "/temp.caf")
        filePath = URL(fileURLWithPath: tmpDirPath + "/" + txtColor! + ".caf")
        
        setAudioSession(isRecording: true)
        
    }
    
    func setAudioSession(isRecording: Bool) {
//        let session = AVAudioSession.sharedInstance()
        do {
//            try session.setActive(true)
            let recordSetting : [String : AnyObject]
                = [
                    AVEncoderAudioQualityKey : AVAudioQuality.min.rawValue as AnyObject,
                    AVEncoderBitRateKey : 16 as AnyObject,
                    AVNumberOfChannelsKey: 2 as AnyObject,
                    AVSampleRateKey: 44100.0 as AnyObject
            ]
            try audioRecorder = AVAudioRecorder(url:filePathTmp!, settings: recordSetting)
        } catch {
            assertionFailure("AVAudioRecorder setup error: \(error)")
        }
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        audioRecorder?.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pressPlay(_ sender: Any) {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: filePath!)
            audioPlayer?.play()
        }
        catch let error {
            print("AVAudioPlayer error:", error)
        }
    }
    
    @IBAction func pressRec(_ sender: Any) {
        btnDone.isEnabled = false
        btnPlay.isEnabled = false
        btnRec.isEnabled = false
        btnCancel.isEnabled = false
        isRecorded = true
        labelStatus.text = NSLocalizedString("NowRecording", comment: "")
        timer = Timer.scheduledTimer(
            timeInterval: 0.001,
            target: self,
            selector: #selector(self.update),
            userInfo: nil,
            repeats: true
        )
        audioRecorder?.record()
    }
    
    @objc func update(t: Timer) {
        // do something
        cnt = cnt + 1
        progressView.progress = (Float(cnt)/1000.0)
        if cnt == 1000 {
            timer?.invalidate()
            audioRecorder?.stop()
            let tmpAudio = NSData(contentsOf: filePathTmp!)
            tmpAudio?.write(to: filePath!, atomically: true)
            audioRecorder?.record()
            audioRecorder?.pause()
            cnt = 0
            btnDone.isEnabled = true
            btnPlay.isEnabled = true
            btnRec.isEnabled = true
            btnCancel.isEnabled = true
            labelStatus.text = NSLocalizedString("NowReady", comment: "")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioRecorder?.stop()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
