class VisitorRequest {
  final int id;
  final String guest;
  final String status;

  VisitorRequest({
    required this.id,
    required this.guest,
    required this.status,
  });

  factory VisitorRequest.fromJson(Map<String, dynamic> json) {
    return VisitorRequest(
      id: json['id'] ?? 0,
      guest: json['guest'] ?? 'Unknown',
      status: json['status'] ?? 'Pending',
    );
  }
}
