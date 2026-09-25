#NoEnv
#MaxHotkeysPerInterval 200
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; --- Global Variables ---
global MacroRunning := 0
global CurrentHotkey := "q"
global GuiMainDisabled := 0

; Target Executable
global TargetWin := "ahk_exe RobloxPlayerBeta.exe"

; Stored Initial Mouse Position (Preserved strictly in RAM, not written to INI)
global SavedMouseX := 0
global SavedMouseY := 0

; Fail Safe Inactivity Watchdog
global InactivityTimeoutSec := 10
global LastClickTick := 0

; Zone Coordinates
global B1_X1 := 0, global B1_Y1 := 0, global B1_X2 := 0, global B1_Y2 := 0
global B2_X1 := 0, global B2_Y1 := 0, global B2_X2 := 0, global B2_Y2 := 0
global B3_X1 := 0, global B3_Y1 := 0, global B3_X2 := 0, global B3_Y2 := 0
global OCR_X1 := 0, global OCR_Y1 := 0, global OCR_X2 := 0, global OCR_Y2 := 0
global ActiveBox := ""

global CyanColor := ""
global EnableExtraColor := 0
global BubbleTolerance := 15
global ClickColor := ""
global RestartColor := ""
global IniFile := A_ScriptDir . "\settings_v2.ini"
global FrameHwnd := 0

; Setup Overlay Coordinates
global CurX := 400, global CurY := 300, global CurW := 100, global CurH := 5

; 9 Extra Bubble Colors
global ExtraColors := ["", "", "", "", "", "", "", "", ""]

; --- AutoSell & Tesseract Variables ---
global EnableAutoSell := 0
global TesseractExePath := A_ScriptDir . "\Tesseract\tesseract.exe"
global AutoSellMode := "Full"
global TargetLeftNum := 0
global TargetRightNum := 0

; --- AutoSell Sequence Variables ---
global SellKeyChoice := "f"
global CustomSellKey := "e"
global Pos05_X := 0, global Pos05_Y := 0
global Pos1_X := 0, global Pos1_Y := 0
global Pos2_X := 0, global Pos2_Y := 0

; Position-Specific Glide and Hover Timers
global SelectedPosTiming := "Pos 0.5"
global Glide_Pos05 := 300, global Hover_Pos05 := 200
global Glide_Pos1  := 300, global Hover_Pos1  := 200
global Glide_Pos2  := 300, global Hover_Pos2  := 200

; --- GUI Setup ---
Gui, Main: New, +AlwaysOnTop
Gui, Add, Tab3, x5 y5 w280 h720 vMainTabs, Macro|AutoSell|Fail Safe

; ==================== TAB 1: MACRO ====================
Gui, Tab, Macro
Gui, Add, Text, x15 y35, 1. Setup Scan Zones:
Gui, Add, Button, x15 y55 w250 gSetZone1, 🎯 Zone 1: Bubble Box
Gui, Add, Button, x15 y85 w250 gSetZone2, 🎯 Zone 2: Scan Line
Gui, Add, Button, x15 y115 w250 gSetZone3, 🎯 Zone 3: Restart Box

Gui, Add, Text, x15 y150, 2. Target Colors:
Gui, Add, Button, x15 y170 w115 gPickCyanColor, 🧪 Cyan Bubble
Gui, Add, Progress, x+5 w130 h23 vCyanVisual -Smooth +Border cWhite BackgroundWhite, 100

Gui, Add, Button, x15 y200 w115 gPickClickColor, 🧪 Click Color
Gui, Add, Progress, x+5 w130 h23 vClickVisual -Smooth +Border cWhite BackgroundWhite, 100

Gui, Add, Button, x15 y230 w115 gPickRestartColor, 🧪 Restart Color
Gui, Add, Progress, x+5 w130 h23 vRestartVisual -Smooth +Border cWhite BackgroundWhite, 100

Gui, Add, Text, x15 y262, Optional Extra Colors (Up to 9):
Gui, Add, CheckBox, x15 y280 vEnableExtraColor gToggleExtraColor, Enable Extra Colors
Gui, Add, Text, x140 y281, Tol:
Gui, Add, Edit, x165 y278 w45 vBubbleToleranceInput gSaveAllSettings Number, 15

; 9 Extra Color Grid
yPos := 305
Loop, 9 {
    Gui, Add, Button, x15 y%yPos% w70 h22 gPickExtraColorSlot%A_Index%, + Color %A_Index%
    Gui, Add, Progress, x+5 w115 h22 vExtraVisual%A_Index% -Smooth +Border cWhite BackgroundWhite, 100
    Gui, Add, Button, x+5 w55 h22 gDeleteColorSlot%A_Index%, ❌ Del
    yPos += 24
}

Gui, Add, Text, x15 y530, Click Cooldown (ms):
Gui, Add, Edit, x15 y548 w250 vNeedleCooldownInput gSaveAllSettings, 150

Gui, Add, Text, x15 y575, Scan Speed / Rate (ms):
Gui, Add, Edit, x15 y593 w250 vScanRateInput gSaveAllSettings, 30

Gui, Add, Text, x15 y620, Restart Delay (ms):
Gui, Add, Edit, x15 y638 w250 vRestartDelayInput gSaveAllSettings, 1000

Gui, Add, Text, x15 y666, ⌨️ Toggle Key:
Gui, Add, Edit, x100 y663 w50 vHotkeyInput gUpdateHotkey Limit1, q
Gui, Add, Text, x15 y693 w130 vStatus, Status: Ready
Gui, Add, Button, x150 y688 w115 h25 vStartBtn gToggleMacro Default, ▶️ Start

; ==================== TAB 2: AUTOSELL ====================
Gui, Tab, AutoSell
Gui, Add, CheckBox, x15 y35 vEnableAutoSell gSaveAllSettings, Enable AutoSell OCR Check
Gui, Add, Button, x15 y60 w250 gSetZoneOCR, 🎯 Set Tesseract OCR Scan Box

Gui, Add, Text, x15 y95, Tesseract Executable Path:
Gui, Add, Edit, x15 y115 w250 vTesseractExePath gSaveAllSettings, %TesseractExePath%

Gui, Add, Text, x15 y145, Detection Mode:
Gui, Add, Radio, x15 y165 vModeFull gUpdateSellMode Checked, Specific Match (Left/Right)
Gui, Add, Radio, x15 y185 vModeAutoMax gUpdateSellMode, Auto-Max (Left == Right)

Gui, Add, Text, x15 y210, Specific Match Config:
Gui, Add, Text, x15 y230, Left:
Gui, Add, Edit, x50 y227 w50 vTargetLeftNum gSaveAllSettings Number, 50
Gui, Add, Text, x110 y230, /  Right:
Gui, Add, Edit, x165 y227 w50 vTargetRightNum gSaveAllSettings Number, 50

Gui, Add, Button, x15 y260 w205 h28 gTestOCRManual, 🔍 Test OCR Scan Now
Gui, Add, Progress, x+5 w40 h28 vOCRTestVisual -Smooth +Border cWhite BackgroundWhite, 100
Gui, Add, Text, x15 y295 w250 vOCRStatus, OCR Status: Idle

Gui, Add, Text, x15 y325, Key To Press (Step 1):
Gui, Add, Radio, x15 y345 vRadioKeyF gUpdateKeySelection Checked, F
Gui, Add, Radio, x65 y345 vRadioKeyE gUpdateKeySelection, E
Gui, Add, Radio, x115 y345 vRadioKeyCustom gUpdateKeySelection, Other:
Gui, Add, Edit, x175 y342 w50 vCustomSellKey gSaveAllSettings Limit1, e

Gui, Add, Button, x15 y375 w250 vBtnPos05 gPickPosition05, 📍 Position 0.5 [E Only]: (0, 0)
Gui, Add, Button, x15 y410 w250 vBtnPos1 gPickPosition1, 📍 Position 1: (0, 0)
Gui, Add, Button, x15 y445 w250 vBtnPos2 gPickPosition2, 📍 Position 2: (0, 0)

Gui, Add, Text, x15 y485, Select Position Timers:
Gui, Add, DropDownList, x15 y505 w250 vSelectedPosTiming gOnTimingTargetChange, Pos 0.5||Pos 1|Pos 2

Gui, Add, Text, x15 y540, Glide Time (ms):
Gui, Add, Edit, x15 y560 w250 vGlideTimeInput gSaveActiveTiming Number, 300

Gui, Add, Text, x15 y590, Hover Time (ms):
Gui, Add, Edit, x15 y610 w250 vHoverTimeInput gSaveActiveTiming Number, 200

; ==================== TAB 3: FAIL SAFE ====================
Gui, Tab, Fail Safe
Gui, Add, Text, x15 y35, Fail Safe Inactivity Watchdog:
Gui, Add, Text, x15 y60 w250, Configure how many seconds without a click before the macro executes an automated fail-safe click at the initial saved position.
Gui, Add, Text, x15 y110, Timeout Duration (Seconds):
Gui, Add, Edit, x15 y130 w250 vInactivityTimeoutSecInput gSaveAllSettings Number, 10
Gui, Add, Text, x15 y165 w250 cGray, Default is 10 seconds. Counter automatically resets on every single click made by the macro.

Gui, Show, w290, Fishing Macro V3

OnMessage(0x0201, "WM_LBUTTONDOWN")
LoadAllSettings()

Hotkey, %CurrentHotkey%, ToggleMacro, On UseErrorLevel
return

; --- Format & Swatch Helper ---
FormatHexColor(val) {
    if (val = "" || val = "ERROR")
        return ""
    clean := RegExReplace(val, "i)^(0x|#)")
    if (clean = "")
        return ""
    if (RegExMatch(clean, "^[0-9]+$") && StrLen(clean) > 6)
        clean := Format("{:X}", val)
    clean := SubStr("000000" . clean, -5)
    StringUpper, clean, clean
    return "0x" . clean
}

UpdateVisualSwatch(controlVar, colorHex) {
    clean := RegExReplace(colorHex, "i)^(0x|#)")
    if (StrLen(clean) = 6) {
        GuiControl, Main: +c%clean% +Background%clean%, %controlVar%
        GuiControl, Main:, %controlVar%, 100
    } else {
        GuiControl, Main: +cWhite +BackgroundWhite, %controlVar%
        GuiControl, Main:, %controlVar%, 100
    }
}

; --- Smooth Mouse Glide Movement ---
GlideMouseMove(targetX, targetY, durationMs) {
    CoordMode, Mouse, Screen
    MouseGetPos, startX, startY
    if (durationMs <= 0) {
        MouseMove, %targetX%, %targetY%, 0
        return
    }

    interval := 15
    steps := Max(1, Floor(durationMs / interval))
    loop, %steps% {
        progress := A_Index / steps
        curX := Round(startX + (targetX - startX) * progress)
        curY := Round(startY + (targetY - startY) * progress)
        MouseMove, %curX%, %curY%, 0
        DllCall("Sleep", "UInt", interval)
    }
    MouseMove, %targetX%, %targetY%, 0
}

; --- Click Execution ---
SendSavedClick() {
    global LastClickTick, SavedMouseX, SavedMouseY
    CoordMode, Mouse, Screen
    MouseGetPos, CurrentX, CurrentY
    Click, %SavedMouseX%, %SavedMouseY%
    MouseMove, %CurrentX%, %CurrentY%, 0
    LastClickTick := A_TickCount
}

; --- Fail Safe Inactivity Watchdog ---
BackgroundInactivityWatchdog:
    if (!MacroRunning || InactivityTimeoutSec <= 0)
        return

    timeoutMs := InactivityTimeoutSec * 1000
    if (A_TickCount - LastClickTick >= timeoutMs) {
        SendSavedClick()
    }
return

WM_LBUTTONDOWN() {
    if (A_Gui = "FrameBox") {
        PostMessage, 0xA1, 2,,, A
    }
}

SetZone1:
    ActiveBox := "B1"
    CurX := (B1_X2 > B1_X1 && B1_X1 > 0) ? B1_X1 : 400
    CurY := (B1_Y2 > B1_Y1 && B1_Y1 > 0) ? B1_Y1 : 300
    CurW := (B1_X2 > B1_X1 && B1_X1 > 0) ? (B1_X2 - B1_X1) : 100
    CurH := (B1_Y2 > B1_Y1 && B1_Y1 > 0) ? (B1_Y2 - B1_Y1) : 30
    ShowSetupBox("Zone 1 Setup (Bubble Box)", 1)
return

SetZone2:
    ActiveBox := "B2"
    CurX := (B2_X2 > B2_X1 && B2_X1 > 0) ? B2_X1 : 400
    CurY := (B2_Y2 > B2_Y1 && B2_Y1 > 0) ? B2_Y1 : 300
    CurW := (B2_X2 > B2_X1 && B2_X1 > 0) ? (B2_X2 - B2_X1) : 100
    CurH := (B2_Y2 > B2_Y1 && B2_Y1 > 0) ? (B2_Y2 - B2_Y1) : 5
    ShowSetupBox("Zone 2 Setup (Scan Line Position)", 0)
return

SetZone3:
    ActiveBox := "B3"
    CurX := (B3_X2 > B3_X1 && B3_X1 > 0) ? B3_X1 : 400
    CurY := (B3_Y2 > B3_Y1 && B3_Y1 > 0) ? B3_Y1 : 300
    CurW := (B3_X2 > B3_X1 && B3_X1 > 0) ? (B3_X2 - B3_X1) : 100
    CurH := (B3_Y2 > B3_Y1 && B3_Y1 > 0) ? (B3_Y2 - B3_Y1) : 30
    ShowSetupBox("Zone 3 Setup (Restart Box)", 1)
return

SetZoneOCR:
    ActiveBox := "OCR"
    CurX := (OCR_X2 > OCR_X1 && OCR_X1 > 0) ? OCR_X1 : 400
    CurY := (OCR_Y2 > OCR_Y1 && OCR_Y1 > 0) ? OCR_Y1 : 300
    CurW := (OCR_X2 > OCR_X1 && OCR_X1 > 0) ? (OCR_X2 - OCR_X1) : 120
    CurH := (OCR_Y2 > OCR_Y1 && OCR_Y1 > 0) ? (OCR_Y2 - OCR_Y1) : 40
    ShowSetupBox("Tesseract OCR Scan Zone Setup (Resizable Box)", 1)
return

ShowSetupBox(titleText, allowResize) {
    Gui, Main: +Disabled

    Gui, FrameBox: Destroy
    if (allowResize) {
        Gui, FrameBox: New, +Resize +AlwaysOnTop +ToolWindow +HwndFrameHwnd -Caption
    } else {
        Gui, FrameBox: New, +AlwaysOnTop +ToolWindow +HwndFrameHwnd -Caption
    }
    
    Gui, FrameBox: Color, Red
    Gui, FrameBox: Add, Text, x0 y0 w100p h100p BackgroundRed, 
    
    Gui, FrameBox: Show, x%CurX% y%CurY% w%CurW% h%CurH% NoActivate
    WinSet, Transparent, 220, ahk_id %FrameHwnd%
    
    ToolTip, % titleText . "`n- Arrow Keys: Nudge position`n- Drag: Move box`n- Press ENTER to save."
    
    Hotkey, Up, NudgeUp, On
    Hotkey, Down, NudgeDown, On
    Hotkey, Left, NudgeLeft, On
    Hotkey, Right, NudgeRight, On
    Hotkey, Enter, ConfirmBoxCoords, On
}

NudgeUp:
    CurY -= 1
    WinMove, ahk_id %FrameHwnd%,, %CurX%, %CurY%
return
NudgeDown:
    CurY += 1
    WinMove, ahk_id %FrameHwnd%,, %CurX%, %CurY%
return
NudgeLeft:
    CurX -= 1
    WinMove, ahk_id %FrameHwnd%,, %CurX%, %CurY%
return
NudgeRight:
    CurX += 1
    WinMove, ahk_id %FrameHwnd%,, %CurX%, %CurY%
return

ConfirmBoxCoords:
    Hotkey, Up, Off
    Hotkey, Down, Off
    Hotkey, Left, Off
    Hotkey, Right, Off
    Hotkey, Enter, Off
    ToolTip
    
    if (FrameHwnd) {
        WinGetPos, VX1, VY1, VW, VH, ahk_id %FrameHwnd%
        VX2 := VX1 + VW
        VY2 := VY1 + VH

        if (ActiveBox = "B1") {
            B1_X1 := VX1, B1_Y1 := VY1, B1_X2 := VX2, B1_Y2 := VY2
        } else if (ActiveBox = "B2") {
            B2_X1 := VX1, B2_Y1 := VY1, B2_X2 := VX2, B2_Y2 := VY2
        } else if (ActiveBox = "B3") {
            B3_X1 := VX1, B3_Y1 := VY1, B3_X2 := VX2, B3_Y2 := VY2
        } else if (ActiveBox = "OCR") {
            OCR_X1 := VX1, OCR_Y1 := VY1, OCR_X2 := VX2, OCR_Y2 := VY2
        }
    }
    
    Gui, FrameBox: Destroy
    Gui, Main: -Disabled
    Gui, Main: Show
    SaveAllSettings()
    GuiControl, Main:, Status, Status: %ActiveBox% Saved
return

; --- Click Position Pickers ---
PickPosition05:
    PickPositionCoord("05")
return

PickPosition1:
    PickPositionCoord("1")
return

PickPosition2:
    PickPositionCoord("2")
return

PickPositionCoord(posType) {
    global GuiMainDisabled, Pos05_X, Pos05_Y, Pos1_X, Pos1_Y, Pos2_X, Pos2_Y
    GuiMainDisabled := 1
    Gui, Main: +Disabled
    ToolTip, Click on the screen to set Position %posType%

    CoordMode, Mouse, Screen
    While (GuiMainDisabled) {
        MouseGetPos, curMX, curMY
        ToolTip, 📍 Click to Set Position %posType% (%curMX%`, %curMY%), % (curMX + 15), % (curMY + 15), 1
        if (GetKeyState("LButton", "P")) {
            if (posType = "05") {
                Pos05_X := curMX, Pos05_Y := curMY
                GuiControl, Main:, BtnPos05, 📍 Pos 0.5: (%Pos05_X%`, %Pos05_Y%)
            } else if (posType = "1") {
                Pos1_X := curMX, Pos1_Y := curMY
                GuiControl, Main:, BtnPos1, 📍 Pos 1: (%Pos1_X%`, %Pos1_Y%)
            } else if (posType = "2") {
                Pos2_X := curMX, Pos2_Y := curMY
                GuiControl, Main:, BtnPos2, 📍 Pos 2: (%Pos2_X%`, %Pos2_Y%)
            }
            KeyWait, LButton
            GuiMainDisabled := 0
            break
        }
        Sleep, 30
    }
    ToolTip, , , , 1
    SaveAllSettings()
    Gui, Main: -Disabled
    Gui, Main: Show
}

; --- Timing UI Management ---
OnTimingTargetChange:
    Gui, Main: Submit, NoHide
    if (SelectedPosTiming = "Pos 0.5") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos05%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos05%
    } else if (SelectedPosTiming = "Pos 1") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos1%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos1%
    } else if (SelectedPosTiming = "Pos 2") {
        GuiControl, Main:, GlideTimeInput, %Glide_Pos2%
        GuiControl, Main:, HoverTimeInput, %Hover_Pos2%
    }
return

SaveActiveTiming:
    Gui, Main: Submit, NoHide
    if (SelectedPosTiming = "Pos 0.5") {
        Glide_Pos05 := GlideTimeInput
        Hover_Pos05 := HoverTimeInput
    } else if (SelectedPosTiming = "Pos 1") {
        Glide_Pos1 := GlideTimeInput
        Hover_Pos1 := HoverTimeInput
    } else if (SelectedPosTiming = "Pos 2") {
        Glide_Pos2 := GlideTimeInput
        Hover_Pos2 := HoverTimeInput
    }
    SaveAllSettings()
return

; --- Color Pickers ---
PickCyanColor:
    SampleScreenColor("Cyan")
return

PickClickColor:
    SampleScreenColor("Click")
return

PickRestartColor:
    SampleScreenColor("Restart")
return

PickExtraColorSlot1:
    SampleScreenColor("Extra", 1)
return
PickExtraColorSlot2:
    SampleScreenColor("Extra", 2)
return
PickExtraColorSlot3:
    SampleScreenColor("Extra", 3)
return
PickExtraColorSlot4:
    SampleScreenColor("Extra", 4)
return
PickExtraColorSlot5:
    SampleScreenColor("Extra", 5)
return
PickExtraColorSlot6:
    SampleScreenColor("Extra", 6)
return
PickExtraColorSlot7:
    SampleScreenColor("Extra", 7)
return
PickExtraColorSlot8:
    SampleScreenColor("Extra", 8)
return
PickExtraColorSlot9:
    SampleScreenColor("Extra", 9)
return

DeleteColorSlot1:
    DeleteSpecificSlot(1)
return
DeleteColorSlot2:
    DeleteSpecificSlot(2)
return
DeleteColorSlot3:
    DeleteSpecificSlot(3)
return
DeleteColorSlot4:
    DeleteSpecificSlot(4)
return
DeleteColorSlot5:
    DeleteSpecificSlot(5)
return
DeleteColorSlot6:
    DeleteSpecificSlot(6)
return
DeleteColorSlot7:
    DeleteSpecificSlot(7)
return
DeleteColorSlot8:
    DeleteSpecificSlot(8)
return
DeleteColorSlot9:
    DeleteSpecificSlot(9)
return

DeleteSpecificSlot(slotNum) {
    global ExtraColors, IniFile
    ExtraColors[slotNum] := ""
    UpdateVisualSwatch("ExtraVisual" . slotNum, "")
    IniWrite, % "", %IniFile%, ExtraColors, Slot%slotNum%
}

SampleScreenColor(targetType, slotNum := 0) {
    global CyanColor, ClickColor, RestartColor, ExtraColors, IniFile
    
    Gui, Main: +Disabled
    ToolTip, Click anywhere on screen to pick color...
    
    While (!GetKeyState("LButton", "P")) {
        MouseGetPos, mX, mY
        ToolTip, █ Click to sample color, % (mX + 15), % (mY + 15), 1
        Sleep, 30
    }
    KeyWait, LButton
    
    CoordMode, Pixel, Screen
    MouseGetPos, cX, cY
    PixelGetColor, sampledRGB, %cX%, %cY%, RGB
    ToolTip, , , , 1
    
    formattedColor := FormatHexColor(sampledRGB)
    
    if (targetType = "Cyan") {
        CyanColor := formattedColor
        UpdateVisualSwatch("CyanVisual", CyanColor)
        IniWrite, %CyanColor%, %IniFile%, Settings, CyanColor
    } else if (targetType = "Click") {
        ClickColor := formattedColor
        UpdateVisualSwatch("ClickVisual", ClickColor)
        IniWrite, %ClickColor%, %IniFile%, Settings, ClickColor
    } else if (targetType = "Restart") {
        RestartColor := formattedColor
        UpdateVisualSwatch("RestartVisual", RestartColor)
        IniWrite, %RestartColor%, %IniFile%, Settings, RestartColor
    } else if (targetType = "Extra") {
        ExtraColors[slotNum] := formattedColor
        UpdateVisualSwatch("ExtraVisual" . slotNum, formattedColor)
        IniWrite, %formattedColor%, %IniFile%, ExtraColors, Slot%slotNum%
    }
    
    Gui, Main: -Disabled
    Gui, Main: Show
}

ToggleExtraColor:
    Gui, Main: Submit, NoHide
    SaveAllSettings()
return

UpdateSellMode:
    Gui, Main: Submit, NoHide
    if (ModeFull)
        AutoSellMode := "Full"
    else
        AutoSellMode := "AutoMax"
    SaveAllSettings()
return

UpdateKeySelection:
    Gui, Main: Submit, NoHide
    if (RadioKeyF)
        SellKeyChoice := "f"
    else if (RadioKeyE)
        SellKeyChoice := "e"
    else if (RadioKeyCustom)
        SellKeyChoice := "custom"
    SaveAllSettings()
return

; --- Settings Management ---
LoadAllSettings() {
    global
    IniRead, SavedNeedle, %IniFile%, Settings, NeedleCooldownInput, 150
    IniRead, SavedRate, %IniFile%, Settings, ScanRateInput, 30
    IniRead, SavedRestartDelay, %IniFile%, Settings, RestartDelayInput, 1000
    IniRead, SavedHotkey, %IniFile%, Settings, CurrentHotkey, q
    
    IniRead, rawCyan, %IniFile%, Settings, CyanColor, % ""
    IniRead, rawClick, %IniFile%, Settings, ClickColor, % ""
    IniRead, rawRestart, %IniFile%, Settings, RestartColor, % ""
    IniRead, EnableExtraColor, %IniFile%, Settings, EnableExtraColor, 0
    IniRead, BubbleTolerance, %IniFile%, Settings, BubbleTolerance, 15

    CyanColor := FormatHexColor(rawCyan)
    ClickColor := FormatHexColor(rawClick)
    RestartColor := FormatHexColor(rawRestart)

    Loop, 9 {
        slot := A_Index
        IniRead, rawSlotColor, %IniFile%, ExtraColors, Slot%slot%, % ""
        ExtraColors[slot] := FormatHexColor(rawSlotColor)
        UpdateVisualSwatch("ExtraVisual" . slot, ExtraColors[slot])
    }

    IniRead, EnableAutoSell, %IniFile%, AutoSell, EnableAutoSell, 0
    IniRead, TesseractExePath, %IniFile%, AutoSell, TesseractExePath, % A_ScriptDir . "\Tesseract\tesseract.exe"
    IniRead, AutoSellMode, %IniFile%, AutoSell, AutoSellMode, Full
    IniRead, TargetLeftNum, %IniFile%, AutoSell, TargetLeftNum, 50
    IniRead, TargetRightNum, %IniFile%, AutoSell, TargetRightNum, 50
    
    IniRead, SellKeyChoice, %IniFile%, AutoSellAction, SellKeyChoice, f
    IniRead, CustomSellKey, %IniFile%, AutoSellAction, CustomSellKey, e
    IniRead, Pos05_X, %IniFile%, AutoSellAction, Pos05_X, 0
    IniRead, Pos05_Y, %IniFile%, AutoSellAction, Pos05_Y, 0
    IniRead, Pos1_X, %IniFile%, AutoSellAction, Pos1_X, 0
    IniRead, Pos1_Y, %IniFile%, AutoSellAction, Pos1_Y, 0
    IniRead, Pos2_X, %IniFile%, AutoSellAction, Pos2_X, 0
    IniRead, Pos2_Y, %IniFile%, AutoSellAction, Pos2_Y, 0
    
    IniRead, Glide_Pos05, %IniFile%, AutoSellTimings, Glide_Pos05, 300
    IniRead, Hover_Pos05, %IniFile%, AutoSellTimings, Hover_Pos05, 200
    IniRead, Glide_Pos1,  %IniFile%, AutoSellTimings, Glide_Pos1,  300
    IniRead, Hover_Pos1,  %IniFile%, AutoSellTimings, Hover_Pos1,  200
    IniRead, Glide_Pos2,  %IniFile%, AutoSellTimings, Glide_Pos2,  300
    IniRead, Hover_Pos2,  %IniFile%, AutoSellTimings, Hover_Pos2,  200

    IniRead, InactivityTimeoutSec, %IniFile%, FailSafe, InactivityTimeoutSec, 10

    IniRead, B1_X1, %IniFile%, Zones, B1_X1, 0
    IniRead, B1_Y1, %IniFile%, Zones, B1_Y1, 0
    IniRead, B1_X2, %IniFile%, Zones, B1_X2, 0
    IniRead, B1_Y2, %IniFile%, Zones, B1_Y2, 0
    
    IniRead, B2_X1, %IniFile%, Zones, B2_X1, 0
    IniRead, B2_Y1, %IniFile%, Zones, B2_Y1, 0
    IniRead, B2_X2, %IniFile%, Zones, B2_X2, 0
    IniRead, B2_Y2, %IniFile%, Zones, B2_Y2

    IniRead, B3_X1, %IniFile%, Zones, B3_X1, 0
    IniRead, B3_Y1, %IniFile%, Zones, B3_Y1, 0
    IniRead, B3_X2, %IniFile%, Zones, B3_X2, 0
    IniRead, B3_Y2, %IniFile%, Zones, B3_Y2

    IniRead, OCR_X1, %IniFile%, Zones, OCR_X1, 0
    IniRead, OCR_Y1, %IniFile%, Zones, OCR_Y1, 0
    IniRead, OCR_X2, %IniFile%, Zones, OCR_X2, 0
    IniRead, OCR_Y2, %IniFile%, Zones, OCR_Y2

    CurrentHotkey := SavedHotkey
    GuiControl, Main:, HotkeyInput, %CurrentHotkey%
    GuiControl, Main:, EnableExtraColor, %EnableExtraColor%
    GuiControl, Main:, BubbleToleranceInput, %BubbleTolerance%
    GuiControl, Main:, NeedleCooldownInput, %SavedNeedle%
    GuiControl, Main:, ScanRateInput, %SavedRate%
    GuiControl, Main:, RestartDelayInput, %SavedRestartDelay%

    GuiControl, Main:, EnableAutoSell, %EnableAutoSell%
    GuiControl, Main:, TesseractExePath, %TesseractExePath%
    GuiControl, Main:, TargetLeftNum, %TargetLeftNum%
    GuiControl, Main:, TargetRightNum, %TargetRightNum%

    GuiControl, Main:, CustomSellKey, %CustomSellKey%
    GuiControl, Main:, InactivityTimeoutSecInput, %InactivityTimeoutSec%

    GuiControl, Main:, GlideTimeInput, %Glide_Pos05%
    GuiControl, Main:, HoverTimeInput, %Hover_Pos05%

    if (Pos05_X > 0 && Pos05_Y > 0)
        GuiControl, Main:, BtnPos05, 📍 Pos 0.5: (%Pos05_X%`, %Pos05_Y%)
    if (Pos1_X > 0 && Pos1_Y > 0)
        GuiControl, Main:, BtnPos1, 📍 Pos 1: (%Pos1_X%`, %Pos1_Y%)
    if (Pos2_X > 0 && Pos2_Y > 0)
        GuiControl, Main:, BtnPos2, 📍 Pos 2: (%Pos2_X%`, %Pos2_Y%)

    if (SellKeyChoice = "e") {
        GuiControl, Main:, RadioKeyE, 1
        GuiControl, Main:, RadioKeyF, 0
        GuiControl, Main:, RadioKeyCustom, 0
    } else if (SellKeyChoice = "custom") {
        GuiControl, Main:, RadioKeyCustom, 1
        GuiControl, Main:, RadioKeyF, 0
        GuiControl, Main:, RadioKeyE, 0
    } else {
        GuiControl, Main:, RadioKeyF, 1
        GuiControl, Main:, RadioKeyE, 0
        GuiControl, Main:, RadioKeyCustom, 0
    }

    if (AutoSellMode = "AutoMax") {
        GuiControl, Main:, ModeAutoMax, 1
        GuiControl, Main:, ModeFull, 0
    } else {
        GuiControl, Main:, ModeFull, 1
        GuiControl, Main:, ModeAutoMax, 0
    }
    
    UpdateVisualSwatch("CyanVisual", CyanColor)
    UpdateVisualSwatch("ClickVisual", ClickColor)
    UpdateVisualSwatch("RestartVisual", RestartColor)
}

SaveAllSettings() {
    global
    Gui, Main: Submit, NoHide
    IniWrite, %NeedleCooldownInput%, %IniFile%, Settings, NeedleCooldownInput
    IniWrite, %ScanRateInput%, %IniFile%, Settings, ScanRateInput
    IniWrite, %RestartDelayInput%, %IniFile%, Settings, RestartDelayInput
    IniWrite, %CurrentHotkey%, %IniFile%, Settings, CurrentHotkey
    IniWrite, %CyanColor%, %IniFile%, Settings, CyanColor
    IniWrite, %EnableExtraColor%, %IniFile%, Settings, EnableExtraColor
    
    BubbleTolerance := BubbleToleranceInput
    IniWrite, %BubbleTolerance%, %IniFile%, Settings, BubbleTolerance
    
    IniWrite, %ClickColor%, %IniFile%, Settings, ClickColor
    IniWrite, %RestartColor%, %IniFile%, Settings, RestartColor

    Loop, 9 {
        val := ExtraColors[A_Index]
        IniWrite, %val%, %IniFile%, ExtraColors, Slot%A_Index%
    }

    IniWrite, %EnableAutoSell%, %IniFile%, AutoSell, EnableAutoSell
    IniWrite, %TesseractExePath%, %IniFile%, AutoSell, TesseractExePath
    IniWrite, %AutoSellMode%, %IniFile%, AutoSell, AutoSellMode
    IniWrite, %TargetLeftNum%, %IniFile%, AutoSell, TargetLeftNum
    IniWrite, %TargetRightNum%, %IniFile%, AutoSell, TargetRightNum

    IniWrite, %SellKeyChoice%, %IniFile%, AutoSellAction, SellKeyChoice
    IniWrite, %CustomSellKey%, %IniFile%, AutoSellAction, CustomSellKey
    IniWrite, %Pos05_X%, %IniFile%, AutoSellAction, Pos05_X
    IniWrite, %Pos05_Y%, %IniFile%, AutoSellAction, Pos05_Y
    IniWrite, %Pos1_X%, %IniFile%, AutoSellAction, Pos1_X
    IniWrite, %Pos1_Y%, %IniFile%, AutoSellAction, Pos1_Y
    IniWrite, %Pos2_X%, %IniFile%, AutoSellAction, Pos2_X
    IniWrite, %Pos2_Y%, %IniFile%, AutoSellAction, Pos2_Y
    
    IniWrite, %Glide_Pos05%, %IniFile%, AutoSellTimings, Glide_Pos05
    IniWrite, %Hover_Pos05%, %IniFile%, AutoSellTimings, Hover_Pos05
    IniWrite, %Glide_Pos1%,  %IniFile%, AutoSellTimings, Glide_Pos1
    IniWrite, %Hover_Pos1%,  %IniFile%, AutoSellTimings, Hover_Pos1
    IniWrite, %Glide_Pos2%,  %IniFile%, AutoSellTimings, Glide_Pos2
    IniWrite, %Hover_Pos2%,  %IniFile%, AutoSellTimings, Hover_Pos2

    InactivityTimeoutSec := InactivityTimeoutSecInput
    IniWrite, %InactivityTimeoutSec%, %IniFile%, FailSafe, InactivityTimeoutSec
    
    IniWrite, %B1_X1%, %IniFile%, Zones, B1_X1
    IniWrite, %B1_Y1%, %IniFile%, Zones, B1_Y1
    IniWrite, %B1_X2%, %IniFile%, Zones, B1_X2
    IniWrite, %B1_Y2%, %IniFile%, Zones, B1_Y2
    
    IniWrite, %B2_X1%, %IniFile%, Zones, B2_X1
    IniWrite, %B2_Y1%, %IniFile%, Zones, B2_Y1
    IniWrite, %B2_X2%, %IniFile%, Zones, B2_X2
    IniWrite, %B2_Y2%, %IniFile%, Zones, B2_Y2

    IniWrite, %B3_X1%, %IniFile%, Zones, B3_X1
    IniWrite, %B3_Y1%, %IniFile%, Zones, B3_Y1
    IniWrite, %B3_X2%, %IniFile%, Zones, B3_X2
    IniWrite, %B3_Y2%, %IniFile%, Zones, B3_Y2

    IniWrite, %OCR_X1%, %IniFile%, Zones, OCR_X1
    IniWrite, %OCR_Y1%, %IniFile%, Zones, OCR_Y1
    IniWrite, %OCR_X2%, %IniFile%, Zones, OCR_X2
    IniWrite, %OCR_Y2%, %IniFile%, Zones, OCR_Y2
}

UpdateHotkey:
    Gui, Main: Submit, NoHide
    if (HotkeyInput = "")
        return
    if (CurrentHotkey != "")
        Hotkey, %CurrentHotkey%, Off, UseErrorLevel
        
    CurrentHotkey := HotkeyInput
    Hotkey, %CurrentHotkey%, ToggleMacro, On, UseErrorLevel
    SaveAllSettings()
return

; --- Tesseract OCR Execution with White Isolation & Noise Rejection ---
CaptureZoneToBMP(x1, y1, x2, y2, outFile) {
    w := Abs(x2 - x1)
    h := Abs(y2 - y1)
    if (w <= 0 || h <= 0)
        return false

    rx := (x1 < x2) ? x1 : x2
    ry := (y1 < y2) ? y1 : y2

    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    mDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
    hBM := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", w, "Int", h, "Ptr")
    oBM := DllCall("SelectObject", "Ptr", mDC, "Ptr", hBM, "Ptr")

    DllCall("BitBlt", "Ptr", mDC, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hDC, "Int", rx, "Int", ry, "UInt", 0x00CC0020)

    VarSetCapacity(bi, 40, 0)
    NumPut(40, bi, 0, "UInt")
    NumPut(w, bi, 4, "Int")
    NumPut(h, bi, 8, "Int")
    NumPut(1, bi, 12, "UShort")
    NumPut(24, bi, 14, "UShort")
    NumPut(0, bi, 16, "UInt")

    rowSize := Floor((w * 3 + 3) / 4) * 4
    dataSize := rowSize * h
    VarSetCapacity(pixelData, dataSize, 0)

    DllCall("GetDIBits", "Ptr", mDC, "Ptr", hBM, "UInt", 0, "UInt", h, "Ptr", &pixelData, "Ptr", &bi, "UInt", 0)

    ; White thresholding filter: keep white within tolerance 10 (channels >= 245), turn all other pixels black
    minVal := 255 - 10
    ptr := &pixelData
    loop, %h% {
        rowOffset := (A_Index - 1) * rowSize
        loop, %w% {
            idx := rowOffset + (A_Index - 1) * 3
            b := NumGet(ptr + idx, 0, "UChar")
            g := NumGet(ptr + idx, 1, "UChar")
            r := NumGet(ptr + idx, 2, "UChar")

            if (r >= minVal && g >= minVal && b >= minVal) {
                NumPut(255, ptr + idx, 0, "UChar")
                NumPut(255, ptr + idx, 1, "UChar")
                NumPut(255, ptr + idx, 2, "UChar")
            } else {
                NumPut(0, ptr + idx, 0, "UChar")
                NumPut(0, ptr + idx, 1, "UChar")
                NumPut(0, ptr + idx, 2, "UChar")
            }
        }
    }

    VarSetCapacity(bf, 14, 0)
    NumPut(0x4D42, bf, 0, "UShort")
    NumPut(14 + 40 + dataSize, bf, 2, "UInt")
    NumPut(14 + 40, bf, 10, "UInt")

    f := FileOpen(outFile, "w")
    if (IsObject(f)) {
        f.RawWrite(&bf, 14)
        f.RawWrite(&bi, 40)
        f.RawWrite(&pixelData, dataSize)
        f.Close()
    }

    DllCall("SelectObject", "Ptr", mDC, "Ptr", oBM)
    DllCall("DeleteObject", "Ptr", hBM)
    DllCall("DeleteDC", "Ptr", mDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
    return FileExist(outFile)
}

RunTesseractOCR() {
    global OCR_X1, OCR_Y1, OCR_X2, OCR_Y2, TesseractExePath
    if (!FileExist(TesseractExePath))
        return ""

    tempImg := A_Temp . "\ocr_target.bmp"
    tempOutBase := A_Temp . "\ocr_result"
    tempOutTxt := tempOutBase . ".txt"

    FileDelete, %tempImg%
    FileDelete, %tempOutTxt%

    if (!CaptureZoneToBMP(OCR_X1, OCR_Y1, OCR_X2, OCR_Y2, tempImg))
        return ""

    ; Whitelist strictly digits 0-9 and separator /
    cmd := """" . TesseractExePath . """ """ . tempImg . """ """ . tempOutBase . """ --psm 6 -c tessedit_char_whitelist=0123456789/"
    RunWait, %ComSpec% /c "%cmd%", , Hide

    rawText := ""
    if (FileExist(tempOutTxt)) {
        FileRead, rawText, %tempOutTxt%
        FileDelete, %tempOutTxt%
    }
    FileDelete, %tempImg%
    
    ; Strip all non-digit and non-slash characters
    cleanDigitsOnly := RegExReplace(rawText, "[^0-9/]", "")
    return cleanDigitsOnly
}

CheckAutoSellMatch(ByRef outLeft, ByRef outRight) {
    global AutoSellMode, TargetLeftNum, TargetRightNum
    scannedText := RunTesseractOCR()
    
    outLeft := ""
    outRight := ""

    ; Extract valid numeric pattern
    if (!RegExMatch(scannedText, "(\d+)\/(\d+)", match)) {
        if (RegExMatch(scannedText, "(\d+)", singleMatch)) {
            outLeft := singleMatch1
        }
        return false
    }

    outLeft := match1
    outRight := match2

    if (AutoSellMode = "AutoMax") {
        if (outLeft != "" && outRight != "" && outLeft = outRight)
            return true
    } else {
        if (outLeft = TargetLeftNum && outRight = TargetRightNum)
            return true
    }
    return false
}

ExecuteAutoSellSequence() {
    global SellKeyChoice, CustomSellKey, Pos05_X, Pos05_Y, Pos1_X, Pos1_Y, Pos2_X, Pos2_Y
    global Glide_Pos05, Hover_Pos05, Glide_Pos1, Hover_Pos1, Glide_Pos2, Hover_Pos2
    CoordMode, Mouse, Screen

    ; Determine active key
    keyToPress := (SellKeyChoice = "f") ? "f" : (SellKeyChoice = "e") ? "e" : CustomSellKey
    isEActive := (SellKeyChoice = "e" || (SellKeyChoice = "custom" && (CustomSellKey = "e" || CustomSellKey = "E")))

    ; Step 1: Press configured key
    if (keyToPress != "") {
        Send, {%keyToPress% down}
        Sleep, 50
        Send, {%keyToPress% up}
        Sleep, 200
    }

    ; Step 2 (Position 0.5): Move and click Position 0.5 first (Only if 'e' is active)
    if (isEActive && Pos05_X > 0 && Pos05_Y > 0) {
        GlideMouseMove(Pos05_X, Pos05_Y, Glide_Pos05)
        Sleep, %Hover_Pos05%
        Click, %Pos05_X%, %Pos05_Y%
        Sleep, 200
    }

    ; Step 3 (Position 1): Move and click Position 1 with individual glide & hover
    if (Pos1_X > 0 && Pos1_Y > 0) {
        GlideMouseMove(Pos1_X, Pos1_Y, Glide_Pos1)
        Sleep, %Hover_Pos1%
        Click, %Pos1_X%, %Pos1_Y%
        Sleep, 200
    }

    ; Step 4 (Position 2): Move and click Position 2 with individual glide & hover
    if (Pos2_X > 0 && Pos2_Y > 0) {
        GlideMouseMove(Pos2_X, Pos2_Y, Glide_Pos2)
        Sleep, %Hover_Pos2%
        Click, %Pos2_X%, %Pos2_Y%
        Sleep, 200
    }
}

TestOCRManual:
    Gui, Main: Submit, NoHide
    curL := "", curR := ""
    isMatched := CheckAutoSellMatch(curL, curR)
    resText := "OCR: " . curL . "/" . curR . " | Match: " . (isMatched ? "YES" : "NO")
    GuiControl, Main:, OCRStatus, %resText%
    
    if (isMatched) {
        GuiControl, Main: +c00FF00 +Background00FF00, OCRTestVisual
        GuiControl, Main:, OCRTestVisual, 100
    } else {
        GuiControl, Main: +cFF0000 +BackgroundFF0000, OCRTestVisual
        GuiControl, Main:, OCRTestVisual, 100
    }
    
    SetTimer, ResetOCRTestBox, -2000
return

ResetOCRTestBox:
    GuiControl, Main: +cWhite +BackgroundWhite, OCRTestVisual
    GuiControl, Main:, OCRTestVisual, 100
return

ToggleMacro:
    if (MacroRunning) {
        MacroRunning := 0
        SetTimer, BackgroundInactivityWatchdog, Off
        GuiControl, Main:, StartBtn, ▶️ Start
        GuiControl, Main:, Status, Status: Stopped
        return
    }
    
    Gui, Main: Submit, NoHide
    CoordMode, Mouse, Screen
    
    ; RAM-only storage of original cursor placement at macro launch
    MouseGetPos, SavedMouseX, SavedMouseY
    
    MacroRunning := 1
    LastClickTick := A_TickCount
    SetTimer, BackgroundInactivityWatchdog, 250
    GuiControl, Main:, StartBtn, ⏹️ Stop
    SetTimer, MainWorkflow, -10
return

; --- MAIN WORKFLOW LOOP ---
MainWorkflow:
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ; Normalize scan zone boundaries so X1 < X2 and Y1 < Y2 regardless of selection direction
    ScanX1 := Min(B1_X1, B1_X2)
    ScanY1 := Min(B1_Y1, B1_Y2)
    ScanX2 := Max(B1_X1, B1_X2)
    ScanY2 := Max(B1_Y1, B1_Y2)

    While (MacroRunning) {
        ; STEP 0: Check AutoSell Threshold Before Every Single Cast
        if (EnableAutoSell) {
            Loop {
                if (!MacroRunning)
                    break 2

                GuiControl, Main:, Status, Status: Pre-Cast OCR Check...
                detLeft := "", detRight := ""
                if (CheckAutoSellMatch(detLeft, detRight)) {
                    GuiControl, Main:, Status, Status: Match Found (%detLeft%/%detRight%) - Selling...
                    ExecuteAutoSellSequence()
                    Sleep, 500
                } else {
                    MouseMove, %SavedMouseX%, %SavedMouseY%, 0
                    Sleep, 100
                    break
                }
            }
        }

        ; STEP 1: Initial Cast Click
        GuiControl, Main:, Status, Status: Step 1 - Initial Click...
        SendSavedClick()
        Sleep, 300

        ; STEP 2: Strict Scan in Zone 1 (Cyan Bubble + 9 Extra Bubble Colors)
        GuiControl, Main:, Status, Status: Step 2 - Scanning Bubble...
        Loop {
            if (!MacroRunning)
                break 2

            BubbleFound := 0

            ; Primary Cyan Color Search
            if (CyanColor != "") {
                PixelSearch, FX, FY, %ScanX1%, %ScanY1%, %ScanX2%, %ScanY2%, %CyanColor%, %BubbleTolerance%, Fast RGB
                if (ErrorLevel = 0)
                    BubbleFound := 1
            }

            ; 9 Extra Bubble Colors Search
            if (!BubbleFound && EnableExtraColor) {
                Loop, 9 {
                    slotColor := ExtraColors[A_Index]
                    if (slotColor != "") {
                        PixelSearch, EFX, EFY, %ScanX1%, %ScanY1%, %ScanX2%, %ScanY2%, %slotColor%, %BubbleTolerance%, Fast RGB
                        if (ErrorLevel = 0) {
                            BubbleFound := 1
                            break
                        }
                    }
                }
            }

            if (BubbleFound) {
                SendSavedClick()
                break
            }

            Sleep, %ScanRateInput%
        }

        ; STEP 3: Wait for Restart Color with a 2-second timeout (Tolerance set to 5)
        GuiControl, Main:, Status, Status: Step 3 - Waiting for Minigame...
        WaitStart := A_TickCount

        Loop {
            if (!MacroRunning)
                break 2

            PixelSearch, UIX, UIY, %B3_X1%, %B3_Y1%, %B3_X2%, %B3_Y2%, %RestartColor%, 5, Fast RGB
            if (ErrorLevel = 0)
                break

            if (A_TickCount - WaitStart >= 2000) {
                GuiControl, Main:, Status, Status: UI Timeout - Resetting...
                Sleep, %RestartDelayInput%
                continue 2
            }

            Sleep, 20
        }

        ; STEP 4: Minigame Active Loop (Tolerance set to 5)
        GuiControl, Main:, Status, Status: Step 4 - Minigame Active...
        While (MacroRunning) {
            ; 1. Check if restart color is present in Zone 3
            PixelSearch, UIX, UIY, %B3_X1%, %B3_Y1%, %B3_X2%, %B3_Y2%, %RestartColor%, 5, Fast RGB
            if (ErrorLevel != 0) {
                GuiControl, Main:, Status, Status: Minigame Ended - Waiting Delay...
                Sleep, %RestartDelayInput%
                break
            }

            ; 2. Scan Zone 2 for Click Color
            PixelSearch, WX, WY, %B2_X1%, %B2_Y1%, %B2_X2%, %B2_Y2%, %ClickColor%, 5, Fast RGB
            if (ErrorLevel = 0) {
                SendSavedClick()
                Sleep, %NeedleCooldownInput%
            }

            Sleep, %ScanRateInput%
        }
    }

    GuiControl, Main:, StartBtn, ▶️ Start
    GuiControl, Main:, Status, Status: Stopped
return

FrameBoxGuiClose:
return

MainGuiClose:
F2::ExitApp