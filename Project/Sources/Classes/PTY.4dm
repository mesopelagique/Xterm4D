
property id : Integer
property shell : Text
property cols : Integer
property rows : Integer

Class constructor($shell : Text; $cols : Integer; $rows : Integer; $cwd : Text)
	This.shell:=(Length($shell)>0) ? $shell : "/bin/zsh"
	This.cols:=($cols)<=0 ? 80 : $cols
	This.rows:=($rows<=0) ? 24 : $rows
	This.id:=PTY Create(This.shell; This.cols; This.rows; $cwd)
	
Function get isOpen() : Boolean
	
	return (This.id#0)
	
Function getStatus() : cs.PTYStatus
	If (This.id=0)
		var $object:={pid: 0; running: False; exitCode: -1}
	Else 
		$object:=PTY Get status(This.id)
	End if 
	return cs.PTYStatus.new($object)
	
Function write($text : Text) : cs.PTY
	
	If (This.id#0)
		var $code:=PTY Write(This.id; $text)
	End if 
	
	return This
	
Function writeLine($text : Text) : cs.PTY
	
	return This.write($text+"\n")
	
Function read($bufferSize : Integer; $timeoutMs : Integer) : Text
	
	If (This.id=0)
		return ""
	End if 
	
	$bufferSize:=$bufferSize || 65536
	$timeoutMs:=$timeoutMs || 2000
	
	return PTY Read(This.id; $bufferSize; $timeoutMs)
	
Function readAll($timeoutMs : Integer) : Text
	
	If (This.id=0)
		return ""
	End if 
	
	$timeoutMs:=$timeoutMs || 500
	
	var $result : Text
	var $chunk : Text
	
	$result:=""
	Repeat 
		$chunk:=PTY Read(This.id; 65536; $timeoutMs)
		$result:=$result+$chunk
	Until ($chunk="")
	
	return $result
	
Function resize($cols : Integer; $rows : Integer) : Integer
	
	If (This.id=0)
		return 0
	End if 
	
	This.cols:=$cols
	This.rows:=$rows
	
	return PTY Set window size(This.id; $cols; $rows)
	
Function sendSignal($signal : Integer) : Integer
	
	If (This.id=0)
		return 0
	End if 
	
	return PTY Send signal(This.id; $signal)
	
Function interrupt() : Integer
	
	return This.sendSignal(2)  // SIGINT — same as Ctrl+C, but hits entire process group
	
Function close()
	
	If (This.id#0)
		PTY Close(This.id)
		This.id:=0
	End if 
	