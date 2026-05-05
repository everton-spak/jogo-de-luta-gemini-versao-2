class_name Component
extends Node

# --- REFERÊNCIAS DA HIERARQUIA ---
var fighter: CharacterBody2D
var parent_component: Component
var sub_components: Dictionary = {} # O dicionário que guarda todos os filhos que também são componentes

func _ready() -> void:
	# 1. Descobre quem é o lutador (a raiz física) e quem é o componente pai
	# NOVA LÓGICA (ASCENSÃO): Em vez de olhar apenas 1 nível acima, fazemos um loop 
	# subindo pela árvore. Isso permite que o componente esteja dentro de pastas 
	# organizadoras (Nodes vazios) e ainda consiga achar o Fighter no topo.
	var current_parent = get_parent()
	while current_parent != null:
		if current_parent is CharacterBody2D:
			fighter = current_parent
			break # Achou o lutador, pode parar de subir!
		elif current_parent is Component:
			parent_component = current_parent
			fighter = parent_component.fighter # Herda a referência do lutador do pai
			break # Achou o componente pai, pode parar de subir!
			
		# Se o pai atual não for nem Fighter nem Component, assumimos que é uma pasta.
		# Então, pedimos o pai dessa pasta e o loop continua a subir!
		current_parent = current_parent.get_parent()
		
	# 2. Recursividade: Procura todos os filhos deste nó e regista-os se forem Componentes
	# NOVA LÓGICA (DESCENSÃO): Trocamos o loop simples por uma função recursiva.
	# Ela vai "mergulhar" nas pastas organizadoras para puxar os componentes de lá de dentro.
	_register_sub_components(self)
			
	# 3. Executa a lógica individual de configuração do componente
	# (Usamos deferred para garantir que a árvore inteira já terminou o _ready)
	call_deferred("_on_initialized")

# --- NOVA FUNÇÃO DE REGISTRO RECURSIVO ---
# Função auxiliar que vasculha a árvore para baixo, ignorando nós de organização
func _register_sub_components(node_to_search: Node) -> void:
	for child in node_to_search.get_children():
		if child is Component:
			# Achamos um componente! Regista no cache e para a busca neste galho
			# (Não precisamos olhar os filhos dele, pois o próprio _ready dele fará isso)
			sub_components[child.name] = child
		else:
			# Não é um componente. Provavelmente é um Node organizador (ex: "CombatComponents").
			# A mágica acontece aqui: chamamos esta mesma função para olhar DENTRO dessa pasta!
			_register_sub_components(child)

# --- COMUNICAÇÃO RECURSIVA (A Mágica do Sistema) ---

# Procura um componente em toda a árvore (Filhos e Pais)
func get_component(component_name: String) -> Component:
	# 1. Está nos meus sub-componentes diretos?
	if sub_components.has(component_name):
		return sub_components[component_name]
		
	# 2. Busca em profundidade: pergunta aos meus filhos se eles têm nos filhos deles
	for child in sub_components.values():
		var found = child.get_component_local(component_name)
		if found: 
			return found
		
	# 3. Não achei na minha sub-árvore? Subo a recursividade e peço ao meu pai!
	if parent_component:
		return parent_component.get_component(component_name)
		
	# Se chegou à raiz e não achou, retorna nulo
	return null

# Busca apenas para baixo (evita loop infinito de um pai perguntar pro filho e o filho perguntar pro pai)
func get_component_local(component_name: String) -> Component:
	if sub_components.has(component_name):
		return sub_components[component_name]
		
	for child in sub_components.values():
		var found = child.get_component_local(component_name)
		if found: 
			return found
			
	return null

# --- FUNÇÃO VIRTUAL ---
# Todo script que herdar de Component (Hitbox, Health, InputBuffer) deve usar esta função 
# em vez do _ready() nativo da Godot. Isso garante que as referências já foram carregadas.
func _on_initialized() -> void:
	pass
