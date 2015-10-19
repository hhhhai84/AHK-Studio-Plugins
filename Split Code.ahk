#SingleInstance,Force
;menu Split Code
global settings
x:=Studio(),settings:=x.get("settings"),cexml:=x.get("cexml"),sc:=x.sc,text:=sc.getuni(),ce:=x.get("Code_Explorer"),pos:=1,obj:=[],root:=cexml.ssn("//main[@file='" x.current(2).file "']"),newwin:=new GUIKeep("Split_Code"),bad:=new XML("bad"),top:=bad.ssn("//*"),newwin.add("ListView,w150 h200 ggo AltSubmit,Code,h","Edit,x+M w400 h200 -wrap,,wh","Text,xm y+3 section,Path:,y","Edit,x+M ys-3 w300,,wy","Button,xm gsplit Default,Split By Selected,y")
while,RegExMatch(text,ce.class,found,pos),pos:=found.Pos(1)+found.len(1){
	name:=SubStr(found.1,7),ea:=ea(ssn(root,"descendant::*[@type='Class' and @upper='" upper(name) "']")),end:=SubStr(text,ea.end,1)="}"?ea.end+1:ea.end,obj[found.1]:=(SubStr(text,ea.opos,end-ea.opos)),bad.under(top,"class",{start:ea.opos,end:ea.end}),list:=sn(root,"descendant::*[@type='Class']")
}pos:=1
while,RegExMatch(text,ce.function,found,pos),pos:=found.Pos(1)+found.len(1){
	if(bad.ssn("//class[@start<=" found.pos(1) " and @end>=" found.pos(1) "]")||found.1="if")
		Continue
	tt:=SubStr(text,found.Pos(1)),total:="",braces:=0,start:=0
	for a,b in StrSplit(tt,"`n"){
		line:=Trim(RegExReplace(b,"(\s+" Chr(59) ".*)")),total.=b "`n"
		if(SubStr(line,0,1)="{")
			braces++,start:=1
		if(SubStr(line,1,1)="}"){
			while,((found1:=SubStr(line,A_Index,1))~="(}|\s)"){
				if(found1~="\s")
					Continue
				braces--
			}
		}if(start&&braces=0)
			break
	}obj[found.1]:=Trim(total,"`n")
}newwin.show("Split Code")
ControlSetText,Edit2,% settings.ssn("//Split_Code").text,% newwin.id
for a,b in obj
	LV_Add("",a)
LV_Modify(1,"Select Vis Focus")
return
go:
LV_GetText(code,LV_GetNext())
ControlSetText,Edit1,% RegExReplace(obj[code],"\R","`r`n"),% newwin.id
return
upper(text){
	StringUpper,text,text
	return text
}
Split(){
	global obj,text,newwin,sc,x
	ControlGetText,dir,Edit2,% newwin.id
	dir:=dir?(SubStr(dir,0)="\"?dir:dir "\"):"",newtext:=text,current:=x.current(2).file
	SplitPath,current,,directory
	if(!FileExist(directory "\" dir))
		FileCreateDir,% directory "\" dir
	while,next:=LV_GetNext(){
		LV_GetText(info,next),tt:=obj[info],LV_Delete(next)
		if(FileExist(directory "\" dir info ".ahk")){
			oops:
			InputBox,info,File Conflict,Please enter a new filename (Without extension),,,,,,,,%info%
			if(ErrorLevel||info="")
				Continue
			if(FileExist(directory "\" dir info ".ahk"))
				goto,oops
		}
		StringReplace,newtext,newtext,% Trim(tt,"`n"),% "#Include " dir info ".ahk",All
		FileAppend,%tt%,% directory "\" dir info ".ahk",UTF-8
	}
	x.settext(newtext),LV_Modify(1,"Select Vis Focus"),x.SetTimer("Refresh_Project_Explorer",-1)
	ExitApp
}
Split_CodeEscape(){
	global newwin
	Split_Codeclose:
	ControlGetText,dir,Edit2,% newwin.id
	settings.add("Split_Code").text:=dir
	ExitApp
	return
}