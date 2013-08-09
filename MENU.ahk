class MENU
{

	static __INIT__ := MENU.__INIT_CLASS__()
	__CHECK_INIT__ := MENU.__INIT_CLASS__()
	
	__New(arg) {
		ObjInsert(this, "_", {item:{base:MENU.__ITEM__}}) ; proxy object
		this.item.Insert("_", [])
		
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
		OutputDebug, % "CLASS[" this.__Class "]: Deleted"
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
			Menu, % this.name, % {0:"NoStandard", 1:"Standard"}[v]

			if v {
				Loop, 10
					std := {base:MENU.ITEM} , std.Insert("_", [])
					, this.item._.Insert(std)
				
				this.__node.appendChild(MENU.__xml.createElement("Standard"))
				v := this.standard
			
			} else this.item._.Remove(this.standard, this.standard+9)
				, this.__node.removeChild(this.__node.selectSingleNode("Standard"))
		
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
		mi := new MENU.ITEM(this, item)
		this.item[this.count+1] := mi
	}

	show(x:="", y:="", coordmode:="") {
		if (coordmode && (x <> "" || y <> "")) {
			if (coordmode ~= "i)^(Screen|Relative|Window|Client)$")
				CoordMode, Menu, % coordmode
		}	
		
		Menu, % this.name, Show, % x, % y
	}

	__INIT_CLASS__() {
		static init

		if init
			return
		init := true
		
		MENU.base := {__Get:MENU.__baseGet, __Set:MENU.__baseSet}
		MENU.__ := []
		
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
			MENU.thisItem.__onEvent()
		else SetTimer, MENU_ITEMLABELTIMER, -1
		return
	}

	class ITEM
	{

		__New(self, item) {
			this.Insert("_", {menu: self.name})

			this.name := IsObject(item) ? item.name : ""
			
			item.action := item.Haskey("action") ? item.action : ""
			for a, b in item {
				if !(a ~= "i)^(action|icon|enable|check|default)$")
					continue
				this[a] := b
			}

		}

		__Delete() {
			OutputDebug, % "CLASS[" this.__Class "]: Deleted"
		}

		__Set(k, v, p*) {
			self := this.menu
			StringLower, k, k
			
			if (k = "name") {
				if this_.HasKey(k) {
					if (v = this.name)
						return
					Menu, % self.name, Rename, % this.name, % v
				
				} else {
					Menu, % self.name, Add, % v, % (v<>"") ? "MENU_ITEMLABEL" : ""
					self.__node.appendChild(n:=MENU.__xml.createElement("Item"))
					n.setAttribute("ref", &this)
				}
			
			} else if (k = "action") {
				sub := ((str:=(v~="^:")) || (v.__Class="MENU"))
				    ?  (str ? v : ":" v.name)
				    :  false

				if sub
					Menu, % self.name, Add, % this.name, % (v:=sub)
				
				if (IsObject(v) && IsFunc(v))
					v := v.Name . "()"
			
			} else if (k = "icon") {
				RegExMatch(v, "iO)^([^,]+)(?:,(\d+|)(?:,(\d+|)|$)|$)$", icon)
				Menu, % self.name, Icon, % this.name, % icon.1, % icon.2, % icon.3
			
			} else if (k ~= "i)^(check|enable)$") {
				cmd := {check: {1: "Check", 0: "Uncheck", 2: "ToggleCheck"}
			        ,   enable: {1: "Enable", 0: "Disable", 2: "ToggleEnable"}}[k, v]
		        
		        Menu, % self.name, % cmd, % this.name
			
			} else if (k = "default") {
				self.default := v ? this.name : false

			} else if (k = "pos") {
				if (v.type = "Standard")
					return false
				if !(v >= 1 && v <= self.count)
					return false
				if (v == this.pos)
					return false
				if (std:=this.standard) {
					if (v > this.pos && v >= std && v < (std+9))
					|| (v < this.pos && v > std && v <= (std+9))
						return false
				}
				
				return self.item.__(this, v)
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
				type := this._.HasKey("name")
				     ? ((this.name="")
				        ? "Separator"
				        : ((this.action~="^:")
				          ? "Submenu"
				          : "Normal"))
				     : "Standard"

				return type
			}

			__node(p*) {
				return this.menu.__node.selectSingleNode("Item[@ref='" &this "']")
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

	class __ITEM__
	{

		__New() {
			return false
		}

		__Set(k, v, p*) {
			
			return this._[k] := v
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

			if pos
				this._.Insert(pos, this._.Remove(item.pos))
				, node := oMenu.__node.removeChild(item.__node)
				, arg := (end:=(pos=oMenu.count))
				      ? [node]
				      : [node, oMenu.__node.selectSingleNode("Item[@ref='" &this[pos] "']")]
				, (oMenu.__node)[end ? "appendChild" : "insertBefore"](arg*)

			Menu, % oMenu.name, DeleteAll
			Menu, % oMenu.name, NoStandard

			for k, v in this._ {
				if (!pos && v = item)
					continue
				if (v.type = "Standard") {
					if (k = oMenu.standard)
						Menu, % self.name, Standard
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
		OutputDebug, % k
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