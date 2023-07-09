import Foundation
import SpriteKit
import GameplayKit
import CoreMotion

public class GameScene2: SKScene, SKPhysicsContactDelegate {
    var innerContentSize: CGSize = CGSize.zero
    var innerContentOffset: CGPoint = CGPoint.zero
    weak var spriteToScroll: SKSpriteNode?
    weak var spriteForScrollingGeometry: SKSpriteNode?
    
    let secondesParHauteur:CGFloat = 3
    var secondeToPixel:CGFloat = 1
    var heightDefault:CGFloat = 100
    var duration:CGFloat = 0
    
    weak var myPlayer:PlayerVC2?
    var rondASupprimer:SKShapeNode?
    var oldRondASupprimer:SKShapeNode?
    
    deinit{
        print("deinit gamescene2")
    }

    override init(size: CGSize) {
        super.init(size:size)

        self.anchorPoint = CGPoint.zero
        let spriteToScroll = SKSpriteNode(color: SKColor.clear, size: size)
        spriteToScroll.anchorPoint = CGPoint.zero
        self.addChild(spriteToScroll)

        let spriteForScrollingGeometry = SKSpriteNode(color: SKColor.clear, size: size)
        spriteForScrollingGeometry.anchorPoint = CGPoint.zero
        spriteForScrollingGeometry.position = CGPoint.zero
        spriteToScroll.addChild(spriteForScrollingGeometry)

        self.contentSize = size
        self.spriteToScroll = spriteToScroll
        self.spriteForScrollingGeometry = spriteForScrollingGeometry
        self.contentOffset = CGPoint.zero
        bougerPianoRoll(seconds:0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var contentSize: CGSize {
        get {
            return innerContentSize
        }
        set {
            if !newValue.equalTo(innerContentSize) {
                innerContentSize = newValue
                self.spriteToScroll?.size = newValue
                self.spriteForScrollingGeometry?.size = newValue
                self.spriteForScrollingGeometry?.position = CGPoint.zero
                updateConstrainedScrollerSize()
            }
        }
    }

    public var contentOffset: CGPoint {
        get {
            return innerContentOffset
        }
        set {
            if !newValue.equalTo(innerContentOffset) {
                innerContentOffset = newValue
                contentOffsetReload()
            }
        }
    }

    func contentOffsetReload() {
        self.spriteToScroll?.position = CGPoint(x: -innerContentOffset.x, y: -innerContentOffset.y)
        print("offset: \(innerContentOffset.y)")
    }

    func updateConstrainedScrollerSize() {
        let contentSize: CGSize = self.contentSize
        contentOffsetReload()
    }

    func getCurrentTime() -> CGFloat {
        return pixelToSecondeFunc(pixels: -spriteForScrollingGeometry!.position.y)
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch:UITouch = touches.first!
        let positionInScene = touch.location(in: self)
        print("touched: \(positionInScene.x), \(positionInScene.y)")
        let touchedNodes = self.nodes(at: positionInScene)

        if touchedNodes.count > 2 {
            guard let cercle = touchedNodes.first as? SKShapeNode else{
                print("whaaaat ?!")
                return
            }
            if cercle != rondASupprimer{
                if(oldRondASupprimer != nil){
                    desentourerRond(circle: oldRondASupprimer!)
                }
                rondASupprimer = cercle
                entourerRond(circle: rondASupprimer!)
                oldRondASupprimer = rondASupprimer
            } else {
                desentourerRond(circle: rondASupprimer!)
                rondASupprimer = nil
                oldRondASupprimer = nil
            }
        }

    }

    
    func getCircle() -> SKShapeNode{
//        let circle = SKShapeNode(circleOfRadius: size.width / 14)
        let largeur = size.width / 7
        let hauteur = largeur / 2
        let sizeEllipse = CGSize(width: largeur, height: hauteur)
        let circle = SKShapeNode(ellipseOf: sizeEllipse)
        return circle
    }
    
    func getRectangle() -> SKShapeNode{
        let largeur = size.width / 7
        let hauteur = largeur / 2
        let sizeRectangle = CGSize(width: largeur, height: hauteur)
        let circle = SKShapeNode(rectOf: sizeRectangle, cornerRadius: 4)
        return circle
    }
    
    func ajouterRectangleChord(seconde:CGFloat, colonne:Int, tag:Int){
        var circle = getRectangle()
        let yy = seconde * secondeToPixel
        circle.position = CGPoint(x: size.width * (CGFloat(myPlayer!.noteColumn[colonne]) + 0.5)/7 , y: yy)
        let i1 = tag
        let isDiese = myPlayer!.noteLine[(i1+1200) % 12]
        var quelleLigne = i1 / 12
        circle.fillColor = myPlayer!.buttonColors[quelleLigne][isDiese]
        circle.name = String(tag)
        spriteForScrollingGeometry!.addChild(circle)
    }
    
    /*func ajouterRondChord(seconde:CGFloat, colonne:Int, tag:Int){
        var circle = getCircle()
        let yy = seconde * secondeToPixel
        circle.position = CGPoint(x: size.width * (CGFloat(myPlayer!.noteColumn[colonne]) + 0.5)/7 , y: yy)

        let i1 = tag
        let isDiese = myPlayer!.noteLine[(i1+1200) % 12]
        var quelleLigne = i1 / 12
        circle.fillColor = myPlayer!.buttonColors[quelleLigne][isDiese]

        circle.name = String(tag)
        spriteForScrollingGeometry!.addChild(circle)
    }*/

    func ajouterRond(seconde:CGFloat, colonne:Int, noteNumber:Int){
        var circle = getCircle()
        let yy = seconde * secondeToPixel
        circle.position = CGPoint(x: size.width * (CGFloat(colonne) + 0.5)/7 , y: yy)
        let i1 = noteNumber - globalVar.song!.rootNote
        let isDiese = myPlayer!.noteLine[(i1+1200) % 12]
        var quelleLigne = i1 / 12
        if quelleLigne >= 3{
            quelleLigne = 2
        } else if quelleLigne < 0{
            quelleLigne = 0
        }
        circle.fillColor = myPlayer!.buttonColors[quelleLigne][isDiese]
        circle.name = String(noteNumber)
        spriteForScrollingGeometry!.addChild(circle)
    }

    func entourerRond(circle:SKShapeNode){
        circle.glowWidth = 5
        circle.strokeColor = SKColor.red
    }

    func desentourerRond(circle:SKShapeNode){
        circle.glowWidth = 0
        circle.strokeColor = SKColor.black
    }

    func supprimerRond(circle:SKShapeNode){
        spriteForScrollingGeometry!.removeChildren(in: [circle])
    }

    func animerToFin(){
        let myDuration = TimeInterval(duration - getCurrentTime())
        let yObjectif = secondeToPixelFunc(secondes: duration)
        let pointObjectif = CGPoint(x: 0, y: -yObjectif)
        let action = SKAction.move(to: pointObjectif, duration: myDuration)
        print("myDuration \(myDuration)")
        print("yObjectif \(yObjectif)")
        spriteForScrollingGeometry!.run(action, withKey: "coucou")
    }

    func stopDefilement(){
        spriteForScrollingGeometry!.removeAllActions()
    }

    func bougerPianoRoll(seconds:CGFloat){
        let xx:CGFloat = 0 //-innerContentOffset.x
        let yy = -secondeToPixelFunc(secondes: seconds)
        print("moved to x,y: \(xx), \(yy)")
        self.spriteForScrollingGeometry?.position = CGPoint(x: xx, y: yy)
    }

    func secondeToPixelFuncLecture(secondes:CGFloat) -> CGFloat{
        return (secondes * secondeToPixel)
    }

    func pixelToSecondeFuncLecture(pixels:CGFloat) -> CGFloat{
        return (pixels) / secondeToPixel
    }

    func secondeToPixelFuncEcriture(secondes:CGFloat) -> CGFloat{
        return (secondes * secondeToPixel) - heightDefault
    }

    func pixelToSecondeFuncEcriture(pixels:CGFloat) -> CGFloat{
        return (pixels + heightDefault) / secondeToPixel
    }

    func secondeToPixelFuncInBetween(secondes:CGFloat) -> CGFloat{
        return (secondes * secondeToPixel) - (heightDefault / 2)
    }

    func pixelToSecondeFuncInBetween(pixels:CGFloat) -> CGFloat{
        return (pixels + (heightDefault / 2)) / secondeToPixel
    }

    func pixelToSecondeFunc(pixels:CGFloat) -> CGFloat{
        switch globalVar.modeAffichage{
        case 0:
            return pixelToSecondeFuncEcriture(pixels: pixels)
        case 1:
            return pixelToSecondeFuncInBetween(pixels: pixels)
        case 2:
            return pixelToSecondeFuncLecture(pixels: pixels)
        default:
            return pixelToSecondeFuncEcriture(pixels: pixels)
        }
    }

    func secondeToPixelFunc(secondes:CGFloat) -> CGFloat{
        switch globalVar.modeAffichage{
        case 0:
            return secondeToPixelFuncEcriture(secondes: secondes)
        case 1:
            return secondeToPixelFuncInBetween(secondes: secondes)
        case 2:
            return secondeToPixelFuncLecture(secondes: secondes)
        default:
            return secondeToPixelFuncEcriture(secondes: secondes)
        }
    }
    
}
