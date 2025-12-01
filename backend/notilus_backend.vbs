' Script VBScript pour lancer le backend Notilus de manière furtive (sans fenêtre)
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Obtenir le répertoire du script
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Changer vers le répertoire du backend
objShell.CurrentDirectory = strScriptPath

' Lancer Python en mode furtif (WindowStyle = 0 = caché)
objShell.Run "pythonw main.py", 0, False

' Le script se termine immédiatement, laissant Python tourner en arrière-plan

