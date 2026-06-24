/// Represents the authenticated user's session within a specific SACCO tenant
/// workspace. The profile is hydrated from the JWT `app_metadata` and
/// `user_metadata` claims returned by Supabase on successful sign-in.
///
/// Fields:
/// - [userId]               — Supabase `auth.users.id` UUID
/// - [email]                — User's registered email address
/// - [fullName]             — Display name from `user_metadata.full_name`
/// - [assignedSaccoId]      — The SACCO UUID from `app_metadata.sacco_id`
/// - [targetSchemaNamespace]— The isolated DB schema from `app_metadata.schema_name`
/// - [userRole]             — Access level from `app_metadata.role`
/// - [bearerToken]          — Raw JWT access token for API calls
class SessionProfile {
  final String userId;
  final String email;
  final String fullName;
  final String assignedSaccoId;
  final String targetSchemaNamespace;
  final String userRole;
  final String bearerToken;

  const SessionProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.assignedSaccoId,
    required this.targetSchemaNamespace,
    required this.userRole,
    required this.bearerToken,
  });

  /// Constructs a [SessionProfile] from the raw Supabase user JSON map and the
  /// session access token. Matches the exact JWT claim structure documented in
  /// SKILLS_FRONTEND.md Section 5D.
  ///
  /// Expected [json] shape:
  /// ```json
  /// {
  ///   "id": "...",
  ///   "email": "...",
  ///   "app_metadata": { "sacco_id": "...", "schema_name": "...", "role": "..." },
  ///   "user_metadata": { "full_name": "..." }
  /// }
  /// ```
  factory SessionProfile.fromSupabaseUser(
    Map<String, dynamic> json,
    String token,
  ) {
    final appMeta = json['app_metadata'] as Map<String, dynamic>? ?? {};
    final userMeta = json['user_metadata'] as Map<String, dynamic>? ?? {};

    return SessionProfile(
      userId: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: userMeta['full_name'] as String? ?? 'Anonymous Member',
      assignedSaccoId: appMeta['sacco_id'] as String? ?? '',
      targetSchemaNamespace: appMeta['schema_name'] as String? ?? '',
      userRole: appMeta['role'] as String? ?? 'Member',
      bearerToken: token,
    );
  }

  /// Serialises the profile for local secure storage persistence.
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'assignedSaccoId': assignedSaccoId,
        'targetSchemaNamespace': targetSchemaNamespace,
        'userRole': userRole,
        'bearerToken': bearerToken,
      };

  /// Restores a [SessionProfile] from a previously serialised JSON map.
  factory SessionProfile.fromJson(Map<String, dynamic> json) => SessionProfile(
        userId: json['userId'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        assignedSaccoId: json['assignedSaccoId'] as String? ?? '',
        targetSchemaNamespace: json['targetSchemaNamespace'] as String? ?? '',
        userRole: json['userRole'] as String? ?? 'Member',
        bearerToken: json['bearerToken'] as String? ?? '',
      );

  /// Returns true when all critical identity fields are populated.
  bool get isValid =>
      userId.isNotEmpty &&
      assignedSaccoId.isNotEmpty &&
      targetSchemaNamespace.isNotEmpty;

  @override
  String toString() =>
      'SessionProfile(userId: $userId, role: $userRole, schema: $targetSchemaNamespace)';
}
