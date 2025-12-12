#!/bin/bash

# Script de test des connexions dans le cluster Kubernetes
# Ce script teste toutes les connexions entre les composants

set -e

NAMESPACE="smarthome"

echo "🧪 Test des Connexions Kubernetes - Smart Home Load Balancer"
echo "=============================================================="
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour tester une connexion
test_connection() {
    local description=$1
    local command=$2
    echo -n "Test: $description... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

# Fonction pour tester une commande avec sortie
test_with_output() {
    local description=$1
    local command=$2
    echo -e "${YELLOW}Test: $description${NC}"
    echo "Commande: $command"
    echo "Résultat:"
    eval "$command"
    echo ""
}

# 1. Vérifier l'état des pods
echo "📋 Étape 1: Vérification de l'état des pods"
echo "--------------------------------------------"
kubectl get pods -n $NAMESPACE
echo ""

# 2. Vérifier les services
echo "📋 Étape 2: Vérification des services"
echo "--------------------------------------"
kubectl get services -n $NAMESPACE
echo ""

# 3. Test de connexion à PostgreSQL
echo "🗄️  Étape 3: Test de connexion à PostgreSQL"
echo "---------------------------------------------"

# Obtenir le nom du pod usage-collector
USAGE_COLLECTOR_POD=$(kubectl get pods -n $NAMESPACE -l app=usage-collector-service -o jsonpath='{.items[0].metadata.name}')

if [ -z "$USAGE_COLLECTOR_POD" ]; then
    echo -e "${RED}❌ Aucun pod usage-collector-service trouvé${NC}"
else
    echo "Pod utilisé: $USAGE_COLLECTOR_POD"
    
    # Test de résolution DNS
    test_connection "Résolution DNS de postgres-service" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- nslookup postgres-service"
    
    # Test de connexion TCP
    test_connection "Connexion TCP au port 5432" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- nc -zv postgres-service 5432"
    
    # Test de connexion PostgreSQL (si psql est disponible)
    test_with_output "Test de connexion PostgreSQL avec psql" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- sh -c 'command -v psql > /dev/null && PGPASSWORD=smarthome psql -h postgres-service -U smarthome -d smarthome -c \"SELECT version();\" || echo \"psql non disponible dans le pod\"'"
fi
echo ""

# 4. Test de connexion à RabbitMQ
echo "🐰 Étape 4: Test de connexion à RabbitMQ"
echo "-----------------------------------------"

if [ -z "$USAGE_COLLECTOR_POD" ]; then
    echo -e "${RED}❌ Aucun pod usage-collector-service trouvé${NC}"
else
    # Test de résolution DNS
    test_connection "Résolution DNS de rabbitmq-service" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- nslookup rabbitmq-service"
    
    # Test de connexion TCP au port AMQP
    test_connection "Connexion TCP au port 5672 (AMQP)" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- nc -zv rabbitmq-service 5672"
    
    # Test de connexion TCP au port management
    test_connection "Connexion TCP au port 15672 (Management)" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- nc -zv rabbitmq-service 15672"
    
    # Test avec rabbitmq-diagnostics (depuis le pod RabbitMQ)
    RABBITMQ_POD=$(kubectl get pods -n $NAMESPACE -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$RABBITMQ_POD" ]; then
        test_with_output "Test RabbitMQ ping" \
            "kubectl exec $RABBITMQ_POD -n $NAMESPACE -- rabbitmq-diagnostics ping"
    fi
fi
echo ""

# 5. Test de communication entre services
echo "🔗 Étape 5: Test de communication entre services"
echo "-------------------------------------------------"

# Test usage-collector -> peak-detector
PEAK_DETECTOR_POD=$(kubectl get pods -n $NAMESPACE -l app=peak-detector-service -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$PEAK_DETECTOR_POD" ] && [ ! -z "$USAGE_COLLECTOR_POD" ]; then
    test_connection "Résolution DNS usage-collector-service" \
        "kubectl exec $PEAK_DETECTOR_POD -n $NAMESPACE -- nslookup usage-collector-service"
    
    test_connection "Connexion HTTP à usage-collector-service:8083" \
        "kubectl exec $PEAK_DETECTOR_POD -n $NAMESPACE -- wget -q --spider --timeout=5 http://usage-collector-service:8083/actuator/health"
fi
echo ""

# 6. Test des endpoints HTTP des services
echo "🌐 Étape 6: Test des endpoints HTTP"
echo "------------------------------------"

# Test usage-collector-service
if [ ! -z "$USAGE_COLLECTOR_POD" ]; then
    test_with_output "Health check usage-collector-service" \
        "kubectl exec $USAGE_COLLECTOR_POD -n $NAMESPACE -- wget -q -O- http://localhost:8083/actuator/health"
fi

# Test peak-detector-service
if [ ! -z "$PEAK_DETECTOR_POD" ]; then
    test_with_output "Health check peak-detector-service" \
        "kubectl exec $PEAK_DETECTOR_POD -n $NAMESPACE -- wget -q -O- http://localhost:8084/actuator/health"
fi

# Test optimizer-service
OPTIMIZER_POD=$(kubectl get pods -n $NAMESPACE -l app=optimizer-service -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$OPTIMIZER_POD" ]; then
    test_with_output "Health check optimizer-service" \
        "kubectl exec $OPTIMIZER_POD -n $NAMESPACE -- wget -q -O- http://localhost:8085/actuator/health"
fi

# Test device-simulator-service
DEVICE_SIM_POD=$(kubectl get pods -n $NAMESPACE -l app=device-simulator-service -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$DEVICE_SIM_POD" ]; then
    test_with_output "Health check device-simulator-service" \
        "kubectl exec $DEVICE_SIM_POD -n $NAMESPACE -- wget -q -O- http://localhost:8082/actuator/health"
fi
echo ""

# 7. Test via port-forward (accès local)
echo "🔌 Étape 7: Test via port-forward (accès local)"
echo "------------------------------------------------"
echo "Pour tester depuis votre machine locale, utilisez:"
echo ""
echo "Usage Collector Service:"
echo "  kubectl port-forward service/usage-collector-service 8083:8083 -n $NAMESPACE"
echo "  curl http://localhost:8083/actuator/health"
echo ""
echo "Peak Detector Service:"
echo "  kubectl port-forward service/peak-detector-service 8084:8084 -n $NAMESPACE"
echo "  curl http://localhost:8084/actuator/health"
echo ""
echo "Optimizer Service:"
echo "  kubectl port-forward service/optimizer-service 8085:8085 -n $NAMESPACE"
echo "  curl http://localhost:8085/actuator/health"
echo ""
echo "RabbitMQ Management:"
echo "  kubectl port-forward service/rabbitmq-service 15672:15672 -n $NAMESPACE"
echo "  Ouvrir http://localhost:15672 (guest/guest)"
echo ""
echo "PostgreSQL:"
echo "  kubectl port-forward service/postgres-service 5432:5432 -n $NAMESPACE"
echo ""

# 8. Test des logs pour vérifier les connexions
echo "📝 Étape 8: Vérification des logs de connexion"
echo "----------------------------------------------"
echo "Logs usage-collector-service (dernières 20 lignes):"
if [ ! -z "$USAGE_COLLECTOR_POD" ]; then
    kubectl logs $USAGE_COLLECTOR_POD -n $NAMESPACE --tail=20 | grep -i "connect\|database\|rabbitmq\|error" || echo "Aucune ligne de connexion trouvée"
fi
echo ""

# 9. Résumé
echo "📊 Résumé des tests"
echo "-------------------"
echo "Vérifiez les résultats ci-dessus pour identifier les problèmes de connexion."
echo ""
echo "Commandes utiles pour le débogage:"
echo "  - Voir les logs: kubectl logs -f <pod-name> -n $NAMESPACE"
echo "  - Décrire un pod: kubectl describe pod <pod-name> -n $NAMESPACE"
echo "  - Exécuter une commande: kubectl exec -it <pod-name> -n $NAMESPACE -- /bin/sh"
echo "  - Voir les événements: kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
echo ""

