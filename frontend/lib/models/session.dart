import 'package:frontend/models/trainer.dart';
import 'package:frontend/models/workshop.dart';

class Session {
  final int id;
  final String location;
  final String dateTime;
  final String targetAudience;
  final String registrationDeadline;
  final Workshop workshop;
  final List<Trainer> trainers;

  Session({
    required this.id,
    required this.location,
    required this.dateTime,
    required this.targetAudience,
    required this.registrationDeadline,
    required this.workshop,
    required this.trainers,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      location: json['location'],
      dateTime: json['date_time'],
      targetAudience: json['target_audience'],
      registrationDeadline: json['registration_deadline'],
      workshop: Workshop.fromJson(json['workshop']),
      trainers:
          (json['trainers'] as List)
              .map((trainer) => Trainer.fromJson(trainer))
              .toList(),
    );
  }
}
