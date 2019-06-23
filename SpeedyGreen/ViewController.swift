//
//  ViewController.swift
//  SpeedyGreen
//
//  Created by Christopher on 6/16/19.
//  Copyright © 2019 Christopher. All rights reserved.
//

import UIKit
import GameKit

class ViewController: UIViewController, GKGameCenterControllerDelegate{

    
    
    @IBOutlet weak var dSlider: UISegmentedControl!
    @IBOutlet weak var livesLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var world: UIImageView!
    @IBOutlet weak var logo: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    //GameCenter Stuff
    var gcEnabled = Bool()
    var gcDefaultLeaderBoard = String()
    let LEADERBOARD_ID = "com.taptationhighscores.taptation"
    
    
    var shapeLayer = CAShapeLayer()
    var particleEmitter = CAEmitterLayer()
    var totalLevels = 0
    var lives = 3
    var score = 0
    var gameRunning = false
    var active = true
    var difficulty = 2
    var images = [Data]()
    var gameLoaded = false
    var onIPad = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startButton.layer.cornerRadius = 15
        startButton.clipsToBounds = true
        
        dSlider.layer.cornerRadius = 4.0;
        dSlider.clipsToBounds = true;
        
        dSlider.centerXAnchor.constraint(equalTo: world.centerXAnchor).isActive = true
        startButton.centerXAnchor.constraint(equalTo: world.centerXAnchor).isActive = true
        
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            onIPad = false
        case .pad:
            onIPad = true
        default:
            onIPad = false
        }
        
        totalLevels = 6
        startButton.setTitle("Loading...", for:.normal)
        nextColor = Int.random(in: 0..<colors.count)
        growImages()
        
        // Authenticate GameCenter
        authenticateLocalPlayer()
    }
    
    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer:GKLocalPlayer = GKLocalPlayer.localPlayer
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error)
            }
        }
    }
    
    // MARK: - ADD 10 POINTS TO THE SCORE AND SUBMIT THE UPDATED SCORE TO GAME CENTER
    @IBAction func uploadScore() {
        // Submit score to GC leaderboard
        let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        bestScoreInt.value = Int64(score)
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to your Leaderboard!")
            }
        }
    }
    // Delegate to dismiss the GC controller
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    // MARK: - OPEN GAME CENTER LEADERBOARD
    @IBAction func checkGCLeaderboard() {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
    }
    
    //Downloads 1 more image
    func growImages(){
        var url: URL
        if(onIPad){
            url = URL(string: "https://source.unsplash.com/2732x2048/?" + colors[nextColor])!
        }else{
            url = URL(string: "https://source.unsplash.com/1920x1080/?" + colors[nextColor])!
        }
        
        downloadImage(from: url)
        
        totalLevels = images.count
        
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL) {
        print("Download Started, with query " + colors[nextColor])
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                self.images.append(data)
                self.gameLoaded = true
                self.startButton.setTitle("Tap", for:.normal)
            }
        }
    }
    
    func destroyParticles(){
        particleEmitter.removeFromSuperlayer()
    }
    //Add particles to game
    func createParticles() {
        particleEmitter = CAEmitterLayer()
        
        particleEmitter.emitterPosition = CGPoint(x: view.center.x, y: -96)
        particleEmitter.emitterShape = .line
        particleEmitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        let white = makeEmitterCell(eColor: UIColor.white)
        
        particleEmitter.emitterCells = [white]
        
        view.layer.addSublayer(particleEmitter)
    }
    func makeEmitterCell(eColor: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 4
        cell.lifetime = 45.0
        cell.lifetimeRange = 0
        cell.color = eColor.cgColor
        cell.velocity = 25
        cell.velocityRange = 50
        cell.emissionLongitude = CGFloat.pi
        cell.emissionRange = CGFloat.pi / 4
        cell.spin = 2
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05
        
        cell.contents = UIImage(named: "snow")?.cgImage
        return cell
    }
    
    
    //App background and foreground logic
    func becomeActive(){
        print("Back in foreground")
        active = true
        if(gameRunning){
            addBall()
        }
    }
    func becomeInactive(){
        print("Game sent to background")
        active = false
        timer?.invalidate()
        timer = nil
    }
    
    //Make it rotate for when the app starts
    override var shouldAutorotate: Bool {
        return true
    }
    //Hide Status Bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //On Screen Touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameRunning){
            let touch = touches.first
        
            guard let point = touch?.location(in: world) else { return }
        
            if(shapeLayer.path!.contains(point)){
                destroyBall()
            }
        }
    }
    
    func destroyBall(){
        timer?.invalidate()
        timer = nil
        vibe()
        score+=1
        if score > (level + 5) * (level + 1) {
            nextLevel()
        }
        addBall()
        scoreLabel.text = String(score)
        livesLabel.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    //Go to next Level, after getting a certain number of points
    var level = 0;
    var minLevelTime = 1.5
    var colors = ["blue","red","green","white","black","orange","yellow","purple"]
    var colorNum = 0
    var color = UIColor(red:0,green: 0,blue: 0,alpha:1)
    var nextColor = 0
    
    func nextLevel(){
        colorNum = nextColor
        levelTime-=0.25
        if(levelTime < minLevelTime){ //Around level 6, ball shrinking caps at 1.5 seconds
            levelTime = minLevelTime
        }
        if(level>totalLevels || level<0){
            level = 0
        }
        world.image = UIImage(data: images[level])
        addBall()
        nextColor = Int.random(in: 0..<colors.count)
        print("Next Color will be " + colors[nextColor])
        level+=1
        print("Entering next level")
        growImages()
    }
    
    //Spawn the next ball to tap, only supports one at a time
    func addBall(){
        shapeLayer.removeFromSuperlayer();
        
        //Calculate Spawn Location
        let screensize: CGRect = UIScreen.main.bounds
        let xPos = Int.random(in: 50 ..< Int(screensize.width - 50))
        let yPos = Int.random(in: 50 ..< Int(screensize.height - 50))
        
        switch difficulty{
        case 0:
            color = getColor(levelColor: colorNum, a:1)
        case 1:
            color = getColor(levelColor: colorNum, a:0.5)
        case 2:
            //color = getColor(levelColor: colorNum, a:0.2)
            color = getPixel(x:xPos,y:yPos,image:world.image!)
        default:
            color = getColor(levelColor: colorNum, a:1)
        }
        
        
        createCircle(color:color,xP:xPos,yP:yPos);

        startTimer()
        
        print("Ball Spawned, color " + colors[colorNum])
    }
    
    func getColor(levelColor:Int, a:CGFloat) -> UIColor{
        switch levelColor{
            case 0://Blue
                return UIColor.blue.withAlphaComponent(a)
            case 1://Red
                return UIColor.red.withAlphaComponent(a)
            case 2://Green
                return UIColor.green.withAlphaComponent(a)
            case 3://White
                return UIColor.white.withAlphaComponent(a)
            case 4://Black
                return UIColor.black.withAlphaComponent(a)
            case 5://Orange
                return UIColor.orange.withAlphaComponent(a)
            case 6://Yellow
                return UIColor.yellow.withAlphaComponent(a)
            case 7://Purple
                return UIColor.purple.withAlphaComponent(a)
            default: //Anything else returns white
                return UIColor.white.withAlphaComponent(a)
        }
    }
    
    
    //Get Pixel color from the Image at a x and y location
    func getPixel(x:Int,y:Int,image:UIImage) ->UIColor{
        if x < 0 || x > Int(image.size.width) || y < 0 || y > Int(image.size.height) {
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        let provider = image.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        
        let numberOfComponents = 4
        let pixelData = ((Int(image.size.width) * y) + x) * numberOfComponents
        
        let r = CGFloat(data![pixelData]) / 255.0
        let g = CGFloat(data![pixelData + 1]) / 255.0
        let b = CGFloat(data![pixelData + 2]) / 255.0
        //let a = CGFloat(data![pixelData + 3]) / 255.0
        let a  = CGFloat(0.5)
        //print("Pixel at " + \(x) + "," + \(y) + " is red:" + \(r) + ", green:" + \(g) + ", blue:" + \(b))
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    //Make the circle
    func createCircle(color:UIColor,xP:Int,yP:Int){
        let circleStart = UIBezierPath(arcCenter: CGPoint(x: xP,y: yP), radius: CGFloat(30), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        let circleEnd = UIBezierPath(arcCenter: CGPoint(x: xP,y: yP), radius: CGFloat(1), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer.path = circleStart.cgPath
        
        //change the fill color
        shapeLayer.fillColor = color.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = color.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 0
        
        view.layer.addSublayer(shapeLayer)
        
        
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.toValue = circleEnd.cgPath
        pathAnimation.duration = levelTime + 0.05
        //pathAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        //pathAnimation.autoreverses = true
        pathAnimation.repeatCount = 0
        
        shapeLayer.add(pathAnimation, forKey: "pathAnimation")
    }
    
    //Restart the timer after being stopped for moveToBackground or from addBall
    var timer:Timer?
    var levelTime = 3.0 //defaults to 3.0
    func startTimer(){
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: levelTime, target: self,   selector: #selector(lostLevel), userInfo: nil, repeats: false)
        }
    }
    
    //Haptic feedback from tapping the ball
    func vibe(){
        let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
    }
    
    //Send to previous level, also checks for end of game
    @objc func lostLevel(){
        print("Missed Ball. Health -1")
        destroyBall()
        livesLabel.textColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        lives-=1
        score-=1
        livesLabel.text = String(lives)
        if(lives<=0){ //End Game
            print("Player Died, Ending Game")
            resetGame()
        }
    }
    
    //Reset Game after it ends
    func resetGame(){
        shapeLayer.removeFromSuperlayer();
        timer?.invalidate()
        timer = nil
        lives = 3
        livesLabel.text = String(lives)
        level = 0
        if(self.gcEnabled){
            uploadScore()
            checkGCLeaderboard()
        }
        score = 0
        logo.text = "Try Again?"
        logo.isHidden = false
        startButton.isHidden = false
        livesLabel.isHidden = true
        dSlider.isHidden = false
        gameRunning = false
        images = [Data]()
        gameLoaded = false
        startButton.setTitle("Loading...", for:.normal)
        levelTime = 3.0
        growImages()
    }
    
    //Start game from the start menu
    @IBAction func startGame(_ sender: Any) {
        if(gameLoaded){
            logo.isHidden = true
            startButton.isHidden = true
            dSlider.isHidden = true
            livesLabel.text = String(lives)
            livesLabel.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            livesLabel.isHidden = false
            scoreLabel.isHidden = false
            scoreLabel.text = String(score)
            difficulty = dSlider.selectedSegmentIndex
            if(difficulty == 2){
                createParticles()
            }else{
                destroyParticles()
            }
            nextLevel()
            gameRunning = true
        }
    }
    
}

