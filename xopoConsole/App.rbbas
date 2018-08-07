#tag Class
Protected Class App
Inherits ConsoleApplication
	#tag Event
		Function Run(args() as String) As Integer
		  // xopo - Command line helper for xojo vcp projects.
		  // Copyright (C) 2018  lbmonsalve - Bernardo Monsalve, see Copyright note
		  // https://github.com/lbmonsalve/Xojo-xopo.git
		  
		  mOptions = GetOptions
		  
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
		  Dim theOption As Option = mOptions.OptionValue(kOptionVersion)
		  If theOption.WasSet Then
		    Print ""
		    Print "Version: "+ kVersion
		    Print ""
		    Return 0
		  End If
		  
		  theOption = mOptions.OptionValue(kOptionTargetOS)
		  If theOption.WasSet Then
		    Print ""
		    #if TargetWin32
		      Print "TargetWin"
		    #elseif TargetMacOS
		      Print "TargetMacOS"
		    #elseif TargetLinux
		      Print "TargetLinux"
		    #else
		      Print "TargetUnknow"
		    #endif
		    Print ""
		    Return 0
		  End If
		  
		  theOption = mOptions.OptionValue(kOptionProject)
		  If theOption.WasSet Then ProcessProjectOptions(theOption)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function GetOptions() As OptionParser
		  Dim parser As New OptionParser
		  
		  Dim o As Option
		  
		  o = New Option("v", kOptionVersion, "get Version", Option.OptionType.Boolean)
		  parser.AddOption o
		  
		  o = New Option("", kOptionTargetOS, "get TargetOS", Option.OptionType.Boolean)
		  parser.AddOption o
		  
		  o = New Option("p", kOptionProject, "set project FILE", Option.OptionType.File)
		  'o.IsArray = True
		  parser.AddOption o
		  
		  o = New Option("", kOptionSearchText, "search STR in FILE") // , Option.OptionType.String
		  parser.AddOption o
		  
		  o = New Option("", kOptionReplaceText, "replace STR in FILE") // , Option.OptionType.String
		  parser.AddOption o
		  
		  parser.AdditionalHelpNotes = "xopo  Copyright (C) 2018  Bernardo Monsalve."+ EndOfLine+ _
		  "This program comes with ABSOLUTELY NO WARRANTY;"+ EndOfLine+ _
		  "This is free software, and you are welcome to redistribute it"+ EndOfLine+ _
		  "under certain conditions."
		  
		  Return parser
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PrintAndQuit(msg As String, ret As Integer = 10)
		  Print ""
		  Print msg
		  Print ""
		  mOptions.ShowHelp
		  
		  Quit ret
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PrintHelp()
		  Print ""
		  Print "Usage: " + mOptions.AppName + " [params] "
		  Print ""
		  mOptions.ShowHelp
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessProjectOptions(projectOption As Option)
		  If projectOption.Value.IsNull Then PrintAndQuit("project option is empty")
		  
		  Dim project As FolderItem = projectOption.Value
		  
		  If project Is Nil Then PrintAndQuit("project FILE is nil")
		  If Not project.Exists Then PrintAndQuit("project FILE doesnt exists")
		  
		  // read FILE
		  Dim content As String
		  
		  Try
		    Dim t As TextInputStream= TextInputStream.Open(project)
		    content= t.ReadAll
		    t= Nil
		  Catch e As RuntimeException
		    PrintAndQuit("reading error: "+ e.Message)
		  End Try
		  
		  Dim searchOption As Option = mOptions.OptionValue(kOptionSearchText)
		  Dim replaceOption As Option = mOptions.OptionValue(kOptionReplaceText)
		  
		  Dim searchStr, replaceStr As String
		  Dim searchAndReplace, doWrite As Boolean
		  
		  If searchOption.WasSet And replaceOption.WasSet Then
		    searchStr = searchOption.Value
		    replaceStr = replaceOption.Value
		    
		    If searchStr<> "" And replaceStr<> "" Then searchAndReplace= True
		  Else // try las STR args
		    Dim args() As String= mOptions.Arguments
		    If args.Ubound> 3 Then
		      replaceStr= args(args.Ubound)
		      searchStr= args(args.Ubound- 1)
		      
		      If searchStr<> "" And replaceStr<> "" Then searchAndReplace= True
		    End If
		  End If
		  
		  If searchAndReplace Then
		    'content= content.ReplaceAll(searchStr, replaceStr)
		    
		    Dim enc As TextEncoding= content.Encoding
		    content = ConvertEncoding(content, Encodings.UTF8) // regex needs utf8
		    
		    searchStr = ConvertEncoding(searchStr, Encodings.UTF8)
		    replaceStr = ConvertEncoding(replaceStr, Encodings.UTF8)
		    
		    Dim rg As New RegEx
		    Dim rgm As RegExMatch
		    
		    // set
		    rg.Options.ReplaceAllMatches= True
		    
		    // search and replace
		    rg.SearchPattern= searchStr
		    rg.ReplacementPattern= replaceStr
		    rgm= rg.Search(content)
		    
		    Dim searchCount As Integer
		    
		    While rgm<> Nil
		      searchCount= searchCount+ 1
		      rgm= rg.Search
		    Wend
		    
		    If searchCount> 0 Then
		      Print "found "+ Str(searchCount)+ " of """+ searchStr+ """"
		      content= rg.Replace(content, 0)
		    End If
		    
		    If Not (enc Is Nil) Then content= ConvertEncoding(content, enc)
		    
		    doWrite= True
		  End If
		  
		  // TODO: others options
		  
		  If Not doWrite Then PrintAndQuit("nothing to do", 0)
		  
		  // write FILE
		  Try
		    Dim t As TextOutputStream = TextOutputStream.Create(project)
		    t.Write content // ConvertEncoding(content, Encodings.UTF8)
		    t= Nil
		  Catch e As RuntimeException
		    PrintAndQuit("writing error: "+ e.Message)
		  End Try
		  
		  Quit 0
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
	#tag EndNote


	#tag Property, Flags = &h21
		Private mOptions As OptionParser
	#tag EndProperty


	#tag Constant, Name = kOptionProject, Type = String, Dynamic = False, Default = \"project", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionReplaceText, Type = String, Dynamic = False, Default = \"replaceText", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionSearchText, Type = String, Dynamic = False, Default = \"searchText", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionTargetOS, Type = String, Dynamic = False, Default = \"targetOS", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionVersion, Type = String, Dynamic = False, Default = \"version", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kVersion, Type = String, Dynamic = False, Default = \"0.0.180806", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
