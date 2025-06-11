from .models import FeedbackResponse, FeedbackQuestion, Session, Registration, SessionStatistics
from collections import Counter
from django.db.models import Count

def analyze_session_feedback(session_id):
    feedback_questions = FeedbackQuestion.objects.filter(session_id=session_id)
    analysis = {}

    for question in feedback_questions:
        responses = FeedbackResponse.objects.filter(question=question)
        if question.response_type == 'rating':
            total_ratings = 0
            count = 0
            for response in responses:
                total_ratings += float(response.response)
                count += 1
            average_rating = total_ratings / count if count > 0 else None
            analysis[question.question_text] = {'average_rating': average_rating, 'total_responses': count}
        elif question.response_type == 'checkbox':
            # For checkbox questions, analyze the distribution of answers
            options_count = {option: 0 for option in question.options}
            for response in responses:
                selected_options = response.response.split(",")  # Assuming response is a comma-separated string of options
                for option in selected_options:
                    if option in options_count:
                        options_count[option] += 1
            analysis[question.question_text] = {'options_count': options_count, 'total_responses': len(responses)}

    return analysis

def analyze_feedback_for_session(session_id):
    questions = FeedbackResponse.objects.filter(session_id=session_id)
    analysis = {}

    for question in questions.values('question__id', 'question__question_text', 'question__response_type'):
        q_id = question['question__id']
        q_text = question['question__question_text']
        q_type = question['question__response_type']

        answers = FeedbackResponse.objects.filter(question_id=q_id)
        if q_type == 'paragraph':
            result = [a.answer_text for a in answers]
        elif q_type == 'rating':
            ratings = [a.answer_rating for a in answers if a.answer_rating is not None]
            avg = sum(ratings) / len(ratings) if ratings else 0
            result = {'average_rating': round(avg, 2), 'count': len(ratings)}
        elif q_type == 'checkbox':
            all_choices = []
            for a in answers:
                all_choices.extend(a.answer_checkbox or [])
            result = dict(Counter(all_choices))
        else:
            result = "Unsupported question type"

        analysis[q_id] = {
            'question_text': q_text,
            'type': q_type,
            'result': result
        }

    return analysis

def compute_and_update_session_statistics(session_id):
    session = Session.objects.get(id=session_id)
    registered_count = Registration.objects.filter(session=session).count()
    attended_count = Registration.objects.filter(session=session, attendance=True).count()
    attendance_percentage = (attended_count / registered_count * 100) if registered_count > 0 else 0

    # Average rating (from feedback)
    rating_questions = FeedbackQuestion.objects.filter(session=session, response_type__in=['rating', 'scale'])
    rating_responses = FeedbackResponse.objects.filter(question__in=rating_questions)
    ratings = []
    for resp in rating_responses:
        try:
            ratings.append(float(resp.response))
        except Exception:
            continue
    average_rating = round(sum(ratings) / len(ratings), 2) if ratings else None

    # Impact summary (from paragraph/text feedback)
    impact_questions = FeedbackQuestion.objects.filter(session=session, response_type__in=['paragraph', 'text'])
    impact_responses = FeedbackResponse.objects.filter(question__in=impact_questions)
    impact_texts = [resp.response for resp in impact_responses]
    impact_summary = "\n".join(impact_texts[:5])  # Show first 5 as summary

    # Future improvements (from questions containing 'improve' or 'suggest')
    improvement_questions = FeedbackQuestion.objects.filter(session=session, question_text__icontains='improv') | \
                            FeedbackQuestion.objects.filter(session=session, question_text__icontains='suggest')
    improvement_responses = FeedbackResponse.objects.filter(question__in=improvement_questions)
    improvements = [resp.response for resp in improvement_responses]

    # Save or update statistics
    stats, _ = SessionStatistics.objects.get_or_create(session=session)
    stats.registered_count = registered_count
    stats.attended_count = attended_count
    stats.attendance_percentage = attendance_percentage
    stats.average_rating = average_rating
    stats.impact_summary = impact_summary
    stats.improvement_suggestions = improvements
    stats.save()
    return stats
