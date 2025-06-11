import uuid
from django.db import models

# Participant Type Model
class ParticipantType(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    properties = models.JSONField(default=dict)  # Correct field for MySQL (Django >= 3.1)

    def __str__(self):
        return self.name


# Workshop Model
class Workshop(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=[('Upcoming', 'Upcoming'), ('Completed', 'Completed'), ('Cancelled', 'Cancelled')], default='Upcoming')

    def __str__(self):
        return self.title


# Session Model
class Session(models.Model):
    workshop = models.ForeignKey(Workshop, on_delete=models.CASCADE, related_name='sessions')
    date_time = models.DateTimeField()
    location = models.CharField(max_length=255)
    target_audience = models.CharField(max_length=255)
    registration_deadline = models.DateTimeField(null=True, blank=True)
    token = models.UUIDField(unique=True, default=uuid.uuid4, editable=False)  # Unique token for each session

    def __str__(self):
        return f"{self.workshop.title} - {self.date_time.strftime('%Y-%m-%d %H:%M')}"

    def get_session_url(self):
        from django.conf import settings
        return f"{settings.FRONTEND_BASE_URL}/session/{self.token}/attendance"


# Trainer Model
class Trainer(models.Model):
    name = models.CharField(max_length=255)
    designation = models.CharField(max_length=255)
    email = models.EmailField()
    contact_number = models.CharField(max_length=20)
    expertise = models.TextField()

    def __str__(self):
        return self.name


# TrainerSession Model (Many-to-Many linking)
class TrainerSession(models.Model):
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE)
    session = models.ForeignKey(Session, on_delete=models.CASCADE)

    class Meta:
        unique_together = ('trainer', 'session')

    def __str__(self):
        return f"{self.trainer.name} - {self.session}"


# Participant Model
class Participant(models.Model):
    name = models.CharField(max_length=150, default='Unknown')  # Add default here
    email = models.EmailField(unique=True)
    contact_number = models.CharField(max_length=20)
    nic = models.CharField(max_length=20,unique=True)
    dob = models.DateField()
    district = models.CharField(max_length=100)
    gender = models.CharField(max_length=10, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    participant_type = models.ForeignKey(ParticipantType, on_delete=models.SET_NULL, null=True)
    properties = models.JSONField(default=dict)

    def __str__(self):
        return self.name


# Registration Model
class Registration(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='registrations')
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='registrations')
    registered_on = models.DateTimeField(auto_now_add=True)
    attendance = models.BooleanField(default=False)

    class Meta:
        unique_together = ('participant', 'session')

    def __str__(self):
        return f"{self.participant} - {self.session}"


# Feedback Models
#---------------------------------------------------------------------------

# Feedback Questions Model
class FeedbackQuestion(models.Model):
    RESPONSE_TYPES = [
        ('paragraph', 'Paragraph'),
        ('checkbox', 'Checkbox'),
        ('rating', 'Rating'),
        ('text', 'Text'),
        ('multiple_choice', 'Multiple Choice'),
        ('yes_no', 'Yes/No'),
        ('scale', 'Scale'),
    ]

    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='feedback_questions')
    question_text = models.TextField()  # The feedback question itself
    response_type = models.CharField(max_length=20, choices=RESPONSE_TYPES)  # Type of response (e.g., paragraph, checkbox, rating)
    options = models.JSONField(null=True, blank=True)  # Store options for checkboxes or multiple-choice questions (JSON format)

    def __str__(self):
        return self.question_text

# Feedback Response Model
class FeedbackResponse(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='feedback_responses')
    question = models.ForeignKey(FeedbackQuestion, on_delete=models.CASCADE, related_name='responses')
    response = models.TextField()  # This will store the participant's response (it could be a text, JSON, rating, etc.)

    def __str__(self):
        return f"Response from {self.participant} to {self.question.question_text}"


# This model aggregates feedback from multiple participants into a session summary. It can be used for easy retrieval of feedback summaries for analysis and reports.
class SessionFeedback(models.Model):
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='session_feedback')
    total_responses = models.PositiveIntegerField(default=0)  # Track how many participants have provided feedback
    average_rating = models.FloatField(null=True, blank=True)  # Calculate and store average rating for the session if feedback includes ratings

    def update_feedback_summary(self):
        """Method to update the feedback summary (e.g., average rating, response count)"""
        feedback_responses = FeedbackResponse.objects.filter(question__session=self.session)
        total_ratings = 0
        rating_count = 0

        for response in feedback_responses:
            if response.question.response_type == 'rating':
                total_ratings += float(response.response)
                rating_count += 1

        self.total_responses = feedback_responses.count()
        self.average_rating = total_ratings / rating_count if rating_count > 0 else None
        self.save()

    def __str__(self):
        return f"Feedback for session {self.session.id}"


# This model can store reminders for participants to fill out feedback after a session. This will help in managing follow-up reminders (e.g., email).

class ParticipantFeedbackReminder(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name='feedback_reminders')
    session = models.ForeignKey(Session, on_delete=models.CASCADE, related_name='feedback_reminders')
    reminder_sent = models.BooleanField(default=False)  # Whether the reminder has been sent
    reminder_sent_at = models.DateTimeField(null=True, blank=True)  # When the reminder was sent

    def send_reminder(self):
        # Logic to send an email or notification reminder to the participant to fill feedback.
        pass

    def __str__(self):
        return f"Reminder for {self.participant} to fill feedback for session {self.session.id}"


class SessionStatistics(models.Model):
    session = models.OneToOneField(Session, on_delete=models.CASCADE, related_name='statistics')
    registered_count = models.PositiveIntegerField(default=0)
    attended_count = models.PositiveIntegerField(default=0)
    attendance_percentage = models.FloatField(default=0.0)
    average_rating = models.FloatField(null=True, blank=True)
    impact_summary = models.TextField(blank=True, null=True)
    improvement_suggestions = models.JSONField(default=list, blank=True)

    def __str__(self):
        return f"Statistics for session {self.session.id}"
