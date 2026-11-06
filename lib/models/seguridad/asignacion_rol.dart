class AsignacionRol {
	final int? id;
	final int userId;
	final int roleId;
	final int? assignedBy;
	final List<dynamic> previousRoles;
	final List<dynamic> resultingRoles;
	final String userNombre;
	final String roleNombre;
	final String assignedByNombre;

	AsignacionRol({
		this.id,
		required this.userId,
		required this.roleId,
		this.assignedBy,
		this.previousRoles = const [],
		this.resultingRoles = const [],
		this.userNombre = '',
		this.roleNombre = '',
		this.assignedByNombre = '',
	});

	factory AsignacionRol.fromJson(Map<String, dynamic> json) {
		// El backend incluye las relaciones user, role y assigned_by como objetos.
		String nombre(dynamic rel) => rel is Map ? '${rel['name'] ?? rel['nombre'] ?? ''}' : '';
		final assignedBy = json['assigned_by'];
		return AsignacionRol(
			id: json['id'],
			userId: int.tryParse('${json['user_id']}') ?? 0,
			roleId: int.tryParse('${json['role_id']}') ?? 0,
			assignedBy: assignedBy is Map
					? int.tryParse('${assignedBy['id']}')
					: int.tryParse('$assignedBy'),
			previousRoles: json['previous_roles'] is List
					? List<dynamic>.from(json['previous_roles'])
					: [],
			resultingRoles: json['resulting_roles'] is List
					? List<dynamic>.from(json['resulting_roles'])
					: [],
			userNombre: nombre(json['user']),
			roleNombre: nombre(json['role']),
			assignedByNombre: nombre(assignedBy),
		);
	}

	/// El backend solo recibe usuario y rol; "asignado por" lo toma del usuario logueado.
	Map<String, dynamic> toJson() {
		return {
			'user_id': userId,
			'role_id': roleId,
		};
	}

	String get userDisplay => userNombre.isNotEmpty ? userNombre : '#$userId';
	String get roleDisplay => roleNombre.isNotEmpty ? roleNombre : '#$roleId';
	String get assignedByDisplay => assignedByNombre.isNotEmpty
			? assignedByNombre
			: (assignedBy == null ? '-' : '#$assignedBy');
}
