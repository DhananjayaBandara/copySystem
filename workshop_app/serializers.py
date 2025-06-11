from rest_framework import serializers
from .models import (
    ParticipantType,
    Workshop,
    Session,
    Trainer,
    TrainerSession,
    Participant,
    Registration,
    FeedbackQuestion,
    FeedbackResponse,

)

import re

def validate_email_format(email):
    if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
        raise serializers.ValidationError("Invalid email format.")
    return email

def validate_contact_number(number):
    if not re.match(r"^\d{10}$", number):
        raise serializers.ValidationError("Contact number must be exactly 10 digits.")
    return number

def validate_nic(nic):
    if not (re.match(r"^\d{9}[vV]$", nic) or re.match(r"^\d{12}$", nic)):
        raise serializers.ValidationError("NIC must be 9 digits followed by 'V' or 12 digits.")
    return nic



# ParticipantType Serializer
class ParticipantTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParticipantType
        fields = '__all__'


# Workshop Serializer
class WorkshopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Workshop
        fields = '__all__'


# Session Serializer
class SessionSerializer(serializers.ModelSerializer):
    workshop_id = serializers.PrimaryKeyRelatedField(
        queryset=Workshop.objects.all(),
        source='workshop',
        write_only=True
    )
    workshop = WorkshopSerializer(read_only=True)
    trainers = serializers.SerializerMethodField()
    token = serializers.UUIDField(read_only=True)  # Include the token field

    class Meta:
        model = Session
        fields = [
            'id', 'workshop', 'workshop_id', 'date_time', 'location', 
            'target_audience', 'registration_deadline', 'trainers', 'token'
        ]

    def get_trainers(self, obj):
        trainer_sessions = TrainerSession.objects.filter(session=obj)
        return [
            {
                "id": ts.trainer.id,
                "name": ts.trainer.name
            }
            for ts in trainer_sessions
        ]



# Trainer Serializer
class TrainerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Trainer
        fields = '__all__'
    
    def validate_email(self, value):
            return validate_email_format(value)

    def validate_contact_number(self, value):
        return validate_contact_number(value)

# TrainerSession Serializer
class TrainerSessionSerializer(serializers.ModelSerializer):
    trainer_id = serializers.PrimaryKeyRelatedField(
        queryset=Trainer.objects.all(),
        source='trainer',
        write_only=True
    )
    session_id = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        source='session',
        write_only=True
    )
    trainer = TrainerSerializer(read_only=True)
    session = SessionSerializer(read_only=True)

    class Meta:
        model = TrainerSession
        fields = '__all__'


# Participant Serializer
class ParticipantSerializer(serializers.ModelSerializer):
    participant_type_id = serializers.PrimaryKeyRelatedField(
        queryset=ParticipantType.objects.all(),
        source='participant_type',
        write_only=True
    )
    participant_type = ParticipantTypeSerializer(read_only=True)

    class Meta:
        model = Participant
        fields = [
            'id', 'name', 'email', 'contact_number', 'nic', 'dob',
            'district', 'gender', 'participant_type', 'participant_type_id', 'properties'
        ]

    def validate_email(self, value):
        return validate_email_format(value)

    def validate_contact_number(self, value):
        return validate_contact_number(value)

    def validate_nic(self, value):
        return validate_nic(value)

    def validate(self, data):
        participant_type = data.get('participant_type')
        submitted_properties = data.get('properties', {})

        required_fields = participant_type.properties  # This should be a list of required field names
        missing_fields = [f for f in required_fields if f not in submitted_properties]

        if missing_fields:
            raise serializers.ValidationError({
                "properties": f"Missing required fields for {participant_type.name}: {', '.join(missing_fields)}"
            })

        return data



# Registration Serializer
class RegistrationSerializer(serializers.ModelSerializer):
    participant = ParticipantSerializer(read_only=True)
    participant_id = serializers.PrimaryKeyRelatedField(
        queryset=Participant.objects.all(),
        source='participant',
        write_only=True
    )

    session = SessionSerializer(read_only=True)
    session_id = serializers.PrimaryKeyRelatedField(
        queryset=Session.objects.all(),
        source='session',
        write_only=True
    )

    class Meta:
        model = Registration
        fields = [
            'id', 'participant', 'participant_id', 'session', 'session_id',
            'registered_on', 'attendance'
        ]



# Feedback Question Serializer
class FeedbackQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedbackQuestion
        fields = '__all__'

    def create(self, validated_data):
        request = self.context.get('request')
        return super().create(validated_data)
    
    def validate_session(self, value):
        if value is None:
            raise serializers.ValidationError("Session is required.")
        return value


# Feedback Response Serializer
class FeedbackResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedbackResponse
        fields = ['id', 'participant', 'question', 'response']
        read_only_fields = ['id']

    def validate(self, data):
        question = data.get('question')
        response = data.get('response')

        if not question:
            raise serializers.ValidationError("Question must be provided.")

        response_type = question.response_type

        # Accept all types, but validate format for structured types
        if response_type in ['paragraph', 'text']:
            if not isinstance(response, str):
                raise serializers.ValidationError("Response must be a string for paragraph/text type.")

        elif response_type == 'checkbox' or response_type == 'multiple_choice':
            import json
            try:
                value = json.loads(response)
                if not isinstance(value, list):
                    raise serializers.ValidationError("Checkbox/multiple_choice responses must be a JSON array.")
            except Exception:
                raise serializers.ValidationError("Checkbox/multiple_choice responses must be a valid JSON array.")

        elif response_type in ['rating', 'scale']:
            try:
                val = float(response)
                # Optionally, check range for scale/rating
            except ValueError:
                raise serializers.ValidationError("Rating/scale response must be a number.")

        elif response_type == 'yes_no':
            if response not in ['Yes', 'No', 'yes', 'no', True, False, 'true', 'false']:
                raise serializers.ValidationError("Yes/No response must be 'Yes' or 'No'.")

        else:
            # Accept any other types as string
            if not isinstance(response, str):
                raise serializers.ValidationError("Response must be a string.")

        return data


# Feedback Analysis Serializer
class FeedbackAnalysisSerializer(serializers.Serializer):
    question_id = serializers.IntegerField()
    question_text = serializers.CharField()
    response_type = serializers.CharField()
    analysis_result = serializers.JSONField()
    
class CalendarSessionSerializer(serializers.ModelSerializer):
    title = serializers.SerializerMethodField()
    start = serializers.DateTimeField(source='date_time')
    end = serializers.SerializerMethodField()

    class Meta:
        model = Session
        fields = ['id', 'title', 'start', 'end', 'location']

    def get_title(self, obj):
        return obj.workshop.title

    def get_end(self, obj):
        # Example: add 2 hours to start time (or store an explicit end field)
        from datetime import timedelta
        return obj.date_time + timedelta(hours=2)

class TrainerDashboardSerializer(serializers.Serializer):
    session_id = serializers.IntegerField()
    session_title = serializers.CharField()
    date_time = serializers.DateTimeField()
    workshop_title = serializers.CharField()
    location = serializers.CharField()
    total_participants = serializers.IntegerField()
    attendance_count = serializers.IntegerField()
    average_rating = serializers.FloatField(allow_null=True)