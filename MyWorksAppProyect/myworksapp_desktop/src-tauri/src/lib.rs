use tauri::{Emitter, Manager};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let mut builder = tauri::Builder::default();
    #[cfg(desktop)]
    {
        builder = builder.plugin(tauri_plugin_single_instance::init(|app, argv, _cwd| {
            forward_deep_link(&app, argv);
        }));
    }
    builder
        .plugin(tauri_plugin_deep_link::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

/// La segunda instancia reenvía el deep link a la ventana que ya está abierta.
#[cfg(desktop)]
fn forward_deep_link(app: &tauri::AppHandle, argv: Vec<String>) {
    let urls: Vec<String> = argv
        .into_iter()
        .filter(|arg| arg.starts_with("myworksapp-admin:"))
        .collect();
    if !urls.is_empty() {
        let _ = app.emit("deep-link://new-url", urls);
    }
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.unminimize();
        let _ = window.set_focus();
    }
}
