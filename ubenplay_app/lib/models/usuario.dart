/// Usuario registrado en la app (estudiante).
///
/// Es la "sesión" que se persiste en SharedPreferences. Refleja el estado
/// devuelto por el backend (`/api/usuarios/*`).
class Usuario {
  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final int rangoEdad; // 1<18, 2=18-35, 3=36-50, 4>50
  final String pais;
  final String? correoRepresentante;
  final int estado; // 0 inactivo (pendiente de código), 1 activo
  final int lopdp; // 0 no autorizado, 1 autorizado
  final int nivelAcceso;

  const Usuario({
    this.idUsuario,
    this.nombre = '',
    this.apellido = '',
    this.correo = '',
    this.rangoEdad = 2,
    this.pais = '',
    this.correoRepresentante,
    this.estado = 0,
    this.lopdp = 0,
    this.nivelAcceso = 1,
  });

  String get nombreCompleto {
    final s = '$nombre $apellido'.trim();
    return s.isEmpty ? correo : s;
  }

  bool get esMenor => rangoEdad == 1;
  bool get activo => estado == 1;
  bool get autorizadoLopdp => lopdp == 1;

  Usuario copyWith({
    int? idUsuario,
    String? nombre,
    String? apellido,
    String? correo,
    int? rangoEdad,
    String? pais,
    String? correoRepresentante,
    int? estado,
    int? lopdp,
    int? nivelAcceso,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      correo: correo ?? this.correo,
      rangoEdad: rangoEdad ?? this.rangoEdad,
      pais: pais ?? this.pais,
      correoRepresentante: correoRepresentante ?? this.correoRepresentante,
      estado: estado ?? this.estado,
      lopdp: lopdp ?? this.lopdp,
      nivelAcceso: nivelAcceso ?? this.nivelAcceso,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] ?? json['idUsuario'],
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      rangoEdad: json['rango_edad'] ?? json['rangoEdad'] ?? 2,
      pais: json['pais'] as String? ?? '',
      correoRepresentante: json['correo_representante'] as String?,
      estado: json['estado'] ?? 0,
      lopdp: json['lopdp'] ?? 0,
      nivelAcceso: json['nivel_acceso'] ?? json['nivelAcceso'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_usuario': idUsuario,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'rango_edad': rangoEdad,
        'pais': pais,
        'correo_representante': correoRepresentante,
        'estado': estado,
        'lopdp': lopdp,
        'nivel_acceso': nivelAcceso,
      };
}
