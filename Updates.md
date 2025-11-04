# 更新日志

## 2025-11-04 (更新5)

### 批量导入功能
- ✅ 新增批量导入视图（BatchImportView）
- ✅ 支持解析"名称接口：URL"格式
- ✅ 支持中英文冒号分隔符
- ✅ 自动移除名称中的"接口"后缀
- ✅ 实时解析和验证输入内容
- ✅ 显示解析结果预览（有效/无效条目）
- ✅ URL格式验证（需要http://或https://开头）
- ✅ 批量导入进度提示
- ✅ 导入完成统计（成功/失败数量）
- ✅ 主界面添加批量导入按钮（下载图标）
- ✅ 为所有工具栏按钮添加提示文本

## 2025-11-04 (更新4)

### 设置页面
- ✅ 创建独立的设置页面
- ✅ 导入/导出功能移至设置页
- ✅ 添加应用版本信息
- ✅ 添加快速打开数据库文件夹功能
- ✅ iCloud 功能说明（需要付费账号）

### 主界面改进
- ✅ 显示订阅总数
- ✅ 添加设置按钮（齿轮图标）
- ✅ 简化界面，移除导入导出菜单

### 免费账号支持
- ✅ 移除 iCloud 依赖
- ✅ 完全支持免费个人开发者账号
- ✅ 保留完整的本地数据库功能
- ✅ 保留导入/导出备份功能

## 2025-11-04 (更新3)

### 界面改进
- ✅ 使用 HSplitView 替代 NavigationView（更稳定的 macOS 布局）
- ✅ 改进 SubscriptionRow 样式，确保描述信息正确显示
- ✅ 优化间距和字体大小
- ✅ 添加自定义标题栏

### 数据库导入/导出
- ✅ 导出数据库功能（带时间戳的文件名）
- ✅ 导入数据库功能（完全覆盖现有数据）
- ✅ 导入前显示确认对话框
- ✅ 自动重新连接数据库
- ✅ 导入后自动刷新界面
- ✅ 在标题栏添加菜单按钮访问导入/导出

## 2025-11-04 (更新2)

### 数据持久化修复
- ✅ 修复数据库路径问题
- ✅ 使用 ApplicationSupportDirectory 替代 DocumentDirectory
- ✅ 自动创建应用专用目录
- ✅ 添加详细的错误日志和调试信息
- ✅ 增强数据库操作的错误处理
- ✅ 添加数据库连接状态检查

### UI 更新修复
- ✅ 确保数据加载后在主线程更新 UI
- ✅ 使用 DispatchQueue.main.async 包裹状态更新
- ✅ 修复删除后选中状态处理
- ✅ 添加完整的操作日志

### 调试功能
- 在控制台输出数据库路径
- 每次操作显示成功/失败状态
- 显示读取到的记录数量
- UI 更新状态追踪

## 2025-11-04 (更新1)

### 完整 Xcode 工程创建
- ✅ 创建完整的 Xcode 项目结构
- ✅ 配置 project.pbxproj 文件
- ✅ 创建 xcscheme 和 workspace
- ✅ 配置 Assets.xcassets
- ✅ 添加 App Sandbox 权限

### 功能实现
- ✅ SQLite 数据库完整 CRUD 操作
- ✅ SwiftUI 现代化界面
- ✅ 主-从布局（Master-Detail）
- ✅ 点击左侧列表查看右侧详情
- ✅ 详情页面包含完整信息展示
- ✅ 详情页面支持编辑和删除
- ✅ 搜索过滤功能
- ✅ 右键菜单快捷操作
- ✅ 滑动删除手势
- ✅ 复制 URL 到剪贴板
- ✅ 文本可选择复制

### 项目结构
```
CatTool/
├── CatTool.xcodeproj/
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/
├── CatTool/
│   ├── CatToolApp.swift
│   ├── ContentView.swift
│   ├── AddEditSubscriptionView.swift
│   ├── SubscriptionDetailView.swift
│   ├── DatabaseManager.swift
│   ├── Subscription.swift
│   ├── Assets.xcassets/
│   └── CatTool.entitlements
└── README.md
```

### 技术特性
- 最低支持 macOS 13.0
- Swift 5.0
- 硬化运行时
- 应用沙盒
- NavigationView 主-从布局
- List selection binding
- Hashable 协议支持

