import SpriteKit
import GameplayKit
let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"
let BallCategory : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4






class GameScene: SKScene, SKPhysicsContactDelegate {
    var isFingerOnPaddle = false
    
    func  randomFloat (from: CGFloat, to: CGFloat) -> CGFloat {
        let rand = CGFloat (Double(arc4random()) / 0xFFFFFFFF )
        return (rand) * (to - from) + from
    }
    
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    func breakBlock(node: SKNode) {
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0),
                                         SKAction.removeFromParent()]))
        node.removeFromParent()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        
        
        // 1
        let numberOfBlocks = 9
        let blockWidth = SKSpriteNode (imageNamed: "block") .size.width
        let totalBlocksWidth = blockWidth * CGFloat (numberOfBlocks)
        // 2
        let xOffset = (frame.width - totalBlocksWidth) / 2
        // 3
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block")
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat (i) + 0.5) *
                blockWidth,
                                     y: frame.height * 0.8)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
        
        
        //1
        let borderBody = SKPhysicsBody (edgeLoopFrom: self .frame)
        //2
        borderBody.friction = 0
        //3
        self .physicsBody = borderBody
        
        physicsWorld.contactDelegate = self
        
        physicsWorld.gravity = CGVector (dx: 0.0, dy: 0.0 )
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y,
                                width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
        
        
        let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        ball.physicsBody! .contactTestBitMask = BottomCategory | BlockCategory
        
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        gameState.enter(WaitingForTap.self)

        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnPaddle = true
            
        case is Playing:
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            
            if let body = physicsWorld.body(at: touchLocation) {
                if body.node!.name == PaddleCategoryName {
                    isFingerOnPaddle = true
                }
            }
        default :
            break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if isFingerOnPaddle {
            // 2
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            //3
            let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
            //4
            var paddleX = paddle.position.x + (touchLocation.x -
                previousLocation.x)
            //5
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            //6
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
        
    }
    
    func  didBegin ( _ contact: SKPhysicsContact) {
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        // 2
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        // 3
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
            print ( " Hit bottom. First contact has been made." )
        }
        
        if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask
            == BlockCategory {
            breakBlock(node: secondBody.node!)
            //TODO: check if the game has been won
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
}


