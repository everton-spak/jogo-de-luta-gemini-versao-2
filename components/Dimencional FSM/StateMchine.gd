class_name StateMachine
extends State

@export var initial_state_name: String
var current_state: State
var current_state_name: String = ""
var _global_state_map: Dictionary = {}

func _on_initialized() -> void:
	# 👇 CORREÇÃO: Obriga a FSM a registar os nós filhos!
	sub_components.clear()
	for child in get_children():
		if child is State:
			sub_components[child.name] = child
			
	super._on_initialized()
	
	if not _is_child_of_fsm():
		_global_state_map.clear()
		_build_global_map(self)
	
	for child in sub_components.values(): 
		if child is State:
			child.fighter = self.fighter
			if child.has_method("_on_initialized"):
				child._on_initialized()
				
			var trans_callable = Callable(self, "_on_child_transition_requested")
			if not child.transition_requested.is_connected(trans_callable):
				child.transition_requested.connect(trans_callable)
				
	# O Pontapé de Saída!
	if not _is_child_of_fsm() and initial_state_name != "":
		print("🟢 [FSM Raiz] A iniciar motor no estado: ", initial_state_name)
		change_state(initial_state_name)

func _on_enter(_payload: Dictionary = {}) -> void: pass
func _on_exit() -> void: pass
func _on_physics_update(_delta: float) -> void: pass

func enter(payload: Dictionary = {}) -> void:
	if payload.has("query"):
		print("🔍 FSM RECEBEU QUERY: ", payload["query"])
	_on_enter(payload) 
	if current_state != null: return
		
	if payload.has("query"):
		var query = payload["query"]
		var best_child_name = ""
		var best_score = -1
		
		for child_name in sub_components.keys():
			var child = sub_components[child_name]
			var score = _calculate_match_score(child, query)
			
			if score > best_score:
				best_score = score
				best_child_name = child_name
				
		if best_child_name != "":
			change_state(best_child_name, payload)
			return

	var target_sub_state = payload.get("sub_state", initial_state_name)
	if target_sub_state != "":
		print("📂 [", self.name, "] Roteando para a sub-pasta: ", target_sub_state)
		change_state(target_sub_state, payload)
		
func exit() -> void:
	_on_exit()
	if current_state:
		current_state.exit()
		current_state = null
	current_state_name = ""

func physics_update(delta: float) -> void:
	_on_physics_update(delta) 
	if current_state: current_state.physics_update(delta)

func _calculate_match_score(node: State, query: Dictionary) -> int:
	var score = 0
	for key in query.keys():
		var dim_var = key + "_dim"
		if dim_var in node:
			var node_val = node.get(dim_var)
			if node_val == query[key]: score += 10 
			elif node_val == "any" or node_val == "" or node_val == "none": score += 1  
			else: return -1   
		else: score += 1      
	return score

func _simulate_leaf_routing(query: Dictionary) -> State:
	var best_child = null
	var best_score = -1
	for child in sub_components.values():
		var score = _calculate_match_score(child, query)
		if score > best_score:
			best_score = score
			best_child = child
	if best_child != null:
		if best_child is StateMachine: return best_child._simulate_leaf_routing(query)
		else: return best_child
	return null

func _is_child_of_fsm() -> bool:
	var p = get_parent()
	while p != null:
		if p is StateMachine: return true
		p = p.get_parent()
	return false

func _build_global_map(root: StateMachine) -> void:
	for state_name in sub_components.keys():
		var state_node = sub_components[state_name]
		root._global_state_map[state_name] = state_node
		if state_node is StateMachine: state_node._build_global_map(root)

func find_state_recursive(target_name: String) -> State:
	if not _global_state_map.is_empty(): return _global_state_map.get(target_name)
	var p = get_parent()
	while p != null:
		if p is StateMachine and not p._global_state_map.is_empty(): return p._global_state_map.get(target_name)
		p = p.get_parent()
	return null

func get_tags() -> Array[String]:
	var tags = get_machine_tags()
	if current_state: tags.append_array(current_state.get_tags())
	var unique_tags: Array[String] = []
	for t in tags:
		if not t in unique_tags: unique_tags.append(t)
	return unique_tags

func get_machine_tags() -> Array[String]: return []

func change_state(new_state_name: String, payload: Dictionary = {}) -> void:
	if sub_components.has(new_state_name):
		if current_state: current_state.exit()
		current_state = sub_components[new_state_name] as State
		current_state_name = new_state_name 
		print("➡️ [", self.name, "] Entrou no estado/pasta: ", current_state_name)
		current_state.enter(payload)
	else:
		var target_node = find_state_recursive(new_state_name)
		if target_node: 
			_resolve_hierarchical_transition(target_node, payload)
		else:
			push_error("❌ ERRO GRAVE: O estado '" + new_state_name + "' não foi encontrado na FSM " + self.name + "!")

func _resolve_hierarchical_transition(target_node: State, payload: Dictionary) -> void:
	for child_name in sub_components.keys():
		var child = sub_components[child_name]
		if child == target_node or (child is StateMachine and child._contains_state_recursive(target_node)):
			if child != target_node: payload["sub_state"] = target_node.name
			change_state(child_name, payload)
			return

func _contains_state_recursive(target_node: State) -> bool:
	for child in sub_components.values():
		if child == target_node: return true
		if child is StateMachine and child._contains_state_recursive(target_node): return true
	return false
	
	
# =========================================================
# O OUVIDO DA MÁQUINA DE ESTADOS (Faltava isto!)
# =========================================================
func _on_child_transition_requested(new_state_name: String, payload: Dictionary = {}) -> void:
	print("📞 [", self.name, "] Ouviu o pedido de transição para: '", new_state_name, "'")
	change_state(new_state_name, payload)
