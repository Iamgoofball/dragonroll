/obj/structure/cooking
	name = "campfire"
	desc = "keeps things warm."
	icon = 'sprite/obj/alchemy/structures.dmi'
	icon_state = "campfire"
	var/burnTime = 1200
	var/icon/cookOverlay // the overlay applied for cooking
	var/lit = FALSE // is the cooking structure providing fire to cook
	var/capacity = 2 // how many things can this pot use to cook?
	var/cookingLevel = 1 // what level of ingredients this can cook
	var/list/curCooking = list() // list of what is cooking and its times
	var/mob/lastUsr

/obj/structure/cooking/New()
	..()
	cookOverlay = icon('sprite/obj/alchemy/items.dmi',icon_state="cook_overlay")

/obj/structure/cooking/objFunction(var/mob/user,var/obj/item/I)
	if(!lit)
		if(istype(I,/obj/item/weapon/tool/firelighter))
			lit = TRUE
			messageInfo("You light the fire.",user,src)
			icon_state = "[icon_state]_lit"
			set_light(4,4,"orange")
			addProcessingObject(src)
			return
		return
	else
		if(istype(I,/obj/item/weapon/tool/tongs))
			showCookingMenu(user)
			return
		if(!istype(I,/obj/item/food))
			messageInfo("Only food items can be cooked.",user,src)
			return
		if(contents.len < capacity)
			user.DropItem()
			messageInfo("You insert the [I] into the [src]!",user,src)
			I.loc = src

/obj/structure/cooking/doProcess()
	if(lastUsr)
		if(Adjacent(lastUsr) && curCooking.len > 0)
			showCookingMenu(lastUsr)
	if(burnTime > 0)
		--burnTime
		if(contents.len)
			for(var/obj/item/food/A in curCooking)
				if(curCooking[A] <= 0)
					curCooking -= A
					A.name = "Cooked [A.cooked_name ? A.cooked_name : A:name]"
					A.color = "white"
					if(!A.cooked_icon_state)
						var/icon/cooked = icon(A.icon,icon_state=A.icon_state)
						cooked.Blend(rgb(204,102,0),ICON_MULTIPLY)
						cooked.Blend(cookOverlay,ICON_MULTIPLY)
						A.icon = cooked
					else
						A.icon = 'sprite/obj/food.dmi'
						A.icon_state = A.cooked_icon_state
					A.loc = get_turf(pick(orange(src,1)))
					showCookingMenu(lastUsr)
				else
					curCooking[A]--
	else
		lit = FALSE
		burnTime = initial(burnTime)
		icon_state = "[initial(icon_state)]"
		messageArea("The [src] extinguishes!","The [src] extinguishes!", src, src)
		set_light(0,0,"white")
		remProcessingObject(src)
		return

/obj/structure/cooking/proc/showCookingMenu(var/user)
	var/html = "<title>[src.name]</title><html><center><br><body style='background:grey'>"
	html += "<b>Contents:</b><br>"
	html += "<table>"
	html += "<tr>"
	for(var/obj/item/food/F in contents)
		if(!(F in curCooking))
			html += "<td style=\"text-align:center\"><a href=?src=\ref[src];function=cook;food=\ref[F]>[parseIcon(user,F)]</a></td>"
	html += "</tr></table>"
	html += "<br>"
	html += "<b>Cooking:</b><br>"
	html += "<table>"
	html += "<tr>"
	for(var/obj/item/food/F in curCooking)
		html += "</td style=\"text-align: center\">[parseIcon(user,F)]</td>"
	html += "<br>"
	for(var/obj/item/food/F in curCooking)
		html += "<td style=\"text-align:center\">"
		for(var/I = 0; I < ((curCooking[F]/100)*(F.foodLevel*10)); ++I)
			html += "<b>|</b>"
		html += "</td>"
	html += "</tr></table>"
	html += "</body></center></html>"
	user << browse(html,"window=cooking")

/obj/structure/cooking/Topic(href,href_list[])
	var/function = href_list["function"]
	if(function == "cook")
		var/fud = href_list["food"]
		if(fud)
			var/obj/item/food/A = locate(fud)
			if(A)
				curCooking[A] = A.foodLevel*10
				lastUsr = usr
				showCookingMenu(usr)