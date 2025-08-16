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
# Dynamic UI elements
var mission_button
var recruit_button
var log_display_area  # Clean log container

func _ready():
	print("=== ETERNAL GUILD STARTING ===")
	
	# Setup UI structure first
	setup_clean_log_system()
	setup_buttons()
	connect_signals()
	
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
func setup_buttons():
	"""Create the mission and recruit buttons in TopBar"""
	print("Setting up buttons...")
	
	# Mission button
	mission_button = Button.new()
	mission_button.text = "Send on Mission"
	mission_button.custom_minimum_size = Vector2(120, 0)
	top_bar.add_child(mission_button)
	
	# Recruit button
	recruit_button = Button.new()
	recruit_button.text = "Recruit (10g)"
	recruit_button.custom_minimum_size = Vector2(100, 0)
	top_bar.add_child(recruit_button)
	
	print("Buttons created!")

func connect_signals():
	"""Connect all button signals"""
	print("Connecting signals...")
	
	next_day_button.connect("pressed", _on_next_day_pressed)
	mission_button.connect("pressed", _on_mission_pressed)
	recruit_button.connect("pressed", _on_recruit_pressed)
	
	next_day_button.text = "Next Day"
	
	print("Signals connected!")

# === LOGGING SYSTEM ===


# === GAME LOGIC (unchanged - this is working perfectly!) ===

func _on_next_day_pressed():
	advance_day()

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

func _on_recruit_pressed():
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
	
	
	
