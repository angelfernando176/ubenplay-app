/// Perfil del usuario con datos personales
class UserProfile {
  final String firstName;
  final String lastName;
  final String ageRange; // '12-17', '18-26', '27-59', '60+'
  final String email;
  final bool isComplete;

  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.ageRange = '',
    this.email = '',
    this.isComplete = false,
  });

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    return '$firstName $lastName'.trim();
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? ageRange,
    String? email,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      ageRange: ageRange ?? this.ageRange,
      email: email ?? this.email,
      isComplete: true,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      ageRange: json['ageRange'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'ageRange': ageRange,
        'email': email,
        'isComplete': isComplete,
      };
}
