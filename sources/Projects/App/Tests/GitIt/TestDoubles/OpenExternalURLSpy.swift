import Foundation

actor OpenExternalURLSpy {

    private(set) var openedURLs = [URL]()

    var callCount: Int {
        openedURLs.count
    }

    func callAsFunction(_ url: URL) {
        openedURLs.append(url)
    }

}
