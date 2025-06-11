class Trainer {
  final int id;
  final String name;
  final String? designation;

  Trainer({required this.id, required this.name, this.designation});

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: json['id'],
      name: json['name'],
      designation: json['designation'],
    );
  }
}
