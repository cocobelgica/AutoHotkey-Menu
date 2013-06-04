class menu
{

	static _init_ := menu.__INIT__()
	static destroy := Func("MENU_delete")

	class _properties_
	{

		__Call(target, name, params*) {
			if !(name ~= "i)^(base|__Class)$") {
				return ObjHasKey(this, name)
				       ? this[name].(target, params*)
				       : this.__.(target, name, params*)
			}
		}
	}
	
	__New(arg) {
		ObjInsert(this, "_", []) ; proxy object
		
		if !(name := IsObject(arg) ? (arg.HasKey("name") ? arg.name : 0) : arg)
			throw Exception("Menu name not specified.", -1)
		try (this.name := name)
		catch e
			throw Exception(e.Message, -1)
		
		for k, v in arg {
			if !(k ~= "i)^(standard|color|icon)$")
				continue
			this[k] := v
		}
	}

	__Delete() {
		try {
			if this.isMenu
				this.destroy()
		}	
		OutputDebug, Class: menu released.
	}

	__Set(key, value, p*) {
		
		if (key = "name") {
			if this._.HasKey(key)
				throw Exception("The 'name' property is read-only.", -1)
			if (MENU_handle(value) && value <> "Tray")
				throw Exception("Menu name already exists.", -1)
			
			this._.Insert(key, value)
			this[value] := true
			this.item := new menu._menuitems_(this)
			if (value = "Tray") {
				Menu, % value, NoStandard
				this.standard := true
			} else for i, j in ["Standard", "NoStandard"]
				Menu, % value, % j

			init_handle := this.handle
			return true
		}
		
		if (key == this.name)
			return MENU_list([key, value ? this : false]*)

		if (key = "default") {
			Menu, % this.name, Default
			    , % value ? (IsObject(value) ? value.name : value) : ""
		}

		if (key = "standard") {
			std := this.standard ? 1 : 0
			;cmd := {0: "NoStandard"
			;    ,   1: "Standard"
			;    ,   2: ({0: "Standard", 1: "NoStandard"}[std])}[value]
			
		    value := {"$": {0:false, 1:true, 2:{0:true, 1:false}[std]}[value]
		          ,   "@": (value ? this.count+1 : 0)}
		    
		    p := (s := value["$"]) ? this.count : this.standard+10
		    Loop, % (s ? (std ? 0 : 10) : (std ? 10 : 0))
		    	idx := p+(s ? A_Index : -A_Index)
		    	, this.item[idx] := s
		    	                 ? new menu._item_(this, {name: {idx:A_Index}})
		    	                 : ""
		}

		if (key = "color") {
			sg := {1: 1, 0: 0, "true": 1, "false": 0, single: 1, "": 0}
			if IsObject(value) {
				mi := value.MinIndex() ? true : false
				Menu, % this.name, Color
				    , % (v := mi ? value.1 : value.value)
				    , % (s := sg[mi ? value.2 : value.single]) ? "Single" : ""
			
			} else {
				RegExMatch(value, "iO)^(.*)[,\|\s](1|0|true|false|single)$", cv)
				Menu, % this.name, Color
				    , % (v := cv ? cv.1 : value)
				    , % (s := sg[cv ? cv.2 : 0]) ? "Single" : ""
			}
			value := {value: v, single: s}
		}

		if (key = "gui") {
			Gui, % (value ? value : this.gui) ":Menu"
			   , % (value ? this.name : "")
		}

		if (key = "item") {
			if p.MinIndex()
				return (this.item)[value] := p.1
		}
		; TRAY Menu only
		if (key ~= "i)^(icon|file|number|tip|click)$") {
			if (this.name <> "Tray")
				throw Exception("Menu name must be 'Tray'.", -1)
			
			if (key <> "icon") {
				if (this.__Class <> "_trayicon_")
					throw Exception("Invalid target object!", -1)
				return this.icon[key] := value
			}

			if p.1 {
				if (value ~= "i)^(tip|click)$")
					Menu, % this.name, % value, % p.1
				if (value ~= "i)^(file|number)$") {
					x := {file: [p.1, this.icon.number], number: [this.icon.file, p.1]}[value]
					Menu, % this.name, Icon, % x.1, % x.2
				}
			
			} else {
				if IsObject(value) {
					for k, v in value
						if (k ~= "i)^(file|number|tip|click)$")
							this.icon[k] := v
				} else if (value ~= "^[0-2]$") {
					Menu, % this.name
					    , % {0: "NoIcon"
					       , 1: "Icon"
					       , 2: {0: "NoIcon", 1: "Icon"}[A_IconHidden]}[value]
				} else if RegExMatch(value, "Oi)^([^\,]+|)(?:,|$)(\d+|)(?:,|$)(1|2|)(?:,|$)(.*)$", m) {
					for k, v in ["file", "number", "click", "tip"] {
						if (m[k] == "")
							continue
						this.icon[v] := m[k]
					}
				}
			}
			return true
		}
		
		return this._[key] := value
	}

	class __Get extends menu._properties_
	{

		__(key, params*) {
			if ObjHasKey(this._, key)
				return this._[key, params*]

			if (key ~= "i)^(hMenu|hwnd)$")
				return this.handle[params*]

			if (key ~= "i)^(file|number|tip)$") {
				if (this.__Class <> "_trayicon_")
					throw Exception("Invalid target object!", -2)
				return this.icon[key]
			}

			return false
		}

		isMenu(p*) {
			return DllCall("IsMenu", "Ptr", this.hwnd)
		}

		handle(p*) {
			if DllCall("IsMenu", "Ptr", this._.handle)
				return this._.handle
			return this._.handle := MENU_handle(this.name)
		}

		count(p*) {	
			return (c := DllCall("GetMenuItemCount", "Ptr", this.hwnd)) < 0 ? 0 : c
		}
		
		standard(p*) {
			if !this._.HasKey("standard")
				return false
			for x, y in this.item.()
				pos := x
			until (std := (y.type = "Standard"))
			return std ? (p.1 ? this._.standard[p.1] : pos) : false
		}

		default(p*) {
			idx := DllCall("GetMenuDefaultItem"
			             , "Ptr", this.hwnd
			             , "UInt", true
			             , "UInt", 0x0001L) ; GMDI_USEDISABLED
			
			return (idx >= 0) ? (this.item)[idx+1] : false
		}
		; TRAY Menu only
		icon(p*) {
			static _base_ := {__Set: menu.__Set, __Get: menu.__Get, __Class: "_trayicon_"}
			
			if (this.name <> "Tray")
				throw Exception("Menu name must be 'Tray'.", -2)
			
			if p.1 {			
				if (p.1 ~= "i)^(tip|number)$")
					return {tip: (A_IconTip ? A_IconTip : A_ScriptName)
					      , number: (A_IconNumber ? A_IconNumber : 1)}[p.1]
				if (p.1 = "file") {
					file := A_IconFile ? A_IconFile : false
					if file
						SplitPath, file, name
					return file ? (FileExist(file) ? file : name) : A_AhkPath
				}
			
			} else {
				obj := {base: _base_} , obj.Insert("_", {name: this.name})
				return obj
			}
		}
	
	}

	add(item:="") {
		if !IsObject(this.item)
			this.item := new menu._menuitems_(this)
		mi := new menu._item_(this, item)
		this.item[this.count] := mi
	}

	insert(p1:=0, p2:=0) {
		this.add((mi := IsObject(p1)) ? p1 : "")
		this.item[this.count].pos := mi ? p2 : p1
	}

	delete(item:="") {
		if item
			this.item[item] := ""
		else (this.item := "")
	}

	show(x:="", y:="", coordmode:="") {
		if (coordmode && (x <> "" || y <> "")) {
			if (coordmode ~= "i)^(Screen|Relative|Window|Client)$")
				CoordMode, Menu, % coordmode
		}	
		Menu, % this.name, Show, % x, % y
	}

	attach(gui:=false) {
		this.gui := gui
	}

	class _menuitems_
	{
		
		static _keys_ := menu._menuitems_.__([[], [], []])

		__New(self) {		
			for a, b in this.base._keys_
				this.Insert(b, (a <= 2 ? [] : self.name))
		}

		__Set(key, value, p*) {
			if (key ~= "^\d+$") {
				if (IsObject(value) && value.__Class = "menu._item_") {
					if (value.type ~= "i)^(Normal|Submenu)$")
						this.ins([value.name, true], 2)
				
				} else {
					if (this[key].type ~= "i)^(Normal|Submenu)$")
						this.del(this[key].name, 2)
					this.set([key, ""]) , this.del(key)
					return true
				}
			
			} else if this.has(key, 2)
				return this[this[key].pos] := value

			return this.ins([key, value])
			;return this.set([key, value])
		}

		class __Get extends menu._properties_
		{

			__(key, params*) {
				if this.has(key)
					return this.get([key, params*])
				else if this.has(key, 2) {
					for a, b in this.()
						idx := a
					until (n := (b.name = key))
					return n ? this[idx] : false
				}
			}
		}

		__Call(method, params*) {
			
			if (method ~= "i)^(get|set|ins|has|del)$") {
				m := {ins: "Insert", del: "Remove", has: "HasKey", get: 1, set: 0}[method]
				k := this.__(params.2 ? params.2 : 1)
				p := IsObject(params.1) ? params.1 : [params.1]

				return (m ~= "i)[A-Z]+")
				       ? (this[k])[m](p*)
				       : (m ? this[k][p*] : (this[k][p.1] := p.2))
			}

			if (method = "max") {
				for a in this.()
					idx := A_Index
				return idx ? idx : 0
			}

			if (method = "menu") {
				return MENU_obj(this[this.__(3)])
			}

			if (method ~= "i)^(delete|move)$")
				return this["$"](params*)

			if !method
				return this[this.__(params.1 ? params.1 : 1)]
		}

		; PRIVATE
		__(k) {
			static keys

			return keys ? ((k == keys) ? 0 : (keys.HasKey(k) ? keys[k] : 0)) : (keys := k)
		}

		$(item, pos:=false) {
			self := this.menu()

			if pos
				this.ins([pos, this.del(item.pos)])
			
			Menu, % self.name, DeleteAll
			Menu, % self.name, NoStandard

			for k, v in this.() {
				if (!pos && v == item)
					continue
				if (v.type = "Standard") {
					if (k = self.standard)
						Menu, % self.name, Standard
					continue
				}
				Menu, % self.name, Add
				    , % v._.name
				    , % (v._.name <> "") ? "MenuItemEventHandlerLabel" : ""
			    for x, y in v._ {
			    	if (x ~= "i)^(name|menu)$")
			    		continue
			    	this[k][x] := y
			    }
			}
		}
	
	}

	class _item_
	{

		__New(self, item) {
			this.Insert("_", {menu: self.name})
			
			this.name := IsObject(item) ? item.name : ""
			if (this.type = "Normal") {
				item.target := item.Haskey("target") ? item.target : ""
				for a, b in item {
					if !(a ~= "i)^(target|icon|enable|check|default)$")
						continue
					this[a] := b
				}
			}
		}

		__Delete() {
			if this.menu.isMenu {
				self := this.menu
				if (this.type ~= "i)^(Normal|Submenu)$")
					Menu, % self.name, Delete, % this.name
				else if (this.type = "Separator")
					self.item.delete(this)
				else if (this.type = "Standard") {
					if (this._.name.idx == 1)
						Menu, % self.name, NoStandard
				}
			}
			;OutputDebug, % "Class: " this.__Class " released"
		}

		__Set(key, value) {
			self := this.menu

			if (key = "name") {
				if this._.HasKey(key) {
					if (this.type ~= "i)^(Standard|Separator)$") ; <stditem>
						return false
					if (this.name = value)
						return false
					self.item.del(this.name, 2)
					Menu, % self.name, Rename, % this.name, % value
					self.item.ins([this.name, true], 2)
				} else {
					if IsObject(value) {
						if (value.idx == 1)
							Menu, % self.name, Standard
					} else Menu, % self.name, Add
					           , % value
					           , % (value <> "") ? "MenuItemEventHandlerLabel" : ""
				}
			}

			if (key = "target") {
				sm := ((sm1:=(value~="^:")) || value.IsMenu)
				   ?  (sm1 ? value : ":" value.name)
				   :  false
					
				if sm
					Menu, % self.name, Add, % this.name, % sm
	    		
	    		value := (value == "")
	    		      ?  this.name
	    		      :  (sm
	    		         ? sm
	    		         : (RegExMatch(value, "O)^(.*)(\(\)|:)$", m)
	    		           ? ({"()":1,":":0}[m.2] ? Func(m.1) : m.Value)
	    		           : value))
			}
			
			if (key = "icon") {
				if RegExMatch(value, "O)^(.*),(\d+)$", icon)
					Menu, % self.name, Icon, % this.name, % icon.1, % icon.2
				else
					Menu, % self.name, Icon, % this.name, % value
			}

			if (key ~= "i)^(check|enable)$") {
				cmd := {check: {1: "Check", 0: "Uncheck", 2: "ToggleCheck"}
			        ,   enable: {1: "Enable", 0: "Disable", 2: "ToggleEnable"}}[key, value]
		        
		        Menu, % self.name, % cmd, % this.name
			}

			if (key = "default")
				self.default := value ? this.name : false

			if (key = "pos") {
				if !(value >= 1 && value <= self.count && value <> this.pos)
					return false
				if (pos := self.standard) {
					if (value > this.pos && value >= pos && value < (pos+9))
						return false
					if (value < this.pos && value > pos && value <= (pos+9))
						return false
				}
				self.item.move(this, value)
				return true
			}

			return this._[key] := value
		}

		class __Get extends menu._properties_
		{

			__(key, params*) {
				if ObjHasKey(this._, key)
					return this._[key, params*]
				if (key ~= "i)^(f(Type|State)|(w|)ID|hSubmenu|dwTypeData)$")
					return MENU_mii(this.menu.handle, this.pos, (key = "id") ? "wID" : key)
			}

			name(p*) {
				static NULL := ""

				if (this.type = "Separator")
					return NULL
				return this.dwTypeData
			}

			target(p*) {
				t := this._.target
				return p.1
				       ? t
				       : (IsObject(t)
				         ? t.Name
				         : (RegExMatch(t, "O)^(.*):$", m) ? m.1 : t))
			}

			menu(p*) {
				return MENU_obj(this._.menu)
			}

			pos(p*) {
				self := this.menu
				Loop, % self.count
					pos := A_Index
				until ((self.item)[pos] == this)
				return pos
			}

			type(p*) {
				wID := this.id , fType := this.fType , std := IsObject(this._.name)
				id := wID ? ((fType<>2048) ? (this.hSubmenu ? -1 : 1) : fType) : fType
				return std
				       ? "Standard"
				       : {1:"Normal", 2048:"Separator", -1:"Submenu", 0:"NULL"}[id]
			}

			check(p*) {
				return (this.fState & 0x8) ? true : false
			}

			enable(p*) {
				return (this.fState & 0x3) ? false : true
			}
		
		}

		onEvent() {
			t := ((t:=this.target[1])~=":$" ? this.target : t)
			lbl := IsLabel(t) , fn := IsFunc(t) , obj := IsObject(t)
			if (lbl && (!fn || (fn && !obj)))
				SetTimer, % this.target, -1
			else if (fn && (!lbl || (lbl && obj)))
				return (this.target).(this)
			return
			MenuItemEventHandlerLabel:
			MenuItemEventHandlerTimerLabel:
			if InStr(A_ThisLabel, "Timer")
				menu.thisItem.onEvent()
			else SetTimer, MenuItemEventHandlerTimerLabel, -1		
			return
		}
	
	}

	__INIT__() {
		static init
		static $ := menu.Remove("_init_")

		if init ; call once
			return
		menu.base := menu.__BASE__
		init := true
	}

	class __BASE__
	{

		class __Get extends menu._properties_
		{

			__(key, p*) {
				if RegExMatch(key, "Oi)^(this(Menu|Item))$", m)
					return MENU_obj({menu: [A_ThisMenu]
					               , item: [A_ThisMenu, A_ThisMenuItem]}[m.2]*)
				
				return MENU_obj(key, p*)
			}
		
		}
	
	}

}
; PUBLIC FUNCTIONS
MENU_delete(ByRef this) {
	if (!IsObject(this) || (this.base <> menu))
		throw Exception("[Invalid Parameter] Not a menu object.", -1)

	this[this.name] := false
	this.item := ""
	Menu, % this.name, Delete
	return IsByRef(this) ? (true, this := "") : false
}

MENU_obj(name, p*) {
	if MENU_list(name, 2) {
		m := MENU_list(name)
		return p.1 ? (IsObject(mi:=m.item[p.1]) ? mi : false) : m
	}
}

MENU_handle(name) {
	static mDummy := "MENU_dummy_" A_TickCount
	static hDummy

	if !hDummy {
		Menu, % mDummy, Add
		Menu, % mDummy, DeleteAll
		Gui, New, +LastFound
		Gui, Menu, % mDummy
		hDummy := DllCall("GetMenu", "Ptr", WinExist())
		Gui, Menu
		Gui, Destroy
		if !hDummy
			return false
	}

	if MENU_obj(name).gui {
		Gui, New, +LastFound
		try Gui, Menu, % name
		catch {
			Gui, Destroy
			return false
		}
		hMenu := DllCall("GetMenu", "Ptr", WinExist())
		Gui, Menu
		Gui, Destroy
	
	} else {
		try Menu, % mDummy, Add, % ":" name
		catch
			return false
		hMenu := DllCall("GetSubMenu", "Ptr", hDummy, "Int", 0)
		DllCall("RemoveMenu", "Ptr", hDummy, "UInt", 0, "UInt", 0x400)
		Menu, % mDummy, Delete, % ":" name
	}

	return DllCall("IsMenu", "Ptr", hMenu) ? hMenu : false
}

MENU_mii(hMenu, pos, field:="dwTypeData") {
	static fMask := 4
	static _ := {fType:[256,8], fState:[1,12], wID:[2,16], hSubmenu:[4,20], dwTypeData:[64,36]}

	VarSetCapacity(MII, 48, 0)
	NumPut(48, MII, 0)
	NumPut(_[field,1], MII, fMask)
	DllCall("GetMenuItemInfo", "Ptr", hMenu, "UInt", pos-1, "UInt", true, "UInt", &MII)
	
	if (field = "dwTypeData") {
		len := NumGet(MII, 40, "Int")
		VarSetCapacity(text, (len+1)*(A_IsUnicode ? 2 : 1), 0)
		NumPut(len+1, MII, 40) , NumPut(&text, MII, _[field,2])
		DllCall("GetMenuItemInfo", "Ptr", hMenu, "UInt", pos-1, "UInt", true, "UInt", &MII)
		
		return StrGet(NumGet(MII, _[field,2]))
	}

	return NumGet(MII, _[field,2])
}

MENU_from(src) {
	static MSXML := "MSXML2.DOMDocument" (A_OSVersion ~= "(7|8)" ? ".6.0" : "")
	, xpr := ["*[translate(name(), 'MENU', 'menu')='menu']"
	      ,   "*[translate(name(), 'ITEM', 'item')='item']"
	      ,   "@*[translate(name(), 'NAME', 'name')='name']"
	      ,   "i)^(name|target|icon|check|enable|default)$"]
	
	if !IsObject(menu)
		throw Exception("Cannot create menu(s) from XML source. "
		      . "Super-global variable 'menu' is not an object.", -1)
	
	x := ComObjCreate(MSXML)
	x.async := false

	; Load XML source
	if (src ~= "s)^<.*>$")
		x.loadXML(src)
	else if ((f:=FileExist(src)) && !(f ~= "D"))
		x.load(src)
	else throw Exception("Invalid XML source.", -1)

	m := [] , mn := []
	_m_ := x.selectNodes("//" xpr.1 "[" xpr.3 "]")
	
	; Create menu(s)
	Loop, % (len := _m_.length) {
		node := _m_.item(A_Index-1) , $mp := []
		Loop, % (_mp_ := node.attributes).length
			mp := _mp_.item(A_Index-1)
			, $mp[mp.name] := mp.value
		mn[$mp.name] := node
		m[$mp.name] := new menu($mp)
	}
	
	; Add item(s)
	for k, v in m {
		_mi_ := mn[k].selectNodes(xpr.2)
		
		; Set item(s) properties
		Loop, % _mi_.length {
			_p_ := _mi_.item(A_Index-1).attributes
			
			item := _p_.length ? [] : ""
			Loop, % _p_.length {	
				p := _p_.item(A_Index-1)
				if (p.name ~= xpr.4)
					item[p.name] := p.value	
			}		
			v.add(item)
		}
	}
	return len > 1 ? m : m[$mp.name]
}

MENU_to(p*) {
	static MSXML := "MSXML2.DOMDocument" (A_OSVersion ~= "(7|8)" ? ".6.0" : "")

	x := ComObjCreate(MSXML)
	mn := {base: {max: Func("ObjMaxIndex"), del: Func("ObjRemove")}} , mi := []
	for k, v in p {
		mn[k] := x.createElement("Menu")
		mn[k].setAttribute("name", v.name)

		for a, b in v.item.() {
			mi[a] := x.createElement("Item")

			for i, j in b._ {
				if (i = "menu")
					continue
				mi[a].setAttribute(i, IsObject(j) ? j.Name "()" : j)
			}
			mn[k].appendChild(mi[a])
		}
	}

	x.documentElement := (mn.max() > 1) ? x.createElement("MENU") : mn.del()
	for y, z in mn
		x.documentElement.appendChild(z)

	return x
}

MENU_json(src) {
	static sc , has := "hasOwnProperty"
	, e := "(?P<p>menu|name|items|target|icon|standard|default|color|check|enable)"

	if !sc {
		sc := ComObjCreate("ScriptControl")
		sc.Language := "JScript"
	}
	; Convert all JSON elements to lowercase
	src := RegExReplace(src, "i)(""|'|)\K" e "(?=(""|'|):)", "$L{p}")
	
	sc.ExecuteStatement("j = " src)
	j := sc.Eval("j")

	m := [] , mn := []
	Loop, % (len := ($j := j[has]("name")) ? 1 : j.length) {
		_m_ := ($j ? j : j[A_Index-1]) , mp := []
		for q, r in ["name","color","standard","icon"]
			if _m_[has](r)
				mp[r] := _m_[r]
		mn[mp.name] := _m_
		m[mp.name] := new menu(mp)
	}

	for k, v in m {
		Loop, % mn[k].items.length {
			_mi_ := (mn[k].items)[A_Index-1]
			mi := _mi_[has]("name") ? [] : ""
			for x, y in (mi ? ["name","target","icon","default","check","enable"] : [])
				if _mi_[has](y)
					mi[y] := _mi_[y]
			v.add(mi)
		}
	}
	return len > 1 ? m : m[mp.name]
}
; PRIVATE FUNCTIONS
MENU_list(k:="", v:=1) {
	static list := []

	return (k == "") ? list : (IsObject(v) ? (list[k] := v) : (v ? {1: list[k], 2: list.HasKey(k)}[v] : list.Remove(k)))
}