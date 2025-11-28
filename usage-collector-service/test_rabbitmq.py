#!/usr/bin/env python3
"""
Script de test pour envoyer des messages RabbitMQ au Usage Collector Service
Usage: python test_rabbitmq.py
"""

import pika
import json
import time
import sys

def send_test_messages():
    """Envoie des messages de test à RabbitMQ"""
    try:
        # Connexion à RabbitMQ
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                'localhost',
                5672,
                '/',
                pika.PlainCredentials('guest', 'guest')
            )
        )
        channel = connection.channel()
        
        # Déclarer la queue
        channel.queue_declare(queue='device.usage.queue', durable=True)
        print("✅ Connecté à RabbitMQ")
        
        # Messages de test
        devices = [
            {"deviceId": "tv-1", "currentPowerKw": 0.12},
            {"deviceId": "aircon-1", "currentPowerKw": 0.8},
            {"deviceId": "oven-1", "currentPowerKw": 1.6},
            {"deviceId": "fridge-1", "currentPowerKw": 0.15},
            {"deviceId": "tv-1", "currentPowerKw": 0.15},  # Mise à jour
        ]
        
        print(f"\n📤 Envoi de {len(devices)} messages...\n")
        
        for i, device in enumerate(devices, 1):
            message = json.dumps(device)
            channel.basic_publish(
                exchange='',
                routing_key='device.usage.queue',
                body=message,
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Rendre le message persistant
                    content_type='application/json'
                )
            )
            print(f"[{i}/{len(devices)}] ✅ Envoyé : {message}")
            time.sleep(0.5)  # Petite pause entre les messages
        
        connection.close()
        print(f"\n✅ Tous les {len(devices)} messages ont été envoyés avec succès !")
        print("\n💡 Vérifiez maintenant avec : curl http://localhost:8082/usage/current")
        
    except pika.exceptions.AMQPConnectionError:
        print("❌ Erreur : Impossible de se connecter à RabbitMQ")
        print("   Assurez-vous que RabbitMQ est démarré sur localhost:5672")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erreur : {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("=" * 60)
    print("🧪 Test RabbitMQ - Usage Collector Service")
    print("=" * 60)
    send_test_messages()

