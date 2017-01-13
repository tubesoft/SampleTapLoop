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
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var lblColor: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    var timer: Timer!
    var cnt: Float = 0.0
    let fileManager = FileManager()
    let engine = AVAudioEngine()
    var audioPlayer: AVAudioPlayer!
    var fileName: String = ""
    var filePath: NSURL?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblColor.text = txtColor
        // Do any additional setup after loading the view.
        do {
            // 保存する場所: 今回はDocumentディレクトリにファイル名"sample.caf"で保存
            let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            filePath = NSURL(fileURLWithPath: documentDir + "/" + txtColor! + ".caf")
            // オーディオフォーマット
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32  , sampleRate: 44100, channels: 1 , interleaved: true)
            // オーディオファイル
            let audioFile = try AVAudioFile(forWriting: filePath as! URL, settings: format.settings)
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func pressPlay(_ sender: Any) {
        play()
    }
    
    @IBAction func pressRec(_ sender: Any) {
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
        labelStatus.text = "Now Recording"
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
        print(cnt)
        if cnt == 1000 {
            timer.invalidate()
            engine.stop()
            btnDone.isEnabled = true
            btnPlay.isEnabled = true
            labelStatus.text = "Recording is ready. (Within 1 min)"
        }
    }
    
    // 再生
    func play() {
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: filePath as! URL)
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
