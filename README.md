# CatTool - 订阅管理应用

一个使用 SwiftUI 和 SQLite 构建的 Mac 桌面订阅地址管理应用。

## 功能特性

- ✅ 添加、编辑、删除订阅
- ✅ 搜索订阅
- ✅ 复制订阅 URL
- ✅ SQLite 本地数据库存储
- ✅ 现代化 SwiftUI 界面
- ✅ 右键菜单快捷操作
- ✅ 滑动删除
- ✅ 显示订阅总数
- ✅ 数据导入/导出备份

## 快速开始

### 打开项目

1. 双击 `CatTool.xcodeproj` 打开项目
2. 在 Xcode 中选择开发团队（Signing & Capabilities）
3. 按 `⌘ + R` 运行应用

### 项目结构

```
CatTool/
├── CatTool.xcodeproj/          # Xcode 项目文件
├── CatTool/                    # 源代码目录
│   ├── CatToolApp.swift        # 应用入口
│   ├── ContentView.swift       # 主视图
│   ├── AddEditSubscriptionView.swift  # 添加/编辑视图
│   ├── DatabaseManager.swift   # 数据库管理
│   ├── Subscription.swift      # 数据模型
│   ├── Assets.xcassets/        # 资源文件
│   └── CatTool.entitlements   # 权限配置
├── README.md                   # 项目说明
└── Updates.md                  # 更新日志
```

## 功能说明

### 查看详情
点击左侧列表中的订阅源，右侧显示详细信息，包括：
- 订阅名称
- 完整 URL（可复制）
- 描述信息
- 创建和更新时间
- 编辑和删除按钮

### 添加订阅
点击工具栏 "+" 按钮，填写订阅名称、URL 和描述（可选）

### 编辑订阅
- 在详情页面点击 "编辑" 按钮
- 右键选择 "编辑"

### 删除订阅
- 在详情页面点击 "删除订阅" 按钮
- 向左滑动订阅项
- 右键选择 "删除"

### 复制 URL
- 在详情页面点击 "复制地址" 按钮
- 右键点击订阅项，选择 "复制 URL"
- 在详情页面直接选择文本复制

### 搜索订阅
在顶部搜索框输入关键词，支持搜索名称、URL 和描述

### 设置
点击标题栏的 `⚙️` 图标进入设置页面：

**数据管理**
- **导出数据库**：将当前数据导出为 `.db` 文件备份
- **导入数据库**：从 `.db` 文件导入（会完全覆盖现有数据，导入前会提示确认）
- **数据库位置**：快速打开数据库文件所在文件夹

**iCloud 同步**
- 需要付费开发者账号（$99/年）才支持
- 免费账号可使用导入/导出功能备份数据

## 数据库位置

数据库文件 `subscriptions.db` 存储在：
```
~/Library/Application Support/CatTool/subscriptions.db
```

启动应用后，在 Xcode 控制台可以看到完整路径。

## 快捷键

- `⌘ + R`: 刷新列表
- `⌘ + W`: 关闭窗口

## 系统要求

- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本

## 技术栈

- SwiftUI - UI 框架
- SQLite3 - 本地数据库
- Combine - 响应式编程

## 注意事项

### 数据备份
- 定期使用"导出数据库"功能备份数据
- 导出的 `.db` 文件可在任何设备导入
- 建议备份到 iCloud Drive 或其他云存储

### iCloud 同步（可选）
- 需要 Apple Developer Program（$99/年）
- 详见 `iCloud配置说明.md`

