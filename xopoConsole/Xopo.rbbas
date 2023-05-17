#tag Module
Protected Module Xopo
	#tag Method, Flags = &h1
		Protected Function GetOptions() As OptionParser
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
		  
		  o = New Option("", kOptionFolderMove, "folder to move", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionFolderMoveTo, "folder to move to", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionFolderShellBase, "shellPath folder base (optional)", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionGitClone, "the remote repository to clone", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionGitCloneToPath, "local directory to clone to", Option.OptionType.Directory)
		  parser.AddOption o
		  
		  o = New Option("", kOptionGitUserName, "username credential", Option.OptionType.String)
		  parser.AddOption o
		  
		  o = New Option("", kOptionGitUserPwd, "password credential", Option.OptionType.String)
		  parser.AddOption o
		  
		  parser.AdditionalHelpNotes = "xopo  Copyright (C) 2023  Bernardo Monsalve."+ EndOfLine+ _
		  "This program comes with ABSOLUTELY NO WARRANTY;"+ EndOfLine+ _
		  "This is free software, and you are welcome to redistribute it"+ EndOfLine+ _
		  "under certain conditions."
		  
		  mOptions= parser
		  
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
		Private Sub HandlerCheckoutProgress(path As String, cur As UInt32, tot As UInt32)
		  Const frmtI= "####"
		  
		  'System.DebugLog CurrentMethodName+ " path="+ path+ " cur="+ Str(cur)+ " tot="+ Str(tot)
		  Print "checkout "+ Str(cur, frmtI)+ "/"+ Str(tot, frmtI)+ " "+ path
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MoveFileOrFolder(source As FolderItem, destination As FolderItem) As Boolean
		  Dim newItem As FolderItem= destination.Child(source.Name)
		  If source.Directory Then
		    newItem.CreateAsFolder
		    If Not newItem.Exists Or Not newItem.Directory Then
		      Return False // folder was not created - stop processing
		    End If
		    While source.Count> 0
		      Dim file As FolderItem= source.Item(1)
		      If file Is Nil Then Return False // inaccessible
		      If Not MoveFileOrFolder(file, newItem) Then Return False // copy operation failed
		    Wend
		  Else // it's not a folder
		    If newItem.Exists Then newItem.Delete
		    source.CopyFileTo newItem
		    If source.LastErrorCode <> 0 Then Return False
		  End If
		  source.Delete
		  
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub PrintAndQuit(msg As String, ret As Integer = 10)
		  Print ""
		  Print msg
		  Print ""
		  'mOptions.ShowHelp
		  
		  Quit ret
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ProcessFolderMove(theOption As Option)
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
		  
		  If Not MoveFileOrFolder(folderMove, folderMoveTo) Then
		    PrintAndQuit("some error to move")
		  End If
		  
		  folderMove.Delete
		  
		  'Dim sh As New Shell
		  'Dim cmd As String
		  '
		  '#if TargetWin32
		  'If folderMoveStr.Right(1)= "\" Then folderMoveStr= folderMoveStr.Left(folderMoveStr.Len- 1)
		  'Dim afolderMove() As String= folderMoveStr.Split("\")
		  'Dim  folderMoveToTemp As String= folderMoveToStr
		  ''If folderMoveToStr.Right(1)= "\" Then folderMoveToTemp= folderMoveToStr.Left(folderMoveToStr.Len- 1)
		  ''
		  ''cmd= "rd /S /Q """+ folderMoveToTemp+ "\"+ afolderMove(afolderMove.Ubound)+ """"
		  ''System.DebugLog cmd
		  ''sh.Execute cmd
		  ''System.DebugLog sh.Result
		  ''
		  ''cmd= "move /Y """+ folderMoveStr+ """ """+ folderMoveToStr+ """"
		  ''System.DebugLog cmd
		  ''sh.Execute cmd
		  ''System.DebugLog sh.Result
		  '
		  'If folderMoveToStr.Right(1)<> "\" Then folderMoveToTemp= folderMoveToStr+ "\"
		  '
		  'cmd= "xcopy """+ folderMoveStr+ """ """+ folderMoveToTemp+ afolderMove(afolderMove.Ubound)+ """ /S /I /F /Y"
		  'System.DebugLog cmd
		  'sh.Execute cmd
		  'System.DebugLog sh.Result
		  '
		  'If sh.ErrorCode<> 0 Then PrintAndQuit("shell xcopy error", sh.ErrorCode)
		  '
		  'cmd= "rd /S /Q """+ folderMoveStr+ """"
		  'System.DebugLog cmd
		  'sh.Execute cmd
		  'System.DebugLog sh.Result
		  '#elseIf TargetMacOS Or TargetLinux
		  '
		  '#endif
		  
		  'Quit 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ProcessGitClone(theOption As Option)
		  If theOption.Value.IsNull Then PrintAndQuit("git url repo option is empty")
		  
		  Dim repoURL As String= theOption.Value.StringValue
		  If repoURL= "" Then PrintAndQuit("repo url to clone STR is empty")
		  
		  Dim toPathFolder As FolderItem
		  
		  Dim toPath As Option = mOptions.OptionValue(kOptionGitCloneToPath)
		  If toPath.WasSet Then
		    toPathFolder= toPath.Value
		  Else
		    toPathFolder= GetFolderItem("")
		  End If
		  
		  If toPathFolder Is Nil Then PrintAndQuit("cloneToPath DIR is nil")
		  If toPathFolder.Exists And toPathFolder.Directory Then PrintAndQuit("cloneToPAth DIR exist")
		  
		  Dim toPathFolderStr As String
		  #if RBVersion < 2013
		    toPathFolderStr= toPathFolder.AbsolutePath
		  #else
		    toPathFolderStr= toPathFolder.NativePath
		  #endif
		  
		  Dim userNameStr, userPwdStr As String
		  
		  Dim userName As Option = mOptions.OptionValue(kOptionGitUserName)
		  If userName.WasSet Then userNameStr= userName.Value.StringValue
		  
		  Dim userPwd As Option = mOptions.OptionValue(kOptionGitUserPwd)
		  If userPwd.WasSet Then userPwdStr= userPwd.Value.StringValue
		  
		  Dim cred As libgit2.Credentials
		  
		  If userNameStr<> "" And userPwdStr<> "" Then cred= New libgit2.Credentials(userNameStr, userPwdStr)
		  
		  libgit2.Init
		  
		  Try
		    libgit2.Clone repoURL, toPathFolderStr, cred, AddressOf HandlerCheckoutProgress
		  Catch e As RuntimeException
		    libgit2.Shutdown
		    PrintAndQuit e.Message, e.ErrorNumber
		  End Try
		  
		  libgit2.Shutdown
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ProcessProjectOptions(projectOption As Option)
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

	#tag Method, Flags = &h1
		Protected Sub ProcessTargetOS()
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

	#tag Method, Flags = &h1
		Protected Sub ProcessVersion()
		  Print ""
		  Print "Version: "+ App.ShortVersion
		  Print ""
		  
		  Quit 0
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mOptions As OptionParser
	#tag EndProperty


	#tag Constant, Name = kOptionFolderMove, Type = String, Dynamic = False, Default = \"folderMove", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionFolderMoveTo, Type = String, Dynamic = False, Default = \"folderMoveTo", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionFolderShellBase, Type = String, Dynamic = False, Default = \"folderShellBase", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionGitClone, Type = String, Dynamic = False, Default = \"gitClone", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionGitCloneToPath, Type = String, Dynamic = False, Default = \"gitCloneToPath", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionGitUserName, Type = String, Dynamic = False, Default = \"gitUserName", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionGitUserPwd, Type = String, Dynamic = False, Default = \"gitUserPwd", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionProject, Type = String, Dynamic = False, Default = \"project", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionReplaceText, Type = String, Dynamic = False, Default = \"replaceText", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionSearchText, Type = String, Dynamic = False, Default = \"searchText", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionTargetOS, Type = String, Dynamic = False, Default = \"targetOS", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = kOptionVersion, Type = String, Dynamic = False, Default = \"version", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = Version, Type = String, Dynamic = False, Default = \"0.0.230516", Scope = Protected
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Module
#tag EndModule
