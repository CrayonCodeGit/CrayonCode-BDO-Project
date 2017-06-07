#include <WinAPI.au3>

Func cw($text)
	ConsoleWrite(@CRLF & $text)
EndFunc   ;==>cw

Func CoSe($key, $raw = 0)
	Dim $hTitle
	$hwnd = WinActive($hTitle)
	If $hwnd = 0 Then $hwnd = WinActivate($hTitle)

	Local $Pos = WinGetPos($hwnd)
	If @error Then
		Local $Pos[4] = [0, 0, @DesktopWidth, @DesktopHeight]
	EndIf

	Opt("MouseCoordMode", 2)
	If MouseGetPos(0) < 0 Or MouseGetPos(0) > $Pos[2] Or MouseGetPos(1) < 0 Or MouseGetPos(1) > $Pos[3] Then MouseMove(100, 100, 0)
	Opt("MouseCoordMode", 1)

	ControlSend($hwnd, "", "", $key, $raw)
EndFunc   ;==>CoSe

Func _terminate()
	Exit (0)
EndFunc   ;==>_terminate

Func VisibleCursor()
	Local $cursor = _WinAPI_GetCursorInfo()
	Return ($cursor[1])
EndFunc   ;==>VisibleCursor

Func VMouse($x, $y, $clicks = 0, $button = "left", $speed = 10)
	If Not VisibleCursor() Then CoSe("{LCTRL}")
	If $clicks > 0 Then
		MouseClick($button, $x, $y, $clicks, $speed)
	Else
		MouseMove($x, $y, $speed)
	EndIf
EndFunc   ;==>VMouse

Func ObfuscateTitle($Title, $length = 5)
	Local $newtitle = ""
	If $length > 0 Then
		For $i = 1 To $length
			Switch Random(1, 3, 1)
				Case 1
					$newtitle &= Chr(Random(65, 90, 1)) ; small letter
				Case 2
					$newtitle &= Chr(Random(97, 122, 1)) ; big letter
				Case 3
					$newtitle &= Random(0, 9, 1) ; number
			EndSwitch
		Next
	EndIf
	$newtitle &= @HOUR & @MIN & @SEC
	WinSetTitle($Title, "", $newtitle)
	Return $newtitle
EndFunc   ;==>ObfuscateTitle

Func AntiScreenSaverMouseWiggle($minutes = 2)
	Local Static $ScreenSaver = TimerInit()
	$minutes *= 60000

	If TimerDiff($ScreenSaver) >= $minutes Then
		Local $MPos = MouseGetPos()
		MouseMove($MPos[0] + 10, $MPos[1])
		MouseMove($MPos[0], $MPos[1])
		$ScreenSaver = TimerInit()
		Return True
	EndIf

	Return False
EndFunc

Func IsProcessConnected($ProcessName)
	Local $PID = ProcessExists($ProcessName)
	If Not $PID Then Return -1
	Local $Pattern = "\s" & $PID & "\s"
	Local $iPID = Run(@ComSpec & " /c netstat -aon", @SystemDir, @SW_HIDE, 4 + 2) ;  $STDERR_CHILD (0x4) + $STDOUT_CHILD (0x2)
	If Not $iPID Then Return -2
	Local $sOutput = ""

	While True
		$sOutput &= StdoutRead($iPID)
		If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
			ExitLoop
		EndIf
	WEnd

	Return (Int(StringRegExp($sOutput, $Pattern, 0))) ; Returns 1 if connceted, 0 if disconnected.
EndFunc   ;==>IsProcessConnected

Func MouseFreeZone($left, $top, $right, $bottom, $x, $y)
	Local $MGS = MouseGetPos()
	If Not VisibleCursor() Then CoSe("{LCTRL}")
	If $MGS[0] >= $left And $MGS[0] <= $right And $MGS[1] >= $top And $MGS[1] <= $bottom Then MouseMove($x, $y)
EndFunc   ;==>MouseFreeZone

Func IniReadKey($Key, ByRef $aSection)
	For $i = 1 To UBound($aSection) - 1 Step 1
		If $aSection[$i][0] = $Key Then Return ($aSection[$i][1])
	Next
	Return ("KeyNotFound")
EndFunc

Func CBT($data) ; Transforms Checkbox values for ini
	Switch Int($data)
		Case 1
			Return 1
		Case 4
			Return 0
		Case 0
			Return 4
	EndSwitch
EndFunc   ;==>CBT

Func LogData($text, $File = "LOGFILE.txt")
	Global $LogFile = ""
	If $LogFile = "" Then
		$LogFile = FileOpen($File, 9)
		OnAutoItExitRegister(CloseLog)
	EndIf
	FileWriteLine($LogFile, $text)
EndFunc   ;==>LogData

Func CloseLog()
	If $LogFile <> "" Then
		FileClose($LogFile)
	EndIf
EndFunc   ;==>CloseLog