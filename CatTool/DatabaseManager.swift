import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createTable()
    }
    
    private func openDatabase() {
        // 使用应用支持目录，更适合沙盒应用
        let fileManager = FileManager.default
        
        // 获取应用支持目录
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ 无法获取应用支持目录")
            return
        }
        
        // 创建应用专用目录
        let appDirectory = appSupportURL.appendingPathComponent("CatTool", isDirectory: true)
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: appDirectory.path) {
            do {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ 创建应用目录: \(appDirectory.path)")
            } catch {
                print("❌ 创建目录失败: \(error.localizedDescription)")
                return
            }
        }
        
        let fileURL = appDirectory.appendingPathComponent("subscriptions.db")
        print("📁 数据库路径: \(fileURL.path)")
        
        // 打开数据库
        let result = sqlite3_open(fileURL.path, &db)
        if result != SQLITE_OK {
            print("❌ 无法打开数据库，错误码: \(result)")
            if let error = sqlite3_errmsg(db) {
                print("❌ 错误信息: \(String(cString: error))")
            }
            return
        }
        print("✅ 数据库打开成功")
    }
    
    private func createTable() {
        guard db != nil else {
            print("❌ 数据库未初始化")
            return
        }
        
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        var errorMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, createTableQuery, nil, nil, &errorMsg)
        
        if result != SQLITE_OK {
            print("❌ 创建表失败，错误码: \(result)")
            if let error = errorMsg {
                print("❌ 错误信息: \(String(cString: error))")
                sqlite3_free(error)
            }
        } else {
            print("✅ 数据表创建/验证成功")
        }
    }
    
    func addSubscription(name: String, url: String, description: String?) -> Bool {
        guard db != nil else {
            print("❌ 数据库未初始化")
            return false
        }
        
        let insertQuery = "INSERT INTO subscriptions (name, url, description) VALUES (?, ?, ?);"
        var statement: OpaquePointer?
        
        let prepareResult = sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil)
        if prepareResult == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (url as NSString).utf8String, -1, nil)
            if let desc = description {
                sqlite3_bind_text(statement, 3, (desc as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE {
                print("✅ 添加订阅成功: \(name)")
                sqlite3_finalize(statement)
                return true
            } else {
                print("❌ 插入数据失败，错误码: \(stepResult)")
                if let error = sqlite3_errmsg(db) {
                    print("❌ 错误信息: \(String(cString: error))")
                }
            }
        } else {
            print("❌ 准备SQL语句失败，错误码: \(prepareResult)")
            if let error = sqlite3_errmsg(db) {
                print("❌ 错误信息: \(String(cString: error))")
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllSubscriptions() -> [Subscription] {
        guard db != nil else {
            print("❌ 数据库未初始化")
            return []
        }
        
        let query = "SELECT id, name, url, description, created_at, updated_at FROM subscriptions ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        var subscriptions: [Subscription] = []
        
        let prepareResult = sqlite3_prepare_v2(db, query, -1, &statement, nil)
        if prepareResult == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let url = String(cString: sqlite3_column_text(statement, 2))
                
                let description: String?
                if let descText = sqlite3_column_text(statement, 3) {
                    description = String(cString: descText)
                } else {
                    description = nil
                }
                
                let createdAt = String(cString: sqlite3_column_text(statement, 4))
                let updatedAt = String(cString: sqlite3_column_text(statement, 5))
                
                subscriptions.append(Subscription(
                    id: id,
                    name: name,
                    url: url,
                    description: description,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                ))
            }
            print("📊 读取到 \(subscriptions.count) 条订阅记录")
        } else {
            print("❌ 准备查询失败，错误码: \(prepareResult)")
            if let error = sqlite3_errmsg(db) {
                print("❌ 错误信息: \(String(cString: error))")
            }
        }
        sqlite3_finalize(statement)
        return subscriptions
    }
    
    func updateSubscription(id: Int, name: String, url: String, description: String?) -> Bool {
        guard db != nil else {
            print("❌ 数据库未初始化")
            return false
        }
        
        let updateQuery = "UPDATE subscriptions SET name = ?, url = ?, description = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (url as NSString).utf8String, -1, nil)
            if let desc = description {
                sqlite3_bind_text(statement, 3, (desc as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_int(statement, 4, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ 更新订阅成功: ID \(id)")
                sqlite3_finalize(statement)
                return true
            } else {
                print("❌ 更新订阅失败: ID \(id)")
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func deleteSubscription(id: Int) -> Bool {
        guard db != nil else {
            print("❌ 数据库未初始化")
            return false
        }
        
        let deleteQuery = "DELETE FROM subscriptions WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("✅ 删除订阅成功: ID \(id)")
                sqlite3_finalize(statement)
                return true
            } else {
                print("❌ 删除订阅失败: ID \(id)")
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func exportDatabase(to url: URL) -> Bool {
        guard let dbPath = getDatabasePath() else {
            print("❌ 无法获取数据库路径")
            return false
        }
        
        do {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: dbPath), to: url)
            print("✅ 导出数据库成功: \(url.path)")
            return true
        } catch {
            print("❌ 导出失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func importDatabase(from url: URL) -> Bool {
        guard let dbPath = getDatabasePath() else {
            print("❌ 无法获取数据库路径")
            return false
        }
        
        // 关闭当前数据库连接
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
        
        do {
            let targetURL = URL(fileURLWithPath: dbPath)
            
            // 删除现有数据库
            if FileManager.default.fileExists(atPath: dbPath) {
                try FileManager.default.removeItem(at: targetURL)
                print("✅ 删除旧数据库")
            }
            
            // 复制导入的数据库
            try FileManager.default.copyItem(at: url, to: targetURL)
            print("✅ 导入数据库成功")
            
            // 重新打开数据库
            openDatabase()
            
            return true
        } catch {
            print("❌ 导入失败: \(error.localizedDescription)")
            // 重新打开数据库
            openDatabase()
            return false
        }
    }
    
    private func getDatabasePath() -> String? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDirectory = appSupportURL.appendingPathComponent("CatTool", isDirectory: true)
        return appDirectory.appendingPathComponent("subscriptions.db").path
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
}

