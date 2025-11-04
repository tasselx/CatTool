import SwiftUI

struct SubscriptionDetailView: View {
    let subscription: Subscription
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Text(subscription.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            // 详情内容
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // URL 部分
                    DetailSection(title: "订阅地址") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(subscription.url)
                                .textSelection(.enabled)
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                copyToClipboard(subscription.url)
                            } label: {
                                Label("复制地址", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // 描述部分
                    if let description = subscription.description, !description.isEmpty {
                        DetailSection(title: "描述") {
                            Text(description)
                                .textSelection(.enabled)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 时间信息
                    DetailSection(title: "时间信息") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("创建时间:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDate(subscription.createdAt))
                            }
                            
                            HStack {
                                Text("更新时间:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDate(subscription.updatedAt))
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // 删除按钮
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("删除订阅", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
        }
    }
}

#Preview {
    SubscriptionDetailView(
        subscription: Subscription(
            id: 1,
            name: "示例订阅",
            url: "https://example.com/subscribe",
            description: "这是一个示例订阅源",
            createdAt: "2025-11-04 10:00:00",
            updatedAt: "2025-11-04 15:30:00"
        ),
        onEdit: {},
        onDelete: {}
    )
    .frame(width: 600, height: 800)
}

