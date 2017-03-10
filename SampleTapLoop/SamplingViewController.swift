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
    private var txtColor: String?
    var valueAccessor: String? {
        get {
            return self.txtColor
        }
        set(value) {
            self.txtColor = value
        }
    }
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnRec: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var lblColor: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    var timer: Timer!
    var cnt: Float = 0.0
    let fileManager = FileManager()
    let engine = AVAudioEngine()
    var audioPlayer: AVAudioPlayer!
    let session = AVAudioSession.sharedInstance()
    var audioFileSpare: NSData!
    var fileName: String = ""
    var filePath: URL?
    var isRecorded = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblColor.text = NSLocalizedString(txtColor!, comment: "")
        btnDone.isEnabled = false
        btnPlay.isEnabled = false
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
//            try session.setMode(AVAudioSessionModeDefault)
//            let ioBufferDuration = 128.0 / 44100.0
//            try session.setPreferredIOBufferDuration(ioBufferDuration)
            try session.setActive(true)
        } catch {
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        // 保存する場所: 今回はDocumentディレクトリにファイル名"xxxxx.caf"で保存
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        filePath = URL(fileURLWithPath: documentDir + "/" + txtColor! + ".caf")
        
        audioFileSpare = NSData(contentsOf: filePath!)  // 元のファイルを退避
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func pressPlay(_ sender: Any) {
        play()
    }
    
    @IBAction func pressRec(_ sender: Any) {
        do {
            
            // オーディオフォーマット
//            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32  , sampleRate: 44100, channels: 1 , interleaved: true)
            let format = engine.inputNode?.outputFormat(forBus: 0)
            // オーディオファイル
            let audioFile = try AVAudioFile(forWriting: filePath!, settings: (format?.settings)!)
            // inputNodeの出力バス(インデックス0)にタップをインストール
            // installTapOnBusの引数formatにnilを指定するとタップをインストールしたノードの出力バスのフォーマットを使用する
            // (この例だとフォーマットに inputNode.outputFormatForBus(0) を指定するのと同じ)
            // tapBlockはメインスレッドで実行されるとは限らないので注意
            let inputNode = engine.inputNode!  // 端末にマイクがあると仮定する
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { (buffer, when) in
                do {
                    // audioFileにバッファを書き込む
                    try audioFile.write(from: buffer)
                } catch let error {
                    print("audioFile.writeFromBuffer error:", error)
                }
            }
        } catch let error {
            print("AVAudioFile error:", error)
        }
        
        engine.prepare()
        timer = Timer.scheduledTimer(
            timeInterval: 0.001,
            target: self,
            selector: #selector(self.update),
            userInfo: nil,
            repeats: true
        )
        cnt = 0.0
        timer.fire()
        btnDone.isEnabled = false
        btnPlay.isEnabled = false
        btnRec.isEnabled = false
        btnCancel.isEnabled = false
        isRecorded = true
        labelStatus.text = NSLocalizedString("NowRecording", comment: "")
        do {
            // エンジンを開始
            try engine.start()
        } catch let error {
            print("engine.start() error:", error)
        }

    }
    
    func update(t: Timer) {
        // do something
        cnt = cnt + 1
        progressView.progress = (cnt/1000.0)
//        print(cnt)
        if cnt == 1000 {
            timer.invalidate()
            engine.pause()
            engine.stop()
            engine.inputNode?.removeTap(onBus: 0)
            btnDone.isEnabled = true
            btnPlay.isEnabled = true
            btnRec.isEnabled = true
            btnCancel.isEnabled = true
            labelStatus.text = NSLocalizedString("NowReady", comment: "")
        }
    }
    
    // 再生
    func play() {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: filePath!)
            audioPlayer.play()
        }
        catch let error {
                print("AVAudioPlayer error:", error)
            }
    }
    
    func documentFilePath()-> NSURL {
        let name = txtColor! + ".caf"
        
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask) as [URL]
        let dirURL = urls[0]
        return dirURL.appendingPathComponent(name) as NSURL
    }
    
    @IBAction func touchUpCancel(_ sender: Any) {
        if fileManager.fileExists(atPath: (filePath?.path)!) {
            if audioFileSpare != nil {
                audioFileSpare.write(to: filePath!, atomically: true)
            } else {
                do {
                    try fileManager.removeItem(at: filePath!)
                } catch let error {
                    print ("removeItem error", error)
                }
            }
        }
        
        let targetViewController:ViewController = self.storyboard!.instantiateViewController( withIdentifier: "main" ) as! ViewController
        self.present(targetViewController, animated: true, completion: nil)
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
