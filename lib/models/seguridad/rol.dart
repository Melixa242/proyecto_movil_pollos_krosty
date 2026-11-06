class Rol {
	final int? id;
	final String nombre;
	final String guardName;

	Rol({
		this.id,
		required this.nombre,
		required this.guardName,
	});

	factory Rol.fromJson(Map<String, dynamic> json) {
		return Rol(
			id: json['id'],
			nombre: json['name']?.toString() ?? json['nombre']?.toString() ?? '',
			guardName: json['guard_name']?.toString() ?? '',
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'name': nombre,
			'guard_name': guardName,
		};
	}
}