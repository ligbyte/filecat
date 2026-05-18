use std::ffi::{CStr, CString};
use std::fs;
use std::os::raw::c_char;
use std::ptr;
use serde::{Deserialize, Serialize};
use serde_json;
use local_ip_address::local_ip;
use actix_web::{web, App, HttpServer, Responder, dev::ServerHandle};
use actix_files;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use std::thread;

static SERVER_HANDLE: Lazy<Mutex<Option<ServerHandle>>> = Lazy::new(|| Mutex::new(None));
static CURRENT_PATH: Lazy<Mutex<String>> = Lazy::new(|| Mutex::new("F:/apk".to_string()));

#[derive(Serialize, Deserialize)]
struct FileInfo {
    name: String,
    size: u64,
    path: String,
}

/// 获取用户目录下的filecat文件夹路径，如果不存在则创建
#[no_mangle]
pub extern "C" fn get_filecat_path() -> *mut c_char {
    let home_dir = match dirs::home_dir() {
        Some(dir) => dir,
        None => return create_error_response("Failed to get home directory"),
    };
    
    let filecat_path = home_dir.join("filecat");
    
    // 如果文件夹不存在，则创建
    if !filecat_path.exists() {
        if let Err(e) = fs::create_dir_all(&filecat_path) {
            return create_error_response(&format!("Failed to create filecat directory: {}", e));
        }
    }
    
    let path_str = match filecat_path.to_str() {
        Some(s) => s,
        None => return create_error_response("Invalid path encoding"),
    };
    
    create_data_response(path_str)
}

/// 列出目录内容
#[no_mangle]
pub extern "C" fn list_directory(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::read_dir(path_str) {
        Ok(entries) => {
            let mut items: Vec<serde_json::Value> = Vec::new();
            
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    let name = path.file_name()
                        .map(|n| n.to_string_lossy().to_string())
                        .unwrap_or_default();
                    
                    let is_dir = path.is_dir();
                    let metadata = fs::metadata(&path).ok();
                    let size = if is_dir { 
                        0 
                    } else {
                        metadata.as_ref().map(|m| m.len()).unwrap_or(0)
                    };
                    
                    let modified = metadata.as_ref()
                        .and_then(|m| m.modified().ok())
                        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                        .map(|d| d.as_millis() as u64)
                        .unwrap_or(0);
                    
                    items.push(serde_json::json!({
                        "name": name,
                        "is_dir": is_dir,
                        "size": size,
                        "modified": modified,
                        "path": path.to_string_lossy().to_string()
                    }));
                }
            }
            
            // 排序：文件夹在前，然后按名称排序
            items.sort_by(|a, b| {
                let a_is_dir = a["is_dir"].as_bool().unwrap_or(false);
                let b_is_dir = b["is_dir"].as_bool().unwrap_or(false);
                
                match (a_is_dir, b_is_dir) {
                    (true, false) => std::cmp::Ordering::Less,
                    (false, true) => std::cmp::Ordering::Greater,
                    _ => a["name"].as_str().unwrap_or("")
                        .cmp(&b["name"].as_str().unwrap_or(""))
                }
            });
            
            match serde_json::to_string(&items) {
                Ok(json_str) => create_data_response(&json_str),
                Err(e) => create_error_response(&format!("Serialization error: {}", e)),
            }
        },
        Err(e) => create_error_response(&format!("Failed to read directory: {}", e)),
    }
}

/// 创建文件
#[no_mangle]
pub extern "C" fn create_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::write(path_str, b"") {
        Ok(_) => create_success_response("File created successfully"),
        Err(e) => create_error_response(&format!("Failed to create file: {}", e)),
    }
}

/// 读取文件内容
#[no_mangle]
pub extern "C" fn read_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::read_to_string(path_str) {
        Ok(content) => create_data_response(&content),
        Err(e) => create_error_response(&format!("Failed to read file: {}", e)),
    }
}

/// 写入文件内容
#[no_mangle]
pub extern "C" fn write_file(path: *const c_char, content: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    if content.is_null() {
        return create_error_response("Content pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    let content_str = unsafe { 
        match CStr::from_ptr(content).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in content"),
        }
    };
    
    match fs::write(path_str, content_str.as_bytes()) {
        Ok(_) => create_success_response("File written successfully"),
        Err(e) => create_error_response(&format!("Failed to write file: {}", e)),
    }
}

/// 获取文件信息
#[no_mangle]
pub extern "C" fn get_file_info(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::metadata(path_str) {
        Ok(metadata) => {
            let file_info = FileInfo {
                name: get_filename_from_path(path_str),
                size: metadata.len(),
                path: path_str.to_string(),
            };
            
            match serde_json::to_string(&file_info) {
                Ok(json_str) => create_data_response(&json_str),
                Err(e) => create_error_response(&format!("Serialization error: {}", e)),
            }
        },
        Err(e) => create_error_response(&format!("Failed to get file info: {}", e)),
    }
}

/// 删除文件
#[no_mangle]
pub extern "C" fn delete_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::remove_file(path_str) {
        Ok(_) => create_success_response("File deleted successfully"),
        Err(e) => create_error_response(&format!("Failed to delete file: {}", e)),
    }
}

/// 获取文件名从完整路径
fn get_filename_from_path(path: &str) -> String {
    path.split('/').last().unwrap_or(path).split('\\').last().unwrap_or(path).to_string()
}

/// 辅助函数：创建成功响应
fn create_success_response(message: &str) -> *mut c_char {
    let response = format!("{{\"success\":true,\"message\":\"{}\"}}", message);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 辅助函数：创建错误响应
fn create_error_response(message: &str) -> *mut c_char {
    let response = format!("{{\"success\":false,\"message\":\"{}\"}}", message);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 辅助函数：创建数据响应
fn create_data_response(data: &str) -> *mut c_char {
    let response = format!("{{\"success\":true,\"data\":\"{}\"}}", data);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 释放字符串内存
#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            // This takes ownership of the string and drops it,
            // effectively freeing the memory
            let _ = CString::from_raw(ptr);
        }
    }
}

// --- 静态文件服务器逻辑 ---

async fn index() -> impl Responder {
    "Hello world!"
}

async fn health_check() -> impl Responder {
    "OK"
}

/// 启动静态文件服务器
#[no_mangle]
pub extern "C" fn start_static_server(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }

    let path_str = unsafe {
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s.to_string(),
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };

    // 更新当前路径
    {
        let mut current_path = CURRENT_PATH.lock().unwrap();
        *current_path = path_str.clone();
    }

    // 如果已经在运行，先停止
    stop_static_server_internal();

    // 在新线程中启动服务器
    thread::spawn(move || {
        let sys = actix_rt::System::new();
        sys.block_on(async {
            let server = HttpServer::new(move || {
                let p = CURRENT_PATH.lock().unwrap().clone();
                App::new()
                    .service(actix_files::Files::new("/file", &p).show_files_listing())
            })
            .bind(("0.0.0.0", 9202));

            match server {
                Ok(srv) => {
                    let s = srv.run();
                    let handle = s.handle();
                    {
                        let mut global_handle = SERVER_HANDLE.lock().unwrap();
                        *global_handle = Some(handle);
                    }
                    let _ = s.await;
                }
                Err(e) => {
                    eprintln!("Failed to bind server: {}", e);
                }
            }
        });
    });

    create_success_response(&format!("Server started on port 9202 with path: {}", path_str))
}

/// 停止服务器的内部辅助函数
fn stop_static_server_internal() {
    let mut handle = SERVER_HANDLE.lock().unwrap();
    if let Some(server_handle) = handle.take() {
        // 停止服务器，参数为 true 表示优雅停止
        let _ = server_handle.stop(true);
        // 给一点时间让服务器停止
        thread::sleep(std::time::Duration::from_millis(500));
    }
}

/// 停止静态文件服务器
#[no_mangle]
pub extern "C" fn stop_static_server() -> *mut c_char {
    stop_static_server_internal();
    create_success_response("Server stopped")
}

/// 更新共享文件夹路径并重启服务
#[no_mangle]
pub extern "C" fn update_server_path(path: *const c_char) -> *mut c_char {
    start_static_server(path)
}

/// 获取本机内网IPv4地址
#[no_mangle]
pub extern "C" fn get_local_ip() -> *mut c_char {
    match local_ip() {
        Ok(ip) => create_data_response(&ip.to_string()),
        Err(e) => create_error_response(&format!("Failed to get local IP: {}", e)),
    }
}

// --- 开机自启动逻辑 ---

#[cfg(target_os = "windows")]
pub mod autostart {
    use std::error::Error;
    use std::path::Path;
    use winreg::enums::*;
    use winreg::RegKey;

    pub fn enable(app_name: &str, app_path: &Path) -> Result<(), Box<dyn Error>> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let run_key = hkcu.open_subkey_with_flags(
            "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
            KEY_SET_VALUE | KEY_READ,
        )?;
        let full_command = format!("\"{}\"", app_path.display());
        run_key.set_value(app_name, &full_command)?;
        Ok(())
    }

    pub fn disable(app_name: &str) -> Result<(), Box<dyn Error>> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let run_key = hkcu.open_subkey_with_flags(
            "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
            KEY_SET_VALUE | KEY_READ,
        )?;
        let _ = run_key.delete_value(app_name);
        Ok(())
    }

    pub fn is_enabled(app_name: &str, app_path: &Path) -> Result<bool, Box<dyn Error>> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let run_key = hkcu.open_subkey_with_flags(
            "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
            KEY_READ,
        )?;
        match run_key.get_value::<String, _>(app_name) {
            Ok(current_value) => {
                let expected_value = format!("\"{}\"", app_path.display());
                Ok(current_value == expected_value)
            }
            Err(_) => Ok(false),
        }
    }
}

#[cfg(target_os = "macos")]
pub mod autostart {
    use std::error::Error;
    use std::fs::{self, File};
    use std::path::Path;
    use dirs::home_dir;

    pub fn enable(app_name: &str, app_path: &Path) -> Result<(), Box<dyn Error>> {
        let plist_dir = home_dir()
            .ok_or("无法获取用户目录")?
            .join("Library")
            .join("LaunchAgents");
        fs::create_dir_all(&plist_dir)?;
        let plist_path = plist_dir.join(format!("com.{}.plist", app_name));
        let plist_content = format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.{}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>"#,
            app_name,
            app_path.display()
        );
        fs::write(&plist_path, plist_content)?;
        let _ = std::process::Command::new("launchctl")
            .arg("load")
            .arg("-w")
            .arg(&plist_path)
            .status();
        Ok(())
    }

    pub fn disable(app_name: &str) -> Result<(), Box<dyn Error>> {
        let plist_path = home_dir()
            .ok_or("无法获取用户目录")?
            .join("Library")
            .join("LaunchAgents")
            .join(format!("com.{}.plist", app_name));
        let _ = std::process::Command::new("launchctl")
            .arg("unload")
            .arg("-w")
            .arg(&plist_path)
            .status();
        if plist_path.exists() {
            fs::remove_file(plist_path)?;
        }
        Ok(())
    }

    pub fn is_enabled(app_name: &str) -> Result<bool, Box<dyn Error>> {
        let plist_path = home_dir()
            .ok_or("无法获取用户目录")?
            .join("Library")
            .join("LaunchAgents")
            .join(format!("com.{}.plist", app_name));
        Ok(plist_path.exists())
    }
}

#[cfg(target_os = "linux")]
pub mod autostart {
    use std::error::Error;
    use std::fs::{self, File};
    use std::io::Write;
    use std::path::Path;
    use xdg::BaseDirectories;

    pub fn enable(app_name: &str, app_path: &Path) -> Result<(), Box<dyn Error>> {
        let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
        let autostart_dir = xdg_dirs
            .place_config_file("autostart")
            .map_err(|_| "无法创建autostart目录")?;
        let desktop_entry_path = autostart_dir.join(format!("{}.desktop", app_name));
        let mut file = File::create(&desktop_entry_path)?;
        writeln!(file, "[Desktop Entry]")?;
        writeln!(file, "Type=Application")?;
        writeln!(file, "Name={}", app_name)?;
        writeln!(file, "Exec={}", app_path.display())?;
        writeln!(file, "Terminal=false")?;
        writeln!(file, "NoDisplay=false")?;
        writeln!(file, "X-GNOME-Autostart-enabled=true")?;
        Ok(())
    }

    pub fn disable(app_name: &str) -> Result<(), Box<dyn Error>> {
        let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
        if let Ok(path) = xdg_dirs.place_config_file("autostart") {
            let desktop_entry_path = path.join(format!("{}.desktop", app_name));
            if desktop_entry_path.exists() {
                fs::remove_file(desktop_entry_path)?;
            }
        }
        Ok(())
    }

    pub fn is_enabled(app_name: &str) -> Result<bool, Box<dyn Error>> {
        let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
        if let Ok(path) = xdg_dirs.place_config_file("autostart") {
            let desktop_entry_path = path.join(format!("{}.desktop", app_name));
            return Ok(desktop_entry_path.exists());
        }
        Ok(false)
    }
}

#[no_mangle]
pub extern "C" fn enable_autostart(app_name: *const c_char) -> *mut c_char {
    if app_name.is_null() {
        return create_error_response("App name pointer is null");
    }
    let app_name_str = unsafe {
        match CStr::from_ptr(app_name).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in app name"),
        }
    };
    if let Ok(exe_path) = std::env::current_exe() {
        match autostart::enable(app_name_str, &exe_path) {
            Ok(_) => create_success_response("Autostart enabled"),
            Err(e) => create_error_response(&format!("Failed to enable autostart: {}", e)),
        }
    } else {
        create_error_response("Failed to get current executable path")
    }
}

#[no_mangle]
pub extern "C" fn disable_autostart(app_name: *const c_char) -> *mut c_char {
    if app_name.is_null() {
        return create_error_response("App name pointer is null");
    }
    let app_name_str = unsafe {
        match CStr::from_ptr(app_name).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in app name"),
        }
    };
    match autostart::disable(app_name_str) {
        Ok(_) => create_success_response("Autostart disabled"),
        Err(e) => create_error_response(&format!("Failed to disable autostart: {}", e)),
    }
}

#[no_mangle]
pub extern "C" fn is_autostart_enabled(app_name: *const c_char) -> *mut c_char {
    if app_name.is_null() {
        return create_error_response("App name pointer is null");
    }
    let app_name_str = unsafe {
        match CStr::from_ptr(app_name).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in app name"),
        }
    };
    if let Ok(exe_path) = std::env::current_exe() {
        match autostart::is_enabled(app_name_str, &exe_path) {
            Ok(enabled) => {
                let response = format!("{{\"success\":true,\"data\":{}}}", enabled);
                match CString::new(response) {
                    Ok(c_string) => return c_string.into_raw(),
                    Err(_) => return ptr::null_mut(),
                }
            }
            Err(e) => create_error_response(&format!("Failed to check autostart status: {}", e)),
        }
    } else {
        create_error_response("Failed to get current executable path")
    }
}

#[no_mangle]
pub extern "C" fn is_server_running() -> *mut c_char {
    let handle = SERVER_HANDLE.lock().unwrap();
    let running = handle.is_some();
    let response = format!("{{\"success\":true,\"data\":{}}}", running);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}