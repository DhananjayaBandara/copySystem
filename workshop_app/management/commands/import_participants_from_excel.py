from django.core.management.base import BaseCommand
import pandas as pd
import ast
from django.utils.dateparse import parse_date
from workshop_app.models import Participant, ParticipantType, Registration, Session
from django.db import transaction

class Command(BaseCommand):
    help = 'Import participants from Excel file'

    def handle(self, *args, **kwargs):
        EXCEL_PATH = "../../May 08 workshop Details/Preprocessed data/participants_transport_ministry_cleaned.xlsx"
        df = pd.read_excel(EXCEL_PATH)
        
        participants = []
        with transaction.atomic():
            for index, row in df.iterrows():
                try:
                    name = str(row['name']).strip()
                    contact_number = str(row['contact_number']).strip()
                    email = str(row['email']).strip()
                    district = str(row['district']).strip()
                    nic = str(row['nic']).strip()
                    gender = str(row['gender']).strip()
                    participant_type_id = int(row['participant_type_id'])
                    properties_str = str(row['properties']).strip()
                    dob = parse_date(str(row['dob']))

                    properties = ast.literal_eval(properties_str)
                    participant_type = ParticipantType.objects.get(id=participant_type_id)

                    participant = Participant(
                        name=name,
                        email=email,
                        contact_number=contact_number,
                        nic=nic,
                        dob=dob,
                        district=district,
                        gender=gender,
                        participant_type=participant_type,
                        properties=properties
                    )
                    participants.append(participant)
                except Exception as e:
                    self.stderr.write(f"Error at row {index + 2}: {e}")

            Participant.objects.bulk_create(participants)
            self.stdout.write(self.style.SUCCESS(f"Successfully imported {len(participants)} participants"))

            # Register all imported participants to session id 1 with attendance=1
            session = Session.objects.get(id=1)
            registrations = []
            for participant in Participant.objects.filter(email__in=[p.email for p in participants]):
                registrations.append(
                    Registration(
                        participant=participant,
                        session=session,
                        attendance=True
                    )
                )
            Registration.objects.bulk_create(registrations)
            self.stdout.write(self.style.SUCCESS(f"Registered all participants to session id 1 with attendance=1"))
