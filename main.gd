extends Node3D

var money := 50000
var electricity := 100.0
var water := 100.0
var goods := 0
var workers := 2
var productivity := 1.0
var machine_level := 1
var player_pos := Vector3(0, 0.9, 8)
var production_timer := 0.0
var message := "مرحبًا بك في مصنعك الأول"
var task_progress := 0
var camera: Camera3D
var player: MeshInstance3D
var machines: Array[MeshInstance3D] = []
var workers_nodes: Array[MeshInstance3D] = []
var ui: Label

func _ready():
    _build_world()
    _build_ui()
    _spawn_player()
    _spawn_workers()
    _update_ui()

func _build_world():
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#111916")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#aebdb5")
    environment.ambient_light_energy = 0.75
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    add_child(sun)

    _box("الأرض", Vector3(0,-0.25,0), Vector3(30,0.5,22), Color("#29352f"))
    _box("المصنع", Vector3(0,1.5,0), Vector3(20,3,12), Color("#59646a"))
    _box("سقف", Vector3(0,3.2,0), Vector3(20.5,0.35,12.5), Color("#78858b"))
    _box("المستودع", Vector3(-11,1.5,-2), Vector3(4,3,7), Color("#765f4b"))
    _box("المختبر", Vector3(11,1.5,-2), Vector3(4,3,7), Color("#4d6470"))
    _box("الممر", Vector3(0,0,7), Vector3(30,0.12,3), Color("#3b413e"))

    for i in range(3):
        var m := _box("آلة", Vector3(-6 + i*6, 0.8, 0), Vector3(3,1.6,2), Color("#a4adb0"))
        machines.append(m)

    camera = Camera3D.new()
    camera.position = Vector3(0, 16, 17)
    camera.rotation_degrees = Vector3(-48, 0, 0)
    add_child(camera)
    camera.current = true

func _box(n:String, pos:Vector3, size:Vector3, color:Color) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mi.material_override = mat
    add_child(mi)
    return mi

func _spawn_player():
    player = _box("اللاعب", player_pos, Vector3(0.8,1.8,0.8), Color("#d9a441"))

func _spawn_workers():
    for i in range(workers):
        var w := _box("عامل", Vector3(-5+i*10,0.9,2), Vector3(0.7,1.7,0.7), Color("#4b83b8"))
        workers_nodes.append(w)

func _build_ui():
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := ColorRect.new()
    panel.position = Vector2(18,18)
    panel.size = Vector2(420,170)
    panel.color = Color(0.04,0.06,0.055,0.9)
    layer.add_child(panel)
    ui = Label.new()
    ui.position = Vector2(20,20)
    ui.size = Vector2(390,150)
    ui.add_theme_font_size_override("font_size", 18)
    panel.add_child(ui)

    var help := Label.new()
    help.text = "WASD للتحرك • تشغيل الإنتاج من الأزرار أدناه"
    help.position = Vector2(18,665)
    help.add_theme_font_size_override("font_size", 18)
    layer.add_child(help)

    var produce := Button.new()
    produce.text = "⚙ إنتاج"
    produce.position = Vector2(900,630)
    produce.size = Vector2(150,55)
    produce.pressed.connect(_produce)
    layer.add_child(produce)

    var bonus := Button.new()
    bonus.text = "💵 حافز العمال"
    bonus.position = Vector2(1060,630)
    bonus.size = Vector2(180,55)
    bonus.pressed.connect(_bonus)
    layer.add_child(bonus)

func _process(delta):
    _move_player(delta)
    production_timer += delta
    if production_timer >= 4.0:
        production_timer = 0
        if machine_level > 1 and electricity >= 5 and water >= 2:
            _produce()
    for i in workers_nodes.size():
        var w = workers_nodes[i]
        w.position.x = -6 + fmod(Time.get_ticks_msec()/900.0 + i*3.0, 12.0)
    _update_ui()

func _move_player(delta):
    var dir := Vector3.ZERO
    if Input.is_action_pressed("move_left"): dir.x -= 1
    if Input.is_action_pressed("move_right"): dir.x += 1
    if Input.is_action_pressed("move_up"): dir.z -= 1
    if Input.is_action_pressed("move_down"): dir.z += 1
    if dir.length() > 0:
        dir = dir.normalized()
        player_pos += dir * delta * 6.0
        player_pos.x = clamp(player_pos.x, -13.0, 13.0)
        player_pos.z = clamp(player_pos.z, -9.0, 9.0)
        player.position = player_pos

func _produce():
    if money < 300 or electricity < 8 or water < 3:
        message = "الموارد أو المال غير كافٍ للإنتاج"
        return
    var amount := int((8 + workers * 2 + machine_level * 3) * productivity)
    money -= 300
    electricity -= 8
    water -= 3
    goods += amount
    task_progress += amount
    message = "تم إنتاج %d وحدة" % amount
    if task_progress >= 30:
        message = "🎉 اكتملت مهمة الإنتاج! أرسل 30 وحدة للبيع"

func _bonus():
    if money < 1000:
        message = "لا يوجد رصيد كافٍ للحافز"
        return
    money -= 1000
    productivity = min(productivity + 0.15, 1.5)
    message = "💵 تم صرف حافز للعمال — الإنتاجية ارتفعت"

func _update_ui():
    if not ui: return
    ui.text = "🏭 محاكي المصنع\n\n💰 المال: %s ر.س\n⚡ الكهرباء: %d%%   💧 الماء: %d%%\n📦 المنتجات: %d\n👷 العمال: %d   ⚙ مستوى الآلات: %d\n\n🎯 المهمة: إنتاج 30 وحدة (%d/30)\n%s" % [money, electricity, water, goods, workers, machine_level, min(task_progress,30), message]
