Local $h_ImageSearchDLL = -1

Func cr($text = "", $addCR = 1, $printTime = False) ;Print to console
	Static $sToolTip
	If Not @Compiled Then
		If $printTime Then ConsoleWrite(@HOUR & ":" & @MIN & ":" & @SEC & ":" & @MSEC & " ")
		ConsoleWrite($text)
		If $addCR >= 1 Then ConsoleWrite(@CR)
		If $addCR = 2 Then ConsoleWrite(@CR)
	Else
		If $printTime Then $sToolTip &= @HOUR & ":" & @MIN & ":" & @SEC & ":" & @MSEC & " "
		$sToolTip &= $text
		If $addCR >= 1 Then $sToolTip &= @CR
		If $addCR = 2 Then $sToolTip &= @CR
;~ 		ToolTip($sToolTip)
	EndIf
	Return $text
EndFunc   ;==>cr

Func _ImageSearchStartup()
;~ 	_WinAPI_Wow64EnableWow64FsRedirection(True)
	$sOSArch = @OSArch ;Check if running on x64 or x32 Windows ;@OSArch Returns one of the following: "X86", "IA64", "X64" - this is the architecture type of the currently running operating system.
	$sAutoItX64 = @AutoItX64 ;Check if using x64 AutoIt ;@AutoItX64 Returns 1 if the script is running under the native x64 version of AutoIt.
	If $sOSArch = "X86" Or $sAutoItX64 = 0 Then
		cr("+>" & "@OSArch=" & $sOSArch & @TAB & "@AutoItX64=" & $sAutoItX64 & @TAB & "therefore using x32 ImageSearch DLL")
;~ 		TrayTip("","@OSArch=" & $sOSArch & @TAB & "@AutoItX64=" & $sAutoItX64 & @TAB & "ImageSearchDLLx32.dll", 5)
		$h_ImageSearchDLL = DllOpen("ImageSearchDLLx32.dll")
		If $h_ImageSearchDLL = -1 Then Return "DllOpen failure"
	ElseIf $sOSArch = "X64" And $sAutoItX64 = 1 Then
		cr("+>" & "@OSArch=" & $sOSArch & @TAB & "@AutoItX64=" & $sAutoItX64 & @TAB & "therefore using x64 ImageSearch DLL")
;~ 		TrayTip("","@OSArch=" & $sOSArch & @TAB & "@AutoItX64=" & $sAutoItX64 & @TAB & "ImageSearchDLLx64.dll", 5)
		$h_ImageSearchDLL = DllOpen("ImageSearchDLLx64.dll")
		If $h_ImageSearchDLL = -1 Then Return "DllOpen failure"
	Else
		Return "Inconsistent or incompatible Script/Windows/CPU Architecture"
	EndIf
	Return True
EndFunc   ;==>_ImageSearchStartup

Func _ImageSearchShutdown()
	DllClose($h_ImageSearchDLL)
	cr(">" & "_ImageSearchShutdown() completed")
	Return True
EndFunc   ;==>_ImageSearchShutdown

; ------------------------------------------------------------------------------
;
; AutoIt Version: 3.0
; Language:       English
; Description:    Functions that assist with Image Search
;                 Require that the ImageSearchDLL.dll be loadable
;
; ------------------------------------------------------------------------------
;===============================================================================
;
; Description:      Find the position of an image on the desktop
; Syntax:           _ImageSearchArea, _ImageSearch
; Parameter(s):
;                   $findImage - the image to locate on the desktop
;                   $tolerance - 0 for no tolerance (0-255). Needed when colors of
;                                image differ from desktop. e.g GIF
;                   $resultPosition - Set where the returned x,y location of the image is.
;                                     1 for centre of image, 0 for top left of image
;                   $x $y - Return the x and y location of the image
;                   $transparency - TRANSBLACK, TRANSWHITE or hex value (e.g. 0xffffff) of
;                                  the color to be used as transparency; can be omitted if
;                                  not needed
;
; Return Value(s):  On Success - Returns True
;                   On Failure - Returns False
;
; Note: Use _ImageSearch to search the entire desktop, _ImageSearchArea to specify
;       a desktop region to search
;
;===============================================================================
Func _ImageSearch($findImage, $resultPosition, ByRef $x, ByRef $y, $tolerance, $transparency = 0)
	Return _ImageSearchArea($findImage, $resultPosition, 0, 0, @DesktopWidth, @DesktopHeight, $x, $y, $tolerance, $transparency)
EndFunc   ;==>_ImageSearch

Func _ImageSearchArea($findImage, $resultPosition, $x1, $y1, $right, $bottom, ByRef $x, ByRef $y, $tolerance = 0, $transparency = 0);Credits to Sven for the Transparency addition
	If Not FileExists($findImage) Then
		ConsoleWriteError(@CRLF & "!Image File not found")
		SetError(1, 1, "Image File not found")
		Return False
	EndIf
	If $tolerance < 0 Or $tolerance > 255 Then $tolerance = 0
	If $h_ImageSearchDLL = -1 Then _ImageSearchStartup()

	If $transparency <> "" Then $findImage = "*Trans" & $transparency & " " & $findImage
	If $tolerance > 0 Then $findImage = "*" & $tolerance & " " & $findImage
	$result = DllCall($h_ImageSearchDLL, "str", "ImageSearch", "int", $x1, "int", $y1, "int", $right, "int", $bottom, "str", $findImage)
	If @error Then
		ConsoleWriteError(@CRLF & "!Image File not found")
		SetError(1, 1, "DllCall Error=" & @error)
		Return False
	EndIf
	If $result = "0" Or Not IsArray($result) Or $result[0] = "0" Then Return False

	$array = StringSplit($result[0], "|")
	If (UBound($array) >= 4) Then
		$x = Int(Number($array[2])); Get the x,y location of the match
		$y = Int(Number($array[3]))
		If $resultPosition = 1 Then
			$x = $x + Int(Number($array[4]) / 2); Account for the size of the image to compute the centre of search
			$y = $y + Int(Number($array[5]) / 2)
		EndIf
		Return True
	EndIf
EndFunc   ;==>_ImageSearchArea

;===============================================================================
;
; Description:      Wait for a specified number of seconds for an image to appear
;
; Syntax:           _WaitForImageSearch, _WaitForImagesSearch
; Parameter(s):
;                   $waitSecs  - seconds to try and find the image
;                   $findImage - the image to locate on the desktop
;                   $tolerance - 0 for no tolerance (0-255). Needed when colors of
;                                image differ from desktop. e.g GIF
;                   $resultPosition - Set where the returned x,y location of the image is.
;                                     1 for centre of image, 0 for top left of image
;                   $x $y - Return the x and y location of the image
;                   $transparency - TRANSBLACK, TRANSWHITE or hex value (e.g. 0xffffff) of
;                                  the color to be used as transparency can be omitted if
;                                  not needed
;
; Return Value(s):  On Success - Returns 1
;                   On Failure - Returns 0
;
;
;===============================================================================
Func _WaitForImageSearch($findImage, $waitSecs, $resultPosition, ByRef $x, ByRef $y, $tolerance, $transparency = 0)
	$waitSecs = $waitSecs * 1000
	$startTime = TimerInit()
	While TimerDiff($startTime) < $waitSecs
		Sleep(100)
		If _ImageSearch($findImage, $resultPosition, $x, $y, $tolerance, $transparency) Then
			Return True
		EndIf
	WEnd
	Return False
EndFunc   ;==>_WaitForImageSearch