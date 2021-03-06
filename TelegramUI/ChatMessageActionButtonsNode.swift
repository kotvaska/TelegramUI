import Foundation
import AsyncDisplayKit
import TelegramCore
import Postbox
import Display

private let titleFont = Font.medium(16.0)

private final class ChatMessageActionButtonNode: ASDisplayNode {
    private let backgroundNode: ASImageNode
    private var titleNode: TextNode?
    private var buttonView: HighlightTrackingButton?
    
    private var button: ReplyMarkupButton?
    var pressed: ((ReplyMarkupButton) -> Void)?
    
    override init() {
        self.backgroundNode = ASImageNode()
        self.backgroundNode.displayWithoutProcessing = true
        self.backgroundNode.displaysAsynchronously = false
        self.backgroundNode.isLayerBacked = true
        self.backgroundNode.alpha = 1.0
        self.backgroundNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.backgroundNode)
    }
    
    override func didLoad() {
        super.didLoad()
        
        let buttonView = HighlightTrackingButton(frame: self.bounds)
        buttonView.addTarget(self, action: #selector(self.buttonPressed), for: [.touchUpInside])
        self.buttonView = buttonView
        self.view.addSubview(buttonView)
        buttonView.highligthedChanged = { [weak self] highlighted in
            if let strongSelf = self {
                if highlighted {
                    strongSelf.backgroundNode.layer.removeAnimation(forKey: "opacity")
                    strongSelf.backgroundNode.alpha = 0.55
                } else {
                    strongSelf.backgroundNode.alpha = 1.0
                    strongSelf.backgroundNode.layer.animateAlpha(from: 0.55, to: 1.0, duration: 0.2)
                }
            }
        }
    }
    
    @objc func buttonPressed() {
        if let button = self.button, let pressed = self.pressed {
            pressed(button)
        }
    }
    
    class func asyncLayout(_ maybeNode: ChatMessageActionButtonNode?) -> (_ account: Account, _ theme: PresentationTheme, _ strings: PresentationStrings, _ message: Message, _ button: ReplyMarkupButton, _ constrainedWidth: CGFloat, _ position: MessageBubbleActionButtonPosition) -> (minimumWidth: CGFloat, layout: ((CGFloat) -> (CGSize, () -> ChatMessageActionButtonNode))) {
        let titleLayout = TextNode.asyncLayout(maybeNode?.titleNode)
        
        return { account, theme, strings, message, button, constrainedWidth, position in
            let sideInset: CGFloat = 8.0
            let minimumSideInset: CGFloat = 4.0
            
            let incoming = message.effectivelyIncoming(account.peerId)
            
            var title = button.title
            if case .payment = button.action {
                for media in message.media {
                    if let invoice = media as? TelegramMediaInvoice {
                        if invoice.receiptMessageId != nil {
                            title = strings.Message_ReplyActionButtonShowReceipt
                        }
                    }
                }
            }
            
            let (titleSize, titleApply) = titleLayout(TextNodeLayoutArguments(attributedString: NSAttributedString(string: title, font: titleFont, textColor: incoming ? theme.chat.bubble.actionButtonsIncomingTextColor : theme.chat.bubble.actionButtonsOutgoingTextColor), backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: max(1.0, constrainedWidth - minimumSideInset - minimumSideInset), height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets(top: 1.0, left: 0.0, bottom: 1.0, right: 0.0)))
            
            let backgroundImage: UIImage?
            switch position {
                case .middle:
                    backgroundImage = incoming ? PresentationResourcesChat.chatBubbleActionButtonIncomingMiddleImage(theme) : PresentationResourcesChat.chatBubbleActionButtonOutgoingMiddleImage(theme)
                case .bottomLeft:
                    backgroundImage = incoming ? PresentationResourcesChat.chatBubbleActionButtonIncomingBottomLeftImage(theme) : PresentationResourcesChat.chatBubbleActionButtonOutgoingBottomLeftImage(theme)
                case .bottomRight:
                    backgroundImage = incoming ?  PresentationResourcesChat.chatBubbleActionButtonIncomingBottomRightImage(theme) : PresentationResourcesChat.chatBubbleActionButtonOutgoingBottomRightImage(theme)
                case .bottomSingle:
                    backgroundImage = incoming ?  PresentationResourcesChat.chatBubbleActionButtonIncomingBottomSingleImage(theme) : PresentationResourcesChat.chatBubbleActionButtonOutgoingBottomSingleImage(theme)
            }
            
            return (titleSize.size.width + sideInset + sideInset, { width in
                return (CGSize(width: width, height: 42.0), {
                    let node: ChatMessageActionButtonNode
                    if let maybeNode = maybeNode {
                        node = maybeNode
                    } else {
                        node = ChatMessageActionButtonNode()
                    }
                    
                    node.button = button
                    
                    node.backgroundNode.image = backgroundImage
                    node.backgroundNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: max(0.0, width), height: 42.0))
                    
                    let titleNode = titleApply()
                    if node.titleNode !== titleNode {
                        node.titleNode = titleNode
                        node.addSubnode(titleNode)
                        titleNode.isUserInteractionEnabled = false
                    }
                    titleNode.frame = CGRect(origin: CGPoint(x: floor((width - titleSize.size.width) / 2.0), y: floor((42.0 - titleSize.size.height) / 2.0) + 1.0), size: titleSize.size)
                    
                    node.buttonView?.frame = CGRect(origin: CGPoint(), size: CGSize(width: width, height: 42.0))
                    
                    return node
                })
            })
        }
    }
}

final class ChatMessageActionButtonsNode: ASDisplayNode {
    private var buttonNodes: [ChatMessageActionButtonNode] = []
    
    private var buttonPressedWrapper: ((ReplyMarkupButton) -> Void)?
    var buttonPressed: ((ReplyMarkupButton) -> Void)?
    
    override init() {
        super.init()
        
        self.buttonPressedWrapper = { [weak self] button in
            if let buttonPressed = self?.buttonPressed {
                buttonPressed(button)
            }
        }
    }
    
    class func asyncLayout(_ maybeNode: ChatMessageActionButtonsNode?) -> (_ account: Account, _ theme: PresentationTheme, _ strings: PresentationStrings, _ replyMarkup: ReplyMarkupMessageAttribute, _ message: Message, _ constrainedWidth: CGFloat) -> (minWidth: CGFloat, layout: (CGFloat) -> (CGSize, (_ animated: Bool) -> ChatMessageActionButtonsNode)) {
        let currentButtonLayouts = maybeNode?.buttonNodes.map { ChatMessageActionButtonNode.asyncLayout($0) } ?? []
        
        return { account, theme, strings, replyMarkup, message, constrainedWidth in
            let buttonHeight: CGFloat = 42.0
            let buttonSpacing: CGFloat = 4.0
            
            var overallMinimumRowWidth: CGFloat = 0.0
            
            var finalizeRowLayouts: [[((CGFloat) -> (CGSize, () -> ChatMessageActionButtonNode))]] = []
            
            var rowIndex = 0
            var buttonIndex = 0
            for row in replyMarkup.rows {
                var maximumRowButtonWidth: CGFloat = 0.0
                let maximumButtonWidth: CGFloat = max(1.0, floor((constrainedWidth - CGFloat(max(0, row.buttons.count - 1)) * buttonSpacing) / CGFloat(row.buttons.count)))
                var finalizeRowButtonLayouts: [((CGFloat) -> (CGSize, () -> ChatMessageActionButtonNode))] = []
                var rowButtonIndex = 0
                for button in row.buttons {
                    let buttonPosition: MessageBubbleActionButtonPosition
                    if rowIndex == replyMarkup.rows.count - 1 {
                        if row.buttons.count == 1 {
                            buttonPosition = .bottomSingle
                        } else if rowButtonIndex == 0 {
                            buttonPosition = .bottomLeft
                        } else if rowButtonIndex == row.buttons.count - 1 {
                            buttonPosition = .bottomRight
                        } else {
                            buttonPosition = .middle
                        }
                    } else {
                        buttonPosition = .middle
                    }
                    
                    let prepareButtonLayout: (minimumWidth: CGFloat, layout: ((CGFloat) -> (CGSize, () -> ChatMessageActionButtonNode)))
                    if buttonIndex < currentButtonLayouts.count {
                        prepareButtonLayout = currentButtonLayouts[buttonIndex](account, theme, strings, message, button, maximumButtonWidth, buttonPosition)
                    } else {
                        prepareButtonLayout = ChatMessageActionButtonNode.asyncLayout(nil)(account, theme, strings, message, button, maximumButtonWidth, buttonPosition)
                    }
                    
                    maximumRowButtonWidth = max(maximumRowButtonWidth, prepareButtonLayout.minimumWidth)
                    finalizeRowButtonLayouts.append(prepareButtonLayout.layout)
                    
                    buttonIndex += 1
                    rowButtonIndex += 1
                }
                
                overallMinimumRowWidth = max(overallMinimumRowWidth, maximumRowButtonWidth * CGFloat(row.buttons.count) + buttonSpacing * max(0.0, CGFloat(row.buttons.count - 1)))
                finalizeRowLayouts.append(finalizeRowButtonLayouts)
                
                rowIndex += 1
            }
            
            return (min(constrainedWidth, overallMinimumRowWidth), { constrainedWidth in
                var buttonFramesAndApply: [(CGRect, () -> ChatMessageActionButtonNode)] = []
                
                var verticalRowOffset: CGFloat = 0.0
                verticalRowOffset += buttonSpacing
                
                var rowIndex = 0
                for finalizeRowButtonLayouts in finalizeRowLayouts {
                    let actualButtonWidth: CGFloat = max(1.0, floor((constrainedWidth - CGFloat(max(0, finalizeRowButtonLayouts.count - 1)) * buttonSpacing) / CGFloat(finalizeRowButtonLayouts.count)))
                    var horizontalButtonOffset: CGFloat = 0.0
                    for finalizeButtonLayout in finalizeRowButtonLayouts {
                        let (buttonSize, buttonApply) = finalizeButtonLayout(actualButtonWidth)
                        let buttonFrame = CGRect(origin: CGPoint(x: horizontalButtonOffset, y: verticalRowOffset), size: buttonSize)
                        buttonFramesAndApply.append((buttonFrame, buttonApply))
                        horizontalButtonOffset += buttonSize.width + buttonSpacing
                    }
                    
                    verticalRowOffset += buttonHeight + buttonSpacing
                    rowIndex += 1
                }
                if verticalRowOffset > 0.0 {
                    verticalRowOffset = max(0.0, verticalRowOffset - buttonSpacing)
                }
                
                return (CGSize(width: constrainedWidth, height: verticalRowOffset), { animated in
                    let node: ChatMessageActionButtonsNode
                    if let maybeNode = maybeNode {
                        node = maybeNode
                    } else {
                        node = ChatMessageActionButtonsNode()
                    }
                    
                    var updatedButtons: [ChatMessageActionButtonNode] = []
                    var index = 0
                    for (buttonFrame, buttonApply) in buttonFramesAndApply {
                        let buttonNode = buttonApply()
                        buttonNode.frame = buttonFrame
                        updatedButtons.append(buttonNode)
                        if buttonNode.supernode == nil {
                            node.addSubnode(buttonNode)
                            buttonNode.pressed = node.buttonPressedWrapper
                        }
                        index += 1
                    }
                    
                    var buttonsUpdated = false
                    if node.buttonNodes.count != updatedButtons.count {
                        buttonsUpdated = true
                    } else {
                        for i in 0 ..< updatedButtons.count {
                            if updatedButtons[i] !== node.buttonNodes[i] {
                                buttonsUpdated = true
                                break
                            }
                        }
                    }
                    if buttonsUpdated {
                        for currentButton in node.buttonNodes {
                            if !updatedButtons.contains(currentButton) {
                                currentButton.removeFromSupernode()
                            }
                        }
                    }
                    node.buttonNodes = updatedButtons
                    
                    if animated {
                        /*UIView.transition(with: node.view, duration: 0.2, options: [.transitionCrossDissolve], animations: {
                            
                        }, completion: nil)*/
                    }
                    
                    return node
                })
            })
        }
    }
}
