import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            ScrollView {
                VStack(spacing: 24) {
                    // iCloud 功能提示（免费账号不支持）
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "icloud.slash")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("iCloud 同步")
                                        .font(.headline)
                                    Text("需要付费开发者账号（$99/年）")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("免费个人账号不支持 iCloud 功能。您仍可使用导入/导出功能备份数据。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .padding()
                    }
                    
                    // 数据管理
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("数据管理")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("导出数据库")
                                        .font(.subheadline)
                                    Text("备份订阅数据到本地文件")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    exportDatabase()
                                } label: {
                                    Label("导出", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("导入数据库")
                                        .font(.subheadline)
                                    Text("从备份文件恢复数据（会覆盖现有数据）")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    importDatabase()
                                } label: {
                                    Label("导入", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                    }
                    
                    // 关于
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("关于")
                                .font(.headline)
                            
                            HStack {
                                Text("版本")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("1.0.0")
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("数据库位置")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    openDatabaseFolder()
                                } label: {
                                    Label("打开", systemImage: "folder")
                                }
                                .buttonStyle(.borderless)
                            }
                            .font(.subheadline)
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportDatabase() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.database]
        panel.nameFieldStringValue = "subscriptions_\(Date().timeIntervalSince1970).db"
        panel.message = "选择导出位置"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if DatabaseManager.shared.exportDatabase(to: url) {
                    alertMessage = "导出成功"
                    showingAlert = true
                }
            }
        }
    }
    
    private func importDatabase() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.database]
        panel.message = "选择要导入的数据库文件（将完全覆盖现有数据）"
        panel.prompt = "导入"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let alert = NSAlert()
                alert.messageText = "确认导入"
                alert.informativeText = "导入将完全覆盖现有的所有订阅数据，此操作不可撤销。是否继续？"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "导入")
                alert.addButton(withTitle: "取消")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    if DatabaseManager.shared.importDatabase(from: url) {
                        alertMessage = "导入成功，请重启应用生效"
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    private func openDatabaseFolder() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let appDirectory = appSupportURL.appendingPathComponent("CatTool", isDirectory: true)
        NSWorkspace.shared.open(appDirectory)
    }
}

#Preview {
    SettingsView()
}

