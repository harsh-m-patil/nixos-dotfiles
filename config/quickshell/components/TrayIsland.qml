import QtQuick

// Tray icons now live in the status island's Control Center; this bar slot stays empty
// so existing `tray` entries in Settings.bar keep loading.
Item {
    visible: false
}
