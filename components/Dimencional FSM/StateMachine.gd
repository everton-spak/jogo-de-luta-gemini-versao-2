class_name StateMachine
extends State

@export var initial_state_name: String
var current_state: State
var current_state_name: String = ""
var last_winning_score: int = 0
var _global_state_map: Dictionary = {}

func _on_initialized() -> void:
	sub_components.clear()
	for child in get_children():
		# Registamos tudo o que for um nó para garantir que nada fica de fora
		sub_components[child.name] = child
		#print("✅ [%s] Filho registado no inventário: %s" % [name, child.name])
			
	# O seu Fighter.gd já garante que o fighter é passado para baixo
	for child in sub_components.values(): 
		if child.has_method("_on_initialized"):
			child._on_initialized()
				
		var trans_callable = Callable(self, "_on_child_transition_requested")
		if child.has_signal("transition_requested"):
			if not child.transition_requested.is_connected(trans_callable):
				child.transition_requested.connect(trans_callable)
				
	# Se eu não tenho um pai FSM, eu sou a RootFSM. Construo o mapa inteiro!
	if not _is_child_of_fsm():
		_build_global_map(self)
		print("🌍 [RootFSM] Mapa Global construído! Total de estados: ", _global_state_map.size())

func _on_enter(_payload: Dictionary = {}) -> void: pass
func _on_exit() -> void: pass
func _on_physics_update(_delta: float) -> void: pass

func enter(payload: Dictionary = {}) -> void:
	super.enter(payload)
	#print("--- 📥 [%s] RECEBEU CHAMADA ENTER! ---" % name)
	#if payload.has("query"):
		#print("🔍 [%s] Analisando Query: %s" % [name, payload["query"]])

	
	# 2. LOGICA DE INTERRUPÇÃO (GOLPES)
	# Se existe uma query, tentamos mudar de estado MESMO que já tenhamos um current_state
	if payload.has("query"):
		var query = payload["query"]
		var best_child_name = ""
		var best_score = -1
		
		# 2. Verifique se sub_components não está vazio
		if sub_components.is_empty():
			print("⚠️ [%s] Erro: sub_components está vazio! Os filhos não foram registrados." % name)
		
		for child_name in sub_components.keys():
			var child = sub_components[child_name]
			var score = _calculate_match_score(child, query)
			
			# 3. Este print TEM que aparecer para os filhos DIRETOS (ex: AttackStateMachine)
			#print("📊 [%s] comparando filho: %s | Score: %d" % [name, child_name, score])
			
			if score > best_score:
				best_score = score
				best_child_name = child_name
				
		if best_child_name != "" and best_score > 0:
			#print("➡️ FSM decidiu entrar no estado: ", best_child_name, " | Score Vencedor: ", best_score)
			last_winning_score = best_score
			change_state(best_child_name, payload)
			return # Saímos aqui pois o golpe foi processado
			
	# 3. LOGICA DE ENTRADA PADRÃO (Só executa se não for um golpe)
	_on_enter(payload) 
	
	# Só barramos a entrada se NÃO houver uma query e já estivermos num estado
	if current_state != null: 
		return

	var target_sub_state = payload.get("sub_state", initial_state_name)
	if target_sub_state != "":
		#print("📂 [", self.name, "] Roteando para a sub-pasta: ", target_sub_state)
		change_state(target_sub_state, payload)
		
func exit() -> void:
	super.exit()
	_on_exit()
	if current_state:
		current_state.exit()
		current_state = null
	current_state_name = ""

func physics_update(delta: float) -> void:
	super.physics_update(delta)
	_on_physics_update(delta) 
	if current_state: current_state.physics_update(delta)

func _calculate_match_score(node: State, query: Dictionary) -> int:
	var score = 0
	for key in query.keys():
		var dim_var = key + "_dim"
		if dim_var in node:
			var node_val = node.get(dim_var)
			if node_val == query[key]: score += 10 
			elif node_val == "any": score += 1 # "any" ganha pouco
			else: return -1 # Se for diferente e não for any, descarta
		else:
			# Se o nó NÃO tem a variável (é uma pasta genérica), 
			# ele não deve ganhar pontos extras.
			score += 0 # Mude de += 1 para += 0 aqui
		
	# 👇 ADICIONE ESTA LINHA PARA O LOG:
	#if score > 0:
		#print("📊 [Score] Nó: ", node.name, " | Pontuação: ", score, " para a Query: ", query)      
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
	# 👇 ADICIONE ESTA LINHA PARA DEBUG
	#print("Trying to enter state: ", new_state_name)
	if sub_components.has(new_state_name):
		if current_state: current_state.exit()
		current_state = sub_components[new_state_name] as State
		current_state_name = new_state_name 
		#print("➡️ [", self.name, "] Entrou no estado/pasta: ", current_state_name)
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
	# 1. Se o estado é meu filho direto, eu mudo agora
	if sub_components.has(new_state_name):
		change_state(new_state_name, payload)
	else:
		# 2. BUBBLING: Se NÃO é meu filho, passo o pedido para o meu pai (sobe na hierarquia)[cite: 2]
		var p = get_parent()
		if p and p.has_method("_on_child_transition_requested"):
			p._on_child_transition_requested(new_state_name, payload)
		else:
			# 3. Se eu for a RootFSM, uso a busca global
			change_state(new_state_name, payload)
