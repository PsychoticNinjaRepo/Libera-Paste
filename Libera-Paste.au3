#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; include AutoIT pre-defined constants
#include <Constants.au3>
; include constants for GUI message boxes
#include <MsgBoxConstants.au3>
; include constants for various String constants
#include <StringConstants.au3>
; include clipboard bits
#include <ClipBoard.au3>
; Windows API Error handling and reporting
#include <WinAPIError.au3>
; Windows Constants
#include <WindowsConstants.au3>

; set various program-wide requirements here
; variable declaration is mandatory
AutoItSetOption("MustDeclareVars", 1)
; force exact matches on window names for WinActivate and friends
AutoItSetOption ("WinTitleMatchMode", 3)
; (default) 1 = show debug
AutoItSetOption("TrayIconDebug", 1)

; how many pastes were done on Libera
Global $LiberaPastes			= 0
; how many pastes in total
Global $TotalPastes				= 0
; state value of paste traps
Global Const $STATE_FREE		= 0
Global Const $STATE_TRAPPED		= 1

; the Libera IRC window title we're looking for
; NOTE: this value is special; use Au3Info to get the actual window title and copy/paste into the quoted string below
; TODO: This needs to be moved into a config file
Global Const $LiberaWinTitle = "[screen 0: jrd@atl-02 - IRSSI]"

; Trap Control-END to terminate session
HotKeySet ("^{End}", "Quit")

; trap pastes
TrapPastes($STATE_TRAPPED)

; gracefully loop forever
While 1
	Sleep (10000)
WEnd
Exit


;===========================================================================================================
; Function Name:    TrapPastes
; Description:      Trap or release ^v/shift-insert
; Parameter(s):     Trap state ($STATE_FREE/$STATE_TRAPPED)
; Requirement(s):   None
; Return Value(s):  None
;
;===========================================================================================================
;
Func TrapPastes($state)
	If $state = $STATE_TRAPPED Then
		; trap control-v and shift-insert
		HotKeySet ("^v", "HandlePaste")
		HotKeySet ("+{INSERT}", "HandlePaste")
	Else
		; release our traps
		HotKeySet ("^v")
		HotKeySet ("+{INSERT}")
	EndIf
EndFunc

;===========================================================================================================
;
; Function Name:    Debug
; Description:      Display debug message on screen; wait for user input to continue
; Parameter(s):     String: message to display
; Requirement(s):   None
; Return Value(s):  None
;
;===========================================================================================================
;
Func Debug ($msg)
	Msgbox (0, "Debug Message", $msg)
EndFunc

;===========================================================================================================
;
; Function Name:    HandlePaste
; Description:      Intercept ^v/shift-insert and prompt user to continue or abort if in a protected window
;                   and invalidate the clipboard in either case
; Parameter(s):     None
; Requirement(s):   None
; Return Value(s):  None
;
;===========================================================================================================
;
Func HandlePaste ()
	Local $CurrentWindowTitle
	Local $return
	; the two priority formats we're looking for: text/text in oem charset
	Local $aFormats[3] = [2, $CF_TEXT, $CF_OEMTEXT]

	; first determine if we have a text format in the clipboard and if we do not we return; we check both
	; priority text formats and also unicode text.
	; TODO: consolidate this: $aFormats[4] = [3, $CF_TEXT, $CF_OEMTEXT, $CF_UNICODETEXT]
	If _ClipBoard_GetPriorityFormat($aFormats) = 0 And _ClipBoard_IsFormatAvailable($CF_UNICODETEXT) = 0 Then
		Return
	EndIf

	; grab the window title of the active window
	$CurrentWindowTitle = WinGetTitle ("")

	; Strip leading and trailing whitespace
	$CurrentWindowTitle = StringStripWS ($CurrentWindowTitle, $STR_STRIPLEADING + $STR_STRIPTRAILING)

	; If we're in the Libera window prompt user with a Yes/No popup warning of what's about to happen; return unless user chooses Yes
	If $CurrentWindowTitle == $LiberaWinTitle Then
        $return = MsgBox ($MB_YESNO + $MB_ICONWARNING + $MB_DEFBUTTON2, "WARNING!", "You're about to paste to Libera..." & @CR & @CR & "Pasting will invalidate the clipboard" & @CR & @CR & "Are you sure you wish to do this?")
		If $return <> $IDYES Then
			Return
        Endif
	EndIf

	; release our traps
	TrapPastes($STATE_FREE)

	; send Shift-Insert to trigger the system paste
	Send ("+{INSERT}")

	; reset our traps
	TrapPastes($STATE_TRAPPED)

	; bump total pastes
	$TotalPastes = $TotalPastes + 1

	; if we're in the Libera window bump libera paste count and invalidate the clipboard
	If $CurrentWindowTitle == $LiberaWinTitle Then
		$LiberaPastes = $LiberaPastes + 1
		InvalidateClipboard()
	EndIf
EndFunc

;===========================================================================================================
;
; Function Name:    InvalidateClipboard
; Description:      Invalidate (empty) clipboard completely
;					TODO: research and see if we can only remove text contents
; Parameter(s):     None
; Requirement(s):   None
; Return Value(s):  None
;
;===========================================================================================================
;
Func InvalidateClipboard()
	; open the clipboard; whine if it fails
	If _ClipBoard_Open(0) Then
		; empty it; whine if it fails
		If _ClipBoard_Empty() Then
			; close the clipboard - error checking here is silly
			_ClipBoard_Close()
		Else
			_WinAPI_ShowError("_ClipBoard_Empty failed")
		EndIf
	Else
		_WinAPI_ShowError("_ClipBoard_Open failed")
	EndIf
EndFunc

;===========================================================================================================
;
; Function Name:    Quit
; Description:      Terminate script displaying number of pastes handled
; Parameter(s):     None
; Requirement(s):   None
; Return Value(s):  None
;
;===========================================================================================================
;
Func Quit ()
        Local $String

        $String = StringFormat ("Number of Libera pastes: %d" & @CR & "Total number of pastes: %d", $LiberaPastes, $TotalPastes)

        MsgBox (0, "Session Ending Stats", $String)

        Exit
EndFunc
