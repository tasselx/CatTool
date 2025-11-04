import SwiftUI

struct BatchImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var importText: String = ""
    @State private var parsedItems: [ImportItem] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var importMode: ImportMode = .skipExisting
    @State private var isProcessing = false
    
    let onImportComplete: () -> Void
    
    enum ImportMode: String, CaseIterable {
        case skipExisting = "跳过已存在"
        case replaceExisting = "覆盖已存在"
    }
    
    struct ImportItem: Identifiable {
        let id = UUID()
        var name: String
        var url: String
        var isValid: Bool
        var errorMessage: String?
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("批量导入订阅")
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // 主内容
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 使用说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("使用说明")
                            .font(.headline)
                        Text("请粘贴订阅列表，支持以下格式：")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 名称接口：URL 或 名称：URL")
                                .font(.caption)
                            Text("• URL # 名称 或 URL  # 名称")
                                .font(.caption)
                            Text("• JSON 格式：{\"urls\": [{\"name\": \"...\", \"url\": \"...\"}]}")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // 文本输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("粘贴订阅列表")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $importText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .border(Color.gray.opacity(0.3))
                            .onChange(of: importText) { newValue in
                                parseImportText(newValue)
                            }
                    }
                    
                    // 导入选项
                    HStack {
                        Text("导入模式：")
                            .font(.subheadline)
                        Picker("", selection: $importMode) {
                            ForEach(ImportMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    // 解析结果预览
                    if !parsedItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("解析结果")
                                    .font(.headline)
                                Spacer()
                                Text("\(validItemsCount)/\(parsedItems.count) 条有效")
                                    .font(.caption)
                                    .foregroundColor(validItemsCount == parsedItems.count ? .green : .orange)
                            }
                            
                            Divider()
                            
                            ForEach(parsedItems) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(item.isValid ? .green : .red)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(item.url)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                        
                                        if let error = item.errorMessage {
                                            Text(error)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(item.isValid ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            // 底部按钮
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Spacer()
                Button("开始导入") {
                    performImport()
                }
                .disabled(validItemsCount == 0 || isProcessing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 700, height: 600)
        .alert("导入结果", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {
                if alertMessage.contains("成功") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var validItemsCount: Int {
        parsedItems.filter { $0.isValid }.count
    }
    
    private func parseImportText(_ text: String) {
        var items: [ImportItem] = []
        
        // 尝试解析 JSON 格式
        if let jsonItems = parseJSON(text) {
            items = jsonItems
        } else {
            // 按行解析
            items = parseLineByLine(text)
        }
        
        parsedItems = items
    }
    
    private func parseJSON(_ text: String) -> [ImportItem]? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urls = json["urls"] as? [[String: Any]] {
                var items: [ImportItem] = []
                
                for entry in urls {
                    guard let name = entry["name"] as? String,
                          let url = entry["url"] as? String else {
                        continue
                    }
                    
                    // 修复乱码
                    let decodedName = GarbledTextFixer.fix(name).trimmingCharacters(in: .whitespaces)
                    let decodedUrl = GarbledTextFixer.fix(url).trimmingCharacters(in: .whitespaces)
                    
                    var isValid = true
                    var errorMessage: String?
                    
                    if decodedName.isEmpty {
                        isValid = false
                        errorMessage = "名称为空"
                    } else if decodedUrl.isEmpty {
                        isValid = false
                        errorMessage = "URL为空"
                    } else if !decodedUrl.lowercased().hasPrefix("http://") && !decodedUrl.lowercased().hasPrefix("https://") {
                        isValid = false
                        errorMessage = "URL格式无效（需要http://或https://开头）"
                    }
                    
                    items.append(ImportItem(
                        name: decodedName,
                        url: decodedUrl,
                        isValid: isValid,
                        errorMessage: errorMessage
                    ))
                }
                
                return items.isEmpty ? nil : items
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func parseLineByLine(_ text: String) -> [ImportItem] {
        let lines = text.components(separatedBy: .newlines)
        var items: [ImportItem] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                continue
            }
            
            var name = ""
            var url = ""
            var isValid = true
            var errorMessage: String?
            
            // 格式1: URL # 名称 (如: http://example.com # 示例)
            if let hashIndex = trimmedLine.firstIndex(of: "#") {
                let urlPart = String(trimmedLine[..<hashIndex]).trimmingCharacters(in: .whitespaces)
                let namePart = String(trimmedLine[trimmedLine.index(after: hashIndex)...]).trimmingCharacters(in: .whitespaces)
                
                // 验证URL部分是否以http://或https://开头
                if urlPart.lowercased().hasPrefix("http://") || urlPart.lowercased().hasPrefix("https://") {
                    url = GarbledTextFixer.fix(urlPart)
                    name = GarbledTextFixer.fix(namePart)
                    
                    // 移除名称中的"接口"后缀
                    if name.hasSuffix("接口") {
                        name = String(name.dropLast(2))
                    }
                    
                    if name.isEmpty {
                        isValid = false
                        errorMessage = "名称为空"
                    }
                } else {
                    // 不是URL格式，尝试其他格式
                    isValid = false
                }
            }
            
            // 格式2: 名称：URL 或 名称接口：URL (如果格式1没有匹配)
            if !isValid || url.isEmpty {
                if let colonRange = trimmedLine.range(of: "：") ?? trimmedLine.range(of: ":") {
                    name = GarbledTextFixer.fix(String(trimmedLine[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces))
                    url = GarbledTextFixer.fix(String(trimmedLine[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces))
                    
                    // 移除名称中的"接口"后缀
                    if name.hasSuffix("接口") {
                        name = String(name.dropLast(2))
                    }
                    
                    // 验证
                    if name.isEmpty {
                        isValid = false
                        errorMessage = "名称为空"
                    } else if url.isEmpty {
                        isValid = false
                        errorMessage = "URL为空"
                    } else if !url.lowercased().hasPrefix("http://") && !url.lowercased().hasPrefix("https://") {
                        isValid = false
                        errorMessage = "URL格式无效（需要http://或https://开头）"
                    } else {
                        isValid = true
                        errorMessage = nil
                    }
                } else if !isValid {
                    // 两种格式都不匹配
                    isValid = false
                    name = trimmedLine
                    errorMessage = "格式错误（需要 'URL # 名称' 或 '名称：URL'）"
                }
            }
            
            items.append(ImportItem(
                name: name,
                url: url,
                isValid: isValid,
                errorMessage: errorMessage
            ))
        }
        
        return items
    }
    
    private func performImport() {
        isProcessing = true
        
        let validItems = parsedItems.filter { $0.isValid }
        var successCount = 0
        var failCount = 0
        
        for item in validItems {
            let result = DatabaseManager.shared.addSubscription(
                name: item.name,
                url: item.url,
                description: nil
            )
            
            if result {
                successCount += 1
            } else {
                failCount += 1
            }
        }
        
        isProcessing = false
        alertMessage = "导入完成\n成功: \(successCount) 条\n失败: \(failCount) 条"
        showingAlert = true
        
        if successCount > 0 {
            onImportComplete()
        }
    }
}

#Preview {
    BatchImportView {
        print("Import complete")
    }
}

