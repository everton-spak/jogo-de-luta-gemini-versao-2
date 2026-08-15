class_name CancelComponent
extends Component

# Autoridade GERAL sobre a LEGALIDADE de cancelamento entre estados.
# Divisão de responsabilidade:
#   - StateMachine = MECÂNICA (achar o leaf ativo + simular o leaf-alvo da query).
#   - CancelComponent = POLÍTICA ("essa transição é permitida AGORA?").
#
# É de propósito geral: vale pra TODA transição dirigida por input (movimento,
# normais, specials, supers). Não é exclusivo de nenhuma mecânica — por isso NÃO
# fica no SpecialMechanicComponent (que é só motion move) nem no AttackComponent
# (que executa um golpe por vez).
#
# A StateMachine chama can_cancel() pra decidir, e register_cancel() depois de
# confirmar a transição (pra contabilizar a rota do combo).
#
# Camadas de regra (avaliadas em can_cancel, da mais barata pra mais cara):
#   1. Neutro       — de tier 0 (Idle/Walk/Jump/...) libera qualquer coisa.
#   2. Janela       — dentro de um golpe, só cancela na fase permitida.
#   3. Hierarquia   — tier do alvo > tier atual (normal→special→super).
#   4. Gatling      — cadeia de normais por força (light→light) quando habilitado.
#   5. Self-cancel  — mesmo golpe, se can_cancel_self (rapid fire).
#   6. Hit confirm  — special/super só cancelam se o golpe atual conectou.
#                    (rastreado intrinsecamente via signal HitboxComponent.attack_connected)
#   7. Rota de combo — limite de special-cancels por combo (reset no neutro).

@export_group("Janela de Cancelamento")
# Em qual fase do golpe ATUAL um cancel é permitido. Em jogos reais raramente se
# cancela no startup; default deixa tudo true pra preservar o comportamento atual.
@export var allow_cancel_in_startup: bool = true
@export var allow_cancel_in_active: bool = true
@export var allow_cancel_in_recovery: bool = true

@export_group("Hit Confirm")
# Se true, cancelar um golpe em special/super (tier ≥3) exige que ele tenha
# CONECTADO. Rastreado intrinsecamente: o CancelComponent escuta o signal
# `attack_connected` do HitboxComponent e marca _hit_confirmed=true. Reseta a
# cada novo ataque (em register_cancel) e ao voltar pro neutro.
# OBS: projéteis (Hadouken) têm hitbox PRÓPRIA — esse rastreio só pega hits do
# hitbox principal do fighter. Pra hit-confirm em specials de projétil, o
# projétil precisaria emitir um signal que aqui escutaria também (TODO).
@export var require_hit_to_special_cancel: bool = false

@export_group("Gatling (cadeia de normais)")
# Habilita encadear normais de mesma força (ex: jab→jab, jab→short), que a regra
# de tier estrita bloquearia. light→heavy já é permitido pela hierarquia (2>1).
@export var enable_gatling: bool = false

@export_group("Rota de Combo")
# 0 = ilimitado. Limita quantos special-cancels (alvo tier ≥3) por combo.
@export var max_special_cancels_per_combo: int = 0

# Cadeia de gatling por strength_dim. Só usado quando enable_gatling = true.
const GATLING := {
	"light": ["light"],
	"heavy": [],
}

const TIER_SPECIAL := 3 # tier a partir do qual conta como "special" pra hit-confirm/limite.

var attack: AttackComponent

# Estado por combo — reset ao voltar pro neutro (via register_cancel).
var _special_cancels_used: int = 0
# Hit confirm — true se o ataque ATUAL conectou (set por signal do hitbox).
# Reset a cada novo ataque (register_cancel) e ao voltar pro neutro.
var _hit_confirmed: bool = false

func _on_initialized() -> void:
	attack = get_component("AttackComponent") as AttackComponent
	# Auto-pluga no hitbox principal pra rastrear hits do fighter.
	# (Hits de projétil não passam aqui — o projétil tem hitbox próprio.)
	var hitbox = get_component("HitboxComponent")
	if hitbox and hitbox.has_signal("attack_connected"):
		if not hitbox.attack_connected.is_connected(_on_attack_connected):
			hitbox.attack_connected.connect(_on_attack_connected)

func confirm_hit() -> void:
	_hit_confirmed = true

func _on_attack_connected(_target_box, _contact_point) -> void:
	confirm_hit()

# ==========================================
# Veredito principal — função PURA (sem efeitos colaterais).
# from = leaf ativo; to = leaf-alvo. Ambos vêm da StateMachine.
# ==========================================
func can_cancel(from: State, to: State) -> bool:
	if from == null or to == null:
		return true

	# 1. Neutro/movimento libera tudo.
	if from.cancel_tier_dim == 0:
		return true

	# 2. Janela: a fase atual do golpe permite cancelar?
	if not _phase_allows_cancel():
		return false

	# 3. Hierarquia de tier (base).
	var ok := to.cancel_tier_dim > from.cancel_tier_dim

	# 4. Gatling: cadeia de normais de mesma força (quando habilitado).
	if not ok and enable_gatling and _is_normal(from) and _is_normal(to):
		ok = _gatling_allows(from, to)

	# 5. Self-cancel (rapid fire) — mesmo golpe, se permitido nele.
	if not ok and to.name == from.name and from.can_cancel_self:
		ok = true

	if not ok:
		return false

	# 6. Hit confirm pra special/super.
	if require_hit_to_special_cancel and to.cancel_tier_dim >= TIER_SPECIAL and not _current_attack_connected():
		return false

	# 7. Limite de special-cancels por combo.
	if to.cancel_tier_dim >= TIER_SPECIAL and max_special_cancels_per_combo > 0:
		if _special_cancels_used >= max_special_cancels_per_combo:
			return false

	return true

# ==========================================
# Contabiliza a rota do combo. Chamado pela StateMachine DEPOIS de confirmar a
# transição (só quando can_cancel passou e o enter aconteceu de fato).
# ==========================================
func register_cancel(from: State, to: State) -> void:
	if from == null or to == null:
		return
	# Novo ataque começou → hit ainda não confirmado (vale pra cancels desta nova janela).
	if to.cancel_tier_dim >= 1:
		_hit_confirmed = false
	# Voltou pro neutro → combo acabou, zera a contagem.
	if from.cancel_tier_dim == 0:
		_reset_combo()
		return
	if to.cancel_tier_dim >= TIER_SPECIAL:
		_special_cancels_used += 1

func _reset_combo() -> void:
	_special_cancels_used = 0
	_hit_confirmed = false

# ==========================================
# Helpers de regra
# ==========================================

func _phase_allows_cancel() -> bool:
	if attack == null:
		return true
	match attack.current_phase():
		"startup": return allow_cancel_in_startup
		"active": return allow_cancel_in_active
		"recovery": return allow_cancel_in_recovery
		_: return true # "none" — leaf sem ciclo de ataque (Shoryuken/projétil/movimento)

func _is_normal(s: State) -> bool:
	return s.cancel_tier_dim == 1 or s.cancel_tier_dim == 2

func _gatling_allows(from: State, to: State) -> bool:
	var f := str(from.strength_dim)
	var t := str(to.strength_dim)
	return GATLING.has(f) and t in GATLING[f]

func _current_attack_connected() -> bool:
	# Flag interna setada pelo signal attack_connected do hitbox (auto-plugado
	# no _on_initialized) e resetada a cada novo ataque (em register_cancel).
	return _hit_confirmed
