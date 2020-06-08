FileEncoding,	UTF-8
#SingleInstance	Force
ToolTip	Funções
;{
global cliptext
global istest
global ison
global con
global ora
global nomeSensor
global nrSensor
global forReplace	;}
Ping(addresses) {
	rVal := []
	Loop, Parse, addresses, % A_Space
		addr .= addr ? A_Space "or Address = '" A_LoopField "'" : "Address = '" A_LoopField "'"
	colPings := ComObjGet( "winmgmts:" ).ExecQuery("Select * From Win32_PingStatus where " addr "")._NewEnum
	While colPings[objStatus]
		rVal.Push( [((oS:=(objStatus.StatusCode="" or objStatus.StatusCode<>0)) ? "0" : "1" ), objStatus.Address] )
	Return rVal
}
Menu, Tray, Icon