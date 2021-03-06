import Foundation
import Display
import TelegramCore
import Postbox
import SwiftSignalKit

final class FeedGroupingController: ViewController {
    private var controllerNode: FeedGroupingControllerNode {
        return self.displayNode as! FeedGroupingControllerNode
    }
    
    private let account: Account
    private let groupId: PeerGroupId
    private var presentationData: PresentationData
    
    init(account: Account, groupId: PeerGroupId) {
        self.account = account
        self.groupId = groupId
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        self.title = "Grouping"
        
        /*let rightButton = ChatNavigationButton(action: .search, buttonItem: UIBarButtonItem(image: navigationCompactSearchIcon(self.presentationData.theme), style: .plain, target: self, action: #selector(self.activateSearch)))
        self.navigationItem.setRightBarButton(rightButton.buttonItem, animated: false)*/

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadDisplayNode() {
        self.displayNode = FeedGroupingControllerNode(account: self.account, groupId: self.groupId, presentationData: self.presentationData, ungroupedAll: { [weak self] in
            (self?.navigationController as? NavigationController)?.popToRoot(animated: true)
        })
        
        self.displayNodeDidLoad()
        
        self.ready.set(self.controllerNode.readyPromise.get())
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
}

