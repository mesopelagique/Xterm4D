//%attributes = {}

var $options:=New object
$options.targets:=[]
$options.generateSymbols:=False
$options.generateSyntaxFile:=True
$options.generateTypingMethods:=False

var $components:=Folder(fk database folder).folders().filter(Formula($1.value.extension=".4dbase"))
var $lock:=Folder(fk database folder).folder("userPreferences."+Current system user).file("dependencies-lock.json")
If ($lock.exists)
	var $lockData:=JSON Parse($lock.getText())
	$lockData.dependencies:=$lockData.dependencies || {}
	var $key : Text
	For each ($key; $lockData.dependencies)
		If (Length(String($lockData.dependencies[$key].path))>0)

			var $folder:=Try(Folder(String($lockData.dependencies[$key].path); fk platform path))
			If ($folder=Null)
				$folder:=Try(Folder(String($lockData.dependencies[$key].path); fk posix path))
			End if
			If ($folder#Null)
				$components.push($folder)
			End if

		End if
	End for each
End if

// Find component project files, prefer .4DProject over .4DZ to avoid duplicates
// .4DProject is in Component.4dbase/Project/Component.4DProject
// .4DZ is in Component.4dbase/Component.4DZ
var $projectFiles : Collection:=$components.flatMap(Formula($1.value.files(fk recursive).filter(Formula($1.value.extension=".4DProject"))))
var $zFiles : Collection:=$components.flatMap(Formula($1.value.files(fk recursive).filter(Formula($1.value.extension=".4DZ"))))
// Get component names that have .4DProject files
var $projectNames : Collection:=$projectFiles.map(Formula($1.value.parent.parent.name))
// Keep only .4DZ files for components without .4DProject
$zFiles:=$zFiles.filter(Formula(Not($projectNames.includes($1.value.parent.name))))
$components:=$projectFiles.combine($zFiles)
$options.components:=$components

var $result : Object:=Compile project($options)

If ($result.success)
	LOG EVENT(Into system standard outputs; JSON Stringify($result); Information message)
Else
	LOG EVENT(Into system standard outputs; JSON Stringify($result); Error message)
End if
