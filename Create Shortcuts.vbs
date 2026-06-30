Set oWS  = WScript.CreateObject("WScript.Shell")
Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")

appDir   = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
godotExe = appDir & "Godot_v4.3-stable_win64.exe"
iconFile = appDir & "icon.ico"

' Clear Windows icon cache
oWS.Run "ie4uinit.exe -ClearIconCache", 0, True

' Helper sub to create shortcut
Sub CreateLnk(lnkPath)
    Set oLink = oWS.CreateShortcut(lnkPath)
    oLink.TargetPath       = godotExe
    oLink.Arguments        = "--path app/hub"
    oLink.WorkingDirectory = appDir
    oLink.WindowStyle      = 1
    If oFSO.FileExists(iconFile) Then oLink.IconLocation = iconFile & ", 0"
    oLink.Description      = "KE_ArKade Hub"
    oLink.Save
End Sub

' 1. Desktop shortcut
desktopPath = oWS.SpecialFolders("Desktop")
CreateLnk(desktopPath & "\KE ArKade.lnk")

' 2. Start Menu shortcut
startMenuPath = oWS.SpecialFolders("StartMenu") & "\Programs"
CreateLnk(startMenuPath & "\KE ArKade.lnk")

' 3. Taskbar shortcut
taskbarPath = oWS.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
If oFSO.FolderExists(taskbarPath) Then
    CreateLnk(taskbarPath & "\KE ArKade.lnk")
    
    ' Restart Explorer so the taskbar pin shows up immediately
    oWS.Run "cmd.exe /c taskkill /f /im explorer.exe & start explorer.exe", 0, True
End If

MsgBox "Shortcuts created and pinned to Taskbar!" & vbCrLf & vbCrLf & _
       "Desktop: KE ArKade" & vbCrLf & _
       "Start Menu: Programs > KE ArKade" & vbCrLf & _
       "Taskbar: KE ArKade (Explorer restarted)", _
       vbInformation, "KE_ArKade"
