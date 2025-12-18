#!/bin/bash

# Script de déploiement complet pour Smart Home Load Balancer
# Ce script déploie tous les composants dans l'ordre correct

set -e

NAMESPACE="smarthome"
K8S_DIR="k8s"

echo "🚀 Déploiement de Smart Home Load Balancer sur Kubernetes"
echo "=========================================================="

# Fonction pour attendre qu'un pod soit prêt
wait_for_pod() {
    local selector=$1
    local timeout=${2:-300}
    echo "⏳ Attente que le pod avec le sélecteur '$selector' soit prêt (timeout: ${timeout}s)..."
    kubectl wait --for=condition=ready pod -l $selector -n $NAMESPACE --timeout=${timeout}s || {
        echo "❌ Le pod n'est pas prêt dans le délai imparti"
        kubectl get pods -l $selector -n $NAMESPACE
        exit 1
    }
    echo "✅ Pod prêt"
}

# 1. Créer le namespace
echo ""
echo "📦 Étape 1: Création du namespace..."
kubectl apply -f $K8S_DIR/namespaces/
echo "✅ Namespace créé"

# 2. Créer les secrets (doivent être créés manuellement avant)
echo ""
echo "🔐 Étape 2: Vérification des secrets..."
echo "⚠️  Assurez-vous d'avoir créé tous les secrets nécessaires (voir k8s/secrets/secrets-template.yaml)"
read -p "Appuyez sur Entrée pour continuer..."

# 3. Déployer les bases de données
echo ""
echo "🗄️  Étape 3: Déploiement des bases de données..."
kubectl apply -f $K8S_DIR/databases/postgres-deployment.yaml
kubectl apply -f $K8S_DIR/databases/postgres-service.yaml
wait_for_pod "app=postgres" 300

kubectl apply -f $K8S_DIR/databases/mongodb-deployment.yaml
kubectl apply -f $K8S_DIR/databases/mongodb-service.yaml
wait_for_pod "app=mongodb" 300

kubectl apply -f $K8S_DIR/databases/cassandra-statefulset.yaml
kubectl apply -f $K8S_DIR/databases/cassandra-service.yaml
wait_for_pod "app=cassandra" 600

echo "✅ Bases de données déployées"

# 4. Déployer RabbitMQ
echo ""
echo "🐰 Étape 4: Déploiement de RabbitMQ..."
kubectl apply -f $K8S_DIR/message-broker/
wait_for_pod "app=rabbitmq" 300
echo "✅ RabbitMQ déployé"

# 5. Déployer l'observabilité (en parallèle)
echo ""
echo "📊 Étape 5: Déploiement de l'observabilité..."
kubectl apply -f $K8S_DIR/monitoring/prometheus/
kubectl apply -f $K8S_DIR/monitoring/grafana/
kubectl apply -f $K8S_DIR/monitoring/elastic/
echo "✅ Observabilité déployée (Prometheus, Grafana, Elastic Stack)"

# 6. Déployer Keycloak
echo ""
echo "🔑 Étape 6: Déploiement de Keycloak..."
kubectl apply -f $K8S_DIR/keycloak/
wait_for_pod "app=keycloak" 600
echo "✅ Keycloak déployé"

# 7. Déployer les microservices
echo ""
echo "⚙️  Étape 7: Déploiement des microservices..."
kubectl apply -f $K8S_DIR/services/usage-collector/
kubectl apply -f $K8S_DIR/services/peak-detector/
kubectl apply -f $K8S_DIR/services/device-simulator/
kubectl apply -f $K8S_DIR/services/optimizer/
echo "✅ Microservices déployés"

# 8. Déployer le Frontend
echo ""
echo "🎨 Étape 8: Déploiement du Frontend..."
kubectl apply -f $K8S_DIR/services/frontend/
echo "✅ Frontend déployé"

# 9. Déployer l'API Gateway
echo ""
echo "🌐 Étape 9: Déploiement de l'API Gateway..."
kubectl apply -f $K8S_DIR/api-gateway/
echo "✅ API Gateway déployé"

# 10. Déployer l'Ingress
echo ""
echo "🔀 Étape 10: Déploiement de l'Ingress..."
kubectl apply -f $K8S_DIR/ingress/
echo "✅ Ingress déployé"

# 11. Vérification finale
echo ""
echo "🔍 Étape 11: Vérification du déploiement..."
echo ""
echo "📋 État des pods:"
kubectl get pods -n $NAMESPACE

echo ""
echo "📋 État des services:"
kubectl get services -n $NAMESPACE

echo ""
echo "📋 État de l'ingress:"
kubectl get ingress -n $NAMESPACE

echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "🌐 URLs d'accès (selon votre configuration Ingress):"
echo "   - Frontend: http://your-domain/"
echo "   - API Gateway: http://your-domain/api"
echo "   - Keycloak: http://your-domain/auth"
echo "   - Prometheus: http://your-domain/prometheus"
echo "   - Grafana: http://your-domain/grafana"
echo "   - Kibana: http://your-domain/kibana"
echo ""
echo "📝 Pour voir les logs d'un service:"
echo "   kubectl logs -f deployment/<service-name> -n $NAMESPACE"

