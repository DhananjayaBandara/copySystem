# Generated by Django 5.1.7 on 2025-06-06 15:02

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workshop_app', '0006_remove_participant_first_name_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='participant',
            name='nic',
            field=models.CharField(max_length=20),
        ),
    ]
