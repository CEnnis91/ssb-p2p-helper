; p2p-helper.au3
; call upnpc to automate port mapping for Project64k

#include <Constants.au3>
#include <Inet.au3>

$SCRIPT_NAME = "Project64k P2P Helper"
$SCRIPT_VERSION = "1.2.0"
$SCRIPT_INI = "p2p-helper.ini"

$MESSAGE_TITLE = StringFormat("%s (v%s)", $SCRIPT_NAME, $SCRIPT_VERSION)
$MESSAGE_FAILED = "It appears that UPnP is not enabled in your router. Please enable it and try again."
$MESSAGE_NOT_FOUND = "Unable to find 'upnpc-static.exe', please make sure it's in the correct directory (default: Tools)"
$MESSAGE_SPLASH_WAIT = "Please be patient, setting up P2P takes a few seconds..."
$MESSAGE_SPLASH_EXPLAIN = "In order for this to work UPnP must be enabled on your router."
$MESSAGE_SPLASH_PORT = "This will set up P2P to work from this computer on port: "
$MESSAGE_SUCCEEDED = "P2P was set up successfully. Would you like to copy your IP to the clipboard? (This will erase anything currently in your clipboard)."

; based off the default from the Pizza build
$P2P_DESC_DEFAULT = "Project64k-P2P"
$P2P_PORT_DEFAULT = "27886"
$P2P_PROTO_DEFAULT = "UDP"
$UPNPC_PATH_DEFAULT = "./Tools/upnpc-static.exe"

; use a built in macro to determine the local IP
; there was chatter about @IPAddress1 not always working
; so IPAddress2 is checked, but it probably won't work
Func local_ip()
	$local_ip1 = @IPAddress1
	
	If $local_ip1 = "127.0.0.1" Then
		return @IPAddress2
	ElseIf $local_ip1 = "0.0.0.0" Then
		return @IPAddress2
	Else
		return $local_ip1
	EndIf
EndFunc

; use an internal function to determine the public IP
; there is a 5 minute timer on the _GetIP function call
Func public_ip()
	return _GetIP()
EndFunc

; execute upnpc and capture the output without
; displaying any sort of SCARY console dialog!
Func upnpc($args)
	$upnpc_path = IniRead($SCRIPT_INI, "UPNPC", "path", $UPNPC_PATH_DEFAULT)
	$exists = FileExists($upnpc_path)

	; basic checking to make sure the binary exists
	If $exists = 0 Then
		SplashOff()
		MsgBox($MB_OK + $MB_ICONERROR, $MESSAGE_TITLE, $MESSAGE_NOT_FOUND)
		exit(0)
	Else
		$run_process = Run(StringFormat("%s %s", $upnpc_path, $args), "", @SW_HIDE, $STDERR_MERGED)
		ProcessWaitClose($run_process)
		$output = StdoutRead($run_process)
	EndIf
	
	return $output
EndFunc

;
; start of the script
;

$P2P_DESC = IniRead($SCRIPT_INI, "P2P", "description", $P2P_DESC_DEFAULT)
$P2P_PORT = IniRead($SCRIPT_INI, "P2P", "port", $P2P_PORT_DEFAULT)
$P2P_PROTO = IniRead($SCRIPT_INI, "P2P", "protocol", $P2P_PROTO_DEFAULT)

SplashTextOn($MESSAGE_TITLE, $MESSAGE_SPLASH_WAIT & @CRLF & $MESSAGE_SPLASH_EXPLAIN & @CRLF & @CRLF & $MESSAGE_SPLASH_PORT & $P2P_PORT, -1, 100, -1, -1, $DLG_TEXTVCENTER)
Sleep(3000)

; check to see if UPnP is enabled on the network
; if upnpc is unable to determine the external IP
; UPnP may not be properly enabled in the router
$upnp_check = upnpc(StringFormat("-l"))
$external_ip_fail = StringInStr($upnp_check, "GetExternalIPAddress failed")

If $external_ip_fail = 0 Then
	; remove any existing port mapping
	; then re-add it back with the correct description
	upnpc(StringFormat("-d %s %s", $P2P_PORT, $P2P_PROTO))
	upnpc(StringFormat("-e %s -a %s %s %s %s", $P2P_DESC, local_ip(), $P2P_PORT, $P2P_PORT, $P2P_PROTO))

	; TODO: actually verify the port forward worked
	SplashOff()
	$success_choice = MsgBox($MB_YESNO, $MESSAGE_TITLE, $MESSAGE_SUCCEEDED)
	If $success_choice = $IDYES Then
		ClipPut(StringFormat("%s:%s", public_ip(), $P2P_PORT))
	EndIf
Else
	SplashOff()
	MsgBox($MB_OK + $MB_ICONERROR, $MESSAGE_TITLE, $MESSAGE_FAILED)
EndIf
