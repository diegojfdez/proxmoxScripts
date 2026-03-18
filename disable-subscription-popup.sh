#!/bin/bash

# Ziel-Datei mit dem JavaScript-Code, der das Popup erzeugt
TARGET_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

# Zeitstempel für eindeutige Backup-Dateinamen
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Backup-Dateiname mit Zeitstempel
BACKUP_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak.$TIMESTAMP"

# Überprüfen, ob der Originaltext des Popups noch in der Datei enthalten ist
# Nur wenn das der Fall ist, wird gepatcht und ein Backup erstellt
if grep -q 'No valid subscription' "$TARGET_FILE"; then
    echo "📦 Proxmox Subscription Notice wird deaktiviert..."

    # Erstelle ein zeitgestempeltes Backup der Originaldatei
    cp "$TARGET_FILE" "$BACKUP_FILE"
    echo "🔒 Backup erstellt unter: $BACKUP_FILE"

    # Führe den Patch durch: Kommentiere den Block mit der Popup-Meldung aus
    # sed durchsucht den Codeblock von "Ext.Msg.show({" bis zur schließenden "});"
    # und fügt am Zeilenanfang "//" ein, um den gesamten Block zu deaktivieren
    sed -i.bak -e '/Ext.Msg.show({/,/});/s/^/\/\//' "$TARGET_FILE"

    # Starte den Proxmox-Webdienst neu, damit die Änderungen wirksam werden
    systemctl restart pveproxy
    echo "✅ Fertig: Die Popup-Meldung wurde deaktiviert."
else
    # Wenn bereits gepatcht, wird keine Aktion durchgeführt
    echo "ℹ️ Popup-Meldung wurde bereits deaktiviert oder Patch ist nicht nötig."
fi
