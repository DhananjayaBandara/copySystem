class Workshop {
  final int id;
  final String title;
  final String description;

  Workshop({required this.id, required this.title, required this.description});

  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['id'],
      title: json['title'],
      description: json['description'],
    );
  }
}
