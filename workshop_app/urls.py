from django.urls import path
from . import views
from .views import mark_attendance_by_token

urlpatterns = [
    # Participant Type URLs
    path('participant-types/', views.list_participant_types, name='list_participant_types'),
    path('participant-types/create/', views.create_participant_type, name='create_participant_type'),
    path('participant-types/<int:type_id>/required-fields/', views.get_required_fields_for_participant_type, name='get_required_fields'),
    path('participant-types/update/<int:type_id>/', views.update_participant_type, name='update_participant_type'),
    path('participant-types/delete/<int:type_id>/', views.delete_participant_type, name='delete_participant_type'),

    # Workshop URLs
    path('workshops/', views.list_workshops, name='list_workshops'),
    path('workshops/create/', views.create_workshop, name='create_workshop'),
    path('workshops/<int:workshop_id>/', views.get_workshop_details, name='get_workshop_details'),
    path('workshops/update/<int:workshop_id>/', views.update_workshop, name='update_workshop'),
    path('workshops/delete/<int:workshop_id>/', views.delete_workshop, name='delete_workshop'),

    # Session URLs
    path('sessions/', views.list_sessions, name='list_sessions'),
    path('sessions/create/', views.create_session, name='create_session'),
    path('sessions/update/<int:session_id>/', views.update_session, name='update_session'),
    path('sessions/delete/<int:session_id>/', views.delete_session, name='delete_session'),
    path('sessions/workshop/<int:workshop_id>/', views.get_sessions_by_workshop, name='get_sessions_by_workshop'),
    path('sessions/<str:token>/attendance/', mark_attendance_by_token, name='mark_attendance_by_token'),
    path('sessions/<session_id>/emails/',views.get_emails_for_session, name='get_emails_for_session'),
    path('participants/emails/', views.get_all_participant_emails, name='get_all_participant_emails'),
    
    # Session participant counts
    path('sessions/<int:session_id>/participants/', views.session_participant_counts, name='session_participant_counts'),
    # Session Statistics Dashboard
    path('sessions/<int:session_id>/dashboard/', views.session_statistics_dashboard, name='session_statistics_dashboard'),

    # Trainer URLs
    path('trainers/', views.list_trainers, name='list_trainers'),
    path('trainers/create/', views.create_trainer, name='create_trainer'),
    path('trainers/update/<int:trainer_id>/', views.update_trainer, name='update_trainer'),
    path('trainers/delete/<int:trainer_id>/', views.delete_trainer, name='delete_trainer'),
    path('trainers/<int:trainer_id>/details/', views.get_trainer_details, name='get_trainer_details'),

    # TrainerSession URLs
    path('trainers/sessions/assign/', views.assign_trainer_to_session, name='assign_trainer_to_session'),
    path('trainers/sessions/remove/', views.remove_trainer_from_session, name='remove_trainer_from_session'),

    # Participant URLs
    path('participants/', views.list_participants, name='list_participants'),
    path('participants/register/', views.register_participant, name='register_participant'),
    path('participants/delete/<int:participant_id>/', views.delete_participant, name='delete_participant'),
    path('participants/nic/<str:nic>/', views.get_participant_by_nic, name='get_participant_by_nic'),
    path('participants/<int:participant_id>/sessions/', views.participant_sessions_info, name='participant_sessions_info'),

    # Registration URLs
    path('registrations/', views.register_for_session, name='register_for_session'),

    # Mark Attendance URL
    path('attendance/mark/', views.mark_attendance, name='mark_attendance'),
    
    # Feedback URLs
    path('session-feedback-analysis/<int:session_id>/', views.session_feedback_analysis, name='session_feedback_analysis'),
    
    # Feedback Question
    path('feedback/questions/create/', views.create_feedback_question, name='create_feedback_question'),
    path('feedback/questions/<int:session_id>/', views.list_feedback_questions, name='list_feedback_questions'),

    # Feedback Response
    path('feedback/responses/submit/', views.submit_feedback_response, name='submit_feedback_response'),
    path('feedback/responses/<int:session_id>/', views.list_feedback_responses, name='list_feedback_responses'),

    # Feedback Analysis
    #path('feedback/analysis/<int:session_id>/', views.feedback_analysis, name='feedback_analysis'),
    
    # calendar
    path('calendar/sessions/', views.session_calendar_view, name='session_calendar'),
    
    # Dashboard URLs
    path('dashboard/trainer/<int:trainer_id>/', views.trainer_dashboard, name='trainer_dashboard'),
    path('admin-dashboard/counts/', views.admin_dashboard_counts, name='admin_dashboard_counts'),

    # Data Analytics Dashboard APIs
    path('analytics/sessions/', views.analytics_sessions, name='analytics_sessions'),
    path('analytics/workshops/', views.analytics_workshops, name='analytics_workshops'),
    path('analytics/trainers/', views.analytics_trainers, name='analytics_trainers'),
    path('analytics/participants/', views.analytics_participants, name='analytics_participants'),

    # Analytics Endpoints for Sessions Tab
    path('api/analytics/sessions/overview/', views.analytics_sessions_overview, name='analytics_sessions_overview'),
    path('api/analytics/sessions/list/', views.analytics_sessions_list, name='analytics_sessions_list'),
    path('api/analytics/sessions/<int:session_id>/detail/', views.analytics_session_detail, name='analytics_session_detail'),

    # Analytics Endpoints for Workshops Tab
    path('api/analytics/workshops/overview/', views.analytics_workshops_overview, name='analytics_workshops_overview'),
    path('api/analytics/workshops/list/', views.analytics_workshops_list, name='analytics_workshops_list'),
    path('api/analytics/workshops/<int:workshop_id>/detail/', views.analytics_workshop_detail, name='analytics_workshop_detail'),

    # Analytics Endpoints for Trainers Tab
    path('api/analytics/trainers/', views.analytics_trainers, name='api_analytics_trainers'),
    path('api/analytics/trainers/<int:trainer_id>/detail/', views.analytics_trainer_detail, name='api_analytics_trainer_detail'),

    # Analytics Endpoints for Participants Tab
    path('api/analytics/participants/overview/', views.analytics_participants_overview, name='analytics_participants_overview'),
]
