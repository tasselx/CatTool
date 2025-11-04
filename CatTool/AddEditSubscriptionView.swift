import SwiftUI

struct AddEditSubscriptionView: View {
    enum Mode {
        case add
        case edit(Subscription)
    }
    
    let mode: Mode
    let onSave: (String, String, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var url: String
    @State private var description: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(mode: Mode, onSave: @escaping (String, String, String?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _url = State(initialValue: "")
            _description = State(initialValue: "")
        case .edit(let subscription):
            _name = State(initialValue: subscription.name)
            _url = State(initialValue: subscription.url)
            _description = State(initialValue: subscription.description ?? "")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(mode.isEdit ? "编辑订阅" : "添加订阅")
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // 表单
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("URL", text: $url)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("描述 (可选)") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.3))
                }
            }
            .formStyle(.grouped)
            .padding()
            
            // 底部按钮
            HStack {
                Spacer()
                Button("保存") {
                    saveSubscription()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSubscription() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "请输入订阅名称"
            showingAlert = true
            return
        }
        
        guard !url.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "请输入订阅 URL"
            showingAlert = true
            return
        }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        onSave(
            name.trimmingCharacters(in: .whitespaces),
            url.trimmingCharacters(in: .whitespaces),
            trimmedDescription.isEmpty ? nil : trimmedDescription
        )
        dismiss()
    }
}

extension AddEditSubscriptionView.Mode {
    var isEdit: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

#Preview {
    AddEditSubscriptionView(mode: .add) { _, _, _ in }
}

