from django.contrib import admin
from .utils import analyze_session_feedback
from .models import Workshop,Session,Trainer,TrainerSession,Participant,ParticipantType,FeedbackQuestion,FeedbackResponse,SessionFeedback

admin.site.register(Workshop)
admin.site.register(Trainer)
admin.site.register(TrainerSession)
admin.site.register(Participant)
admin.site.register(ParticipantType)
admin.site.register(FeedbackQuestion)
admin.site.register(FeedbackResponse)
admin.site.register(SessionFeedback)

class TrainerSessionInline(admin.TabularInline):
    model = TrainerSession
    extra = 1
@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    inlines = [TrainerSessionInline]
    actions = ['analyze_feedback']

    def analyze_feedback(self, request, queryset):
        for session in queryset:
            analysis = analyze_session_feedback(session.id)
            # You can log or display the analysis here, or even send it via email
            self.message_user(request, f"Analysis for session {session.id}: {analysis}")
    analyze_feedback.short_description = "Analyze feedback for selected sessions"
