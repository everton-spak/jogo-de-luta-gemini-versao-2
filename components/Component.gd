class_name Component
extends Node

# --- REFERÊNCIAS DA HIERARQUIA ---
var fighter: CharacterBody2D
var parent_component: Component
var sub_components: Dictionary = {} # O dicionário que guarda todos os filhos que também são componentes

func _ready() -> void:
	# 1. Descobre quem é o lutador (a raiz física) e quem é o componente pai
	var parent = get_parent()
	if parent is CharacterBody2D:
		fighter = parent
	elif parent is Component:
		parent_component = parent
		fighter = parent_component.fighter # Herda a referência do lutador do pai
		
	# 2. Recursividade: Procura todos os filhos deste nó e regista-os se forem Componentes
	for child in get_children():
		if child is Component:
			sub_components[child.name] = child
			
	# 3. Executa a lógica individual de configuração do componente
	# (Usamos deferred para garantir que a árvore inteira já terminou o _ready)
	call_deferred("_on_initialized")

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
