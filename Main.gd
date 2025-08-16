extends Control

# Game State Variables
var day = 1
var gold = 30
var beer_stock = 5
var tax_day = 30
var next_id = 1
var max_adventurers = 5
var adventurers = []

# Mission data (from your Python prototype)
var missions = [
	{"name": "Clear Slimes", "danger": 1, "reward_range": [5, 10], "party_required": false},
	{"name": "Escort Merchant", "danger": 5, "reward_range": [40, 60], "party_required": true},
	{"name": "Scavenge Herbs in Forest", "danger": 3, "reward_range": [10, 20], "party_required": true},
	{"name": "Defend the Grain Warehouse", "danger": 2, "reward_range": [15, 25], "party_required": true}
]

# Adventurer data
var adventurer_names = ["Brom", "Ezren", "Kael", "Lyra", "Nim", "Tarin", "Zara", "Garrick", "Mira", "Thorne"]
var adventurer_classes = ["Fighter", "Rogue", "Healer", "Mage"]

# UI References - Clean scene node connections
@onready var day_label = $GameUI/TopBar/DayLabel
@onready var gold_label = $GameUI/TopBar/GoldLabel
@onready var beer_label = $GameUI/TopBar/BeerLabel
@onready var top_bar = $GameUI/TopBar
@onready var next_day_button = $GameUI/BottomBar/NextDayButton
@onready var tavern_view = $GameUI/MainArea/TavernView
@onready var log_container = $GameUI/MainArea/TavernView/LogContainer
@onready var game_log = get_node_or_null("GameUI/MainArea/TavernView/LogContainer/GameLog")
@onready var tavern_bar_hover = $TavernBackground_bar_hover
@onready var tavern_desk_hover = $TavernBackground_desk_hover
@onready var tavern_mission_hover = $TavernBackground_mission_hover
@onready var tavern_button = $tavern_button
@onready var mission_button = $mission_button
@onready var beer_management_popup = $BeerManagementPopup
@onready var mission_board_popup = $MissionBoardPopup
@onready var desk_board_popup = $DeskBoardPopup

# Dynamic UI elements
var log_display_area  # Clean log container
var available_recruits = [] 

func _ready():
	print("=== ETERNAL GUILD STARTING ===")
	
	# Setup UI structure first
	setup_clean_log_system()
	setup_interactive_areas()
	
	# Initialize game state
	adventurers.append(create_adventurer("Brom", "Fighter"))
	
	# Update displays
	update_ui()
	update_adventurer_display()
	
	# Welcome messages
	log_message("🏰 Welcome to the Eternal Guild!")
	log_message("📅 Day " + str(day) + " begins...")
	
	print("=== SETUP COMPLETE ===")

# === UI SETUP FUNCTIONS ===

func setup_interactive_areas():
	"""Create invisible buttons for interactive tavern areas"""
	print("Setting up interactive areas...")
	# Hide all hover effects initially
	tavern_bar_hover.visible = false
	tavern_desk_hover.visible = false
	tavern_mission_hover.visible = false
	# Create invisible button for tavern  (left side - bar area)
	tavern_button.mouse_filter = Control.MOUSE_FILTER_PASS
	# Position it over the tavern  (approximate coordinates)
	#tavern_button.position = Vector2(50, 200)  # Adjust based on your layout
	#tavern_button.size = Vector2(200, 300)     # Cover the bar area


func log_message(message: String):
	"""Simple log function that works with RichTextLabel from Inspector"""
	print("LOG: " + message)

	if game_log and game_log is RichTextLabel:
		# Simple append for RichTextLabel - no formatting overrides
		if game_log.text == "":
			game_log.text = message
		else:
			game_log.text += "\n" + message
		
		# Keep only last 25 lines
		var lines = game_log.text.split("\n")
		if lines.size() > 25:
			lines = lines.slice(-25)
			game_log.text = "\n".join(lines)
		
		# Scroll to bottom
		await get_tree().process_frame
		if log_container.get_v_scroll_bar():
			log_container.get_v_scroll_bar().value = log_container.get_v_scroll_bar().max_value
			
	elif game_log:
		print("GameLog is type: ", game_log.get_class())
	else:
		print("ERROR: game_log not found")

func setup_clean_log_system():
	print("Using pure Inspector-based log system...")
	
	# DEBUG: Let's find the correct path
	print("LogContainer exists: ", get_node_or_null("GameUI/MainArea/TavernView/LogContainer"))
	print("GameLog exists: ", get_node_or_null("GameUI/MainArea/TavernView/LogContainer/GameLog"))
	
	# Try alternative path
	var alternative_log = get_node_or_null("GameUI/MainArea/TavernView/LogContainer").get_children()
	print("Children of LogContainer: ", alternative_log)
	
	if game_log:
		print("GameLog found: ", game_log.name, " (", game_log.get_class(), ")")
	else:
		print("GameLog not found - trying manual search...")
		# Manual assignment
		var log_container_node = get_node_or_null("GameUI/MainArea/TavernView/LogContainer")
		if log_container_node:
			for child in log_container_node.get_children():
				if child is RichTextLabel:
					game_log = child
					print("Found RichTextLabel manually: ", child.name)
					break
	
	print("Inspector-based log system ready!")

func _on_mission_pressed():
	var ready_adventurers = []
	for adv in adventurers:
		if adv.status == "Ready":
			ready_adventurers.append(adv)
	
	if ready_adventurers.size() == 0:
		log_message("❌ No adventurers are ready for missions!")
		return
	
	var adventurer = ready_adventurers[0]
	var mission = missions[0]  # Clear Slimes
	
	log_message("⚔️ " + adventurer.name + " is embarking on: " + mission.name)
	send_on_mission(adventurer, mission)

func send_on_mission(adventurer, mission):
	var adventurer_score = 0
	
	match adventurer.class:
		"Fighter":
			adventurer_score = adventurer.strength + adventurer.endurance
		"Rogue":
			adventurer_score = adventurer.dexterity + adventurer.endurance
		"Mage":
			adventurer_score = adventurer.intelligence * 1.5
		"Healer":
			adventurer_score = adventurer.intelligence
	
	var roll = randi() % 6 + 1
	adventurer_score += roll
	var difficulty = mission.danger * 10
	
	if adventurer_score >= difficulty:
		# SUCCESS!
		var reward = randi() % (mission.reward_range[1] - mission.reward_range[0] + 1) + mission.reward_range[0]
		gold += reward
		log_message("✅ SUCCESS! " + adventurer.name + " completed " + mission.name + " and earned " + str(reward) + " gold!")
		
		for adv in adventurers:
			if adv.id == adventurer.id:
				adv.missions_completed += 1
				adv.gold_earned += reward
				adv.status = "Recovering"
				adv.recovery = 1
				break
	else:
		# FAILURE!
		log_message("💥 FAILED! " + adventurer.name + " failed the mission: " + mission.name)
		
		var injury_roll = randi() % 6 + 1
		for adv in adventurers:
			if adv.id == adventurer.id:
				if injury_roll == 1:
					log_message("☠️ " + adventurer.name + " died on the mission!")
					adventurers.erase(adv)
				else:
					log_message("🤕 " + adventurer.name + " was injured and needs time to recover.")
					adv.status = "Recovering"
					adv.recovery = randi() % 4 + 2
					adv.missions_failed += 1
					adv.injuries_sustained += 1
				break
	
	update_ui()
	update_adventurer_display()

func create_adventurer(adv_name = "", adv_class = ""):
	if adv_name == "":
		adv_name = adventurer_names[randi() % adventurer_names.size()]
	if adv_class == "":
		adv_class = adventurer_classes[randi() % adventurer_classes.size()]
	
	var stats = {
		"strength": randi() % 6 + 1,
		"dexterity": randi() % 6 + 1,
		"intelligence": randi() % 6 + 1,
		"endurance": randi() % 6 + 1
	}
	
	match adv_class:
		"Fighter":
			stats.strength += 2
			stats.endurance += 1
		"Rogue":
			stats.dexterity += 2
		"Mage":
			stats.intelligence += 2
		"Healer":
			stats.intelligence += 1
	
	var adventurer = {
		"id": next_id,
		"name": adv_name,
		"class": adv_class,
		"status": "Ready",
		"recovery": 0,
		"strength": stats.strength,
		"dexterity": stats.dexterity,
		"intelligence": stats.intelligence,
		"endurance": stats.endurance,
		"missions_completed": 0,
		"missions_failed": 0,
		"gold_earned": 0,
		"injuries_sustained": 0
	}
	
	next_id += 1
	return adventurer

func update_ui():
	day_label.text = "Day: " + str(day)
	gold_label.text = "Gold: " + str(gold)
	beer_label.text = "Beer: " + str(beer_stock)

func update_adventurer_display():
	# Remove existing adventurer labels
	var children_to_remove = []
	for child in top_bar.get_children():
		if child.name.begins_with("AdventurerLabel"):
			children_to_remove.append(child)
	
	for child in children_to_remove:
		top_bar.remove_child(child)
		child.queue_free()
	
	# Add current adventurers
	for i in range(adventurers.size()):
		var adv = adventurers[i]
		var adv_label = Label.new()
		adv_label.name = "AdventurerLabel" + str(i)
		
		var status_text = ""
		if adv.status == "Recovering":
			status_text = " (R" + str(adv.recovery) + ")"
		
		adv_label.text = adv.name + "(" + adv.class + ")" + status_text
		top_bar.add_child(adv_label)
	
	# Update mission button
	var ready_count = 0
	for adv in adventurers:
		if adv.status == "Ready":
			ready_count += 1
	
	if ready_count > 0:
		mission_button.text = "Send on Mission"
		mission_button.disabled = false
	else:
		mission_button.text = "No Ready Adventurers"
		mission_button.disabled = true

	var new_adv = create_adventurer()
	var cost = 10
	
	if gold >= cost and adventurers.size() < max_adventurers:
		adventurers.append(new_adv)
		gold -= cost
		log_message("🆕 Recruited " + new_adv.name + " the " + new_adv.class + " for " + str(cost) + " gold!")
		update_ui()
		update_adventurer_display()
	else:
		if gold < cost:
			log_message("💰 Not enough gold to recruit! Need " + str(cost) + " gold.")
		else:
			log_message("🏠 Guild is full! Cannot recruit more adventurers.")

func advance_day():
	day += 1
	log_message("📅 Day " + str(day) + " begins...")
	
	
	# Handle adventurer recovery
	for adv in adventurers:
		if adv.status == "Recovering":
			adv.recovery -= 1
			if adv.recovery <= 0:
				adv.status = "Ready"
				adv.recovery = 0
				log_message("💪 " + adv.name + " has recovered and is ready for missions!")
	
	# Pay wages
	var wages = adventurers.size()
	if gold >= wages:
		gold -= wages
		if wages > 0:
			log_message("💵 Paid " + str(wages) + " gold in wages to adventurers")
	else:
		log_message("⚠️ Cannot pay all adventurers! Some may leave...")
	
	# Beer sales
	if beer_stock > 0 and randf() < 0.5:
		beer_stock -= 1
		var income = randi() % 3 + 1
		gold += income
		log_message("🍺 Visitor bought beer! Earned " + str(income) + " gold")
	
	# Tax day
	if day % tax_day == 0:
		if gold >= 60:
			gold -= 60
			log_message("🏛️ Paid 60 gold in taxes")
		else:
			log_message("💸 Cannot pay taxes! Game Over!")
	
	update_ui()
	update_adventurer_display()
	refresh_daily_recruits()


func _on_tavern_button_mouse_entered() -> void:
	tavern_bar_hover.visible = true
	print("Hovering over tavern keeper")


func _on_tavern_button_mouse_exited() -> void:
	tavern_bar_hover.visible = false
	print("Left tavern keeper area")


func _on_tavern_button_pressed() -> void:
	log_message("🍺 Speaking with the tavern keeper...")
	open_beer_management_popup()



func open_beer_management_popup():
	"""Show the beer management popup and populate it with content"""
	print("Opening beer management popup...")
	
	# Clear any existing content first
	for child in beer_management_popup.get_children():
		if child.name != "CloseButton":  # Keep the default close button
			child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Set popup properties
	#beer_management_popup.title = "🍺 Tavern Keeper - Beer Management"
	#beer_management_popup.size = Vector2(400, 350)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	beer_management_popup.add_child(main_container)
	
	# Add some padding
	main_container.add_theme_constant_override("separation", 10)
	
	# Tavern keeper greeting
	var greeting = Label.new()
	greeting.text = "\"Welcome, Guildmaster! What can I get for you?\""
	greeting.add_theme_font_size_override("font_size", 14)
	greeting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_container.add_child(greeting)
	
	# Current stock display
	var stock_info = Label.new()
	stock_info.name = "StockInfo"
	stock_info.text = "Current Beer Stock: " + str(beer_stock) + " kegs"
	stock_info.add_theme_font_size_override("font_size", 16)
	stock_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(stock_info)
	
	# Gold display
	var gold_info = Label.new()
	gold_info.name = "GoldInfo"
	gold_info.text = "Available Gold: " + str(gold)
	gold_info.add_theme_font_size_override("font_size", 14)
	gold_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(gold_info)
	
	# Purchase section title
	var purchase_title = Label.new()
	purchase_title.text = "🛒 Beer Purchase Options"
	purchase_title.add_theme_font_size_override("font_size", 16)
	purchase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(purchase_title)
	
	# Purchase buttons container
	var button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 5)
	main_container.add_child(button_container)
	
	# Buy 1 keg button
	var buy_1_button = Button.new()
	buy_1_button.text = "Buy 1 Keg of Beer (5 gold)"
	buy_1_button.custom_minimum_size = Vector2(300, 35)
	button_container.add_child(buy_1_button)
	buy_1_button.pressed.connect(func(): buy_beer_from_keeper(1, 5, stock_info, gold_info))
	
	# Buy 5 kegs button (discount)
	var buy_5_button = Button.new()
	buy_5_button.text = "Buy 5 Kegs of Beer (20 gold) - Save 5g!"
	buy_5_button.custom_minimum_size = Vector2(300, 35)
	button_container.add_child(buy_5_button)
	buy_5_button.pressed.connect(func(): buy_beer_from_keeper(5, 20, stock_info, gold_info))
	
	# Buy 10 kegs button (bigger discount)
	var buy_10_button = Button.new()
	buy_10_button.text = "Buy 10 Kegs of Beer (35 gold) - Save 15g!"
	buy_10_button.custom_minimum_size = Vector2(300, 35)
	button_container.add_child(buy_10_button)
	buy_10_button.pressed.connect(func(): buy_beer_from_keeper(10, 35, stock_info, gold_info))
	
	# Show the popup
	beer_management_popup.popup_centered()
	print("Beer management popup shown!")
	
func buy_beer_from_keeper(kegs: int, cost: int, stock_label: Label, gold_label: Label):
	"""Purchase beer and update displays"""
	if gold >= cost:
		gold -= cost
		beer_stock += kegs
		
		# Log the purchase
		log_message("🍺 Purchased " + str(kegs) + " keg(s) from the tavern keeper for " + str(cost) + " gold!")
		log_message("💰 New totals: Gold: " + str(gold) + " | Beer: " + str(beer_stock))
		
		# Update main UI
		update_ui()
		
		# Update popup displays
		stock_label.text = "Current Beer Stock: " + str(beer_stock) + " kegs"
		gold_label.text = "Available Gold: " + str(gold)
		
		# Tavern keeper response (random flavor text)
		var responses = [
			"\"Excellent choice, Guildmaster!\"",
			"\"That should keep your adventurers happy!\"",
			"\"Fresh from the brewery!\"",
			"\"Your guild's reputation grows with good ale!\"",
			"\"A wise investment in your guild's future!\""
		]
		log_message("🗣️ " + responses[randi() % responses.size()])
		
	else:
		# Not enough gold
		log_message("💸 \"Sorry, you need " + str(cost) + " gold for that purchase.\"")
		log_message("🗣️ \"Come back when you have more coin, friend.\"")
		
		# Optional: Flash the gold label red to show insufficient funds
		gold_label.modulate = Color.RED
		await get_tree().create_timer(0.5).timeout
		gold_label.modulate = Color.WHITE

func open_mission_board_popup():
	"""Show the mission board popup with available missions"""
	print("Opening mission board popup...")
	
	# Clear any existing content first
	for child in mission_board_popup.get_children():
		if child.name != "CloseButton":
			child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Set popup properties
	mission_board_popup.title = "📋 Mission Board - Available Contracts"
	mission_board_popup.size = Vector2(600, 500)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	mission_board_popup.add_child(main_container)
	main_container.add_theme_constant_override("separation", 15)
	
	# Mission board header
	var header = Label.new()
	header.text = "\"Choose your contracts wisely, Guildmaster.\""
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(header)
	
	# Available adventurers info
	var ready_adventurers = []
	for adv in adventurers:
		if adv.status == "Ready":
			ready_adventurers.append(adv)
	
	var adventurer_info = Label.new()
	adventurer_info.text = "Ready Adventurers: " + str(ready_adventurers.size()) + "/" + str(adventurers.size())
	adventurer_info.add_theme_font_size_override("font_size", 14)
	adventurer_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(adventurer_info)
	
	# Missions container
	var missions_container = VBoxContainer.new()
	missions_container.add_theme_constant_override("separation", 10)
	main_container.add_child(missions_container)
	
	# Create mission cards
	for i in range(missions.size()):
		var mission = missions[i]
		create_mission_card(mission, missions_container, ready_adventurers)
	
	# Show the popup
	mission_board_popup.popup_centered()
	print("Mission board popup shown!")

# Add this function to create individual mission cards:
func create_mission_card(mission: Dictionary, parent: VBoxContainer, ready_adventurers: Array):
	"""Create a card for each mission with details and assign button"""
	
	# Mission card container
	var card = PanelContainer.new()
	parent.add_child(card)
	
	# Style the card
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)  # Dark brown background
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.6, 0.4, 0.2, 1.0)  # Brown border
	card.add_theme_stylebox_override("panel", card_style)
	
	# Card content
	var card_content = HBoxContainer.new()
	card.add_child(card_content)
	card_content.add_theme_constant_override("separation", 15)
	
	# Mission details (left side)
	var details_container = VBoxContainer.new()
	card_content.add_child(details_container)
	details_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Mission name
	var mission_name = Label.new()
	mission_name.text = "⚔️ " + mission.name
	mission_name.add_theme_font_size_override("font_size", 16)
	mission_name.add_theme_color_override("font_color", Color.WHITE)
	details_container.add_child(mission_name)
	
	# Mission details
	var details = Label.new()
	var danger_text = get_danger_description(mission.danger)
	var reward_text = str(mission.reward_range[0]) + "-" + str(mission.reward_range[1]) + " gold"
	var party_text = "Party Required" if mission.get("party_required", false) else "Solo Mission"
	
	details.text = "🎯 " + danger_text + " | 💰 " + reward_text + " | 👥 " + party_text
	details.add_theme_font_size_override("font_size", 12)
	details.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	details_container.add_child(details)
	
	# Mission description (if we add them later)
	var description = Label.new()
	description.text = get_mission_description(mission.name)
	description.add_theme_font_size_override("font_size", 11)
	description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_container.add_child(description)
	
	# Assignment section (right side)
	var assignment_container = VBoxContainer.new()
	card_content.add_child(assignment_container)
	assignment_container.custom_minimum_size = Vector2(200, 0)
	
	# Check if mission can be assigned
	var can_assign = false
	var assign_text = ""
	
	if mission.get("party_required", false):
		if ready_adventurers.size() >= 2:  # Need at least 2 for party
			can_assign = true
			assign_text = "Assign Party"
		else:
			assign_text = "Need More Adventurers"
	else:
		if ready_adventurers.size() >= 1:
			can_assign = true
			assign_text = "Assign Adventurer"
		else:
			assign_text = "No Ready Adventurers"
	
	# Assign button
	var assign_button = Button.new()
	assign_button.text = assign_text
	assign_button.disabled = not can_assign
	assign_button.custom_minimum_size = Vector2(180, 40)
	assignment_container.add_child(assign_button)
	
	# Connect button to assignment function
	if can_assign:
		assign_button.pressed.connect(func(): assign_mission(mission, ready_adventurers))

# Add helper functions:
func get_danger_description(danger_level: int) -> String:
	"""Convert danger number to descriptive text"""
	match danger_level:
		1: return "Very Easy"
		2: return "Easy"
		3: return "Moderate"
		4: return "Hard"
		5: return "Very Hard"
		_: return "Unknown"

func get_mission_description(mission_name: String) -> String:
	"""Get flavor text for missions"""
	match mission_name:
		"Clear Slimes": return "Simple pest control. Perfect for beginners."
		"Escort Merchant": return "Protect a merchant caravan on dangerous roads."
		"Scavenge Herbs in Forest": return "Gather rare herbs from the enchanted forest."
		"Defend the Grain Warehouse": return "Guard the warehouse from bandits overnight."
		_: return "A standard guild contract."

# Add mission assignment function:
func assign_mission(mission: Dictionary, ready_adventurers: Array):
	"""Assign adventurers to a mission"""
	mission_board_popup.hide()  # Close the mission board
	
	if mission.get("party_required", false):
		# For party missions, take first 2-3 ready adventurers
		var party_size = min(3, ready_adventurers.size())
		var assigned_party = []
		
		for i in range(party_size):
			assigned_party.append(ready_adventurers[i])
		
		log_message("⚔️ Assigning party to: " + mission.name)
		for adv in assigned_party:
			log_message("👥 " + adv.name + " (" + adv.class + ") joins the party")
		
		# Use your existing mission system but with party
		send_party_on_mission(assigned_party, mission)
	else:
		# For solo missions, take the first ready adventurer
		var adventurer = ready_adventurers[0]
		log_message("⚔️ " + adventurer.name + " is embarking on: " + mission.name)
		send_on_mission(adventurer, mission)

# Add party mission function (enhanced version of your existing one):
func send_party_on_mission(party: Array, mission: Dictionary):
	"""Send a party of adventurers on a mission"""
	var party_score = 0
	var healer_count = 0
	
	# Calculate combined party score
	for adv in party:
		match adv.class:
			"Fighter":
				party_score += adv.strength + adv.endurance
			"Rogue":
				party_score += adv.dexterity + adv.endurance
			"Mage":
				party_score += adv.intelligence * 1.5
			"Healer":
				party_score += adv.intelligence
				healer_count += 1
	
	# Party bonus: more adventurers = better teamwork
	party_score += party.size() * 2
	
	# Healer bonus: reduces injury chance
	if healer_count > 0:
		party_score += healer_count * 3
	
	var roll = randi() % 6 + 1
	party_score += roll
	var difficulty = mission.danger * 10
	
	log_message("🎲 Party score: " + str(party_score) + " vs Difficulty: " + str(difficulty))
	
	if party_score >= difficulty:
		# SUCCESS!
		var base_reward = randi() % (mission.reward_range[1] - mission.reward_range[0] + 1) + mission.reward_range[0]
		var party_bonus = party.size() * 2  # Bonus for party missions
		var total_reward = base_reward + party_bonus
		
		gold += total_reward
		log_message("✅ SUCCESS! Party completed " + mission.name + " and earned " + str(total_reward) + " gold!")
		
		# Update all party members
		for adv in party:
			for a in adventurers:
				if a.id == adv.id:
					a.missions_completed += 1
					a.gold_earned += total_reward / party.size()  # Split the gold
					a.status = "Recovering"
					a.recovery = 1
					break
	else:
		# FAILURE!
		log_message("💥 FAILED! Party failed the mission: " + mission.name)
		
		# Handle injuries (healer reduces chance)
		for adv in party:
			var injury_roll = randi() % 6 + 1
			if healer_count > 0:
				injury_roll += 2  # Healer protection
			
			for a in adventurers:
				if a.id == adv.id:
					if injury_roll <= 1:
						log_message("☠️ " + a.name + " died on the mission!")
						adventurers.erase(a)
					else:
						log_message("🤕 " + a.name + " was injured.")
						a.status = "Recovering"
						a.recovery = randi() % 4 + 2
						a.missions_failed += 1
						a.injuries_sustained += 1
					break
	
	update_ui()
	update_adventurer_display()

func _on_mission_button_pressed() -> void:
	log_message("📋 Examining the mission board...")
	open_mission_board_popup()


func _on_mission_button_mouse_entered() -> void:
	tavern_mission_hover.visible = true
	print("Hovering over desk")


func _on_mission_button_mouse_exited() -> void:
	tavern_mission_hover.visible = false
	print("Left desk area")


func _on_next_day_button_pressed() -> void:
	advance_day()


func _on_desk_button_pressed() -> void:
	log_message("📋 Speaking with the guild administrator...")
	open_recruitment_desk_popup()


func _on_desk_button_mouse_exited() -> void:
	tavern_desk_hover.visible = false


func _on_desk_button_mouse_entered() -> void:
	tavern_desk_hover.visible = true

func open_recruitment_desk_popup():
	"""Show the recruitment desk with available candidates and roster management"""
	print("Opening recruitment desk popup...")
	
	# Generate new recruits if needed
	generate_available_recruits()
	
	# Clear any existing content first
	for child in desk_board_popup.get_children():
		if child.name != "CloseButton":
			child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Set popup properties
	desk_board_popup.title = "👥 Guild Administrator - Recruitment Office"
	desk_board_popup.size = Vector2(700, 600)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	desk_board_popup.add_child(main_container)
	main_container.add_theme_constant_override("separation", 15)
	
	# Header
	var header = Label.new()
	header.text = "\"Welcome, Guildmaster. Here are today's applicants.\""
	header.add_theme_font_size_override("font_size", 16)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(header)
	
	# Current roster info
	var roster_info = Label.new()
	roster_info.text = "Current Roster: " + str(adventurers.size()) + "/" + str(max_adventurers) + " | Available Gold: " + str(gold)
	roster_info.add_theme_font_size_override("font_size", 14)
	roster_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(roster_info)
	
	# Create tabs for different sections
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(650, 450)
	main_container.add_child(tab_container)
	
	# Tab 1: Available Recruits
	create_available_recruits_tab(tab_container)
	
	# Tab 2: Current Roster
	create_current_roster_tab(tab_container)
	
	# Show the popup
	desk_board_popup.popup_centered()
	print("Recruitment desk popup shown!")

func generate_available_recruits():
	"""Generate a pool of available recruits for the day"""
	# Only generate if we don't have any, or it's a new day
	if available_recruits.size() == 0:
		available_recruits.clear()
		
		# Generate 3-5 random applicants
		var num_recruits = randi() % 3 + 3  # 3-5 recruits
		
		for i in range(num_recruits):
			var recruit = create_recruit_applicant()
			available_recruits.append(recruit)
		
		log_message("📋 " + str(num_recruits) + " new applicants have arrived today!")

func create_recruit_applicant():
	"""Create a potential recruit with stats and hiring cost"""
	var recruit = create_adventurer()  # Use existing function
	
	# Add recruitment-specific data
	recruit["hiring_cost"] = calculate_hiring_cost(recruit)
	recruit["personality"] = get_random_personality()
	recruit["background"] = get_random_background(recruit.class)
	recruit["availability"] = "Available"  # Available, Hired, Declined
	
	return recruit

func calculate_hiring_cost(recruit: Dictionary) -> int:
	"""Calculate hiring cost based on stats and class"""
	var base_cost = 10
	var stat_bonus = (recruit.strength + recruit.dexterity + recruit.intelligence + recruit.endurance - 16) * 2
	var class_bonus = 0
	
	match recruit.class:
		"Fighter": class_bonus = 0
		"Rogue": class_bonus = 2
		"Mage": class_bonus = 5
		"Healer": class_bonus = 8  # Most expensive
	
	return max(5, base_cost + stat_bonus + class_bonus)

func get_random_personality() -> String:
	"""Get a random personality trait"""
	var personalities = [
		"Eager", "Cautious", "Brave", "Greedy", "Loyal", "Reckless", 
		"Wise", "Ambitious", "Humble", "Proud", "Calm", "Fiery"
	]
	return personalities[randi() % personalities.size()]

func get_random_background(character_class: String) -> String:
	"""Get a background story based on class"""
	var backgrounds = {
		"Fighter": [
			"Former city guard",
			"Retired soldier", 
			"Village protector",
			"Tournament fighter",
			"Mercenary veteran"
		],
		"Rogue": [
			"Reformed thief",
			"Scout from the borderlands",
			"Former spy",
			"Treasure hunter",
			"Street informant"
		],
		"Mage": [
			"Academy dropout",
			"Wandering scholar",
			"Court wizard's apprentice",
			"Self-taught spellcaster",
			"Library researcher"
		],
		"Healer": [
			"Temple acolyte",
			"Traveling physician",
			"Herbalist from the forest",
			"Military medic",
			"Village wise woman"
		]
	}
	var class_backgrounds = backgrounds.get(character_class, ["Unknown origin"])
	return class_backgrounds[randi() % class_backgrounds.size()]

func create_available_recruits_tab(parent: TabContainer):
	"""Create the tab showing available recruits"""
	var recruits_tab = ScrollContainer.new()
	recruits_tab.name = "Available Recruits"
	parent.add_child(recruits_tab)
	
	var recruits_container = VBoxContainer.new()
	recruits_tab.add_child(recruits_container)
	recruits_container.add_theme_constant_override("separation", 10)
	
	if available_recruits.size() == 0:
		var no_recruits = Label.new()
		no_recruits.text = "No applicants available today. Try again tomorrow!"
		no_recruits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recruits_container.add_child(no_recruits)
		return
	
	# Create cards for each available recruit
	for recruit in available_recruits:
		if recruit.availability == "Available":
			create_recruit_card(recruit, recruits_container)

func create_recruit_card(recruit: Dictionary, parent: VBoxContainer):
	"""Create a detailed card for each recruit"""
	var card = PanelContainer.new()
	parent.add_child(card)
	
	# Style the card
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.15, 0.2, 0.15, 0.9)  # Dark green background
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.4, 0.6, 0.4, 1.0)  # Green border
	card.add_theme_stylebox_override("panel", card_style)
	
	var card_content = HBoxContainer.new()
	card.add_child(card_content)
	card_content.add_theme_constant_override("separation", 20)
	
	# Left side: Character info
	var info_container = VBoxContainer.new()
	card_content.add_child(info_container)
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Name and class
	var name_label = Label.new()
	name_label.text = "🗡️ " + recruit.name + " the " + recruit.class
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_container.add_child(name_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "💪 STR:" + str(recruit.strength) + " | 🏃 DEX:" + str(recruit.dexterity) + " | 🧠 INT:" + str(recruit.intelligence) + " | ❤️ END:" + str(recruit.endurance)
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_container.add_child(stats_label)
	
	# Background and personality
	var background_label = Label.new()
	background_label.text = "📖 " + recruit.background + " | 😊 " + recruit.personality
	background_label.add_theme_font_size_override("font_size", 11)
	background_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	background_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(background_label)
	
	# Right side: Hiring
	var hiring_container = VBoxContainer.new()
	card_content.add_child(hiring_container)
	hiring_container.custom_minimum_size = Vector2(150, 0)
	
	# Hiring cost
	var cost_label = Label.new()
	cost_label.text = "💰 Hiring Cost: " + str(recruit.hiring_cost) + "g"
	cost_label.add_theme_font_size_override("font_size", 14)
	cost_label.add_theme_color_override("font_color", Color.YELLOW)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hiring_container.add_child(cost_label)
	
	# Hire button
	var hire_button = Button.new()
	hire_button.custom_minimum_size = Vector2(120, 35)
	hiring_container.add_child(hire_button)
	
	# Check if we can hire
	var can_hire = gold >= recruit.hiring_cost and adventurers.size() < max_adventurers
	
	if can_hire:
		hire_button.text = "Hire"
		hire_button.pressed.connect(func(): hire_recruit(recruit))
	else:
		if gold < recruit.hiring_cost:
			hire_button.text = "Too Expensive"
		else:
			hire_button.text = "Roster Full"
		hire_button.disabled = true

func create_current_roster_tab(parent: TabContainer):
	"""Create the tab showing current adventurers"""
	var roster_tab = ScrollContainer.new()
	roster_tab.name = "Current Roster"
	parent.add_child(roster_tab)
	
	var roster_container = VBoxContainer.new()
	roster_tab.add_child(roster_container)
	roster_container.add_theme_constant_override("separation", 10)
	
	if adventurers.size() == 0:
		var no_adventurers = Label.new()
		no_adventurers.text = "No adventurers in your guild yet. Hire some from the Available Recruits tab!"
		no_adventurers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roster_container.add_child(no_adventurers)
		return
	
	# Create cards for each current adventurer
	for adventurer in adventurers:
		create_adventurer_roster_card(adventurer, roster_container)

func create_adventurer_roster_card(adventurer: Dictionary, parent: VBoxContainer):
	"""Create a card showing current adventurer details"""
	var card = PanelContainer.new()
	parent.add_child(card)
	
	# Style the card
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.2, 0.15, 0.2, 0.9)  # Dark purple background
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.6, 0.4, 0.6, 1.0)  # Purple border
	card.add_theme_stylebox_override("panel", card_style)
	
	var card_content = HBoxContainer.new()
	card.add_child(card_content)
	card_content.add_theme_constant_override("separation", 20)
	
	# Left side: Basic info
	var info_container = VBoxContainer.new()
	card_content.add_child(info_container)
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Name and status
	var name_label = Label.new()
	var status_icon = "✅" if adventurer.status == "Ready" else "🏥"
	name_label.text = status_icon + " " + adventurer.name + " the " + adventurer.class
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info_container.add_child(name_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "💪" + str(adventurer.strength) + " | 🏃" + str(adventurer.dexterity) + " | 🧠" + str(adventurer.intelligence) + " | ❤️" + str(adventurer.endurance)
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_container.add_child(stats_label)
	
	# Right side: Performance stats
	var performance_container = VBoxContainer.new()
	card_content.add_child(performance_container)
	performance_container.custom_minimum_size = Vector2(200, 0)
	
	# Mission stats
	var mission_stats = Label.new()
	mission_stats.text = "⚔️ Missions: " + str(adventurer.missions_completed) + " completed, " + str(adventurer.missions_failed) + " failed"
	mission_stats.add_theme_font_size_override("font_size", 11)
	mission_stats.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	performance_container.add_child(mission_stats)
	
	# Gold earned
	var gold_stats = Label.new()
	gold_stats.text = "💰 Total earned: " + str(adventurer.gold_earned) + "g"
	gold_stats.add_theme_font_size_override("font_size", 11)
	gold_stats.add_theme_color_override("font_color", Color.YELLOW)
	performance_container.add_child(gold_stats)
	
	# Status info
	var status_info = Label.new()
	if adventurer.status == "Recovering":
		status_info.text = "🏥 Recovering for " + str(adventurer.recovery) + " more days"
		status_info.add_theme_color_override("font_color", Color.ORANGE)
	else:
		status_info.text = "✅ Ready for missions"
		status_info.add_theme_color_override("font_color", Color.GREEN)
	status_info.add_theme_font_size_override("font_size", 11)
	performance_container.add_child(status_info)

func hire_recruit(recruit: Dictionary):
	"""Hire a recruit and add them to the adventurers roster"""
	if gold >= recruit.hiring_cost and adventurers.size() < max_adventurers:
		# Deduct cost
		gold -= recruit.hiring_cost
		
		# Add to roster
		var new_adventurer = recruit.duplicate()
		new_adventurer.erase("hiring_cost")
		new_adventurer.erase("personality") 
		new_adventurer.erase("background")
		new_adventurer.erase("availability")
		adventurers.append(new_adventurer)
		
		# Mark as hired
		recruit.availability = "Hired"
		
		# Update UI
		update_ui()
		update_adventurer_display()
		
		# Log the hiring
		log_message("🎉 Hired " + recruit.name + " the " + recruit.class + " for " + str(recruit.hiring_cost) + " gold!")
		log_message("👥 Guild roster: " + str(adventurers.size()) + "/" + str(max_adventurers))
		
		# Close and reopen popup to refresh
		desk_board_popup.hide()
		await get_tree().create_timer(0.1).timeout
		open_recruitment_desk_popup()
	else:
		log_message("❌ Cannot hire " + recruit.name + " - insufficient funds or roster full!")

# Add this function to refresh recruits daily:
func refresh_daily_recruits():
	"""Call this in advance_day() to refresh available recruits"""
	available_recruits.clear()
	log_message("📋 New applicants will arrive tomorrow!")
