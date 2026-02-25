
Case of 
	: (Form event code=On Load)
		
		Form.xterm:=cs.XTerm.new(OBJECT Get name(Object current); ""; 0; 0; Folder(fk database folder))
		
	: (Form event code=On Unload)
		
		Form.xterm.close()
		
End case 