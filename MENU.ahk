class MENU
{

	static __INIT__ := MENU.__INIT_CLASS__()
	;__CHECK_INIT__ := MENU.__INIT_CLASS__()
	
	__New(arg) {
		if !IsObject(MENU.__) ; Fix this
			MENU.__INIT_CLASS__()
		
		ObjInsert(this, "_", {item:new MENU.__ITEM__(this)}) ; proxy object
		
		if !((name := IsObject(arg) ? (arg.HasKey("name") ? arg.name : 0) : arg)<>"")
			throw Exception(MENU.__ERROR["menu_name"], -1)
		try (this.name := name)
		catch e
			throw Exception(e.Message, -1)
		
		for k, v in arg {
			if !(k ~= "i)^(standard|color|icon|tip|click|mainwindow)$")
				continue
			this[k] := v
		}
	}

	__Delete() {
		this.item := ""
		Menu, % this.name, Delete
		OutputDebug, % "CLASS[" this.__Class "]: Deleted | name: " this.name
	}

	__Set(k, v, p*) {
		if (k = "__CHECK_INIT__")
			return
		
		StringLower, k, k

		if (k = "name") {
			if this._.Haskey(k)
				throw Exception(MENU.__ERROR["menu_rename"], -1)
			
			MENU.__[v] := &this
			MENU.__xml.documentElement.appendChild(n:=MENU.__xml.createElement("Menu"))
			n.setAttribute("ref", &this) , this._.Insert(k, v)
			
			if (v = "Tray") {
				this.standard := 1
			
			} else Loop, 2
				Menu, % v, % {1:"Standard", 2:"NoStandard"}[A_Index]
			
			
		} else if (k = "default") {
			Menu, % this.name, Default
			    , % value ? (IsObject(value) ? value.name : value) : ""
		
		} else if (k = "color") {
			RegExMatch(v, "iO)^([^,\s]+)(?:[,\s]+(single|)|$)$", c)
			Menu, % this.name, Color, % c.1, % c.2

		} else if (k = "standard") {
			
			if !v
				this.item._.Remove(this.standard, this.standard+9)
			else Loop, 10
				new MENU.STANDARD_ITEM(this)

			v := this.standard
		
		} else if (k ~= "i)^(icon|tip|click|mainwindow)$") {
			if (this.name <> "Tray")
				throw Exception(MENU.__ERROR["menu_not_tray"], -1)

			if (k = "icon") {
				RegExMatch(v, "iO)^([^,]+|)(?:,(\d+|)(?:,(0|1|)|$)|$)$", icon)
				if (icon.1 ~= "^(0|1|)$")
					Menu, Tray, % icon.1 ? "Icon" : "NoIcon"
				else Menu, Tray, Icon, % icon.1, % icon.2, % icon.3
			
			} else if (k = "mainwindow") {
				if !A_IsCompiled
					return
				Menu, Tray, % v ? "MainWindow" : "NoMainWindow"
			
			} else Menu, Tray, % k, % v
		
		} else if (k = "item") {
			if p.MinIndex()
				return (this.item)[v] := p.1
			return this._[k] := v
		}

		this.__node.setAttribute(k, v)
		return this._[k] := v
	}

	class __Get extends MENU.__PROPERTIES__
	{

		__(k, p*) {
			if this._.HasKey(k)
				return this._[k, p*]

			return false
		}

		count(p*) {
			return (i:=this.item._.MaxIndex())<>"" ? i : 0
		}

		standard(p*) {
			/*
			if !this._.HasKey("standard")
				return false
			*/
			for a, b in this.item._
				pos := a
			until (std:=(b.type = "Standard"))
			return std ? pos : false
		}

		__node(p*) {
			return MENU.__xml.documentElement.selectSingleNode("Menu[@ref='" &this "']")
		}
	}

	add(item:="") {
		return new MENU.ITEM(this, item)
	}

	ins(p1:=0, p2:=0) {
		this.add((mi:=IsObject(p1)) ? p1 : "")
		this.item[this.count].pos := mi ? p2 : p1
	}

	del(item:="") {
		if !item
			this.item := ""
		else this.item[IsObject(item) ? item.pos : item] := ""
	}

	show(x:="", y:="", coordmode:="") {
		static coord

		if !coord
			coord := {s:"Screen", r:"Relative", w:"Window", c:"Client"}
		
		if (coordmode ~= "i)^(S(creen)?|R(elative)?|W(indow)?|C(lient)?)$")
		&& (x <> "" || y <> "")
			CoordMode, Menu, % coord[SubStr(coordmode,1,1)]
		
		Menu, % this.name, Show, % x, % y
	}

	__INIT_CLASS__() {
		static init

		if init
			return
		init := true
		
		MENU.__ := []
		MENU.base := {__Get:MENU.__baseGet, __Set:MENU.__baseSet}
		
		x := ComObjCreate("MSXML2.DOMDocument.6.0")
		x.async := false , x.setProperty("SelectionLanguage", "XPath")
		x.loadXML("<CLASS_MENU/>")
		MENU.__xml := x
	}

	__HANDLER__() {
		return

		MENU_ITEMLABEL:
		MENU_ITEMLABELTIMER:
		if(A_ThisLabel = "MENU_ITEMLABELTIMER")
			Object(MENU.__[A_ThisMenu]).item[A_ThisMenuItemPos].__onEvent()
			;MENU.thisItem.__onEvent()
		else SetTimer, MENU_ITEMLABELTIMER, -1
		return
	}

	class ITEM
	{

		__New(oMenu, item:="") {
			oMenu.item[oMenu.count+1] := this
			this.Insert("_", {menu: oMenu.name})
			
			this.name := IsObject(item) ? item.name : ""
			
			item.action := item.Haskey("action") ? item.action : ""
			for a, b in item {
				if !(a ~= "i)^(action|icon|enable|check|default)$")
					continue
				this[a] := b
			}

		}

		__Delete() {
			OutputDebug, % "CLASS[" this.__Class "]: Deleted | type: " this.type
			
			if (this.type = "Standard") {
				if (this.std_index<9)
					return
				Menu, % this.menu.name, NoStandard
			
			} else if (this.type = "Normal")
				Menu, % this.menu.name, Delete, % this.name

			this.menu.__node.removeChild(this.__node)
		}

		__Set(k, v, p*) {
			oMenu := this.menu
			StringLower, k, k
			
			if (k = "name") {
				if this_.HasKey(k) {
					if (v = this.name)
						return
					Menu, % oMenu.name, Rename, % this.name, % v
				
				} else {
					Menu, % oMenu.name, Add, % v, % (v<>"") ? "MENU_ITEMLABEL" : ""
					oMenu.__node.appendChild(n:=MENU.__xml.createElement("Item"))
					n.setAttribute("ref", &this)
				}
			
			} else if (k = "action") {
				sub := ((str:=(v~="^:")) || (v.__Class="MENU"))
				    ?  (str ? v : ":" v.name)
				    :  false

				if sub
					Menu, % oMenu.name, Add, % this.name, % (v:=sub)
				
				if (IsObject(v) && IsFunc(v))
					v := v.Name . "()"
				else if (v == "")
					v := this.name
			
			} else if (k = "icon") {
				RegExMatch(v, "iO)^([^,]+)(?:,(\d+|)(?:,(\d+|)|$)|$)$", icon)
				Menu, % oMenu.name, Icon, % this.name, % icon.1, % icon.2, % icon.3
			
			} else if (k ~= "i)^(check|enable)$") {
				cmd := {check: {1: "Check", 0: "Uncheck", 2: "ToggleCheck"}
			        ,   enable: {1: "Enable", 0: "Disable", 2: "ToggleEnable"}}[k, v]
		        
		        Menu, % oMenu.name, % cmd, % this.name
			
			} else if (k = "default") {
				oMenu.default := v ? this.name : false

			} else if (k = "pos") {
				if (this.type = "Standard")
					return false
				if !(v >= 1 && v <= oMenu.count)
					return false
				if (v == this.pos)
					return false
				if (std:=oMenu.standard) {
					if (v > this.pos && v >= std && v < (std+9))
					|| (v < this.pos && v > std && v <= (std+9))
						return false
				}
				
				return oMenu.item.__(this, v)
			}
			
			this.__node.setAttribute(k, v)
			if (k="name" && v="")
				this.__node.removeAttribute("name")
			
			return this._[k] := v
		}

		class __Get extends MENU.__PROPERTIES__
		{

			__(k, p*) {
				if this._.HasKey(k)
					return this._[k, p*]
			}

			menu(p*) {
				return Object(MENU.__[this._.menu])
			}

			action(p*) {
				RegExMatch(this._.action, "O)^(.*)(:|\(\))$", m)
				return m ? {":":m.1, "()":Func(m.1)}[m.2] : this._.action
			}

			pos(p*) {
				for k, v in this.menu.item._
					pos := k
				until (match:=(v==this))
				return match ? pos : 0
			}

			type() {
				type := (this.__Class <> "MENU.STANDARD_ITEM")
				     ? ((this.name="")
				        ? "Separator"
				        : ((this.action~="^:")
				          ? "Submenu"
				          : "Normal"))
				     : "Standard"
				return type
			}

			__node(p*) {
				return this.menu.__node.selectSingleNode((this.type<>"Standard") ? "Item[@ref='" &this "']" : "Standard")
			}
		}

		__onEvent() {
			axn := this.action
			lbl := IsLabel(axn) , fn := IsFunc(axn) , obj := IsObject(axn)
			
			if (lbl && (!fn || (fn && !obj)))
				SetTimer, % axn, -1
			else if (fn && (!lbl || (lbl && obj)))
				return (axn).(this)
			return
		}
	
	}

	class STANDARD_ITEM extends MENU.ITEM
	{
		
		__New(oMenu) {
			oMenu.item[oMenu.count+1] := this
			this.Insert("_", {menu:oMenu.name})
			
			if !(this.std_index:=this.pos-oMenu.standard) {
				Menu, % oMenu.name, Standard
				oMenu.__node.appendChild(MENU.__xml.createElement("Standard"))
			}

			this.std_index := this.pos-oMenu.standard
		}

		__Set(k, v, p*) {
			if (k = "std_index")
				return this._[k] := v
			
			return false
		}
	}

	class __ITEM__
	{

		__New(oMenu) {
			this.Insert("_", [])
		}

		__Delete() {
			Loop, % this._.MaxIndex()
				this[1] := ""
		}

		__Set(k, v, p*) {

			if this._.HasKey(k) {
				oItem := this[k]
				return v ? false
				         : ((oItem.type<>"Standard")
				           ? ((oItem.type="Separator")
				             ? this.__(oItem)
				             : this._.Remove(k))
				           : oItem.menu.standard:=0)
			
			} else {
				; Initial __Set
				if (k ~= "^\d+$")
					return this._.Insert(k, v)
				; k = MenuItemName
				else if (oItem:=this[k])
					return this[oItem.pos] := v
				; Invalid key
				else return false
			}
			
		}

		class __Get extends MENU.__PROPERTIES__
		{

			__(k, p*) {
				if this._.HasKey(k)
					return this._[k, p*]
				
				for a, b in this._
					continue
				until (match:=(k=b.name))
				
				return match ? b : false
			}
		}

		__(item, pos:=false) {
			oMenu := item.menu

			if pos {
				this._.Insert(pos, this._.Remove(item.pos))
				, node := oMenu.__node.removeChild(item.__node)
				, arg := (end:=(pos=oMenu.count))
				      ? [node]
				      : [node, oMenu.__node.selectSingleNode("Item[@ref='" &this[pos+1] "']")]
				, (oMenu.__node)[end ? "appendChild" : "insertBefore"](arg*)

			} else this._.Remove(item.pos)

			Menu, % oMenu.name, DeleteAll
			Menu, % oMenu.name, NoStandard

			for k, v in this._ {
				if (!pos && v = item)
					continue
				if (v.type = "Standard") {
					if (k = oMenu.standard)
						Menu, % oMenu.name, Standard
					continue
				}
				Menu, % oMenu.name, Add
				    , % v.name
				    , % (v.type <> "Separator") ? "MENU_ITEMLABEL" : ""

				for a, b in v._ {
					if !(a~="i)^(action|icon|check|enable|default)$")
						continue
					this[k][a] := b
				}
			}

		}
	}

	__baseSet(k, v, p*) {
		;OutputDebug, % k
	}

	class __baseGet extends MENU.__PROPERTIES__
	{

		__(k, p*) {

		}

		thisMenu(p*) {
			return Object(MENU.__[A_ThisMenu])
		}

		thisItem(p*) {
			return MENU.thisMenu.item[A_ThisMenuItemPos]
		}

		__ERROR(p*) {
			static msg := MENU.__ERROR

			if !msg {
				msg := {"menu_name":"Cannot create menu. Menu name not specified."
				      , "menu_rename":"Menu 'name' property is read-only."
				      , "menu_not_tray":"Menu name must be 'Tray'."}
				for k, v in msg
					msg[k] := "[Class: MENU] " . v
			}
			
			return p[1] ? msg[p.1] : msg
		}
	
	}

	class __PROPERTIES__
	{

		__Call(target, name, params*) {
			if !(name ~= "i)^(base|__Class)$") {
				return ObjHasKey(this, name)
				       ? this[name].(target, params*)
				       : this.__.(target, name, params*)
			}
		}
	}

}

MENU_from(src) {
	/*
	Do not initialize 'xpr' as class static initializer(s) will not be
	able to access the variable's content when calling this function.
	*/
	static xpr
	
	;XPath[1.0] expression(s) that allow case-insensitive node selection
	if !xpr
		xpr := ["*[translate(name(), 'MENU', 'menu')='menu']"
		    ,   "*[translate(name(), 'ITEM', 'item')='item' or "
		    .   "translate(name(), 'STANDARD', 'standard')='standard']"
		    ,   "@*[translate(name(), 'NAME', 'name')='name']"]
	
	x := ComObjCreate("MSXML2.DOMDocument.6.0")
	x.setProperty("SelectionLanguage", "XPath") ;Redundant
	x.async := false

	;Load XML source
	if (src ~= "s)^<.*>$")
		x.loadXML(src)
	else if ((f:=FileExist(src)) && !(f~="D"))
		x.load(src)
	else throw Exception("Invalid XML source.", -1)

	m := [] , mn := []
	
	for mnode in x.selectNodes("//" xpr.1 "[" xpr.3 "]") {
		mp := [] , len := A_Index
		for att in mnode.attributes
			mp[att.name] := att.value
		
		m[mp.name] := {node:mnode, menu:new MENU(mp)}
	}

	for k, v in m {
		
		for inode in v.node.selectNodes(xpr.2) {
			
			if (inode.nodeName = "Standard") {
				v.menu.standard := true
				continue
			}
			
			mi := (att:=inode.attributes).length ? [] : ""
			for ip in att
				mi[ip.name] := ip.value
			v.menu.add(mi)
		}
		
		mn[name:=k] := v.Remove("menu")
	}

	return len>1 ? mn : mn.Remove(name)
}