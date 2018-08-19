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
		  If theOption.WasSet Then ProcessVersion
		  
		  theOption = mOptions.OptionValue(kOptionTargetOS)
		  If theOption.WasSet Then ProcessTargetOS
		  
		  theOption = mOptions.OptionValue(kOptionProject)
		  If theOption.WasSet Then ProcessProjectOptions(theOption)
		  
		  theOption = mOptions.OptionValue(kOptionFolderMove)
		  If theOption.WasSet Then ProcessFolderMove(theOption)
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
		  
		  o = New Option("", kOptionFolderMove, "move STR", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionFolderMoveTo, "moveTo STR", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionFolderShellBase, "folder shellPath base STR (optional)", Option.OptionType.String)
		  parser.AddOption o
		  
		  parser.AdditionalHelpNotes = "xopo  Copyright (C) 2018  Bernardo Monsalve."+ EndOfLine+ _
		  "This program comes with ABSOLUTELY NO WARRANTY;"+ EndOfLine+ _
		  "This is free software, and you are welcome to redistribute it"+ EndOfLine+ _
		  "under certain conditions."
		  
		  Return parser
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetPathSepFixed(path As String) As String
		  #if TargetWin32
		    Return path.ReplaceAll("/", "\")
		  #endif
		  
		  Return path
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
		Private Sub ProcessFolderMove(theOption As Option)
		  Dim folderMoveToOption As Option = mOptions.OptionValue(kOptionFolderMoveTo)
		  If Not folderMoveToOption.WasSet Then PrintAndQuit("folderMoveTo option is empty")
		  
		  If theOption.Value.IsNull Then PrintAndQuit("folder option is empty")
		  
		  Dim folderMoveStr As String= GetPathSepFixed(theOption.Value.StringValue)
		  Dim folderBase, folderMove, folderMoveTo As FolderItem
		  
		  Dim folderShellBaseOption As Option = mOptions.OptionValue(kOptionFolderShellBase)
		  If folderShellBaseOption.WasSet Then
		    Try
		      folderBase= New FolderItem(folderShellBaseOption.Value.StringValue, FolderItem.PathTypeShell)
		      folderMove= folderBase.Child(folderMoveStr)
		      #if RBVersion < 2013
		        folderMoveStr= folderMove.AbsolutePath
		      #else
		        folderMoveStr= folderMove.NativePath
		      #endif
		    Catch e As RuntimeException
		      PrintAndQuit("folderShellBase error: "+ e.Message)
		    End Try
		  Else
		    folderMove= New FolderItem(folderMoveStr)
		  End If
		  
		  If folderMove Is Nil Then PrintAndQuit("folder DIR is nil")
		  If Not folderMove.Directory Then PrintAndQuit("folder DIR doesnt a DIR")
		  If Not folderMove.Exists Then PrintAndQuit("folder DIR doesnt exist")
		  
		  Dim folderMoveToStr As String= GetPathSepFixed(folderMoveToOption.Value.StringValue)
		  If folderMoveToStr= "" Then PrintAndQuit("folder dest missing")
		  
		  If Not (folderBase Is Nil) Then
		    folderMoveTo= folderBase.Child(folderMoveToStr)
		    #if RBVersion < 2013
		      folderMoveToStr= folderMoveTo.AbsolutePath
		    #else
		      folderMoveToStr= folderMoveTo.NativePath
		    #endif
		  End If
		  
		  Dim sh As New Shell
		  Dim cmd As String
		  
		  #if TargetWin32
		    If folderMoveStr.Right(1)= "\" Then folderMoveStr= folderMoveStr.Left(folderMoveStr.Len- 1)
		    Dim afolderMove() As String= folderMoveStr.Split("\")
		    Dim  folderMoveToTemp As String= folderMoveToStr
		    'If folderMoveToStr.Right(1)= "\" Then folderMoveToTemp= folderMoveToStr.Left(folderMoveToStr.Len- 1)
		    '
		    'cmd= "rd /S /Q """+ folderMoveToTemp+ "\"+ afolderMove(afolderMove.Ubound)+ """"
		    'System.DebugLog cmd
		    'sh.Execute cmd
		    'System.DebugLog sh.Result
		    '
		    'cmd= "move /Y """+ folderMoveStr+ """ """+ folderMoveToStr+ """"
		    'System.DebugLog cmd
		    'sh.Execute cmd
		    'System.DebugLog sh.Result
		    
		    If folderMoveToStr.Right(1)<> "\" Then folderMoveToTemp= folderMoveToStr+ "\"
		    
		    cmd= "xcopy """+ folderMoveStr+ """ """+ folderMoveToTemp+ afolderMove(afolderMove.Ubound)+ """ /S /I /F /Y"
		    System.DebugLog cmd
		    sh.Execute cmd
		    System.DebugLog sh.Result
		    
		    If sh.ErrorCode<> 0 Then PrintAndQuit("shell xcopy error", sh.ErrorCode)
		    
		    cmd= "rd /S /Q """+ folderMoveStr+ """"
		    System.DebugLog cmd
		    sh.Execute cmd
		    System.DebugLog sh.Result
		  #elseIf TargetMacOS Or TargetLinux
		    
		  #endif
		  
		  'Quit 0
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
		  
		  'Quit 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessTargetOS()
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
		  
		  Quit 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ProcessVersion()
		  Print ""
		  Print "Version: "+ kVersion
		  Print ""
		  
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
		
		--folderShellBase=C:\Users\Usuario\DOCUME~1\Repos\XOJO-S~1\STORAG~2 --folderMove="StorageFactory" --folderMoveTo="../"
		
		--folderMove="C:\Users\Usuario\Documents\Temp\xml" --folderMoveTo="C:\Users\Usuario\Documents"
	#tag EndNote


	#tag Property, Flags = &h21
		Private mOptions As OptionParser
	#tag EndProperty


	#tag Constant, Name = kOptionFolderMove, Type = String, Dynamic = False, Default = \"folderMove", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionFolderMoveTo, Type = String, Dynamic = False, Default = \"folderMoveTo", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kOptionFolderShellBase, Type = String, Dynamic = False, Default = \"folderShellBase", Scope = Private
	#tag EndConstant

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

	#tag Constant, Name = kVersion, Type = String, Dynamic = False, Default = \"0.0.180818", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
