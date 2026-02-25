//%attributes = {"invisible":true,"preemptive":"capable"}
// XTerm_ReadLoop — runs in a background WORKER process
// Reads PTY output and pushes it to the form via CALL FORM.
//
// Called by: CALL WORKER(name; "XTerm_ReadLoop"; ptyId; windowRef; webArea; signal)

#DECLARE($ptyId : Integer; $windowRef : Integer; $webArea : Text; $signal : Object)

var $isCompiled : Boolean:=Is compiled mode
While ($signal.running)
	
	var $status : Object
	$status:=PTY Get status($ptyId)
	
	If (Not($status.running))
		// PTY process exited
		Use ($signal)
			$signal.running:=False
		End use 
	Else 
		var $output : Text
		If ($isCompiled)
			// Compiled mode uses real preemptive OS threads, so we can block 
			// entirely without freezing the parent 4D application's UI
			$output:=PTY Read($ptyId; 8192; -1)
		Else 
			// Interpreted mode runs Workers cooperatively on the main UI thread.
			// We must poll instantly (0) and yield control via DELAY PROCESS
			// to avoid the beachball of death. 
			$output:=PTY Read($ptyId; 8192; 0)
			DELAY PROCESS(Current process; 1)
		End if 
		
		If ($output#"")
			// Push to the form process where WA EXECUTE JAVASCRIPT FUNCTION is allowed
			CALL FORM($windowRef; "XTerm_OnOutput"; $webArea; $output)
		End if 
	End if 
	
End while 

KILL WORKER
