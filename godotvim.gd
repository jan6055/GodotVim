@tool
extends EditorPlugin

enum VimMode {
	Normal = 1,
	Insert = 2,
	Command = 3,
	Visial = 4,
}

const WHITE_SPACE: String = " \n\t"
const SYMBOL: String = "!@#$%^&*()+~`-=[]{}:;\'\"<>,./?"
#在当前状态下，按下特定的按键执行的动作
var insert_keycode_actions: Dictionary = {
	"Escape": set_normal_mode,
}

#用户可视模式和普通模式的命令缓冲
#如果normal_keycode_actions中没有映射，并且unhandle_keycode也没有
#则存放在这个缓冲区中
var input_buffuer: String = ""



var normal_keycode_actions: Dictionary = {
	"I": set_insert_mode,
	"Shift+I": set_insert_mode_adjoint.bind(move_caret_soft_line_start),
	"O": set_insert_mode_adjoint.bind(new_line_down),
	"Shift+O": set_insert_mode_adjoint.bind(new_line_up),
	"A": a_action,
	"Shift+A": set_insert_mode_adjoint.bind(move_caret_line_end),
	"H": move_caret_left,
	"Left": move_caret_left,
	"L": move_caret_right,
	"Right": move_caret_right,
	"J": move_caret_down,
	"Shift+J": merge_two_lines,
	"Down": move_caret_down,
	"K": move_caret_up,
	"Up": move_caret_up,
	"W": move_caret_next_word,
	"Shift+W": move_caret_next_word,
	"B": move_caret_previous_word,
	"Shift+B": move_caret_previous_word,
	"U": undo,
	"0": move_caret_line_start,
	"Shift+6": move_caret_soft_line_start,
	"Shift+4": move_caret_line_end,
	"Shift+Equal": move_caret_soft_line_down_start,
	"Minus": move_caret_soft_line_up_start,
	"X": delete_caret_char,
	"Ctrl+R": redo,
	"Escape": normal_escape,
	"Shift+D": delete_to_line_end,
}


func normal_escape():
	code_editor.deselect()

func a_action():
	code_editor.set_caret_column(current_column() + 1)
	set_insert_mode()

func undo():
	code_editor.undo()
	code_editor.deselect()
func redo():
	code_editor.redo()
##t
#当前光标所在的列，从0开始
func current_column() -> int:
	return code_editor.get_caret_column()
	
var unhandle_keycode = [
	KEY_F1,KEY_F2,KEY_F3,KEY_F4,KEY_F5,
	KEY_F6,KEY_F7,KEY_F8,KEY_F9,KEY_F10
]
var current_mode = VimMode.Normal
var editor_interface: EditorInterface;
var script_editor : ScriptEditor
var default_mode = VimMode.Normal

#编辑当前脚本的编辑器，每个脚本都有一个实例化
var code_editor : CodeEdit

var key_event: InputEventKey;
const TO_END = 999999999

func check_unhandle() -> bool:
	if current_mode == VimMode.Insert:
		return false
	if not unhandle_keycode.has(key_event.keycode):
		get_viewport().set_input_as_handled()
		return true
	else:
		return false

#编译一个脚本
#如果此脚本存在，则用CodeEdit直接的打开
#否则调用ScriptEdit.open_script_create_dialog创建一个新文件，并打开
func edit_script_complete(script_name: String,line: int = -1, column: int = 0, grab_focus: bool = true):
	for script in script_editor.get_open_scripts():
		if script.source_code == script_name:
			pass
#			editor_interfac
		else:
			var base_name = split_scirpt_name(script_name)
			script_editor.open_script_create_dialog(script_name,"../")
			
			
func split_scirpt_name(script_name: String) -> String:
	if script_name.ends_with(".gd"):
		return script_name.left(-3)
	else:
		return script_name
		
#TODO
func all_file_path(path: String) -> Array[String]:
	var result: Array[String] = []
	return result

func set_visial_mode() -> void:
	code_editor.caret_type = TextEdit.CARET_TYPE_BLOCK
	current_mode = VimMode.Visial

func set_insert_mode_adjoint(adjoint_func: Callable) -> void:
	adjoint_func.call()
	set_insert_mode()
	
func set_insert_mode() -> void:
	code_editor.caret_type = TextEdit.CARET_TYPE_LINE
	current_mode = VimMode.Insert

func set_normal_mode() -> void:
	code_editor.caret_type = TextEdit.CARET_TYPE_BLOCK
	current_mode = VimMode.Normal
	if current_column() == current_line_text().length() and current_column() != 0:
		move_caret_left()
	# 取消当前编辑器选择的文本
	code_editor.deselect()
	#取消自动补全的菜单
	code_editor.cancel_code_completion()
	
#line：移动到的行数，如果是-1,则不动
#column：移动到的列数, 如果是-1,则不动
#note: 如果不传递任何参数，什么效果也不会发生
func move_caret(line: int = -1, column: int = -1) -> void:
	if line != -1:
		code_editor.set_caret_line(line)
	if column != -1:
		code_editor.set_caret_column(column)
	
######################MOVE ACTION#########################
func current_line() -> int:
	return code_editor.get_caret_line()
func caret_position() -> Vector2i:
	return Vector2i(code_editor.get_caret_line(),code_editor.get_caret_column())
	
func move_caret_line_start() -> void:
	move_caret(-1,0)
func move_caret_line_end() -> void:
	move_caret(-1, TO_END)
func move_caret_file_start() -> void:
	move_caret(0,0)
func move_caret_file_end() -> void:
	move_caret(TO_END,TO_END)
func move_caret_right() -> void:
	var pos = caret_position()
	if pos.y == current_line_text().length():
		move_caret_down()
		if pos.x + 1!= code_editor.get_line_count():
			move_caret_line_start()
	else:
		move_caret(-1,pos.y + 1)
func move_caret_soft_line_down_start():
	move_caret_down()
	move_caret_soft_line_start()
func move_caret_soft_line_up_start():
	move_caret_up()
	move_caret_soft_line_start()
	
func move_caret_left() -> void:
	var pos = caret_position()
	if pos.y == 0:
		move_caret_up()
		if pos.x != 0:
			move_caret_line_end()
	else:
		move_caret(-1,pos.y - 1)
func move_caret_down() -> void:
	var line = code_editor.get_caret_line()
	code_editor.set_caret_line(line + 1)
func move_caret_up() -> void:
	var line = code_editor.get_caret_line()
	code_editor.set_caret_line(line - 1)


func move_caret_screen_top() -> void:
	
	pass
func move_caret_screen_bottom() -> void:
	pass

#TODO
func move_next_word():
	pass

func new_line_up() -> void:
	
	move_caret_line_start()
	code_editor.insert_text_at_caret("\n")
	move_caret_up()
	
func new_line_down() -> void:
	move_caret_line_end()
	code_editor.insert_text_at_caret("\n")

#找到当前光标后的下一个单词的位置
func move_caret_next_word():
	const Symbol = 1
	const WhiteSpace = 2 
	const Letter = 3
	var currstate = 0;
	
	var index = current_column() 
	var text = current_line_text()
	while index < text.length():
		var ch = text[index]
		if WHITE_SPACE.contains(ch):
			currstate = WhiteSpace
		elif SYMBOL.contains(ch):
			if currstate == Letter or currstate == WhiteSpace:
				move_caret(-1,index)
				return
			currstate = Symbol
		else: 
			if currstate != Letter and currstate != 0:
				move_caret(-1,index)
				return
			else:
				currstate = Letter
		index += 1
		
	#到最后还不是下一个单词,向下一行递归的寻找
	if current_line() != code_editor.get_line_count():
		move_caret_down()
		move_caret_line_start()
		move_caret_next_word()

#只是简单的将光标移动至当前单词词首，
#如果当前光标处不是单词，则什么也不做
#如果已经在词首，则什么也不做
func move_caret_word_start_simple() -> bool:
	var flag: bool = false
	if current_word().length() != 0:
		var col = current_column()
		var text = current_line_text()	
		while col - 1>= 0:
			if WHITE_SPACE.contains(text[col-1]) or SYMBOL.contains(text[col-1]):
				break
			else:
				flag = true
			col -= 1
		if flag:
			move_caret(-1,col)
			return true
		else:
			return false
	else:
		return false

#移动到当前光标所在单词词尾
#行为等同于`move_caret_word_start_simple`
func move_caret_word_end_simple() -> bool:
	var flag: bool = false
	if current_word().length() != 0:
		var col = current_column()
		var text = current_line_text()
		while col + 1< current_line_text().length():
			if WHITE_SPACE.contains(text[col + 1]) or SYMBOL.contains(text[col + 1]):
				break
			else: 
				flag = true
			col += 1
		if flag: 
			move_caret(-1,col)
			return true
		else:
			return false
	else:
		return false
#对应VimMode.Normal 中的 "E" 和 "Shift+E"
func move_caret_word_end():
	pass
	move_caret_word_end_simple()

#获取光标处的单词
func current_word():
	return code_editor.get_word_under_caret()

#将当前光标移动到前一个单词
#如果当前光标不再词首，则移动到词首
func move_caret_previous_word():
	const Symbol = 1
	const WhiteSpace = 2 #05324850
	const Letter = 3
	var currstate = 0
	if move_caret_word_start_simple():
		return 
	#防止越界
	var index = min(current_column(),current_line_text().length() - 1)
	var text = current_line_text()

	
	while index >= 0:
		var ch = text[index]
		if WHITE_SPACE.contains(ch):
			currstate = WhiteSpace
		elif SYMBOL.contains(ch):
			if currstate == Letter or currstate == WhiteSpace:
				move_caret(-1,index)
				return
			currstate = Symbol
		else: 
			if currstate != Letter and currstate != 0:
				move_caret(-1,index)
				return
			else:
				currstate = Letter
		index -= 1
	if current_line() != 0:
		move_caret_up()
		move_caret_line_end()
		move_caret(-1,current_column() - 1)
		move_caret_word_start_simple()
	
func move_caret_soft_line_start():
	var col = 0
	var text = current_line_text()
	while col < text.length():
		if WHITE_SPACE.contains(text[col]):
			col += 1
		else: 
			break
	move_caret(-1,col)

func after_last_whitespace_index() -> int:
#	var text = current_line_text()
#	var col = current_column()
#	while col <= text.length():
#		if text[col]
	return 0
func before_whitespace_index() -> int:
	return 0





func current_line_text() -> String:
	return code_editor.get_line(code_editor.get_caret_line())
	




#############################ACTION########################
#调用这个函数，就像按下了keycode对应的按键一样
func press_key(keycode: int, ctrl: bool = false, shift: bool = false):
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.shift_pressed = shift
	event.ctrl_pressed = ctrl
	Input.parse_input_event(event)
	
func delete_caret_char():
	code_editor.select(current_line(),current_column(),current_line(),current_column() + 1)
	code_editor.delete_selection()
	move_caret(-1,current_column() - 1)
	print("delete")

func keycode_action(event: InputEventKey) -> void:
	var key_lable = event.as_text_keycode()
	print(event.as_text_keycode())
	check_unhandle()
	match current_mode:
		VimMode.Insert:
			if insert_keycode_actions.has(key_lable):
				insert_keycode_actions[key_lable].call()
		VimMode.Visial:
			pass
		VimMode.Normal:
			if normal_keycode_actions.has(key_lable):
				normal_keycode_actions[key_lable].call()

func _input(event: InputEvent) -> void:
	#如果当前输入事件不是键盘事件
	if not event is InputEventKey:
		return

	if code_editor and code_editor.has_focus() and event and event.is_pressed():
		if event is InputEventKey:
			key_event = event as InputEventKey
			keycode_action(key_event)

func set_code_editor_by_script(script: Script) -> void:
	print("script changed")
#	editor_interface.edit_script(script)
	code_editor = script_editor.get_current_editor().get_base_editor() as CodeEdit
	set_normal_mode()
	
func _enable_plugin() -> void:
	editor_interface = get_editor_interface()
	script_editor = editor_interface.get_script_editor()
	#当编辑的脚本做出改变的时候，更改相应的CodeEdit的实例
	if not script_editor.editor_script_changed.is_connected(set_code_editor_by_script):
		script_editor.editor_script_changed.connect(set_code_editor_by_script)
	if not script_editor.script_close.is_connected(reset_code_editor):
		script_editor.script_close.connect(reset_code_editor)
	code_editor = script_editor.get_current_editor().get_base_editor() as CodeEdit
	print("Enable VimMode")
	

func _disable_plugin() -> void:
	script_editor.editor_script_changed.disconnect(set_code_editor_by_script)
	script_editor.script_close.disconnect(reset_code_editor)
	print("Disable VimMode")

# 合并光标所在的行和光标所在的下一行，并以空格分隔
# 如果光标在最后一行，则什么也不做
func merge_two_lines():
	var line = current_line()
	var len = current_line_text().length()
	var next_line_text = code_editor.get_line(line+1)
	var col = next_line_text.length()
	
	if line == code_editor.get_line_count():
		return
	code_editor.select(line,len,line+1,col)
	code_editor.delete_selection()
	insert_text_at_caret(next_line_text)
	
func insert_text_at_caret(text: String) -> void:
	code_editor.insert_text_at_caret(text)

#选择光标所在的行
func select_line(): 
	var line = current_line()
	code_editor.select(line,0,line,current_line_text().length())

#删除光标所在的行并返回删除的字符串
func delete_line() -> String:
	var text: String = current_line_text()
	select_line()
	code_editor.delete_selection()
	return text

#这个函数有一些问题
#它不会立刻删除到行尾，而是有一个短暂的延迟
func delete_to_line_end():
	var line = current_line()
	var text = current_line_text()
	var col = current_column()
	code_editor.set_line(line,text.left(col))
	return text.right(-col)

func _enter_tree():
	_enable_plugin()
		
func reset_code_editor(_script: Script):
	code_editor = null
func _exit_tree():
	
	pass
