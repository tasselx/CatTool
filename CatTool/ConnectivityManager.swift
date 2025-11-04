import Foundation

enum ConnectivityStatus: Equatable {
    case unknown
    case testing
    case success(responseTime: TimeInterval)
    case failure(error: String)
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var displayText: String {
        switch self {
        case .unknown:
            return "未测试"
        case .testing:
            return "测试中..."
        case .success(let time):
            return String(format: "%.0fms", time * 1000)
        case .failure(let error):
            return "失败: \(error)"
        }
    }
}

class ConnectivityManager: ObservableObject {
    static let shared = ConnectivityManager()
    
    @Published var statuses: [Int: ConnectivityStatus] = [:]
    
    private init() {}
    
    func testConnectivity(for subscription: Subscription) async {
        await MainActor.run {
            statuses[subscription.id] = .testing
        }
        
        guard let url = URL(string: subscription.url) else {
            await MainActor.run {
                statuses[subscription.id] = .failure(error: "无效URL")
            }
            return
        }
        
        let startTime = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("CatTool/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...399).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        statuses[subscription.id] = .success(responseTime: responseTime)
                    }
                } else {
                    await MainActor.run {
                        statuses[subscription.id] = .failure(error: "HTTP \(httpResponse.statusCode)")
                    }
                }
            } else {
                await MainActor.run {
                    statuses[subscription.id] = .failure(error: "无效响应")
                }
            }
        } catch {
            await MainActor.run {
                let nsError = error as NSError
                let errorMessage: String
                
                switch nsError.code {
                case NSURLErrorTimedOut:
                    errorMessage = "超时"
                case NSURLErrorCannotFindHost:
                    errorMessage = "无法找到主机"
                case NSURLErrorCannotConnectToHost:
                    errorMessage = "无法连接"
                case NSURLErrorNetworkConnectionLost:
                    errorMessage = "网络连接断开"
                case NSURLErrorNotConnectedToInternet:
                    errorMessage = "无网络连接"
                case NSURLErrorSecureConnectionFailed:
                    errorMessage = "安全连接失败"
                case NSURLErrorServerCertificateUntrusted:
                    errorMessage = "证书不受信任"
                case NSURLErrorAppTransportSecurityRequiresSecureConnection:
                    errorMessage = "需要HTTPS"
                default:
                    errorMessage = "\(nsError.localizedDescription)"
                }
                
                print("🔴 测试失败 [\(subscription.name)]: \(errorMessage) (错误码: \(nsError.code))")
                statuses[subscription.id] = .failure(error: errorMessage)
            }
        }
    }
    
    func testAllConnectivity(subscriptions: [Subscription]) async {
        await withTaskGroup(of: Void.self) { group in
            for subscription in subscriptions {
                group.addTask {
                    await self.testConnectivity(for: subscription)
                }
            }
        }
    }
    
    func getStatus(for subscriptionId: Int) -> ConnectivityStatus {
        return statuses[subscriptionId] ?? .unknown
    }
    
    func clearStatus(for subscriptionId: Int) {
        statuses[subscriptionId] = nil
    }
    
    func clearAllStatuses() {
        statuses.removeAll()
    }
}

