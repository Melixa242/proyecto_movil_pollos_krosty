class Usuario {
	final int? id;
	final String nombre;
	final String email;
	final String password;

	Usuario({
		this.id,
		required this.nombre,
		required this.email,
		this.password = '',
	});

	factory Usuario.fromJson(Map<String, dynamic> json) {
		return Usuario(
			id: json['id'],
			nombre: json['name']?.toString() ?? json['nombre']?.toString() ?? '',
			email: json['email']?.toString() ?? '',
			password: json['password']?.toString() ?? '',
		);
	}

	Map<String, dynamic> toJson() {
		final data = <String, dynamic>{
			'name': nombre,
			'email': email,
		};
		if (password.isNotEmpty) {
			data['password'] = password;
		}
		return data;
	}
}