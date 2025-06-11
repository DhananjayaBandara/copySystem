class Participant {
  int id;
  String name;
  String email;
  String contactNumber;
  String nic;
  String dob;
  String district;
  String gender;
  Map<String, dynamic> properties;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.nic,
    required this.dob,
    required this.district,
    required this.gender,
    required this.properties,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      contactNumber: json['contact_number'],
      nic: json['nic'],
      dob: json['dob'],
      district: json['district'],
      gender: json['gender'],
      properties: json['properties'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact_number': contactNumber,
      'nic': nic,
      'dob': dob,
      'district': district,
      'gender': gender,
      'properties': properties,
    };
  }
}
