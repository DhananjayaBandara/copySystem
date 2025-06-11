from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.http import JsonResponse
from .utils import analyze_session_feedback
from .utils import analyze_feedback_for_session
from .serializers import CalendarSessionSerializer
from datetime import datetime
from django.db.models import Avg, Count, Q
from django.shortcuts import get_object_or_404
from collections import Counter



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
from .serializers import (
    ParticipantTypeSerializer,
    WorkshopSerializer,
    SessionSerializer,
    TrainerSerializer,
    TrainerSessionSerializer,
    ParticipantSerializer,
    RegistrationSerializer,
    FeedbackQuestionSerializer,
    FeedbackResponseSerializer,
    TrainerDashboardSerializer,
)
from workshop_app import models

# Participant Type APIs
@api_view(['GET'])
def list_participant_types(request):
    types = ParticipantType.objects.all()
    serializer = ParticipantTypeSerializer(types, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_participant_type(request):
    serializer = ParticipantTypeSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_participant_type(request, type_id):
    participant_type = get_object_or_404(ParticipantType, id=type_id)
    serializer = ParticipantTypeSerializer(participant_type, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_participant_type(request, type_id):
    participant_type = get_object_or_404(ParticipantType, id=type_id)
    participant_type.delete()
    return Response({"message": "Participant type deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_required_fields_for_participant_type(request, type_id):
    try:
        participant_type = ParticipantType.objects.get(id=type_id)
        return Response({
            "type_id": participant_type.id,
            "type_name": participant_type.name,
            "required_fields": participant_type.properties
        })
    except ParticipantType.DoesNotExist:
        return Response(
            {"error": "Participant type not found."},
            status=status.HTTP_404_NOT_FOUND
        )


# Workshop APIs
@api_view(['GET'])
def list_workshops(request):
    workshops = Workshop.objects.all()
    serializer = WorkshopSerializer(workshops, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_workshop(request):
    serializer = WorkshopSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def get_workshop_details(request, workshop_id):
    try:
        workshop = Workshop.objects.get(id=workshop_id)
        sessions = Session.objects.filter(workshop=workshop)
        participants = Registration.objects.filter(session__workshop=workshop).select_related('participant')

        workshop_data = {
            "id": workshop.id,
            "title": workshop.title,
            "description": workshop.description,
            "sessions": [
                {
                    "id": session.id,
                    "date_time": session.date_time,
                    "location": session.location,
                    "target_audience": session.target_audience,
                    "registration_deadline": session.registration_deadline,
                }
                for session in sessions
            ],
            "participants": [
                {
                    "id": reg.participant.id,
                    "name": reg.participant.name,
                    "email": reg.participant.email,
                    "contact_number": reg.participant.contact_number,
                    "nic": reg.participant.nic,
                    "dob": reg.participant.dob,
                    "district": reg.participant.district,
                    "gender": reg.participant.gender,
                }
                for reg in participants
            ],
        }
        return Response(workshop_data, status=status.HTTP_200_OK)
    except Workshop.DoesNotExist:
        return Response({"error": "Workshop not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['PUT'])
def update_workshop(request, workshop_id):
    workshop = get_object_or_404(Workshop, id=workshop_id)
    serializer = WorkshopSerializer(workshop, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_workshop(request, workshop_id):
    workshop = get_object_or_404(Workshop, id=workshop_id)
    workshop.delete()
    return Response({"message": "Workshop deleted successfully."}, status=status.HTTP_200_OK)



# Session APIs
from .serializers import SessionSerializer

@api_view(['GET'])
def list_sessions(request):
    sessions = Session.objects.all()
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def get_sessions_by_workshop(request, workshop_id):
    sessions = Session.objects.filter(workshop_id=workshop_id)
    serializer = SessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_session(request):
    serializer = SessionSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_session(request, session_id):
    session = get_object_or_404(Session, id=session_id)
    serializer = SessionSerializer(session, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_session(request, session_id):
    session = get_object_or_404(Session, id=session_id)
    session.delete()
    return Response({"message": "Session deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_emails_for_session(request, session_id):
    """
    Returns a list of emails of participants registered for the given session.
    """
    try:
        session = Session.objects.get(id=session_id)
        registrations = Registration.objects.filter(session=session).select_related('participant')
        emails = [reg.participant.email for reg in registrations]
        return Response({"emails": emails}, status=status.HTTP_200_OK)
    except Session.DoesNotExist:
        return Response({"error": "Session not found"}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def get_all_participant_emails(request):
    emails = Participant.objects.values_list('email', flat=True).distinct()
    return Response(list(emails))



# Trainer APIs
@api_view(['GET'])
def list_trainers(request):
    trainers = Trainer.objects.all()
    serializer = TrainerSerializer(trainers, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def create_trainer(request):
    serializer = TrainerSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_trainer(request, trainer_id):
    trainer = get_object_or_404(Trainer, id=trainer_id)
    serializer = TrainerSerializer(trainer, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_trainer(request, trainer_id):
    trainer = get_object_or_404(Trainer, id=trainer_id)
    trainer.delete()
    return Response({"message": "Trainer deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_trainer_details(request, trainer_id):
    try:
        trainer = Trainer.objects.get(id=trainer_id)
        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session__workshop')
        session_data = [
            {
                "session_id": session.session.id,
                "session_title": str(session.session),
                "workshop_title": session.session.workshop.title,
                "date_time": session.session.date_time,
                "location": session.session.location,
            }
            for session in sessions
        ]
        trainer_data = {
            "trainer_id": trainer.id,
            "name": trainer.name,
            "designation": trainer.designation,
            "email": trainer.email,
            "contact_number": trainer.contact_number,
            "expertise": trainer.expertise,
            "sessions": session_data,
        }
        return Response(trainer_data, status=status.HTTP_200_OK)
    except Trainer.DoesNotExist:
        return Response({"error": "Trainer not found"}, status=status.HTTP_404_NOT_FOUND)


# TrainerSession APIs
@api_view(['POST'])
def assign_trainer_to_session(request):
    session_id = request.data.get('session_id')
    trainer_ids = request.data.get('trainer_ids', [])

    if not session_id or not isinstance(trainer_ids, list):
        return Response(
            {"error": "Invalid data. 'session_id' and 'trainer_ids' are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        session = get_object_or_404(Session, id=session_id)
        assigned_trainers = []

        for trainer_id in trainer_ids:
            trainer = get_object_or_404(Trainer, id=trainer_id)
            trainer_session, created = TrainerSession.objects.get_or_create(
                session=session, trainer=trainer
            )
            if created:
                assigned_trainers.append(trainer.id)

        return Response(
            {
                "message": "Trainers assigned successfully.",
                "assigned_trainers": assigned_trainers,
            },
            status=status.HTTP_201_CREATED,
        )
    except Exception as e:
        return Response(
            {"error": f"An error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

@api_view(['DELETE'])
def remove_trainer_from_session(request):
    session_id = request.data.get('session_id')
    trainer_id = request.data.get('trainer_id')

    if not session_id or not trainer_id:
        return Response(
            {"error": "Invalid data. 'session_id' and 'trainer_id' are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        trainer_session = get_object_or_404(
            TrainerSession, session_id=session_id, trainer_id=trainer_id
        )
        trainer_session.delete()
        return Response(
            {"message": "Trainer removed successfully."},
            status=status.HTTP_200_OK,
        )
    except Exception as e:
        return Response(
            {"error": f"An error occurred: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# Participant APIs
@api_view(['GET'])
def list_participants(request):
    participants = Participant.objects.all()
    serializer = ParticipantSerializer(participants, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def register_participant(request):
    serializer = ParticipantSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_participant(request, participant_id):
    participant = get_object_or_404(Participant, id=participant_id)
    participant.delete()
    return Response({"message": "Participant deleted successfully."}, status=status.HTTP_200_OK)

@api_view(['GET'])
def get_participant_by_nic(request, nic):
    try:
        participant = Participant.objects.get(nic=nic)
        serializer = ParticipantSerializer(participant)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Participant.DoesNotExist:
        return Response({"error": "Participant not found."}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def participant_sessions_info(request, participant_id):
    from .models import Registration
    from .serializers import SessionSerializer

    registrations = Registration.objects.filter(participant_id=participant_id).select_related('session', 'session__workshop')
    sessions = []
    attended_sessions = []
    for reg in registrations:
        session = reg.session
        session_info = {
            "id": session.id,
            "workshop_title": session.workshop.title if session.workshop else "",
            "date_time": session.date_time,
            "attended": reg.attendance,
        }
        sessions.append(session_info)
        if reg.attendance:
            attended_sessions.append(session_info)

    return Response({
        "registered_count": len(sessions),
        "attended_count": len(attended_sessions),
        "sessions": sessions,
        "attended_sessions": attended_sessions,
    })


# Registration APIs
@api_view(['POST'])
def register_for_session(request):
    participant_id = request.data.get('participant')
    session_id = request.data.get('session')
    # Check for existing registration
    if Registration.objects.filter(participant_id=participant_id, session_id=session_id).exists():
        return Response(
            {"error": "Participant is already registered for this session."},
            status=status.HTTP_400_BAD_REQUEST
        )
    serializer = RegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Mark Attendance API (for QR scanning)
@api_view(['POST'])
def mark_attendance(request):
    try:
        registration_id = request.data.get('registration_id')
        registration = Registration.objects.get(id=registration_id)
        registration.attendance = True
        registration.save()
        return Response({"message": "Attendance marked successfully!"}, status=status.HTTP_200_OK)
    except Registration.DoesNotExist:
        return Response({"error": "Invalid registration ID"}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def mark_attendance_by_token(request, token):
    nic = request.data.get('nic')
    if not nic:
        return Response({"error": "NIC is required."}, status=status.HTTP_400_BAD_REQUEST)

    session = get_object_or_404(Session, token=token)
    participant = get_object_or_404(Participant, nic=nic)
    registration = Registration.objects.filter(session=session, participant=participant).first()

    if not registration:
        return Response({"error": "Participant is not registered for this session."}, status=status.HTTP_400_BAD_REQUEST)

    registration.attendance = True
    registration.save()

    return Response({"message": "Attendance marked successfully."}, status=status.HTTP_200_OK)

def session_feedback_analysis(request, session_id):
    analysis_result = analyze_session_feedback(session_id)
    return JsonResponse(analysis_result)



@api_view(['POST'])
# @permission_classes([IsAuthenticated])
def create_feedback_question(request):
    serializer = FeedbackQuestionSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def list_feedback_questions(request, session_id):
    questions = FeedbackQuestion.objects.filter(session_id=session_id)
    serializer = FeedbackQuestionSerializer(questions, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def submit_feedback_response(request):
    participant_id = request.data.get('participant')
    question_id = request.data.get('question')
    response_value = request.data.get('response')

    # Prevent duplicate feedback for the same participant/question/response
    if FeedbackResponse.objects.filter(
        participant_id=participant_id,
        question_id=question_id,
        response=response_value
    ).exists():
        return Response(
            {"error": "You have already submitted this response for this question."},
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = FeedbackResponseSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def list_feedback_responses(request, session_id):
    # Fix: filter by question__session_id instead of session_id
    responses = FeedbackResponse.objects.filter(question__session_id=session_id)
    serializer = FeedbackResponseSerializer(responses, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def feedback_analysis(request, session_id):
    analysis_result = analyze_feedback_for_session(session_id)
    return Response(analysis_result)

# Calendar view
@api_view(['GET'])
def session_calendar_view(request):
    # Optionally, filter to upcoming sessions
    now = datetime.now()
    sessions = Session.objects.filter(date_time__gte=now).order_by('date_time')
    serializer = CalendarSessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def trainer_dashboard(request, trainer_id=None):
    if (trainer_id):
        try:
            trainer = Trainer.objects.get(id=trainer_id)
        except Trainer.DoesNotExist:
            return Response({"error": "Trainer not found"}, status=404)

        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session__workshop', 'session')

        dashboard_data = []

        for ts in sessions:
            session = ts.session
            registrations = Registration.objects.filter(session=session)
            total = registrations.count()
            attended = registrations.filter(attendance=True).count()

            # Calculate average rating from feedback
            rating_responses = FeedbackResponse.objects.filter(
                question__session=session,
                question__response_type='scale'
            ).values_list('response', flat=True)

            try:
                ratings = [float(r) for r in rating_responses if r is not None]
                avg_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
            except:
                avg_rating = None

            dashboard_data.append({
                "session_id": session.id,
                "session_title": str(session),
                "date_time": session.date_time,
                "workshop_title": session.workshop.title,
                "location": session.location,
                "total_participants": total,
                "attendance_count": attended,
                "average_rating": avg_rating
            })

        serializer = TrainerDashboardSerializer(dashboard_data, many=True)
        return Response(serializer.data)

    # Admin dashboard for all trainers
    trainers = Trainer.objects.all()
    trainer_data = []

    for trainer in trainers:
        sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session')
        session_count = sessions.count()
        trainer_data.append({
            "trainer_id": trainer.id,
            "trainer_name": trainer.name,
            "designation": trainer.designation,
            "email": trainer.email,
            "contact_number": trainer.contact_number,
            "expertise": trainer.expertise,
            "session_count": session_count
        })

    return Response(trainer_data)

@api_view(['GET'])
def admin_dashboard_counts(request):
    counts = {
        "workshops": Workshop.objects.count(),
        "sessions": Session.objects.count(),
        "participants": Participant.objects.count(),
        "participant_types": ParticipantType.objects.count(),
        "trainers": Trainer.objects.count(),
    }
    return Response(counts)

@api_view(['GET'])
def session_participant_counts(request, session_id):
    from .models import Registration
    from .serializers import ParticipantSerializer

    registrations = Registration.objects.filter(session_id=session_id).select_related('participant')
    registered_participants = [reg.participant for reg in registrations]
    attended_participants = [reg.participant for reg in registrations if reg.attendance]

    registered_serializer = ParticipantSerializer(registered_participants, many=True)
    attended_serializer = ParticipantSerializer(attended_participants, many=True)

    return Response({
        "registered_count": len(registered_participants),
        "registered_participants": registered_serializer.data,
        "attended_count": len(attended_participants),
        "attended_participants": attended_serializer.data,
    })

from .models import SessionStatistics
from .utils import compute_and_update_session_statistics
from rest_framework.decorators import api_view

@api_view(['GET'])
def session_statistics_dashboard(request, session_id):
    stats = compute_and_update_session_statistics(session_id)
    data = {
        "session_id": stats.session.id,
        "registered_count": stats.registered_count,
        "attended_count": stats.attended_count,
        "attendance_percentage": stats.attendance_percentage,
        "average_rating": stats.average_rating,
        "impact_summary": stats.impact_summary,
        "improvement_suggestions": stats.improvement_suggestions,
    }
    return Response(data)

@api_view(['GET'])
def analytics_sessions(request):
    total_sessions = Session.objects.count()
    # Average attendance: mean of attended participants per session
    sessions = Session.objects.all()
    total_attendance = 0
    for session in sessions:
        attended = Registration.objects.filter(session=session, attendance=True).count()
        total_attendance += attended
    average_attendance = round(total_attendance / total_sessions, 2) if total_sessions > 0 else 0
    return Response({
        "total_sessions": total_sessions,
        "average_attendance": average_attendance,
    })

@api_view(['GET'])
def analytics_workshops(request):
    total_workshops = Workshop.objects.count()
    # Average rating: mean of all feedback ratings for all workshops' sessions
    sessions = Session.objects.all()
    ratings = []
    for session in sessions:
        responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type__in=['scale', 'rating']
        ).values_list('response', flat=True)
        for r in responses:
            try:
                ratings.append(float(r))
            except Exception:
                continue
    average_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
    return Response({
        "total_workshops": total_workshops,
        "average_rating": average_rating,
    })

@api_view(['GET'])
def analytics_trainers(request):
    total_trainers = Trainer.objects.count()
    # Top rated trainer: trainer with highest average rating across their sessions
    trainers = Trainer.objects.all()
    top_trainer = None
    top_rating = None
    for trainer in trainers:
        trainer_sessions = TrainerSession.objects.filter(trainer=trainer)
        ratings = []
        for ts in trainer_sessions:
            responses = FeedbackResponse.objects.filter(
                question__session=ts.session,
                question__response_type__in=['scale', 'rating']
            ).values_list('response', flat=True)
            for r in responses:
                try:
                    ratings.append(float(r))
                except Exception:
                    continue
        avg = sum(ratings) / len(ratings) if ratings else None
        if avg is not None and (top_rating is None or avg > top_rating):
            top_rating = avg
            top_trainer = trainer.name
    return Response({
        "total_trainers": total_trainers,
        "top_trainer": top_trainer or "N/A",
    })

@api_view(['GET'])
def analytics_participants(request):
    total_participants = Participant.objects.count()
    # Average completion rate: percentage of attended sessions over registered sessions
    total_registrations = Registration.objects.count()
    total_attended = Registration.objects.filter(attendance=True).count()
    average_completion_rate = round((total_attended / total_registrations) * 100, 2) if total_registrations > 0 else 0
    return Response({
        "total_participants": total_participants,
        "average_completion_rate": average_completion_rate,
    })

from collections import Counter

@api_view(['GET'])
def analytics_sessions_overview(request):
    """
    Returns:
    - total_sessions
    - total_registered
    - total_attended
    - average_attendance_rate
    - feedback_count (number of distinct participants who submitted feedback)
    - average_feedback_rating
    - common_feedback_keywords
    - session_titles
    - registrations_per_session
    - attendance_per_session
    """
    sessions = Session.objects.all()
    total_sessions = sessions.count()
    total_registered = 0
    total_attended = 0
    session_titles = []
    registrations_per_session = []
    attendance_per_session = []

    feedback_count = 0
    feedback_ratings = []
    feedback_texts = []

    # --- Count distinct participants who submitted feedback ---
    from .models import FeedbackResponse
    feedback_participant_ids = set(
        FeedbackResponse.objects.values_list('participant_id', flat=True).distinct()
    )
    feedback_count = len(feedback_participant_ids)

    for session in sessions:
        regs = Registration.objects.filter(session=session)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        total_registered += reg_count
        total_attended += att_count
        session_titles.append(str(session))
        registrations_per_session.append(reg_count)
        attendance_per_session.append(att_count)

        # Feedback
        responses = FeedbackResponse.objects.filter(question__session=session)
        # Ratings
        for resp in responses.filter(question__response_type__in=['scale', 'rating']):
            try:
                feedback_ratings.append(float(resp.response))
            except Exception:
                continue
        # Suggestions/comments
        for resp in responses.filter(question__response_type='text'):
            if resp.response:
                feedback_texts.append(resp.response)

    average_attendance_rate = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0
    average_feedback_rating = round(sum(feedback_ratings) / len(feedback_ratings), 2) if feedback_ratings else None

    # Simple keyword extraction (top 5 words, ignoring short/common words)
    words = []
    for text in feedback_texts:
        words += [w.lower() for w in text.split() if len(w) > 3]
    common_feedback_keywords = [w for w, _ in Counter(words).most_common(5)]

    return Response({
        "total_sessions": total_sessions,
        "total_registered": total_registered,
        "total_attended": total_attended,
        "average_attendance_rate": average_attendance_rate,
        "feedback_count": feedback_count,
        "average_feedback_rating": average_feedback_rating,
        "common_feedback_keywords": common_feedback_keywords,
        "session_titles": session_titles,
        "registrations_per_session": registrations_per_session,
        "attendance_per_session": attendance_per_session,
    })

@api_view(['GET'])
def analytics_sessions_list(request):
    """
    Returns a list of sessions with:
    - id, title, workshop, date_time, registered_count, attended_count, avg_feedback_rating
    """
    sessions = Session.objects.select_related('workshop').all().order_by('-date_time')
    data = []
    for session in sessions:
        regs = Registration.objects.filter(session=session)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        # Feedback
        responses = FeedbackResponse.objects.filter(question__session=session, question__response_type__in=['scale', 'rating'])
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
        avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        data.append({
            "id": session.id,
            "title": str(session),
            "workshop": session.workshop.title if session.workshop else "",
            "date_time": session.date_time,
            "registered_count": reg_count,
            "attended_count": att_count,
            "avg_feedback_rating": avg_feedback_rating,
        })
    return Response(data)

@api_view(['GET'])
def analytics_session_detail(request, session_id):
    """
    Returns:
    - session info
    - registered/attended counts
    - participants list (name, email, attended)
    - feedback rating distribution
    - feedback summary (top suggestions/problems, recommendations)
    """
    session = get_object_or_404(Session, id=session_id)
    regs = Registration.objects.filter(session=session).select_related('participant')
    reg_count = regs.count()
    att_count = regs.filter(attendance=True).count()
    participants = []
    for reg in regs:
        participants.append({
            "name": reg.participant.name,
            "email": reg.participant.email,
            "attended": reg.attendance,
        })

    # Feedback ratings distribution
    responses = FeedbackResponse.objects.filter(question__session=session, question__response_type__in=['scale', 'rating'])
    rating_counts = Counter()
    for resp in responses:
        try:
            rating = int(float(resp.response))
            rating_counts[rating] += 1
        except Exception:
            continue

    # Feedback suggestions/comments
    text_responses = FeedbackResponse.objects.filter(question__session=session, question__response_type='text')
    suggestions = [resp.response for resp in text_responses if resp.response]
    # Top 3 suggestions/problems (by frequency)
    words = []
    for text in suggestions:
        words += [w.lower() for w in text.split() if len(w) > 3]
    top_keywords = [w for w, _ in Counter(words).most_common(5)]
    
    # --- Session funnel: number of distinct participants who submitted feedback for a selected session ---
    # Get all feedback questions for the sessions
    question_ids = list(FeedbackQuestion.objects.filter(session=session).values_list('id', flat=True))
    feedback_participant_ids = (
        FeedbackResponse.objects
        .filter(question_id__in=question_ids)
        .values_list('participant_id', flat=True)
        .distinct()
    )
    feedback_participants_count = len(set(feedback_participant_ids))

    return Response({
        "session_id": session.id,
        "title": str(session),
        "workshop": session.workshop.title if session.workshop else "",
        "date_time": session.date_time,
        "registered_count": reg_count,
        "attended_count": att_count,
        "participants": participants,
        "feedback_rating_distribution": rating_counts,
        "feedback_suggestions": suggestions[:5],
        "top_keywords": top_keywords,
        "feedback_participants": feedback_participants_count,
    })

from collections import Counter

@api_view(['GET'])
def analytics_workshops_overview(request):
    """
    Returns:
    - total_workshops
    - total_sessions
    - total_registered
    - total_attended
    - average_attendance_rate
    - average_feedback_rating
    - workshop_titles
    - registrations_per_workshop
    - attendance_per_workshop
    """
    workshops = Workshop.objects.all()
    total_workshops = workshops.count()
    total_sessions = 0
    total_registered = 0
    total_attended = 0
    workshop_titles = []
    registrations_per_workshop = []
    attendance_per_workshop = []
    feedback_ratings = []
    
    feedback_participant_ids = set(
    FeedbackResponse.objects.filter(question__session__workshop__in=workshops)
    .values_list('participant_id', flat=True)
    .distinct()
    )
    feedback_participants = len(feedback_participant_ids)


    for workshop in workshops:
        sessions = Session.objects.filter(workshop=workshop)
        session_ids = sessions.values_list('id', flat=True)
        session_count = sessions.count()
        total_sessions += session_count

        regs = Registration.objects.filter(session__in=session_ids)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        total_registered += reg_count
        total_attended += att_count

        workshop_titles.append(workshop.title)
        registrations_per_workshop.append(reg_count)
        attendance_per_workshop.append(att_count)

        # Feedback ratings for all sessions under this workshop
        responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type__in=['scale', 'rating'])
        for resp in responses:
            try:
                feedback_ratings.append(float(resp.response))
            except Exception:
                continue

    average_attendance_rate = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0
    average_feedback_rating = round(sum(feedback_ratings) / len(feedback_ratings), 2) if feedback_ratings else None
    

    return Response({
        "total_workshops": total_workshops,
        "total_sessions": total_sessions,
        "total_registered": total_registered,
        "total_attended": total_attended,
        "average_attendance_rate": average_attendance_rate,
        "average_feedback_rating": average_feedback_rating,
        "workshop_titles": workshop_titles,
        "registrations_per_workshop": registrations_per_workshop,
        "attendance_per_workshop": attendance_per_workshop,
        "feedback_participants": feedback_participants,
    })

@api_view(['GET'])
def analytics_workshops_list(request):
    """
    Returns a list of workshops with:
    - id, title, total_sessions, total_registered, total_attended, avg_feedback_rating
    """
    workshops = Workshop.objects.all()
    data = []
    for workshop in workshops:
        sessions = Session.objects.filter(workshop=workshop)
        session_ids = sessions.values_list('id', flat=True)
        session_count = sessions.count()
        regs = Registration.objects.filter(session__in=session_ids)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        # Feedback
        responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type__in=['scale', 'rating'])
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
        avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        data.append({
            "id": workshop.id,
            "title": workshop.title,
            "total_sessions": session_count,
            "total_registered": reg_count,
            "total_attended": att_count,
            "avg_feedback_rating": avg_feedback_rating,
        })
    return Response(data)

@api_view(['GET'])
def analytics_workshop_detail(request, workshop_id):
    """
    Returns:
    - workshop info
    - registration/attendance totals
    - feedback summary (ratings, suggestions)
    - trend data over sessions
    - feedback_participants: number of distinct participants who submitted feedback for this workshop
    """
    workshop = get_object_or_404(Workshop, id=workshop_id)
    sessions = Session.objects.filter(workshop=workshop).order_by('date_time')
    session_ids = list(sessions.values_list('id', flat=True))
    session_titles = [str(s) for s in sessions]
    session_dates = [s.date_time for s in sessions]

    regs = Registration.objects.filter(session__in=session_ids)
    reg_count = regs.count()
    att_count = regs.filter(attendance=True).count()

    # Feedback ratings
    responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type__in=['scale', 'rating'])
    ratings = []
    for resp in responses:
        try:
            ratings.append(float(resp.response))
        except Exception:
            continue
    avg_feedback_rating = round(sum(ratings) / len(ratings), 2) if ratings else None

    # Suggestions/comments
    text_responses = FeedbackResponse.objects.filter(question__session__in=session_ids, question__response_type='text')
    suggestions = [resp.response for resp in text_responses if resp.response]
    words = []
    for text in suggestions:
        words += [w.lower() for w in text.split() if len(w) > 3]
    top_keywords = [w for w, _ in Counter(words).most_common(5)]

    # Trend data: for each session, get reg/att/avg_rating
    trend = []
    for s in sessions:
        regs = Registration.objects.filter(session=s)
        reg_count = regs.count()
        att_count = regs.filter(attendance=True).count()
        responses = FeedbackResponse.objects.filter(question__session=s, question__response_type__in=['scale', 'rating'])
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
            except Exception:
                continue
        avg_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        trend.append({
            "session_id": s.id,
            "title": str(s),
            "date_time": s.date_time,
            "registered": reg_count,
            "attended": att_count,
            "avg_rating": avg_rating,
        })

    # --- Workshop funnel: number of distinct participants who submitted feedback for this workshop ---
    # Get all feedback questions for these sessions
    question_ids = list(FeedbackQuestion.objects.filter(session_id__in=session_ids).values_list('id', flat=True))
    feedback_participant_ids = (
        FeedbackResponse.objects
        .filter(question_id__in=question_ids)
        .values_list('participant_id', flat=True)
        .distinct()
    )
    feedback_participants_count = len(set(feedback_participant_ids))

    participants = Registration.objects.filter(session__workshop=workshop).select_related('participant')
    participants_list = [
        {
            "name": reg.participant.name,
            "email": reg.participant.email,
        }
        for reg in participants
    ]

    return Response({
        "workshop_id": workshop.id,
        "title": workshop.title,
        "description": getattr(workshop, "description", ""),
        "total_sessions": sessions.count(),
        "total_registered": reg_count,
        "total_attended": att_count,
        "avg_feedback_rating": avg_feedback_rating,
        "feedback_suggestions": suggestions[:5],
        "top_keywords": top_keywords,
        "trend": trend,
        "session_titles": session_titles,
        "session_dates": session_dates,
        "feedback_participants": feedback_participants_count,
        "participants": participants_list,
    })


@api_view(['GET'])
def analytics_trainers(request):
    """
    Returns:
    - total_trainers
    - top_trainer
    - trainers: list of {id, name, email, session_count, avg_feedback_rating}
    """
    trainers = Trainer.objects.all()
    trainers_list = []
    top_trainer = None
    top_rating = None
    for trainer in trainers:
        trainer_sessions = TrainerSession.objects.filter(trainer=trainer)
        session_count = trainer_sessions.count()
        ratings = []
        total_participants = 0
        for ts in trainer_sessions:
            regs = Registration.objects.filter(session=ts.session)
            total_participants += regs.count()
            responses = FeedbackResponse.objects.filter(
                question__session=ts.session,
                question__response_type__in=['scale', 'rating']
            ).values_list('response', flat=True)
            for r in responses:
                try:
                    ratings.append(float(r))
                except Exception:
                    continue
        avg = round(sum(ratings) / len(ratings), 2) if ratings else None
        if avg is not None and (top_rating is None or avg > top_rating):
            top_rating = avg
            top_trainer = trainer.name
        trainers_list.append({
            "id": trainer.id,
            "name": trainer.name,
            "email": trainer.email,
            "session_count": session_count,
            "avg_feedback_rating": avg,
            "total_participants": total_participants,
        })
    return Response({
        "total_trainers": trainers.count(),
        "top_trainer": top_trainer or "N/A",
        "trainers": trainers_list,
    })

@api_view(['GET'])
def analytics_trainer_detail(request, trainer_id):
    """
    Returns:
    - name, email, session_count, total_participants, avg_feedback_rating
    - ratings_trend: [{session_title, date_time, avg_rating}]
    - feedback_themes: top keywords from feedback
    """
    trainer = get_object_or_404(Trainer, id=trainer_id)
    trainer_sessions = TrainerSession.objects.filter(trainer=trainer).select_related('session')
    session_count = trainer_sessions.count()
    ratings_trend = []
    all_ratings = []
    total_participants = 0
    feedback_texts = []
    for ts in trainer_sessions:
        session = ts.session
        regs = Registration.objects.filter(session=session)
        total_participants += regs.count()
        responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type__in=['scale', 'rating']
        )
        ratings = []
        for resp in responses:
            try:
                ratings.append(float(resp.response))
                all_ratings.append(float(resp.response))
            except Exception:
                continue
        avg_rating = round(sum(ratings) / len(ratings), 2) if ratings else None
        ratings_trend.append({
            "session_title": str(session),
            "date_time": session.date_time,
            "avg_rating": avg_rating,
        })
        # Text feedback for this session
        text_responses = FeedbackResponse.objects.filter(
            question__session=session,
            question__response_type='text'
        )
        for resp in text_responses:
            if resp.response:
                feedback_texts.append(resp.response)
    avg_feedback_rating = round(sum(all_ratings) / len(all_ratings), 2) if all_ratings else None
    # Simple keyword extraction (top 5 words, ignoring short/common words)
    words = []
    for text in feedback_texts:
        words += [w.lower() for w in text.split() if len(w) > 3]
    feedback_themes = [w for w, _ in Counter(words).most_common(5)]
    return Response({
        "id": trainer.id,
        "name": trainer.name,
        "email": trainer.email,
        "session_count": session_count,
        "total_participants": total_participants,
        "avg_feedback_rating": avg_feedback_rating,
        "ratings_trend": ratings_trend,
        "feedback_themes": feedback_themes,
    })

from collections import Counter
from django.db.models import Q

@api_view(['GET'])
def analytics_participants_overview(request):
    """
    Returns:
    - total_participants
    - district_histogram: {district: count}
    - gender_distribution: {gender: count}
    - type_distribution: {type: count}
    - attendance_percentage
    - feedback_response_rate
    - top_10_participants: list of top 10 participants by attended sessions, including registered session count
    - filters: district, gender, participant_type, date range
    """
    # Filters
    district = request.GET.get('district')
    gender = request.GET.get('gender')
    participant_type = request.GET.get('participant_type')
    date_from = request.GET.get('date_from')
    date_to = request.GET.get('date_to')
    workshop_id = request.GET.get('workshop_id')
    session_id = request.GET.get('session_id')

    participants = Participant.objects.all()
    regs = Registration.objects.all()
    feedbacks = FeedbackResponse.objects.all()

    # Apply filters
    if district:
        participants = participants.filter(district=district)
    if gender:
        participants = participants.filter(gender=gender)
    if participant_type:
        participants = participants.filter(participant_type__name=participant_type)
    if date_from:
        regs = regs.filter(registered_on__gte=date_from)
    if date_to:
        regs = regs.filter(registered_on__lte=date_to)
    if workshop_id:
        regs = regs.filter(session__workshop_id=workshop_id)
    if session_id:
        regs = regs.filter(session_id=session_id)

    participant_ids = participants.values_list('id', flat=True)
    regs = regs.filter(participant_id__in=participant_ids)
    attended_regs = regs.filter(attendance=True)

    # Histogram: District
    district_hist = Counter(participants.values_list('district', flat=True))
    # Pie: Gender
    gender_dist = Counter(participants.values_list('gender', flat=True))
    # Pie: Participant Type
    type_dist = Counter(
        participants.values_list('participant_type__name', flat=True)
    )

    total_participants = participants.count()
    total_registered = regs.count()
    total_attended = attended_regs.count()

    attendance_percentage = round((total_attended / total_registered) * 100, 2) if total_registered > 0 else 0

    # Feedback response rate: attendees who submitted at least one feedback
    attendee_ids = attended_regs.values_list('participant_id', flat=True)
    feedback_participant_ids = feedbacks.filter(participant_id__in=attendee_ids).values_list('participant_id', flat=True).distinct()
    feedback_response_rate = round((len(feedback_participant_ids) / len(attendee_ids)) * 100, 2) if attendee_ids else 0

    # --- Top 10 participants by attended sessions ---
    attended_counts = Counter(attended_regs.values_list('participant_id', flat=True))
    top_10_ids = [pid for pid, _ in attended_counts.most_common(10)]
    top_10_participants = []
    if top_10_ids:
        top_participants_qs = Participant.objects.filter(id__in=top_10_ids)
        # Map id to participant for fast lookup
        id_to_participant = {p.id: p for p in top_participants_qs}
        for pid in top_10_ids:
            p = id_to_participant.get(pid)
            if p:
                # Count number of sessions registered by this participant
                registered_sessions_count = Registration.objects.filter(participant_id=pid).count()
                top_10_participants.append({
                    "id": p.id,
                    "name": p.name,
                    "email": p.email,                 
                    "attended_sessions": attended_counts[pid],
                    "registered_sessions": registered_sessions_count,
                })

    districts = list(Participant.objects.values_list('district', flat=True).distinct())
    genders = list(Participant.objects.values_list('gender', flat=True).distinct())
    participant_types = list(ParticipantType.objects.values_list('name', flat=True).distinct())

    return Response({
        "total_participants": total_participants,
        "district_histogram": dict(district_hist),
        "gender_distribution": dict(gender_dist),
        "type_distribution": dict(type_dist),
        "attendance_percentage": attendance_percentage,
        "feedback_response_rate": feedback_response_rate,
        "top_10_participants": top_10_participants,
        "available_filters": {
            "districts": districts,
            "genders": genders,
            "participant_types": participant_types,
        }
    })
