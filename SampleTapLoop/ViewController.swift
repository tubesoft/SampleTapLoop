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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecording() {
        //タイマーオン
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        //タイマーオフ
    }

    @IBAction func stopPlaying(_ sender: Any) {
    }
    
    @IBAction func startPlaying(_ sender: Any) {
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
            do{
                audioPlayerPurple = try AVAudioPlayer(contentsOf: paths[4] as URL)
                audioPlayerPurple.play()
            }
            catch let error {
                print("AVAudioPlayer error:", error)
            }
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

