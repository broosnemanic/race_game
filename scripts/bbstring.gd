class_name BBString

## Utility class that produces a string in BBCode format
## Example code: var my_string: String = BBString.new("some text").bold.italic.color("red").string
## Using func alias this becomes: BBString.new("some text").b.i.c("red").string
## Note the .string is important because BBString functions return itself, so we have to ask for the string
## A BBString can be easily reset / reused by setting its string attribute: e.g. my_bbstring.string = "my_new_string"


var _string: String = ""	# Intermediary product
var base_string: String		# String attribute before formatting
var tags: Array[String]		# List of custom tags
var _count: int				# Count of <base_string> which 

# Attribute names
enum NAMES{
			BOLD, UNDERLINE, ITALIC, STRIKETHROUGH, CODE, FILL, INDENT, COLOR, 
			HINT, BGCOLOR, FGCOLOR, OUTLINECOLOR, OUTLINESIZE, CENTER, LEFT, RIGHT, 
			SIZE, FONT
			}


var settings: Dictionary[int, Variant] = {}
const BIG: int = 1000000
const BAD_TAG: String = "Bad Tag"

func _init(a_string: String) -> void:
	base_string = a_string


func str(a_string: String) -> BBString:
	base_string = a_string
	return self


# Returns result of <base_string> processed using <settings> 
var out: String:
	get:
		_string = base_string
		process_count()
		for i_key: NAMES in settings.keys():
			process_setting(i_key)
		process_tags()
		return _string






func process_setting(a_settings_key: NAMES):
	match a_settings_key:
		NAMES.BOLD:
			if (settings[a_settings_key] == false): return
			_string = "[b]" + _string + "[/b]"
		NAMES.UNDERLINE:
			if (settings[a_settings_key] == false): return
			_string = "[u]" + _string + "[/u]"
		NAMES.ITALIC:
			if (settings[a_settings_key] == false): return
			_string = "[i]" + _string + "[/i]"
		NAMES.STRIKETHROUGH:
			if (settings[a_settings_key] == false): return
			_string = "[s]" + _string + "[/s]"
		NAMES.CODE:
			if (settings[a_settings_key] == false): return
			_string = "[code]" + _string + "[/code]"
		NAMES.FILL:
			if (settings[a_settings_key] == false): return
			_string = "[f]" + _string + "[/f]"
		NAMES.INDENT:
			if (settings[a_settings_key] == false): return
			_string = "[indent]" + _string + "[/indent]"
		NAMES.CENTER:
			if (settings[a_settings_key] == false): return
			_string = "[center]" + _string + "[/center]"
		NAMES.LEFT:
			if (settings[a_settings_key] == false): return
			_string = "[left]" + _string + "[/left]"
		NAMES.RIGHT:
			if (settings[a_settings_key] == false): return
			_string = "[right]" + _string + "[/right]"
		NAMES.COLOR:
			_string = "[color=" + settings[a_settings_key] + "]" + _string + "[/color]"
		NAMES.HINT:
			_string = "[hint=" + settings[a_settings_key] + "]" + _string + "[/hint]"
		NAMES.COLOR:
			_string = "[color=" + settings[a_settings_key] + "]" + _string + "[/color]"
		NAMES.BGCOLOR:
			_string = "[bgcolor=" + settings[a_settings_key] + "]" + _string + "[/bgcolor]"
		NAMES.FGCOLOR:
			_string = "[fgcolor=" + settings[a_settings_key] + "]" + _string + "[/fgcolor]"
		NAMES.OUTLINECOLOR:
			_string = "[outline_color=" + settings[a_settings_key] + "]" + _string + "[/outline_color]"
		NAMES.OUTLINESIZE:
			_string = "[outline_size=" + str(settings[a_settings_key]) + "]" + _string + "[/outline_size]"
		NAMES.SIZE:
			_string = "[font_size=" + str(settings[a_settings_key]) + "]" + _string + "[/font_size]"
		NAMES.FONT:
			_string = "[font=" + settings[a_settings_key] + "]" + _string + "[/font]"



func process_tags():
	for i_tag: String in tags:
		_string = i_tag + _string + closing_tag(i_tag)


func process_count():
	for i_index: int in range(_count):
		if i_index == 0: continue
		_string += base_string

func clear():
	settings = {}


var bold: BBString:
	get:
		settings[NAMES.BOLD] = true
		#string = "[b]" + string + "[/b]"
		return self


# Short alias for bold
var b: BBString:
	get:
		return bold


var underline: BBString:
	get:
		#string = "[u]" + string + "[/u]"
		settings[NAMES.UNDERLINE] = true
		return self


# Short alias for underline
var u: BBString:
	get:
		return underline


var italic: BBString:
	get:
		#string = "[i]" + string + "[/i]"
		settings[NAMES.ITALIC] = true
		return self


# Short alias for italic
var i: BBString:
	get:
		return italic


var strikethrough: BBString:
	get:
		#string = "[s]" + string + "[/s]"
		settings[NAMES.STRIKETHROUGH] = true
		return self


# Short alias for strikethrough
var s: BBString:
	get:
		return strikethrough


var code: BBString:
	get:
		#string = "[code]" + string + "[/code]"
		settings[NAMES.CODE] = true
		return self


var fill: BBString:
	get:
		#string = "[f]" + string + "[/f]"
		settings[NAMES.FILL] = true
		return self


# Short alias for fill
var f: BBString:
	get:
		return fill


var indent: BBString:
	get:
		#string = "[indent]" + string + "[/indent]"
		settings[NAMES.INDENT] = true
		return self


var center: BBString:
	get:
		#string = "[center]" + string + "[/center]"
		settings[NAMES.CENTER] = true
		return self


var left: BBString:
	get:
		#string = "[left]" + string + "[/left]"
		settings[NAMES.LEFT] = true
		return self


var right: BBString:
	get:
		#string = "[right]" + string + "[/right]"
		settings[NAMES.RIGHT] = true
		return self


func color(a_color_name: String) -> BBString:
	#string = "[color=" + a_color_name + "]" + string + "[/color]"
	settings[NAMES.COLOR] = a_color_name
	return self


# Short alias for color
func c(a_color_name: String) -> BBString:
	return color(a_color_name)


func hint(a_hint: String) -> BBString:
	#string = "[hint=" + a_hint + "]" + string + "[/hint]"
	settings[NAMES.HINT] = a_hint
	return self


# Short alias for hint
func h(a_hint: String) -> BBString:
	return hint(a_hint)


func bgcolor(a_color_name: String) -> BBString:
	#string = "[bgcolor=" + a_color_name + "]" + string + "[/bgcolor]"
	settings[NAMES.BGCOLOR] = a_color_name
	return self


# Short alias for bgcolor
func bg(a_color_name: String) -> BBString:
	return bgcolor(a_color_name)


func fgcolor(a_color_name: String) -> BBString:
	settings[NAMES.FGCOLOR] = a_color_name
	return self


func outline_color(a_color_name: String) -> BBString:
	settings[NAMES.OUTLINECOLOR] = a_color_name
	return self


func outline_size(a_size: int) -> BBString:
	settings[NAMES.OUTLINESIZE] = a_size
	return self


func size(a_font_size: int) -> BBString:
	settings[NAMES.SIZE] = a_font_size
	return self


func font(a_font_path: String) -> BBString:
	settings[NAMES.FONT] = a_font_path
	return self


func tag(a_tag: String) -> BBString:
	if (is_well_formed_tag(a_tag)):
		tags.append(a_tag)
	return self


func count(a_count: int) -> BBString:
	if a_count < 0 or a_count > 100:
		push_warning("BBString.count() has bad arg")
	_count = mini(abs(a_count), 100)
	return self


# Parses the tag name from a well-formed tag
func tag_name_from_tag(a_tag: String) -> String:
	var t_name: String = ""
	if not is_well_formed_tag(a_tag): return BAD_TAG
	var t_space: int = a_tag.find(" ") if a_tag.find(" ") > 0 else BIG
	var t_equal: int = a_tag.find("=") if a_tag.find("=") > 0 else BIG
	var t_end: int = mini(t_space, t_equal)
	t_end = a_tag.length() - 2 if t_end == BIG else t_end - 1
	t_name = a_tag.substr(1, t_end)
	return t_name



func is_well_formed_tag(a_tag: String) -> bool:
	var t_length: int = a_tag.length()
	if t_length < 4: return false
	if a_tag[0] != "[": return false
	if a_tag[t_length - 1] != "]": return false
	return true



func closing_tag(a_tag:String) -> String:
	if (not is_well_formed_tag(a_tag)): return BAD_TAG
	var t_name: String = tag_name_from_tag(a_tag)
	return "[/" + t_name + "]"
	
	
	
	
	
	
	
	
