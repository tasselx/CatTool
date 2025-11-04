import SwiftUI

struct ContentView: View {
    @State private var subscriptions: [Subscription] = []
    @State private var selectedSubscription: Subscription?
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var showingSettings = false
    @State private var showingBatchImport = false
    @State private var searchText = ""
    @StateObject private var connectivityManager = ConnectivityManager.shared
    @State private var isTesting = false
    
    var filteredSubscriptions: [Subscription] {
        if searchText.isEmpty {
            return subscriptions
        }
        return subscriptions.filter { sub in
            sub.name.localizedCaseInsensitiveContains(searchText) ||
            sub.url.localizedCaseInsensitiveContains(searchText) ||
            (sub.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        HSplitView {
            // 左侧列表
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("订阅管理")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("共 \(subscriptions.count) 个订阅")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button {
                        testAllSubscriptions()
                    } label: {
                        Image(systemName: isTesting ? "antenna.radiowaves.left.and.right" : "network")
                    }
                    .help("测试所有订阅")
                    .disabled(isTesting || subscriptions.isEmpty)
                    
                    Button {
                        showingBatchImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down.on.square")
                    }
                    .help("批量导入")
                    
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("添加订阅")
                    
                    Button {
                        loadSubscriptions()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("刷新列表")
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("设置")
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜索订阅...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                // 列表
                if filteredSubscriptions.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "暂无订阅" : "无匹配结果")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List(filteredSubscriptions, selection: $selectedSubscription) { subscription in
                        SubscriptionRow(
                            subscription: subscription,
                            status: connectivityManager.getStatus(for: subscription.id),
                            onOpenInBrowser: {
                                openInBrowser(subscription.url)
                            }
                        )
                        .tag(subscription)
                        .onTapGesture {
                            selectedSubscription = subscription
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteSubscription(subscription)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                Task {
                                    await connectivityManager.testConnectivity(for: subscription)
                                }
                            } label: {
                                Label("测试连通性", systemImage: "network")
                            }
                            
                            Button {
                                openInBrowser(subscription.url)
                            } label: {
                                Label("在浏览器中打开", systemImage: "safari")
                            }
                            
                            Button {
                                copyToClipboard(subscription.url)
                            } label: {
                                Label("复制 URL", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button {
                                selectedSubscription = subscription
                                showingEditSheet = true
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                deleteSubscription(subscription)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 300, maxWidth: 400)
            
            // 右侧详情
            if let subscription = selectedSubscription {
                SubscriptionDetailView(
                    subscription: subscription,
                    status: connectivityManager.getStatus(for: subscription.id),
                    onEdit: {
                        showingEditSheet = true
                    },
                    onDelete: {
                        deleteSubscription(subscription)
                    },
                    onTest: {
                        Task {
                            await connectivityManager.testConnectivity(for: subscription)
                        }
                    }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("选择一个订阅源查看详情")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditSubscriptionView(mode: .add) { name, url, description in
                if DatabaseManager.shared.addSubscription(name: name, url: url, description: description) {
                    DispatchQueue.main.async {
                        loadSubscriptions()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let subscription = selectedSubscription {
                AddEditSubscriptionView(mode: .edit(subscription)) { name, url, description in
                    if DatabaseManager.shared.updateSubscription(id: subscription.id, name: name, url: url, description: description) {
                        DispatchQueue.main.async {
                            loadSubscriptions()
                            // 更新选中的订阅
                            selectedSubscription = Subscription(
                                id: subscription.id,
                                name: name,
                                url: url,
                                description: description,
                                createdAt: subscription.createdAt,
                                updatedAt: subscription.updatedAt
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingBatchImport) {
            BatchImportView {
                DispatchQueue.main.async {
                    loadSubscriptions()
                }
            }
        }
        .onAppear {
            loadSubscriptions()
        }
    }
    
    private func loadSubscriptions() {
        let loadedData = DatabaseManager.shared.getAllSubscriptions()
        print("🔄 ContentView 加载数据: \(loadedData.count) 条")
        DispatchQueue.main.async {
            self.subscriptions = loadedData
            print("🎨 UI 更新完成，当前显示: \(self.subscriptions.count) 条")
        }
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        if DatabaseManager.shared.deleteSubscription(id: subscription.id) {
            // 清除选中状态
            if selectedSubscription?.id == subscription.id {
                selectedSubscription = nil
            }
            DispatchQueue.main.async {
                loadSubscriptions()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func openInBrowser(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func testAllSubscriptions() {
        guard !subscriptions.isEmpty else { return }
        isTesting = true
        Task {
            await connectivityManager.testAllConnectivity(subscriptions: subscriptions)
            await MainActor.run {
                isTesting = false
            }
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription
    let status: ConnectivityStatus
    let onOpenInBrowser: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subscription.url)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if let description = subscription.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                HStack(spacing: 8) {
                    Text("更新: \(formatDate(subscription.updatedAt))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if case .unknown = status {
                        // 不显示
                    } else {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            statusIndicator
                            Text(status.displayText)
                                .font(.caption2)
                                .foregroundColor(statusColor)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onOpenInBrowser()
                } label: {
                    Image(systemName: "safari")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("在浏览器中打开")
                
                if case .testing = status {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 6, height: 6)
    }
    
    private var statusColor: Color {
        switch status {
        case .unknown:
            return .gray
        case .testing:
            return .orange
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    ContentView()
}

