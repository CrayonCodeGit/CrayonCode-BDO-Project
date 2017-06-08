#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         CrayonCode
	Version:		Alpha 0.50
	Contact:		http://www.elitepvpers.com/forum/black-desert/4268940-autoit-crayoncode-bot-project-opensource-free.html
	GitHub: 		https://github.com/CrayonCodeGit/CrayonCode-BDO-Project/

#ce ----------------------------------------------------------------------------


#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compile_Both=y  ;required for ImageSearch.au3
#AutoIt3Wrapper_UseX64=y  ;required for ImageSearch.au3
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#RequireAdmin
#include "ImageSearch.au3"
#include "FastFind.au3"
#include "Support.au3"
#include "GUI.au3"
#include <File.au3>
#include <Array.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>

OnAutoItExitRegister(_ImageSearchShutdown)
Opt("MouseClickDownDelay", 100)
Opt("MouseClickDelay", 50)
Opt("SendKeyDelay", 50)


Global $Fish = False
Global $Res[4] = [0, 0, @DesktopWidth, @DesktopHeight]

Global $WorkerEnable = True, $WorkerCD = 10
Global $BuffEnable = True, $BuffCD = 30
Global $BuffKeybinds[2] = [8, 7]
Global $DryFishEnable = True, $DryFishCD = 5, $DryFishMaxRarity = 2

Global $hTitle = "BLACK DESERT - "
Global $LNG = "en"
Global $ScreenCapLoot = False
Global $LogEnable = True

Global $aListView1[10]
For $i = 1 to 9
	$aListView1[$i] = GUICtrlCreateListViewItem("", $ListView1)
Next

HotKeySet("^{F1}", "_terminate")

HotKeySet("{F3}", "PauseToggle")
HotKeySet("{F4}", "Main_Fishing")
HotKeySet("{F5}", "FishingAssist")


; # GUI
Func SetGUIStatus($data)
	Local Static $LastGUIStatus
	Local Static $Limits = _GUICtrlEdit_SetLimitText ( $ELog, 300000000 ) ; Increase Text Limit since Log usually stopped around 800 lines
	If $data <> $LastGUIStatus Then
		_GUICtrlEdit_AppendText($ELog, @HOUR & ":" & @MIN & "." & @SEC & " " & $data & @CRLF)
		ConsoleWrite(@CRLF & @HOUR & ":" & @MIN & "." & @SEC & " " & $data)
		If $LogEnable = True Then LogData(@HOUR & ":" & @MIN & "." & @SEC & " " & $data, "logs/LOGFILE.txt")
		$LastGUIStatus = $data
	EndIf
EndFunc   ;==>SetGUIStatus

Func GUILoopSwitch()
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $BDryFish
			DryFish(True, 3, 0)
		Case $BFeedWorker
			WorkerFeed(True, 0)
		Case $BBuffKeys
			Buff(True, 0, $BuffKeybinds)
		Case $BPause
			PauseToggle()
		Case $BQuit
			_terminate()
		Case $BFish
			Main_Fishing()
		Case $BMinigame
			FishingAssist()
		Case $BSave
			StoreGUI()
		Case $BLoopSide
			LoopSideFunctions()
	EndSwitch
EndFunc   ;==>GUILoopSwitch

Func InitGUI()
	; LootSettings
	Global $LootSettings = IniReadSection("config/settings.ini", "LootSettings")
	Switch $LootSettings[1][1]
		Case 0
			GUICtrlSetData($CRarity, "|Gold|Blue|Green|White|Specials Only", "White")
		Case 1
			GUICtrlSetData($CRarity, "|Gold|Blue|Green|White|Specials Only", "Green")
		Case 2
			GUICtrlSetData($CRarity, "|Gold|Blue|Green|White|Specials Only", "Blue")
		Case 3
			GUICtrlSetData($CRarity, "|Gold|Blue|Green|White|Specials Only", "Gold")
		Case 4
			GUICtrlSetData($CRarity, "|Gold|Blue|Green|White|Specials Only", "Specials Only")
	EndSwitch
	GUICtrlSetState($CBSpecial1, CBT($LootSettings[2][1]))
	GUICtrlSetState($CBSpecial2, CBT($LootSettings[3][1]))
	GUICtrlSetState($CBSpecial3, CBT($LootSettings[4][1]))
	GUICtrlSetState($CBEvent, CBT($LootSettings[5][1]))
	GUICtrlSetState($CBTrash, CBT($LootSettings[6][1]))

	; InventorySettings
	Global $InventorySettings = IniReadSection("config/settings.ini", "InventorySettings")
	GUICtrlSetState($CBDiscardRods, CBT($InventorySettings[1][1]))
	GUICtrlSetData($IBufferSize, $InventorySettings[2][1])

	; Drying Settings
	Global $DryingSettings = IniReadSection("config/settings.ini", "DryingSettings")
	GUICtrlSetState($CBDryFish, CBT($DryingSettings[1][1]))
	Switch $DryingSettings[2][1]
		Case 0
			GUICtrlSetData($CDryFish, "|Gold|Blue|Green|White", "White")
		Case 1
			GUICtrlSetData($CDryFish, "|Gold|Blue|Green|White", "Green")
		Case 2
			GUICtrlSetData($CDryFish, "|Gold|Blue|Green|White", "Blue")
		Case 3
			GUICtrlSetData($CDryFish, "|Gold|Blue|Green|White", "Gold")
	EndSwitch
	GUICtrlSetData($IDryFishInterval, $DryingSettings[3][1])

	; WorkerSettings
	Global $WorkerSettings = IniReadSection("config/settings.ini", "WorkerSettings")
	GUICtrlSetState($CBFeedWorker, CBT($WorkerSettings[1][1]))
	GUICtrlSetData($IFeedWorkerInterval, $WorkerSettings[2][1])

	; BuffSettings
	Global $BuffSettings = IniReadSection("config/settings.ini", "BuffSettings")
	GUICtrlSetState($CBBuff, CBT($BuffSettings[1][1]))
	GUICtrlSetData($IBuffInterval, $BuffSettings[2][1])
	GUICtrlSetData($IBuffKeys, $BuffSettings[3][1])

	; ClientSettings
	Global $ClientSettings = IniReadSection("config/settings.ini", "ClientSettings")
	GUICtrlSetData($IClientName, $ClientSettings[1][1])
	GUICtrlSetData($CLang, "|en|de|fr", $ClientSettings[2][1])

	GUICtrlSetState($CBLogFile, CBT($ClientSettings[3][1]))
	GUICtrlSetState($CBLootCapture, CBT($ClientSettings[4][1]))

	$hTitle = $ClientSettings[1][1]
	$LNG = $ClientSettings[2][1]
	$LogEnable = $ClientSettings[3][1]
	$ScreenCapLoot = $ClientSettings[4][1]

	Local $TotalStats = IniReadSection("logs/stats.ini", "TotalStats")
	Local $SessionStats = IniReadSection("logs/stats.ini", "SessionStats")


	For $i = 1 To 9
		GUICtrlSetData($aListView1[$i], $SessionStats[$i][0] & "|" & $SessionStats[$i][1] & "|" & $TotalStats[$i][1], "")
	Next
EndFunc

Func StoreGUI()
	; LootSettings
	Global $LootSettings = IniReadSection("config/settings.ini", "LootSettings")
	Switch GUICtrlRead($CRarity)
		Case "White"
			$LootSettings[1][1] = 0
		Case "Green"
			$LootSettings[1][1] = 1
		Case "Blue"
			$LootSettings[1][1] = 2
		Case "Gold"
			$LootSettings[1][1] = 3
		Case "Specials Only"
			$LootSettings[1][1] = 4
	EndSwitch
	$LootSettings[2][1] = CBT(GUICtrlRead($CBSpecial1))
	$LootSettings[3][1] = CBT(GUICtrlRead($CBSpecial2))
	$LootSettings[4][1] = CBT(GUICtrlRead($CBSpecial3))
	$LootSettings[5][1] = CBT(GUICtrlRead($CBEvent))
	$LootSettings[6][1] = CBT(GUICtrlRead($CBTrash))
	IniWriteSection("config/settings.ini", "LootSettings", $LootSettings)

	; InventorySettings
	Global $InventorySettings = IniReadSection("config/settings.ini", "InventorySettings")
	$InventorySettings[1][1] = CBT(GUICtrlRead($CBDiscardRods)) ; Discard Rods
	$InventorySettings[2][1] = Int(GUICtrlRead($IBufferSize))
	If $InventorySettings[2][1] < 2 Then $InventorySettings[2][1] = 2
	IniWriteSection("config/settings.ini", "InventorySettings", $InventorySettings)

	; DryingSettings
	Global $DryingSettings = IniReadSection("config/settings.ini", "DryingSettings")
	$DryingSettings[1][1] = CBT(GUICtrlRead($CBDryFish))
	Switch GUICtrlRead($CDryFish)
		Case "White"
			$DryingSettings[2][1] = 0
		Case "Green"
			$DryingSettings[2][1] = 1
		Case "Blue"
			$DryingSettings[2][1] = 2
		Case "Gold"
			$DryingSettings[2][1] = 3
	EndSwitch
	$DryingSettings[3][1] = GUICtrlRead($IDryFishInterval)
	IniWriteSection("config/settings.ini", "DryingSettings", $DryingSettings)

	; WorkerSettings
	Global $WorkerSettings = IniReadSection("config/settings.ini", "WorkerSettings")
	$WorkerSettings[1][1] = CBT(GUICtrlRead($CBFeedWorker))
	$WorkerSettings[2][1] = GUICtrlRead($IFeedWorkerInterval)
	IniWriteSection("config/settings.ini", "WorkerSettings", $WorkerSettings)

	; BuffSettings
	Global $BuffSettings = IniReadSection("config/settings.ini", "BuffSettings")
	$BuffSettings[1][1] = CBT(GUICtrlRead($CBBuff))
	$BuffSettings[2][1] = GUICtrlRead($IBuffInterval)
	$BuffSettings[3][1] = GUICtrlRead($IBuffKeys)
	IniWriteSection("config/settings.ini", "BuffSettings", $BuffSettings)

	; ClientSettings
	Global $ClientSettings = IniReadSection("config/settings.ini", "ClientSettings")
	$ClientSettings[1][1] = GUICtrlRead($IClientName)
	$ClientSettings[2][1] = GUICtrlRead($CLang)
	$ClientSettings[3][1] = CBT(GUICtrlRead($CBLogFile))
	$ClientSettings[4][1] = CBT(GUICtrlRead($CBLootCapture))
	IniWriteSection("config/settings.ini", "ClientSettings", $ClientSettings)


	InitGUI()
EndFunc

Func CreateConfig()
	If FileExists("logs/") = False Then DirCreate("logs/")
	If FileExists("config/") = False Then DirCreate("config/")


	If FileExists("config/settings.ini") = False Then
		Local $LootSettings = ""
		$LootSettings &= "MinRarity=0" & @LF
		$LootSettings &= "loot_Silverkey=1" & @LF
		$LootSettings &= "loot_AncientRelic=1" & @LF
		$LootSettings &= "loot_Coelacanth=1" & @LF
		$LootSettings &= "loot_EventItems=1" & @LF
		$LootSettings &= "loot_TrashItems=0" & @LF
		IniWriteSection("config/settings.ini", "LootSettings", $LootSettings)

		Local $InventorySettings = ""
		$InventorySettings &= "Enable_DiscardRods=1" & @LF
		$InventorySettings &= "BufferSize=2" & @LF
		IniWriteSection("config/settings.ini", "InventorySettings", $InventorySettings)

		Local $DryingSettings = ""
		$DryingSettings &= "Enable_Drying=1" & @LF
		$DryingSettings &= "MaxRarity=2" & @LF
		$DryingSettings &= "DryingInterval=5" & @LF
		IniWriteSection("config/settings.ini", "DryingSettings", $DryingSettings)

		Local $WorkerSettings = ""
		$WorkerSettings &= "Enable_FeedWorker=1" & @LF
		$WorkerSettings &= "FeedWorkerInterval=60" & @LF
		IniWriteSection("config/settings.ini", "WorkerSettings", $WorkerSettings)

		Local $BuffSettings = ""
		$BuffSettings &= "Enable_Buff=1" & @LF
		$BuffSettings &= "BuffInterval=30" & @LF
		$BuffSettings &= "BuffKeys=7,8" & @LF
		IniWriteSection("config/settings.ini", "BuffSettings", $BuffSettings)

		Local $ClientSettings = ""
		$ClientSettings &= "ClientName=BLACK DESERT - " & @LF
		$ClientSettings &= "ClientLanguage=en" & @LF
		$ClientSettings &= "Enable_Logfile=1" & @LF
		$ClientSettings &= "Enable_ScreencapLoot=0" & @LF
		IniWriteSection("config/settings.ini", "ClientSettings", $ClientSettings)
	EndIf

	If FileExists("logs/stats.ini") = False Then
		Local $Stats = ""
		$Stats &= "White=0" & @LF
		$Stats &= "Green=0" & @LF
		$Stats &= "Blue=0" & @LF
		$Stats &= "Gold=0" & @LF
		$Stats &= "Silverkey=0" & @LF
		$Stats &= "AncientRelic=0" & @LF
		$Stats &= "Coelacanth=0" & @LF
		$Stats &= "Eventitem=0" & @LF
		$Stats &= "Trash=0"
		IniWriteSection("logs/stats.ini", "TotalStats", $Stats)
		IniWriteSection("logs/stats.ini", "SessionStats", $Stats)
	EndIf



EndFunc   ;==>CreateConfig





; # Basic
Func DetectFullscreenToWindowedOffset($hTitle) ; Returns $Offset[4] left, top, right, bottom (Fullscreen returns 0, 0, Width, Height)
	Local $x1, $x2, $y1, $y2
	Local $Offset[4]
	Local $ClientZero[4] = [0, 0, 0, 0]

	WinActivate($hTitle)
	WinWaitActive($hTitle, "", 5)
	WinActivate($hTitle)
	Local $Client = WinGetPos($hTitle)
	If Not IsArray($Client) Then
		SetGUIStatus("E: ClientSize could not be detected")
		Return ($ClientZero)
	EndIf

	If $Client[2] = @DesktopWidth And $Client[3] = @DesktopHeight Then
		SetGUIStatus("Fullscreen detected (" & $Client[2] & "x" & $Client[3] & ") - No Offsets")
		Return ($Client)
	EndIf

	If Not VisibleCursor() Then CoSe("{LCTRL}")
	Opt("MouseCoordMode", 2)
	MouseMove(0, 0, 0)
	Opt("MouseCoordMode", 1)
	$x1 = MouseGetPos(0)
	$y1 = MouseGetPos(1)
	Opt("MouseCoordMode", 0)
	MouseMove(0, 0, 0)
	Opt("MouseCoordMode", 1)
	$x2 = MouseGetPos(0)
	$y2 = MouseGetPos(1)
	MouseMove($x1, $y1, 0)


	$Offset[0] = $Client[0] + $x1 - $x2
	$Offset[1] = $Client[1] + $y1 - $y2
	$Offset[2] = $Client[0] + $Client[2]
	$Offset[3] = $Client[1] + $Client[3]
	For $i = 0 To 3
		SetGUIStatus("ScreenOffset(" & $i & "): " & $Offset[$i])
	Next

	Return ($Offset)
EndFunc   ;==>DetectFullscreenToWindowedOffset

Func WaitForMenu($show = False, $timeout = 5)
	Local Const $WorkerIcon = "res/esc_worker.png"
	Local $x, $y, $IS
	Local $timer = TimerInit()
	$timeout *= 1000

	While TimerDiff($timer) < $timeout
		$IS = _ImageSearchArea($WorkerIcon, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 50, 0)
		If $IS = False Then CoSe("{ESC}") ; Opening Menu
		If $IS = True Then
			If $show = False Then CoSe("{ESC}") ; Closing Menu
			Return True
		EndIf
		Sleep(2000)
	WEnd
	Return False
EndFunc   ;==>WaitForMenu

Func OCInventory($open = True)
;~ 	Local Const $Offset[2] = [-298, 32] ; Offset from reference_inventory to left border of first Inventory Slot.
	Local Const $Offset[2] = [-298, 30] ; Offset from reference_inventory to left border of first Inventory Slot.
	Local $IS = False
	Local $C[2]
	Local $timer = TimerInit()
	While Not $IS And $Fish
		Sleep(250)
		$IS = _ImageSearchArea("res/reference_inventory.png", 0, $Res[0], $Res[1], $Res[2], $Res[3], $C[0], $C[1], 10, 0)
		Sleep(250)
		If $IS = True Then ; If the inventory is already open...
			If $open = True Then ; If $open = True return the inventory coordinates
				$C[0] += $Offset[0]
				$C[1] += $Offset[1]
				Return ($C)
			ElseIf $open = False Then ; If $open = False and the inventory is open, then close then inventory and continue the loop
				CoSe("i")
				Sleep(500)
			EndIf
		ElseIf $IS = False Then ; ElseIf the inventory was not found yet
			If $open = True Then ; Trying to open Inventory when $open = True
				CoSe("i")
				MouseMove($Res[0] + 1, $Res[1] + 1)
				Sleep(500)
			ElseIf $open = False Then ; If $open = False and the Inventory is not found then Return True
				SetGUIStatus("Inventory closed")
				Return True
			EndIf
		EndIf
		If TimerDiff($timer) / 1000 >= 6 Then
			SetGUIStatus("OCInventory Timeout")
			Return False
		EndIf
	WEnd
EndFunc   ;==>OCInventory

Func SearchInventory(ByRef $imagelist, $shadevariation = 0, $transparency = "", $reopen = True) ; Returns $C[2] or False
	Local $C[2], $IS
	If $reopen = True Then OCInventory(False)
	Local $InvA = OCInventory(True)
	If Not IsArray($InvA) Then Return False
	VMouse($InvA[0] + 48 * 8, $InvA[1], 1, "left") ; Click on Inventory to get focus

	Local $IW[4] = [$InvA[0], $InvA[1], $InvA[0] + 48 * 8, $InvA[1] + 47 * 8]
	For $k = 0 To 2
		MouseFreeZone($IW[0], $IW[1], $IW[2], $IW[3], $IW[0] - 50, $IW[1])
		For $i = 0 To UBound($imagelist) - 1
			$IS = _ImageSearchArea($imagelist[$i], 1, $IW[0], $IW[1], $IW[2], $IW[3], $C[0], $C[1], $shadevariation, $transparency)
			If $IS = True Then Return $C
		Next
		If $k < 2 Then ; Scrolling down inventory
			MouseMove($IW[0], $IW[1])
			Sleep(50)
			For $mw = 0 To 7
				MouseWheel("down")
				Sleep(50)
			Next
		EndIf
		Sleep(150)
	Next

	Return False

EndFunc   ;==>SearchInventory

Func PauseToggle()
	Local Static $PauseToggle = False
	$PauseToggle = Not $PauseToggle
	If $PauseToggle = False Then
		SetGUIStatus("Unpause")
		Return True
	EndIf
	SetGUIStatus("Pause")
	While $PauseToggle
		Sleep(500)
		GUILoopSwitch()
	WEnd
	Return True
EndFunc   ;==>PauseToggle

Func DetectFreeInventory()
	Local $IS, $x, $y
	Local $Free = 0
	SetGUIStatus("Detecting free inventory space")
	OCInventory(False)
	Local $InvA = OCInventory(True)
	If IsArray($InvA) = False Then Return False
	For $L = 0 To 2 Step 1
		MouseFreeZone($InvA[0], $InvA[1], $InvA[0] + 500, $InvA[1] + 500, $InvA[0] - 50, $InvA[1])
		For $j = 0 To 7 Step 1
			Local $String = $L & $j
			For $i = 0 To 7 Step 1
				$IS = _ImageSearchArea("res/reference_empty.png", 0, $InvA[0] + $i * 48, $InvA[1] + $j * 47, $InvA[0] + 48 + $i * 48, $InvA[1] + 47 + $j * 47, $x, $y, 25, 0)
				If $IS = True Then
					$Free += 1
					$String &= "[_]"
				Else
					$String &= "[X]"
				EndIf
			Next
			SetGUIStatus($String)
		Next
		If $L < 2 Then
			MouseMove($InvA[0], $InvA[1])
			Sleep(50)
			For $mw = 0 To 7
				MouseWheel("down")
				Sleep(50)
			Next
		EndIf
		Sleep(150)
	Next
	OCInventory(False)
	SetGUIStatus($Free & " empty slots")
	Return ($Free)
EndFunc   ;==>DetectFreeInventory


; # Fishing
Func DetectState($FishingState)
	Local $x, $y, $IS

	; Limiting detection region to speed up the process
	Local $Left = ($Res[0] + $Res[2]) / 2 - 200 ; Center of BDO Clientwindow - 200
	Local $Top = $Res[1] ; Top of BDO Clientwindow
	Local $Right = ($Res[0] + $Res[2]) / 2 + 200 ; Center of BDO Clientwindow + 200
	Local $Bottom = $Res[1] + 200 ; Top of BDO Clientwidow + 200

	$IS = _ImageSearchArea($FishingState, 1, $Left, $Top, $Right, $Bottom, $x, $y, 10, "White")
	If $IS = True Then Return True
	Return False
EndFunc   ;==>DetectState

Func GetState()
	Local Const $FishingStandby = "res/fishing/standby_" & $LNG & ".png"
	Local Const $FishingCurrently = "res/fishing/currently_" & $LNG & ".png"
	Local Const $FishingBite = "res/fishing/bite_" & $LNG & ".png"

	If DetectState($FishingBite) = True Then Return ("FishingBite")
	If DetectState($FishingCurrently) = True Then Return ("FishingCurrently")
	If DetectState($FishingStandby) = True Then Return ("FishingStandby")
	Return False
EndFunc   ;==>GetState

Func ReelIn() ; Solves the fishing timing minigame
	Local Const $ReelIn = "res/fishing/reelin.png"
	Local $x, $y, $IS, $SSN = 1

	CoSe("{SPACE}")

	Local $timer = TimerInit()
	While TimerDiff($timer) < 3000 And $Fish
		$IS = _ImageSearchArea($ReelIn, 0, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 0, "White")
		If $IS = True Then ExitLoop
	WEnd

	$timer = TimerInit()
	While TimerDiff($timer) / 1000 <= 5 And $Fish
		FFSnapShot($x, $y, $x + 97, $y + 21, $SSN)
		$NS = FFNearestSpot(1, 1, $x, $y, 5933000, 30, False, $x, $y, $x + 97, $y + 21, $SSN)
		If Not @error Then
			CoSe("{SPACE}")
			Return True
		EndIf
	WEnd
	Return False
EndFunc   ;==>ReelIn

Func FindRiddleAnchor() ; Waits 4 Seconds for the letter minigame timeline to appear and returns the position
	Local Const $RiddleAnchor = "res/fishing/riddle.png"
	Local $timer = TimerInit()
	Local $C[2] = [-1, -1]
	While TimerDiff($timer) / 1000 <= 4 And $Fish
		If _ImageSearchArea($RiddleAnchor, 0, $Res[0], $Res[1], $Res[2], $Res[3], $C[0], $C[1], 10, "0x00ff00") = 1 Then
			Return ($C)
		EndIf
	WEnd
	Return False
EndFunc   ;==>FindRiddleAnchor

Func Riddle($iAnchorX, $iAnchorY, $AnchorColor, $SSN) ; Recognizes arrow direction by checking offsets for $AnchorColor
	Local Const $ArrowsX[8] = [-2, +3, +3, -2, -2, -2, +3, +3] ; vv^^>><<
	Local Const $ArrowsY[8] = [-3, -3, +2, +2, +3, -3, +2, -2] ; vv^^>><<
	Local $ai[8], $iL = 4

	For $i = 0 To 7 Step 1
		If FFGetPixel($iAnchorX + $ArrowsX[$i], $iAnchorY + $ArrowsY[$i], $SSN) = $AnchorColor Then
			$ai[$i] = 1
		Else
			$ai[$i] = 0
		EndIf
	Next

	For $j = 3 To 0 Step -1
		If $ai[$j * 2] + $ai[$j * 2 + 1] = 2 Then $iL = $j
	Next

	Return ($iL)
EndFunc   ;==>Riddle

Func Riddler() ; Solves the fishing letter minigame
	Local Const $AnchorOffset[2] = [16, 25] ; relative position to Anchor (pointing to center of the arrow beneath each letter)
	Local Const $Spacing = 35 ; Space between each Letter
	Local Const $L[5] = ["s", "w", "d", "a", "."] ; basic minigame letters ("." for unidentified)
	Local $Word[10], $LetterColor, $text, $Riddle, $Wordlength = 0, $SSN = 1

	Local $aAnchor = FindRiddleAnchor()
	If Not IsArray($aAnchor) Then
		SetGUIStatus("Perfect Catch?")
		Return False
	EndIf

	$aAnchor[0] -= 45 ; Base Offset to include letters since anchor is below
	$aAnchor[1] -= 60
	FFSnapShot($aAnchor[0] - 10, $aAnchor[1] - 10, $aAnchor[0] + $Spacing * 10 + 10, $aAnchor[1] + 40, $SSN)
	$LetterColor = FFGetPixel($aAnchor[0] + $AnchorOffset[0], $aAnchor[1] + $AnchorOffset[1], $SSN)

	; Riddle each letter position from left to right until one is unidentified or last position is reached.
	For $i = 0 To 9 Step 1
		$Riddle = Riddle($aAnchor[0] + $AnchorOffset[0] + $Spacing * $i, $aAnchor[1] + $AnchorOffset[1], $LetterColor, $SSN)
		If $Riddle = 4 Then ; If unidentified exit loop
			$Word[$i] = $L[$Riddle]
			ExitLoop
		Else
			$Word[$i] = $L[$Riddle]
			$Wordlength += 1
		EndIf
	Next

	; If Wordlenght is >= 2 Then send each letter
	If $Wordlength < 2 Then
		Return (False)
	Else
		For $i = 0 To 9 Step 1
			If $Word[$i] <> "." Then
				Sleep(50) ; TODO Settings
				CoSe($Word[$i])
				$text &= $Word[$i]
			EndIf
			Sleep(100)
		Next
		Return (True)
	EndIf
EndFunc   ;==>Riddler


; # Fishing Misc
Func Cast()

	SetGUIStatus("Casting Fishingrod")
	Sleep(1000)
	CoSe("{SPACE}")

	Local $timer = TimerInit()
	While GetState() <> "FishingCurrently" And $Fish
		Sleep(500)
		If TimerDiff($timer) >= 8000 Then Return False
	WEnd
	Return True
EndFunc   ;==>Cast

Func InspectFishingrod()
	Local $equip = "res/fishing/equip_" & $LNG & ".png"
	Local $empty = "res/fishing/rod_empty.png"
	Local $WeaponOffSet[2] = [-63, 329]
	Local $x, $y, $IS = False

	Local $InvA = OCInventory(True)
	If IsArray($InvA) = False Then Return False

	$IS = _ImageSearchArea($equip, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 25, "White")
	If $IS = True Then
		SetGUIStatus("Equipment found")
		MouseFreeZone($x - 200, $y - 40, $Res[2], $y + 400, $x, $y - 50)
		Local $WS[4] = [$x + $WeaponOffSet[0] - 24, $y + $WeaponOffSet[1] - 24, $x + $WeaponOffSet[0] + 24, $y + $WeaponOffSet[1] + 24]

		$IS = _ImageSearchArea($empty, 1, $WS[0], $WS[1], $WS[2], $WS[3], $x, $y, 40)
		If $IS = True Then
			OCInventory(False)
			SetGUIStatus("rod_empty detected")
			Return True
		ElseIf $IS = False Then
			OCInventory(False)
			SetGUIStatus("rod_empty missing")
			Return False
		EndIf
	ElseIf $IS = False Then
		SetGUIStatus("Equipment missing.")
		OCInventory(False)
		Return False
	EndIf
EndFunc   ;==>InspectFishingrod

Func SwapFishingrod($discard = False)
	Local $Fishingrods[5] = ["res/fishing/rod_default.png", "res/fishing/rod_balenos.png", "res/fishing/rod_calpheon.png", "res/fishing/rod_epheria.png", "res/fishing/rod_mediah.png"]

	SetGUIStatus("Trying to swap Fishingrod. Discard = " & $discard)

	Local $C = SearchInventory($Fishingrods, 20)
	If IsArray($C) Then
		SetGUIStatus("Equipping Fishingrod")
		MouseClick("right", $C[0], $C[1])
		If $discard = True Then DiscardEmptyRod()
		OCInventory(False)
		Return True
	Else
		SetGUIStatus("No usable Fishingrod found")
		If $discard = True Then DiscardEmptyRod()
		OCInventory(False)
		Return False
	EndIf
EndFunc   ;==>SwapFishingrod

Func DiscardEmptyRod()
	Local Const $TrashCanOffset[2] = [360, 436] ; X,Y
	Local $EmptyRod[1] = ["res/fishing/rod_default_discard.png"]

	SetGUIStatus("Searching for unrepairable Fishingrod")
	Local $C = SearchInventory($EmptyRod, 20)
	If IsArray($C) Then
		Local $InvA = OCInventory(True)
		If IsArray($InvA) Then
			SetGUIStatus("Discarding Fishingrod.")
			MouseMove($C[0], $C[1])
			MouseClickDrag("left", $C[0], $C[1], $C[0] + 100, $C[1], 500)
			MouseClick("left", $InvA[0] + $TrashCanOffset[0], $InvA[1] + $TrashCanOffset[1])
		EndIf
		Sleep(400)
		CoSe("{SPACE}")
		Sleep(250)
		OCInventory(False)
		Return True
	Else
		SetGUIStatus("No empty Fishingrod detected.")
		OCInventory(False)
		Return False
	EndIf
EndFunc   ;==>DiscardEmptyRod

Func TurnAround()
	If VisibleCursor() = True Then CoSe("{LCTRL}")
	MouseMove(MouseGetPos(0) + 500, MouseGetPos(1))
	CoSe("ad")
EndFunc   ;==>TurnAround

; # Fishing Assist
Func FishingAssist()
	$Fish = True
	SetGUIStatus("FishingAssist launched")
	If ReelIn() = True Then Riddler()

EndFunc   ;==>FishingAssist


; # Loot
Func DetectLoot(ByRef $LWref) ; Identifies Rarity by bordercolor and Empty, Trash, Special, Event, Ignore images.
	Local Const $Rarity[4] = ["", 0x447726, 0x3C85AB, 0xA28748] ; Green, Blue, Gold
	Local Const $SpecialLootIdentifier[4] = ["res/fishing/loot_quantity.png", "res/fishing/loot_silverkey.png", "res/fishing/loot_ancientrelic.png", "res/fishing/loot_coelacanth.png"]
	Local Const $lootbag = "res/fishing/lootbag_" & $LNG & ".png"
	Local Static $EventIdentifier = _FileListToArray("res/fishing/event/", "*", 0)
	Local Static $IgnoreIdentifier = _FileListToArray("res/fishing/ignore/", "*", 0)
	Local $Loot[4][3] = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
	Local $FF, $x, $y, $SSN = 1
	Local $x, $y, $IS = False

	SetGUIStatus("DetectLoot Waiting for Item List")
	Local $timer = TimerInit()
	While $IS = False And $Fish
		$IS = _ImageSearchArea($lootbag, 1, ($Res[0] + $Res[2]) / 2, $Res[1], $Res[2], $Res[3], $x, $y, 20, "White") ; Search on the right half of the window
		If $IS = True Then
			Local $LWOffset[2] = [-94, 50]
			Local $LW[5] = [$x + $LWOffset[0], $y + $LWOffset[1] - 24, $x + $LWOffset[0] + 2, $y + $LWOffset[1] + 24, 47]
			$LWref = $LW
			ExitLoop
		Else
			If TimerDiff($timer) > 3000 Then Return False
		EndIf
	WEnd

	SetGUIStatus("DetectLoot Identifying Loot")
	For $j = 0 To 3 Step 1 ; Top left slot to top right slot
		For $i = 1 To UBound($Rarity) - 1 Step 1 ;Check for Green, Blue, Gold border
			$FF = FFColorCount($Rarity[$i], 10, True, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + $LW[4] * $j, $LW[3], $SSN)
			If $FF > 10 Then
				$Loot[$j][0] = $i
			EndIf
		Next
		If $Loot[$j][0] = 0 Then ; If Rarity = 0 then check if slot is empty or has "1" as quantity indicator (trash)
			$IS = _ImageSearchArea("res/fishing/loot_empty.png", 0, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + 44 + $LW[4] * $j, $LW[3], $x, $y, 50, 0)
			If $IS = True Then
				$Loot[$j][0] = -2
			Else ; check for quanity
				$IS = _ImageSearchArea($SpecialLootIdentifier[0], 0, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + 44 + $LW[4] * $j, $LW[3], $x, $y, 40, 0)
				If $IS = True Then $Loot[$j][0] = -1
			EndIf
		EndIf
		For $i = 1 To UBound($SpecialLootIdentifier) - 1 Step 1 ; Check for Specials: Silverkey, AncientRelic, Coelacanth
			If _ImageSearchArea($SpecialLootIdentifier[$i], 0, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + 44 + $LW[4] * $j, $LW[3], $x, $y, 20, 0) = 1 Then
				$Loot[$j][1] = $i
			EndIf
		Next
		For $i = 1 To UBound($EventIdentifier) - 1 Step 1 ; Check for Event items (includes all images in res/fishing/event/ folder)
			If _ImageSearchArea("res/fishing/event/" & $EventIdentifier[$i], 0, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + 44 + $LW[4] * $j, $LW[3], $x, $y, 25, 0) = 1 Then
				$Loot[$j][2] = $i
			EndIf
		Next
		For $i = 1 To UBound($IgnoreIdentifier) - 1 Step 1 ; Check for Ignored Items (includes all images in res/fishing/ignore/ folder)
			If _ImageSearchArea("res/fishing/ignore/" & $IgnoreIdentifier[$i], 0, $LW[0] + $LW[4] * $j, $LW[1], $LW[2] + 44 + $LW[4] * $j, $LW[3], $x, $y, 25, 0) = 1 Then
				$Loot[$j][2] = -$i
			EndIf
		Next
	Next

	; ScreenCapping the first 4 Inventory slots
	Dim $ScreenCapLoot
	If $ScreenCapLoot = True Then
		SetGUIStatus("Saving Loot Screenshot")
		FFSaveBMP("logs/Loot", True, $LW[0], $LW[1], $LW[2] + $LW[4] * 4, $LW[3])
	EndIf

	; Creating readable string for status
	Local $CWLoot = "Loot:"
	For $j = 0 To UBound($Loot, 1) - 1 Step 1
		$CWLoot &= "["
		For $i = 0 To UBound($Loot, 2) - 1 Step 1
			$CWLoot &= $Loot[$j][$i]
		Next
		$CWLoot &= "]"
	Next
	SetGUIStatus($CWLoot)

	Return $Loot
EndFunc   ;==>DetectLoot

Func ResetSession()
	Local $SessionStats = IniReadSection("logs/stats.ini", "SessionStats")
	For $i = 1 To UBound($SessionStats) - 1 Step 1
		$SessionStats[$i][1] = 0
	Next
	IniWriteSection("logs/stats.ini", "SessionStats", $SessionStats)
	InitGUI()
EndFunc   ;==>ResetSession

Func DocLoot(ByRef $Loot)

	Local $TotalStats = IniReadSection("logs/stats.ini", "TotalStats")
	Local $SessionStats = IniReadSection("logs/stats.ini", "SessionStats")

	For $i = 0 To UBound($Loot) - 1 Step 1
		Switch $Loot[$i][0]
			Case -1 ; Trash
				$TotalStats[9][1] += 1
				$SessionStats[9][1] += 1
			Case 0 ; White
				$TotalStats[1][1] += 1
				$SessionStats[1][1] += 1
			Case 1 ; Green
				$TotalStats[2][1] += 1
				$SessionStats[2][1] += 1
			Case 2 ; Blue
				$TotalStats[3][1] += 1
				$SessionStats[3][1] += 1
			Case 3 ; Gold
				$TotalStats[4][1] += 1
				$SessionStats[4][1] += 1
		EndSwitch

		Switch $Loot[$i][1]
			Case 1 ; Silverkey
				$TotalStats[5][1] += 1
				$SessionStats[5][1] += 1
			Case 2 ; AncientRelic
				$TotalStats[6][1] += 1
				$SessionStats[6][1] += 1
			Case 3 ; Coelacanth
				$TotalStats[7][1] += 1
				$SessionStats[7][1] += 1
		EndSwitch

		If $Loot[$i][2] > 0 Then ; Event items
			$TotalStats[8][1] += 1
			$SessionStats[8][1] += 1
		EndIf
	Next


	For $i = 1 To 9
		GUICtrlSetData($aListView1[$i], $SessionStats[$i][0] & "|" & $SessionStats[$i][1] & "|" & $TotalStats[$i][1], "")
	Next

	IniWriteSection("logs/stats.ini", "TotalStats", $TotalStats)
	IniWriteSection("logs/stats.ini", "SessionStats", $SessionStats)
EndFunc   ;==>DocLoot

Func DetectEnterQuantity($Left, $Top)
	Local Const $Quantity = "res/fishing/enteramount.png"
	Local $x, $y, $IS
	Sleep(250)
	$IS = _ImageSearchArea($Quantity, 0, $Left, $Top, $Res[2], $Res[3], $x, $y, 25, "White")
	If $IS = True Then Return True
	Return False
EndFunc   ;==>DetectEnterQuantity

Func HandleLoot(ByRef $LS, $Reserve = 0)
	Local $LW[5]
	Local $Loot = DetectLoot($LW)
	If Not IsArray($Loot) Then Return False
	DocLoot($Loot)

	Local $Pick[4] = [0, 0, 0, 0]
	Local $PickedLoot = 0
	Local $Threshold = 0
	If $Reserve = 1 Then $Threshold = 41

	; Make the loot settings understandable and prevent type confusion
	Local $LS_Rarity = Int($LS[1][1])
	Local $LS_Silverkey = Int($LS[2][1])
	Local $LS_AncientRelic = Int($LS[3][1])
	Local $LS_Coelacanth = Int($LS[4][1])
	Local $LS_EventItems = Int($LS[5][1])
	Local $LS_TrashItems = Int($LS[6][1])


	For $j = 0 To 3 Step 1
		If $Loot[$j][0] >= $LS_Rarity Then ; If loot-rarity >= set rarity
			$Pick[$j] += 10 ; Rarity
		Else
			If $Loot[$j][0] = -1 And $LS_TrashItems = 1 Then $Pick[$j] += 1 ; Trash (stackable; don't count towards picked loot)
		EndIf
		Switch $Loot[$j][1]
			Case 1 ; Silverkey
				If $LS_Silverkey Then $Pick[$j] += 1 ; (stackable; don't count towards picked loot)
			Case 2 ; Ancient Relic
				If $LS_AncientRelic Then $Pick[$j] += 30
			Case 3 ; Coelacanth
				If $LS_Coelacanth Then $Pick[$j] += 20
		EndSwitch
		If $Loot[$j][2] > 0 And $LS_EventItems Then $Pick[$j] += 21 ; Event items (stackable; don't count towards picked loot)
		If $Loot[$j][2] < 0 Then $Pick[$j] = 0 ; ignore items
	Next

	Sleep(1000)
	SetGUIStatus(StringFormat("Filter: R%s S%s A%s C%s E%s T%s", $LS_Rarity, $LS_Silverkey, $LS_AncientRelic, $LS_Coelacanth, $LS_EventItems, $LS_TrashItems))
	SetGUIStatus("Pick:[" & $Pick[0] & "][" & $Pick[1] & "][" & $Pick[2] & "][" & $Pick[3] & "]")
	If $Reserve = 1 Then SetGUIStatus("Relic Reserve reached. Unstackable Picks below " & $Threshold & " will be ignored.")

	For $j = 3 To 0 Step -1
		If $Pick[$j] > $Threshold Or (Mod($Pick[$j], 2) = 1 And $Pick[$j] > 0) Then

			If Mod($Pick[$j], 2) = 0 Then $PickedLoot += 1 ; Increase Picked loot if item is not stackable

			If Not VisibleCursor() Then CoSe("{LCTRL}")
			Sleep(250)

			VMouse($LW[0] + 20 + $LW[4] * $j, $LW[1] + 20, 1, "Right")
			Sleep(50)
			If $Pick[$j] = 21 Or $Pick[$j] = 31 Then ; If it's an event item check for quantity.
				SetGUIStatus("Trying to pick Event Item. Checking Quantity.")
				If DetectEnterQuantity($LW[0], $LW[1]) = True Then
					SetGUIStatus("Quantity detected. Collecting all.")
					CoSe("f")
					Sleep(50)
					CoSe("r")
					Sleep(50)
				EndIf
			EndIf
		EndIf
	Next
	If VisibleCursor() Then CoSe("{LCTRL}")
	Return $PickedLoot
EndFunc   ;==>HandleLoot


; # Drying
Func CheckWeather()
	Local Const $WeatherSunny = "res/fishing/drying_sunny.png"
	Local Const $WeatherRain = "res/fishing/drying_rain.png"
	Local $x, $y, $IS
	$IS = _ImageSearchArea($WeatherSunny, 1, $Res[2] - 350, $Res[1], $Res[2], $Res[1] + 100, $x, $y, 50, "White")
	If $IS = True Then
		SetGUIStatus("Weather: Sunny")
		Return True
	Else
		$IS = _ImageSearchArea($WeatherRain, 1, $Res[2] - 350, $Res[1], $Res[2], $Res[1] + 100, $x, $y, 50, "White")
		If $IS = True Then
			SetGUIStatus("Weather: Rain")
			Return False
		Else
			SetGUIStatus("Weather: None found")
			Return False
		EndIf
	EndIf
EndFunc   ;==>CheckWeather

Func SelectProductionMethod($Method) ; 0=Shaking, 1=Grinding, 2=Chopping, 3=Drying, 4=Filtering, 5=Heating
	Local $x, $y, $IS
	Local $ProductionHammer = "res/processing_hammer.png"
	Local $ProcessingMethodOffset[2] = [62, -62]

	; If $Method is a string translate it to int
	If IsNumber($Method) = False Then
		Switch $Method
			Case "Shaking"
				$Method = 0
			Case "Grinding"
				$Method = 1
			Case "Chopping"
				$Method = 2
			Case "Drying"
				$Method = 3
			Case "Filtering"
				$Method = 4
			Case "Heating"
				$Method = 5
		EndSwitch
	EndIf

	; Check for Production window
	; If closed then open it by pressing "l"
	; If open then close it and reopen it by pressing "l"
	$IS = _ImageSearchArea($ProductionHammer, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 50, 0)
	SetGUIStatus("Processing open: " & $IS)
	If Not $IS Then
		CoSe("l")
		Sleep(500)
	Else
		CoSe("l")
		CoSe("l")
		Sleep(500)
	EndIf
	; Check again for Production window and use $x, $y as Anchorpoint
	$IS = _ImageSearchArea($ProductionHammer, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 50, 0)
	If $IS = True Then
		SetGUIStatus("Processing open: " & $IS)
		Local $ProductionAnchor[2] = [$x, $y]
		VMouse($ProductionAnchor[0] + $ProcessingMethodOffset[0] * $Method, $ProductionAnchor[1] + $ProcessingMethodOffset[1], 1, "left") ; Selecting the Processing Method
		Return $ProductionAnchor
	Else
		SetGUIStatus("Processing open: " & $IS)
		Return False
	EndIf
EndFunc   ;==>SelectProductionMethod

Func StartProduction(ByRef $ProductionAnchor, ByRef $DryableFishC)
	Local Const $processall = "res/processing_check.png"
	Local $ProcessingStartOffset[2] = [256, -294]
	Local $ProcessingAllIdenticalOffset[2] = [256, -326]
	Local $x, $y, $IS

	VMouse($DryableFishC[0], $DryableFishC[1], 1, "Right")
	VMouse($ProductionAnchor[0] + $ProcessingAllIdenticalOffset[0], $ProductionAnchor[1] + $ProcessingAllIdenticalOffset[1], 1) ; Process all identical
	Sleep(250)

	$Left = $ProductionAnchor[0]
	$Top = $ProductionAnchor[1] + $ProcessingAllIdenticalOffset[1] - 10
	$Right = $ProductionAnchor[0] + $ProcessingAllIdenticalOffset[0]
	$Bottom = $ProductionAnchor[1] + $ProcessingAllIdenticalOffset[1] + 10
	$IS = _ImageSearchArea($processall, 0, $Left, $Top, $Right, $Bottom, $x, $y, 50, 0) ; Process all identical items?
	If $IS = True Then
		VMouse($ProductionAnchor[0] + $ProcessingStartOffset[0], $ProductionAnchor[1] + $ProcessingStartOffset[1], 1) ; Start processing
		Sleep(250)
		CoSe("{SPACE}")
	Else
		VMouse($ProductionAnchor[0] + $ProcessingStartOffset[0], $ProductionAnchor[1] + $ProcessingStartOffset[1], 1) ; Start processing
	EndIf
	If ProductionActivityCheckLoop() = True Then Return True
	Return False
EndFunc   ;==>StartProduction

Func CheckInventoryForFishBySlot($MaxRarity = 3)
	Local $Clock = "res/fishing/drying_clock.png"
	Local $ClockRed = "res/fishing/drying_clock_red.png"
	Local Const $Rarity[4] = [0xA49A72, 7184194, 6596799, 13742692] ; Green, Blue, Gold
	Local Const $Slot[2] = [48, 47] ; Width, Height and also offset
	Local $C[2], $IS, $Left, $Top, $Right, $Bottom

	Local $InvA = OCInventory(True)
	If Not IsArray($InvA) Then Return False
	VMouse($InvA[0] + 48 * 8, $InvA[1], 1, "left") ; Click on Inventory to get focus

	Local $IW[4] = [$InvA[0], $InvA[1], $InvA[0] + 48 * 8, $InvA[1] + 47 * 8]
	For $k = 0 To 2 Step 1
		MouseFreeZone($IW[0], $IW[1], $IW[2], $IW[3], $IW[0] - 50, $IW[1])
		For $j = 0 To 7 Step 1
			For $i = 0 To 7 Step 1
				; Region of the current inventory slot
				$Left = $InvA[0] + $Slot[0] * $i
				$Top = $InvA[1] + $Slot[1] * $j
				$Right = $InvA[0] + $Slot[0] * $i + $Slot[0]
				$Bottom = $InvA[1] + $Slot[1] * $j + $Slot[1]

				$IS = _ImageSearchArea($Clock, 1, $Left, $Top, $Right, $Bottom, $C[0], $C[1], 13, "0x00ff00") ; Check for the white clock
				If $IS = False Then $IS = _ImageSearchArea($ClockRed, 1, $Left, $Top, $Right, $Bottom, $C[0], $C[1], 15, "0x00ff00") ; If no white clock present scan for the red clock
				If $IS = True Then
					For $r = 1 To UBound($Rarity) - 1 Step 1
						$FF = FFColorCount($Rarity[$r], 18, True, $Left, $Top, $Left + 1, $Bottom, 1)
						If $FF > 10 Then

							If $r <= $MaxRarity Then
								SetGUIStatus(StringFormat("Dryable fish detected: %s%s%s, rarity: %s", $k, $j, $i, $r))
								Return $C
							Else
								SetGUIStatus(StringFormat("Dryable fish detected: %s%s%s, rarity: %s MaxRarity exceeded!", $k, $j, $i, $r))
								ExitLoop (2)
							EndIf
						EndIf
					Next
					SetGUIStatus(StringFormat("Dryable fish detected: %s%s%s, rarity: 0", $k, $j, $i))
					Return $C
				EndIf
			Next
		Next
		If $k < 2 Then ; Scrolling down inventory
			MouseMove($IW[0], $IW[1])
			Sleep(50)
			For $mw = 0 To 7
				MouseWheel("down")
				Sleep(50)
			Next
		EndIf
		Sleep(150)
	Next
	Return False
EndFunc   ;==>CheckInventoryForFishBySlot

Func ProductionActivityCheckLoop() ; Adpated
	Local Const $Processing_Hammer = "res/processing_hammer.png"
	Local $IS, $x, $y

	SetGUIStatus("Drying started. Waiting for Production end.")
	Sleep(1000)
	$IS = _ImageSearchArea($Processing_Hammer, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 50, 0)
	If $IS = True Then Return False
	Local $counter = 0
	While $Fish
		$IS = _ImageSearchArea($Processing_Hammer, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 50, 0)
		If $IS = True Then Return True
		Sleep(1000)
		$counter += 1
		If $counter = 20 Then
			CoSe("l") ; reopen in case of interupt
		ElseIf $counter >= 22 Then
			CoSe("l") ; reopen in case of interupt
			$counter = 0
		EndIf
		AntiScreenSaverMouseWiggle(2)
	WEnd
	Return False
EndFunc   ;==>ProductionActivityCheckLoop

Func UnequipWeaponSlot()
	Local $equip = "res/fishing/equip_" & $LNG & ".png"
	Local $WeaponOffSet[2] = [-63, 329]
	Local $x, $y, $IS = False

	Local $InvA = OCInventory(True)
	If IsArray($InvA) = False Then Return False

	$IS = _ImageSearchArea($equip, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 20, "White")
	If $IS = True Then
		SetGUIStatus("Equipment found")
		VMouse($x + $WeaponOffSet[0], $y + $WeaponOffSet[1], 2, "Right")
		Return True
	ElseIf $IS = False Then
		SetGUIStatus("Equipment missing.")
		OCInventory(False)
		Return False
	EndIf
EndFunc   ;==>UnequipWeaponSlot

Func DryFish($DryFishEnable, $DryFishMaxRarity = 3, $DryFishCD = 5)
	If $DryFishEnable = False Then Return False
	Local Static $DryingCooldownTimer = TimerInit()

	If $DryFishCD = 0 Then $DryingCooldownTimer = 0
	$Fish = True

	If TimerDiff($DryingCooldownTimer) / 1000 / 60 < $DryFishCD Then
		SetGUIStatus("Drying Cooldown (" & $DryFishCD & "m): " & Round($DryFishCD - TimerDiff($DryingCooldownTimer) / 1000 / 60, 1) & "m left.")
		Return False
	Else
		SetGUIStatus(StringFormat("Dry Fish initiated [%.1fm CD]", $DryFishCD))
	EndIf
	If CheckWeather() = False Then
		SetGUIStatus("Unsuitable weather for drying.")
		Return False
	EndIf
	If UnequipWeaponSlot() = False Then
		SetGUIStatus("Unable to unequip weapon.")
		Return False
	EndIf
	$DryingCooldownTimer = TimerInit()
	SetGUIStatus("Drying requirements met. Starting proces.")
	While $Fish
		If CheckWeather() = False Then
			SetGUIStatus("Unsuitable weather for drying.")
			Return True
		EndIf
		Local $ProductionAnchor = SelectProductionMethod("Drying")
		If Not IsArray($ProductionAnchor) Then
			SetGUIStatus("Could not open Production window.")
			Return True
		EndIf
		Local $DryableFishC = CheckInventoryForFishBySlot($DryFishMaxRarity)
		If Not IsArray($DryableFishC) Then
			SetGUIStatus("No dryable fish found.")
			$DryingCooldownTimer = TimerInit()
			Return True
		EndIf
		If StartProduction($ProductionAnchor, $DryableFishC) = True Then
			SetGUIStatus("Drying successful.")
			ContinueLoop
		Else
			SetGUIStatus("Drying failed.")
			$DryingCooldownTimer = TimerInit()
			Return True
		EndIf
	WEnd
EndFunc   ;==>DryFish


; # Side
Func WorkerFeed($WorkerEnable, $WorkerCD)
	If $WorkerEnable = False Then Return False

	Local Static $WorkerFeedTimer = TimerInit()
	If $WorkerCD = 0 Then $WorkerFeedTimer = 0

	Local $TimerDiff = TimerDiff($WorkerFeedTimer)
	$WorkerCD *= 60000

	If $TimerDiff > $WorkerCD Then
		Local Const $WorkerIcon = "res/esc_worker.png"
		Local Const $WorkerStamina = "res/worker_staminabar.png"
		Local Const $WorkerOffsets[4][2] = [ _
				[-33, 464], _ ; Recover All
				[-302, 9], _ ; Select food
				[-249, 145], _ ; Confirm
				[48, 463]] ; Repeat All
		Local $x, $y, $IS
		SetGUIStatus(StringFormat("Feeding Worker [%.1fm CD]", $WorkerCD / 60000))
		WaitForMenu(True)
		$IS = _ImageSearchArea($WorkerIcon, 1, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 10, 0)
		If $IS = True Then
			VMouse($x, $y, 1, "left")
			Sleep(1500)
			$IS = _ImageSearchArea($WorkerStamina, 0, $Res[0], $Res[1], $Res[2], $Res[3], $x, $y, 10, 0)
			If $IS = True Then
				VMouse($x + $WorkerOffsets[0][0], $y + $WorkerOffsets[0][1], 1, "left") ; Recover All
				VMouse($x + $WorkerOffsets[0][0], $y + $WorkerOffsets[0][1] + 10, 1, "left") ; Recover All DIFFERENT LANGUAGES FIX
				VMouse($x + $WorkerOffsets[1][0], $y + $WorkerOffsets[1][1], 1, "left") ; Select food
				Sleep(100)
				VMouse($x + $WorkerOffsets[2][0], $y + $WorkerOffsets[2][1], 1, "left") ; Confirm
				Sleep(1000)
				VMouse($x + $WorkerOffsets[3][0], $y + $WorkerOffsets[3][1], 1, "left") ; Repeat All
				VMouse($x + $WorkerOffsets[3][0], $y + $WorkerOffsets[3][1] + 10, 1, "left") ; Repeat All DIFFERENT LANGUAGES FIX
				CoSe("{ESC}") ; Close Worker List
				$WorkerFeedTimer = TimerInit()
				Return True
			Else
				SetGUIStatus("WorkerStamina missing")
				Return False
			EndIf
		Else
			SetGUIStatus("WorkerIcon missing")
		EndIf

	Else
		SetGUIStatus("WorkerFeed Cooldown(" & $WorkerCD / 60000 & "m): " & Round(($WorkerCD - $TimerDiff) / 60000, 1) & "m left.")
		Return False
	EndIf
EndFunc   ;==>WorkerFeed

Func Buff($BuffEnable, $BuffCD, ByRef $Keybinds)
	If $BuffEnable = False Then Return False

	Local Static $BuffTimer = TimerInit()
	If $BuffCD = 0 Then $BuffTimer = 0
	$BuffCD *= 60000
	Local $TimerDiff = TimerDiff($BuffTimer)

	Local $sKeys = ""
	For $vElement In $Keybinds
		$sKeys &= "[" & $vElement & "]"
	Next

	If $TimerDiff > $BuffCD Then
		SetGUIStatus(StringFormat("Using Buff Keybinds [%.1fm CD] Keys:%s", $BuffCD / 60000, $sKeys))

		For $vElement In $Keybinds
			CoSe($vElement)
			Sleep(100)
		Next
		$BuffTimer = TimerInit()
		Return True
	Else
		SetGUIStatus("Buff Cooldown(" & $BuffCD / 60000 & "m): " & Round(($BuffCD - $TimerDiff) / 60000, 1) & "m left. Keys:" & $sKeys)
		Return False
	EndIf
EndFunc   ;==>Buff

Func LoopSideFunctions()
	; TODO Load Settings
	$Fish = True
	While $Fish
		Sleep(10000)
		Buff($BuffEnable, $BuffCD, $BuffKeybinds)
		WorkerFeed($WorkerEnable, $WorkerCD)
		AntiScreenSaverMouseWiggle()
	WEnd
EndFunc



; # Main
Func Main_Fishing()
	$Fish = Not $Fish
	If $Fish = False Then
		SetGUIStatus("Stopping Main_Fishing")
		Return False
	EndIf

	; InventorySettings
	$Enable_DiscardRods = IniReadKey("Enable_DiscardRods", $InventorySettings)
	$BufferSize = IniReadKey("BufferSize", $InventorySettings)

	; WorkerSettings
	Local $WorkerEnable = IniReadKey("Enable_FeedWorker", $WorkerSettings)
	Local $WorkerCD = IniReadKey("FeedWorkerInterval", $WorkerSettings)

	; BuffSettings
	Local $BuffEnable = IniReadKey("Enable_Buff", $BuffSettings)
	Local $BuffCD = IniReadKey("BuffInterval", $BuffSettings)
	Local $BuffKeybinds = StringSplit(StringStripWS(IniReadKey("BuffKeys", $BuffSettings),8), ",", 2)

	; DryingSettings
	Local $DryFishEnable = IniReadKey("Enable_Drying", $DryingSettings)
	Local $DryFishMaxRarity = IniReadKey("MaxRarity", $DryingSettings)
	Local $DryFishCD = IniReadKey("DryingInterval", $DryingSettings)

	$Res = DetectFullscreenToWindowedOffset($hTitle)

	Local $Breaktimer = 0
	Local $fishingtimer = 0, $fishingtime
	Local $failedcasts = 0
	Local $RelicReserve = 0 ; TODO implement or remove

	Local $avaibleslots = 16
	Local $freedetectedslots = "NotYetDetected"

	While $Fish
		GUILoopSwitch()
		Switch GetState()
			Case "FishingBite" ; You feel a bite. Press 'Space' bar to start.
				$Breaktimer = 0
				SetGUIStatus("FishingBite detected. Calling ReelIn.")
				If ReelIn() = True Then
					SetGUIStatus("ReelIn successful. Calling Riddler.")
					Riddler()
					SetGUIStatus("Evaluating loot.")

					$avaibleslots -= HandleLoot($LootSettings, $RelicReserve)

				Else
					SetGUIStatus("ReelIn failed. Trying to close obstruction.")
					WaitForMenu(False)
				EndIf

				; Inventory Managmenet
				SetGUIStatus(StringFormat("FreeDetectedSlots: %s, AvaibleSlots: %s", $freedetectedslots, $avaibleslots))
				If $avaibleslots <= 0 Then
					SetGUIStatus("Inventory full! Stopping!")
					$Fish = False
				EndIf

			Case "FishingCurrently" ; You are currently fishing. Please wait until you feel a bite.
				$Breaktimer = 0
				AntiScreenSaverMouseWiggle()
				If $fishingtimer <> 0 Then
					$fishingtime = Round(TimerDiff($fishingtimer) / 1000, 0)
					If Mod($fishingtime, 10) = 0 Then SetGUIStatus("Currently fishing. (" & $fishingtime & "s)")

				Else
					SetGUIStatus("Currently fishing.")
				EndIf

			Case "FishingStandby" ; Press 'Space' near a body of water to start fishing.
				$Breaktimer = 0
				SetGUIStatus("FishingStandby detected.")
				WorkerFeed($WorkerEnable, $WorkerCD)
				Buff($BuffEnable, $BuffCD, $BuffKeybinds)
				If DryFish($DryFishEnable, $DryFishMaxRarity, $DryFishCD) = True Then ; TODO DRY FISH SETTING
					$freedetectedslots = DetectFreeInventory()
					$avaibleslots = $freedetectedslots - $BufferSize
					SwapFishingrod($Enable_DiscardRods)
				EndIf

				If $freedetectedslots = "NotYetDetected" Then
					$freedetectedslots = DetectFreeInventory()
					$avaibleslots = $freedetectedslots - $BufferSize
				EndIf

				If Cast() = False Then
					$failedcasts += 1
					SetGUIStatus("Casting fishingrod failed.")

					If InspectFishingrod() = True Then
						SetGUIStatus("Broken Fishingrod in Weaponslot detected.")
						If SwapFishingrod($Enable_DiscardRods) = True Then
							SetGUIStatus("SwapFishingrod successful.")
						Else
							SetGUIStatus("SwapFishingrod failed. Stopping")
							$Fish = False
							ContinueLoop
						EndIf
					Else
						SetGUIStatus("No broken Fishingrod equipped. Maybe turn around?")
						TurnAround()
					EndIf

				Else
					$failedcasts = 0
					SetGUIStatus("Casting fishingrod successful.")
				EndIf

				$fishingtimer = TimerInit()
			Case Else ; If no state is detected
				If $Breaktimer = 0 Then
					$Breaktimer = TimerInit()
					SetGUIStatus("Unidentified state")
				ElseIf TimerDiff($Breaktimer) / 1000 > 10 Then
					SetGUIStatus("Trying to resolve unidentified state")
					If WaitForMenu(False) = True Then
						SetGUIStatus("Escape to Menu possible.")
					Else
						SetGUIStatus("Escape to Menu failed")
						; TODO
					EndIf

					If IsProcessConnected("BlackDesert64.exe") = 1 Then
						SetGUIStatus("BlackDesert64.exe is connected")
					Else
						SetGUIStatus("BlackDesert64.exe is DISCONNECTED")
						; TODO DC HANDLING
					EndIf

					If SwapFishingrod($Enable_DiscardRods) = True Then
						SetGUIStatus("SwapFishingrod successful.")
					Else
						SetGUIStatus("SwapFishingrod failed. Stopping")
						$Fish = False
					EndIf
					$Breaktimer = TimerInit()
				Else
					SetGUIStatus("Unidentified state (" & Round(TimerDiff($Breaktimer) / 1000, 0) & "s)")
				EndIf
		EndSwitch
		Sleep(100)
		If $Fish = False Then
			SetGUIStatus("Fishing stopped.")
			$fishingtimer = 0
		EndIf
	WEnd

EndFunc   ;==>Main_Fishing

Func Main()
	ObfuscateTitle($Form1_1)
	CreateConfig()
	ResetSession()
	InitGUI()
	While True
		GUILoopSwitch()
	WEnd
EndFunc   ;==>Main



Main()
