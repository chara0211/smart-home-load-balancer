# Guide : URLs pour Postman (Services NodePort)

## ✅ Configuration Terminée

Les services sont maintenant exposés via **NodePort** et accessibles **sans port-forward** !

---

## 🌐 URLs pour Postman

**IP du cluster :** `172.30.95.94`

### Usage Collector Service

```
GET  http://172.30.95.94:30083/actuator/health
GET  http://172.30.95.94:30083/usage/current
GET  http://172.30.95.94:30083/usage/history?limit=10
GET  http://172.30.95.94:30083/usage/devices
POST http://172.30.95.94:30083/usage/save
```

### Optimizer Service

```
GET http://172.30.95.94:30085/optimizer/health
GET http://172.30.95.94:30085/optimizer/info
```

### Device Simulator Service

```
GET http://172.30.95.94:30082/actuator/health
GET http://172.30.95.94:30082/devices
```

### Peak Detector Service

```
GET http://172.30.95.94:30084/actuator/health
```

---

## 📝 Mise à jour de la Collection Postman

Mettez à jour les variables dans votre collection Postman :

- `base_url_usage` : `http://172.30.95.94:30083`
- `base_url_optimizer` : `http://172.30.95.94:30085`
- `base_url_device` : `http://172.30.95.94:30082`
- `base_url_peak` : `http://172.30.95.94:30084`

---

## ✅ Avantages de NodePort

- ✅ **Pas besoin de port-forward manuel**
- ✅ **Services toujours accessibles** (tant que le cluster tourne)
- ✅ **Comme Docker Compose** - accès direct depuis votre machine
- ✅ **Simple et rapide**

---

## 🔍 Vérification

Pour vérifier que les services NodePort fonctionnent :

```powershell
kubectl get services -n smarthome | Select-String -Pattern "nodeport"
```

Vous devriez voir :
- `usage-collector-service-nodeport` (NodePort, port 30083)
- `optimizer-service-nodeport` (NodePort, port 30085)
- `device-simulator-service-nodeport` (NodePort, port 30082)
- `peak-detector-service-nodeport` (NodePort, port 30084)

---

## 🎯 Test dans Postman

1. **Ouvrez Postman**
2. **Créez une nouvelle requête**
3. **Utilisez les URLs ci-dessus**
4. **Testez !**

Exemple :
- Méthode : `GET`
- URL : `http://172.30.95.94:30083/usage/current`
- Cliquez sur "Send"

---

**Note :** Les services ClusterIP originaux restent pour la communication interne entre pods. Les services NodePort sont en plus pour l'accès externe depuis votre machine.

