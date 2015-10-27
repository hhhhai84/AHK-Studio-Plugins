#SingleInstance,Force
;menu Settings
SetBatchLines,-1
x:=Studio()
if(x.get("v").pluginversion<1){
	m("Please update AHK Studio to use this plugin")
	ExitApp
}
DetectHiddenWindows,On
global win,menus,newwin,menulist,searchlist,mn,commands,settings,ib
menus:=new XML("menus"),mn:=x.get("menus"),menus.xml.loadxml(mn[]),ib:=x.get("Icon_Browser")
win:="Settings",newwin:=new GUIKeep(win),settings:=x.get("settings")
commands:={"Add A New Menu":["!A","ANM"],"Change Item":["!C","CI"],"Add Separator":["!S","AS"],"Edit Hotkey":["Enter","EH"],"Re-Load Defaults":["","RD"],"Sort Menus":["","SM"],"Sort Selected Menu":["","SSM"],"Change Icon":["!I","CIcon"],"Remove Icon":["!^x","RI"],"Remove All Icons From Current Menu":["","RAICM"],"ReOrder Menu":["!r","ReOrder"],"Move Selected":["!^m","MS"],"Show Menu Tab":["!m","SMT"],"Show Options Tab":["!o","SOT"],"Add New Sub-Menu":["!U","ANSM"],"Remove All Icons":["","RAI"]}
newwin.add("Tab,w600 h30 Buttons,&Menus|&Options")
newwin.add("Edit,xm y+0 w600 gsearch,Search,w","ListView,xm w600 h200 gjump AltSubmit NoSort,Menu Item|Hotkey,w","TreeView,xm w180 h200 AltSubmit,,h","ListView,x+0 w420 h200 NoSort,Item|Hotkey|Hidden,wh","ListView,xm w600 ggo r10,Action (DoubleClick to Activate)|Hotkey,yw")
Gui,%win%:Tab,2
newwin.add("ListView,xm y+0 w600 h640 Checked AltSubmit,Options,wh")
Default(),Populate_Treeview(),Default("ListView","SysListView321"),LV_Add("","Found Menu Items From Search")
Loop,2
	LV_ModifyCol(A_Index,"AutoHDR")
Default("ListView","SysListView322")
Loop,3
	LV_ModifyCol(A_Index,"AutoHDR")
Default("ListView","SysListView323")
Loop,2
	LV_ModifyCol(A_Index,"AutoHDR")
Default("ListView","SysListView324")
all:=menus.sn("//*[@option='1']"),ts:=new XML("settings"),ts.xml.loadxml(settings[])
while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
	LV_Add(ts.ssn("//options/@" ea.clean).text?"Check":"",ea.clean)
TV(1),Search(1),hotkeys(),LV_ModifyCol(1,"Sort"),newwin.show("Settings")
GuiControl,%win%:+goptions,SysListView324
GuiControl,%win%:+gtv,SysTreeView321
return
/*
	{"*Del":"deletenode"}
	"^up":"moveup"
	"^down":"movedown"
	"^left":"moveover"
	"^right":"moveunder"
	Escape:"2GuiClose"})
*/
SettingsClose:
SettingsEscape:
mn.xml.loadxml(menus[]),x.SetTimer("menuwipe")
Sleep,500
x.SetTimer("menu"),newwin.exit()
return
ANM(){
	KeyWait,alt,U
	ControlGetFocus,focus,% newwin.id
	Default("TreeView","SysTreeView321"),TV_GetText(text,TV_GetSelection()),top:=menus.ssn("//*[@clean='" text "']")
	if(focus="SysListView322")
		item:=MenuInput("Item"),new:=menus.add("menu",{clean:clean(item),name:item},,1),top.InsertBefore(new,top.firstchild),tv(1)
	else
		item:=MenuInput(),new:=menus.add("menu",{clean:clean(item),name:item},,1),menus.under(new,"separator",{clean:"<Separator>"}),top.ParentNode.InsertBefore(new,top),Populate_TreeView(),tv(1)
}
ANSM(){
	KeyWait,alt,U
	ControlGetFocus,focus,% newwin.id
	Default("TreeView","SysTreeView321"),TV_GetText(text,TV_GetSelection()),top:=menus.ssn("//*[@clean='" text "']")
	item:=MenuInput()
	new:=menus.under(top,"menu",{clean:clean(item),name:item})
	next:=menus.under(new,"separator",{clean:"<Separator>"})
	Populate_TreeView()
	tv(1)
}
MenuInput(text:=""){
	InputBox,new,Add New Menu %text%,Enter the name of the new menu %text%
	if(ErrorLevel||new="")
		Exit
	if(menus.ssn("//*[@clean='" clean(new) "']"))
		return m("A Menu, Sub-Menu, or Item with this name already exists.","Please choose another")
	return new
}
/*
	Add New Sub-Menu{
		this will default to the TreeView and create a menu below the currently selected one
		refresh the TreeView
	}
*/
Clean(text,add:=0){
	add:=add?["_"," "]:[" ","_"]
	return RegExReplace(RegExReplace(text,add.1,add.2),"&")
}
Convert_Hotkey(key){
	StringUpper,key,key
	if(InStr(key,"^v"))
		return
	for a,b in [{Shift:"+"},{Win:"#"},{Ctrl:"^"},{Alt:"!"}]
		for c,d in b
			key:=RegExReplace(key,"\" d,c "+")
	return key
}
Default(type:="TreeView",control:="SysTreeView321"){
	Gui,%win%:Default
	Gui,%win%:%type%,%control%
}
Delete(){
	ControlGetFocus,Focus,% newwin.id
	if(focus="SysListView322"){
		Default("ListView","SysListView322"),LV_GetText(text,LV_GetNext()),mm:=menus.ssn("//*[@clean='" text "']"),next:=0
		if(mm.haschildnodes())
			return m("Not an empty menu.")
		if(GetKeyState("Shift","P")){
			parent:=mm.ParentNode
			if(m("Can Not Be Undone!","ico:!","btn:yn","def:2")){
				list:=[]
				while,next:=LV_GetNext(next)
					list.push(next-1)
				all:=sn(parent,"*")
				for a in list
					rem:=all.item[List[list.MaxIndex()-(A_Index-1)]],rem.ParentNode.RemoveChild(rem)
				checkempty(parent)
			}
			tv(1)
		}else
			while,next:=LV_GetNext(next)
				LV_GetText(text,next),mm:=menus.ssn("//*[@clean='" text "']"),ea:=menus.ea(mm),(ea.hide)?(state:="No",mm.RemoveAttribute("hide")):(state:="Yes",mm.SetAttribute("hide",1)),LV_Modify(next,"Col3",state)
	}if(focus="SysTreeView321"){
		return m("Can not delete a menu that has sub-menus","Please delete or move all sub-menus first")
	}
}
checkempty(parent){
	if(!sn(parent,"*").length)
		parent.ParentNode.RemoveChild(parent),Populate_TreeView()
}
EH(){
	global x
	static nw,ea,menu
	Default("ListView","SysListView322")
	if(!LV_GetNext())
		return m("Please select a menu item to change first")
	LV_GetText(menu,LV_GetNext()),ea:=menus.ea("//*[@clean='" menu "']"),nw:=new GUIKeep("Edit_Hotkey"),nw.add("Hotkey,w240 vhotkey gEditHotkey","Edit,w240 vedit gCustomHotkey","ListView,w240 h220,Duplicate Hotkey Definitions"),nw.show("Edit Hotkey")
	GuiControl,Edit_Hotkey:,msctls_hotkey321,% ea.hotkey
	return
	Edit_HotkeyEscape:
	Edit_HotkeyClose:
	hotkey:=nw[].hotkey
	Gui,Edit_Hotkey:Default
	if(!hotkey&&nw[].edit)
		if(m("btn:yn","def:2","ico:!","Creating a hotkey that doesn't exist could cause AHK-Studio to stop working.","Are you sure?")="no")
			Goto,ehclose
	StringUpper,uhotkey,hotkey
	dup:=menus.sn("//*[@hotkey='" hotkey "' or @hotkey='" uhotkey "']")
	if(dup&&hotkey&&dup.length>=1){
		if(m("Replace this as the default item for " hotkey "?","btn:yn")="Yes"){
			while,dd:=dup.item[A_Index-1],ea:=xml.ea(dd){
				;in here do the TV_Modify(line and column 2 change)
				dd.RemoveAttribute("hotkey") ;,mo.ssn("//*[@clean='" ea.clean "']").RemoveAttribute("hotkey")
			}
		}else
			Goto,ehclose
	}
	menus.ssn("//*[@clean='" menu "']").SetAttribute("hotkey",hotkey),Default("ListView","SysListView321"),LV_Modify(searchlist[menu],"Col2 Select Vis Focus",Convert_Hotkey(hotkey)),Default("ListView","SysListView322"),LV_Modify(LV_GetNext(),"Col2",Convert_Hotkey(hotkey)),search(),tv(1),nw.savepos()
	ehclose:
	Gui,Edit_Hotkey:Destroy
	WinActivate,% newwin.id
	return
	CustomHotkey:
	edit:=nw[].edit
	GuiControl,Edit_Hotkey:,msctls_hotkey321,%edit%
	;LV_Modify(searchlist[ea.clean],"Col2",Convert_Hotkey(edit))
	return
	EditHotkey:
	hotkey:=nw[].hotkey
	Gui,Edit_Hotkey:Default
	StringUpper,uhotkey,hotkey
	dup:=menus.sn("//*[@hotkey='" hotkey "' or @hotkey='" uhotkey "']")
	LV_Delete()
	while,dd:=dup.item[A_Index-1],ea:=xml.ea(dd){
		if(ea.clean!=menu)
			LV_Add("",ea.clean)
	}
	return
}
Enable(control,On:=0){
	Gui,%win%:Default
	GuiControl,% win ":" flan:=(on?"+":"-"),%control%
}
Go(){
	Default("ListView","SysListView323")
	LV_GetText(text,LV_GetNext())
	item:=commands[text].2
	if(IsFunc(item))
		%item%()
	else if(IsLabel(item))
		SetTimer,%item%,-1
	else
		m("Coming soon.")
}
Hotkeys(){
	Hotkey,IfWinActive,% newwin.id
	Default("ListView","SysListView323")
	for a,b in commands{
		LV_Add("",a,Convert_Hotkey(b.1))
		if((IsLabel(b.2)||IsFunc(b.2))&&b.1)
			Hotkey,% b.1,% b.2,On
	}
	Hotkey,~*Delete,Delete,On
	Loop,2
		LV_ModifyCol(A_Index,"AutoHDR")
}
Jump(){
	Default("ListView","SysListView321")
	if(!next:=LV_GetNext())
		return
	LV_GetText(menu,next)
	current:=menus.ssn("//*[@clean='" menu "']")
	TV_Modify(ssn(current.ParentNode,"@tv").text,"Select Vis Focus")
	Default("ListView","SysListView322")
	LV_Modify(0,"-Select")
	count:=0
	while,!menulist[menu]{
		Sleep,10
		if(count=400)
			Break
		count++
	}
	LV_Modify(menulist[menu],"Select Vis Focus")
}
MS(){
	static nw,list,parent
	next:=0,list:=[]
	Default("TreeView","SysTreeView321"),TV_Get(parent,TV_GetSelection()),Default("ListView","SysListView322")
	if(!LV_GetNext())
		return m("Select some items to move first")
	while,next:=LV_GetNext(next),LV_GetText(text,next)
		list.push(text)
	nw:=new GUIKeep("Select_Menu"),nw.add("TreeView,w400 h500 gmovesel,,wh","Button,gmovesel Default,Move To Selected Menu"),nw.show("Select Menu"),Populate_TreeView()
	return
	movesel:
	if(A_GuiEvent!="DoubleClick"&&A_GuiControl!="Move To Selected Menu")
		return
	Gui,Select_Menu:Default
	TV_GetText(me,TV_GetSelection()),top:=menus.ssn("//*[@clean='" me "']"),before:=top.firstchild
	for a,b in list
		top.insertbefore(menus.ssn("//*[@clean='" b "']"),before)
	checkempty(menus.ssn("//*[@clean='" parent "']"))
	Select_MenuClose:
	Select_MenuEscape:
	Gui,Select_Menu:Destroy
	Default("TreeView","SysTreeView321"),Populate_TreeView()
	WinActivate,% newwin.id
	return
}
Options(){
	global x
	el:=ErrorLevel,ev:=A_EventInfo
	if(A_GuiEvent="I"&&InStr(el,"c")){
		Default("ListView","SysListView324")
		LV_GetText(text,ev)
		/*
			;change options to match
			node:=settings.ssn("//options")
			if(el~="\bC\b")
				node.SetAttribute(text,1)
			if(el~="\bc\b")
				node.RemoveAttribute(text)
		*/
		x.SetTimer(text,-100)
	}
}
Populate_Search(){
	Default("ListView","SysListView321")
	all:=menus.sn("//*[@clean!='']"),LV_Delete()
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
		LV_Add("",ea.clean,Convert_Hotkey(ea.hotkey))
	Loop,2
		LV_Modify(A_Index,"AutoHDR")
	LV_ModifyCol(1,"Sort")
}
Populate_TreeView(){
	global x
	TV_Delete(),all:=menus.sn("//descendant::*")
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa){
		if(aa.haschildnodes()&&ea.clean)
			aa.SetAttribute("tv",TV_Add(ea.clean,ssn(aa.ParentNode,"@tv").text,"Vis"))
	}
	TV_Modify(TV_GetChild(0),"Select Vis Focus")
}
RD(){
	global x
	if(m("Are you sure?","btn:yn","ico:?","def:2")="No")
		return
	mn.save(1),plugins:=menus.ssn("//*[@clean='Plugin']").clonenode(1)
	FileCopy,% x.path() "\lib\menus.xml",% x.path() "\lib\menus Backup - " A_Now ".xml",1
	hotkeys:=mn.sn("//*[@hotkey!='']")
	SplashTextOn,,40,Downloading Required Files,Please Wait...
	URLDownloadToFile,http://files.maestrith.com/AHK-Studio/menus.xml,temp.xml
	menus.xml.load("temp.xml")
	while,hh:=hotkeys.item[A_Index-1],ea:=xml.ea(hh)
		menus.ssn("//*[@clean='" ea.clean "']").SetAttribute("hotkey",ea.hotkey)
	SplashTextOff
	menus.ssn("//main").AppendChild(plugins)
	Populate_TreeView(),Populate_Search(),tv(1)
	FileDelete,temp.xml
	return
}
ReOrder(){
	static nw,wn,menu
	Default("TreeView","SysTreeView321"),TV_GetText(menu,TV_GetSelection()),wn:="ReOrder_Menu",nw:=new GUIKeep(wn),nw.add("ListView,w400 h400,Menu Name,wh","Button,gup,&Up,y","Button,gdown,&Down,y"),nw.show("ReOrder Menu"),all:=menus.sn("//*[@clean='" menu "']/*")
	Hotkey,IfWinActive,% nw.id
	for a,b in ["Up","Down"]
		Hotkey,^%b%,%b%,on
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
		LV_Add("",ea.clean)
	return
	up:
	Down:
	Gui,ReOrder_Menu:Default
	list:=[],next:=0,add:=A_ThisLabel="up"?1:-1
	while,next:=LV_GetNext(next)
		if((A_ThisLabel="up"&&next!=A_Index)||(A_ThisLabel="Down"&&next!=LV_GetCount()))
			list.push(next)
	Loop,% list.MaxIndex()
		next:=A_ThisLabel="down"?list[list.MaxIndex()-(A_Index-1)]:list[A_Index],LV_GetText(text,next),LV_Delete(next),LV_Modify(LV_Insert(next-add,"",text),"Select Vis Focus")
	return
	ReOrder_MenuClose:
	ReOrder_MenuEscape:
	Gui,ReOrder_Menu:Default
	top:=menus.ssn("//*[@clean='" menu "']")
	Loop,% LV_GetCount()
		LV_GetText(text,A_Index),item:=menus.ssn("//*[@clean='" text "']"),top.AppendChild(item)
	nw.savepos()
	Gui,ReOrder_Menu:Destroy
	WinActivate,% newwin.id
	TV(1),Search(1)
	return
}
Search(info:=0){
	ControlGetText,search,Edit1,% newwin.id
	search:=info=1?"":search,searchlist:=[],Enable("SysListView321"),Default("ListView","SysListView321")
	all:=menus.sn("//menu[@clean!='']"),LV_Delete()
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
		if(!aa.haschildnodes()&&(InStr(ea.clean,search)||InStr(ea.hotkey,search)))
			searchlist[ea.clean]:=LV_Add("",ea.clean,Convert_Hotkey(ea.hotkey))
	Loop,2
		LV_ModifyCol(A_Index,"AutoHDR")
	Enable("SysListView321",1)
}
Tabs(){
	SMT:
	SOT:
	tab:=A_ThisLabel="smt"?1:A_ThisLabel="sot"?2:1
	GuiControl,%win%:Choose,SysTabControl321,%tab%
	return
}
TV(tv:=0){
	static init:=0
	if(A_GuiEvent~="i)i|s|normal"||tv=1){
		Default("ListView","SysListView322"),Enable("SysListView322"),LV_Delete(),list:=menus.sn("//*[@tv='" TV_GetSelection() "']/*"),menulist:=[]
		while,ll:=list.item[A_Index-1],ea:=xml.ea(ll){
			menulist[ea.clean]:=LV_Add("Icon" changeicon.add(ea.filename,ea.icon),ea.clean,Convert_Hotkey(ea.hotkey),ea.hide?"Yes":"No")
			if(ea.icon&&changeicon.init!=1)
				changeicon.start()
			if(ea.select)
				select:=A_Index,ll.RemoveAttribute("select")
		}
		Loop,3
			LV_ModifyCol(A_Index,"AutoHDR")
		Enable("SysListView322",1),LV_Modify(0,"-Select")
		if(select)
			LV_Modify(select,"Select Vis Focus")
	}
}
AS(){
	Default("TreeView","SysTreeView321"),TV_GetText(text,TV_GetSelection()),top:=menus.ssn("//*[@clean='" text "']"),Default("ListView","SysListView322"),next:=LV_GetNext()?LV_GetNext():1,LV_GetText(text,next),current:=menus.ssn("//*[@clean='" text "']"),new:=menus.add("separator",{clean:"<Separator>"},,1),current.ParentNode.InsertBefore(new,current),tv(1)
}
CI(){
	KeyWait,Alt,U
	Default("ListView","SysListView322"),LV_GetText(item,LV_GetNext()),node:=menus.ssn("//*[@clean='" item "']")
	if(node.nodename="")
		return m("Please select an item to change")
	if(node.nodename!="menu")
		return m("Can not change separators")
	ea:=xml.ea(node)
	InputBox,new,Change Menu Item Name,New menu item name?,,,,,,,,% ea.name
	if(ErrorLevel||new="")
		return
	node.SetAttribute("select",1)
	node.SetAttribute("clean",clean(new))
	node.SetAttribute("name",new)
	tv(1)
}
CIcon(){
	KeyWait,Alt,U
	Default("ListView","SysListView322"),LV_GetText(item,LV_GetNext()),node:=menus.ssn("//*[@clean='" item "']")
	if(!LV_GetNext())
		return m("Select an item to change an icon")
	if(node.nodename!="menu")
		return m("Can not add icons to separators")
	icon:=new ib(0,0,"Testing","Shell32.dll",0,changeicon,newwin.hwnd)
}
class changeicon{
	static il:=IL_Create(),icons:=[],init:=0
	add(file,icon){
		ic:=changeicon.icons
		if((item:=Icon[file,icon])="")
			item:=ic[file,icon]:=IL_Add(changeicon.il,file,icon)
		return item
	}
	start(){
		LV_SetImageList(changeicon.il),changeicon.init:=1,IL_Add(changeicon.il,"Shell32.dll",50)
	}
	call(file,icon){
		static init:=0
		Default("ListView","SysListView322"),LV_Modify(LV_GetNext(),"Icon" changeicon.add(file,icon)),LV_GetText(item,LV_GetNext()),mm:=menus.ssn("//*[@clean='" item "']"),att(mm,{filename:file,icon:icon})
		if(!changeicon.init)
			changeicon.start()
	}
}
RAI(){
	all:=menus.sn("//*[@icon!='']")
	while,aa:=all.item[A_Index-1]{
		for a,b in ["icon","filename"]
			aa.RemoveAttribute(b)
	}
	tv(1)
}
RAICM(){
	Default("TreeView","SysTreeView321"),TV_GetText(item,TV_GetSelection())
	all:=menus.sn("//*[@clean='" item "']/*[@icon!='']")
	while,aa:=all.item[A_Index-1]
		for a,b in ["icon","filename"]
			aa.RemoveAttribute(b)
	tv(1)
}
RI(){
	Default("ListView","SysListView322"),LV_GetText(item,LV_GetNext())
	node:=menus.ssn("//*[@clean='" item "']")
	node.SetAttribute("select",1)
	for a,b in ["filename","icon"]
		node.RemoveAttribute(b)
	tv(1)
}
SM(){
	all:=menus.sn("//main/descendant::*"),toplist:=[]
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
		if(aa.haschildnodes())
			toplist.push(ea.clean)
	for a,b in toplist{
		top:=menus.ssn("//*[@clean='" b "']"),menu:=menus.sn("//*[@clean='" b "']/*"),order:=[]
		while,mm:=menu.item[A_Index-1],ea:=xml.ea(mm)
			order[ea.clean]:=mm
		for a,b in order
			top.AppendChild(b)
	}
	TV(1)
}SSM(){
	Default("TreeView","SysTreeView321"),TV_GetText(item,TV_GetSelection())
	all:=menus.sn("//*[@clean='" item "']/descendant::*"),toplist:=[]
	while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
		if(aa.haschildnodes())
			toplist.push(ea.clean)
	if(!toplist.1)
		toplist.push(item)
	for a,b in toplist{
		top:=menus.ssn("//*[@clean='" b "']"),menu:=menus.sn("//*[@clean='" b "']/*"),order:=[]
		while,mm:=menu.item[A_Index-1],ea:=xml.ea(mm)
			order[ea.clean]:=mm
		for a,b in order
			top.AppendChild(b)
	}
	TV(1)
}