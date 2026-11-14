import '../community/community.dart';

/// Study groups and classes on the server (`/v1/circles`). Every call needs
/// the learner's ID token; failures throw `ShareException`, as sharing does.
abstract interface class CircleRepository {
  Future<List<Circle>> mine(String idToken);

  Future<Circle> create(
    String idToken, {
    required CircleKind kind,
    required String name,
    int goal = 3,
  });

  Future<Circle> join(String idToken, String code);

  /// The circle with the week of study days starting on [monday].
  Future<CircleDetail> detail(String idToken, String id, String monday);

  Future<void> update(
    String idToken,
    String id, {
    required String name,
    required int goal,
  });

  /// Leaves; an owner hands the circle on, the last member deletes it.
  Future<void> leave(String idToken, String id);

  /// The owner removes [member].
  Future<void> remove(String idToken, String id, String member);

  /// The teacher sets the shared deck [shareCode], due [due] (`yyyy-mm-dd`).
  Future<void> assign(String idToken, String id, String shareCode, String due);

  Future<void> unassign(String idToken, String id, String assignment);
}
