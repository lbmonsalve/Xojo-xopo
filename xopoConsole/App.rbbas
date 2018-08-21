#tag Class
Protected Class App
Inherits ConsoleApplication
	#tag Event
		Function Run(args() as String) As Integer
		  // xopo - Command line helper for xojo vcp projects.
		  // Copyright (C) 2018  Bernardo Monsalve, see Copyright note
		  // https://github.com/lbmonsalve/Xojo-xopo.git
		  
		  mOptions = Xopo.GetOptions
		  
		  #pragma BreakOnExceptions Off
		  Try
		    mOptions.Parse args
		  Catch e As RuntimeException
		    Print e.Message
		    Print ""
		    Return 1
		  End Try
		  #pragma BreakOnExceptions Default
		  
		  If mOptions.HelpRequested Then
		    PrintHelp
		    Return 0
		  End If
		  
		  // process options...
		  Dim theOption As Option = mOptions.OptionValue(Xopo.kOptionVersion)
		  If theOption.WasSet Then Xopo.ProcessVersion
		  
		  theOption = mOptions.OptionValue(Xopo.kOptionTargetOS)
		  If theOption.WasSet Then Xopo.ProcessTargetOS
		  
		  theOption = mOptions.OptionValue(Xopo.kOptionProject)
		  If theOption.WasSet Then Xopo.ProcessProjectOptions(theOption)
		  
		  theOption = mOptions.OptionValue(Xopo.kOptionFolderMove)
		  If theOption.WasSet Then Xopo.ProcessFolderMove(theOption)
		  
		  'theOption = mOptions.OptionValue(Xopo.kOptionGitClone)
		  'If theOption.WasSet Then Xopo.ProcessGitClone(theOption)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub PrintHelp()
		  Print ""
		  Print "Usage: " + mOptions.AppName + " [params] "
		  Print ""
		  mOptions.ShowHelp
		End Sub
	#tag EndMethod


	#tag Note, Name = Copyright
		
		  This program is free software: you can redistribute it and/or modify
		  it under the terms of the GNU General Public License as published by
		  the Free Software Foundation, either version 3 of the License, or
		  (at your option) any later version.
		  
		  This program is distributed in the hope that it will be useful,
		  but WITHOUT ANY WARRANTY; without even the implied warranty of
		  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		  GNU General Public License for more details.
		  
		  You should have received a copy of the GNU General Public License
		  along with this program.  If not, see <http://www.gnu.org/licenses/>.
	#tag EndNote

	#tag Note, Name = Readme
		
		# xopo
		Command line helper for xojo vcp projects
		
		## Usage
		```
		xopo -p PROJECT_FILE --searchText=STR --replaceText=STR
		```
		or
		```
		xopo -p PROJECT_FILE STR STR
		```
		
		could use RegEx expressions.
		
		```
		xopo -h
		```
		
		-p "C:\Users\Usuario\Documents\XojoUnitResults.txt" "Skipped"  "SkippedD"
		
		--folderShellBase=C:\Users\Usuario\DOCUME~1\Repos\XOJO-S~1\STORAG~2 --folderMove="StorageFactory" --folderMoveTo="../"
		
		--folderMove="C:\Users\Usuario\Documents\Temp\xml" --folderMoveTo="C:\Users\Usuario\Documents"
	#tag EndNote


	#tag Property, Flags = &h21
		Private mOptions As OptionParser
	#tag EndProperty


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
