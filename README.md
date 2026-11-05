# helm-chart-generic-app

Chart de Helm **genérico y reutilizable** para desplegar cualquier aplicación
_stateless_ en Kubernetes, con dependencias opcionales. Es el núcleo del patrón
"un chart, muchos values" del circuito **QuickTask GitOps**.

> El chart **no conoce ninguna aplicación concreta**. Solo expone un contrato de
> `values`. La configuración específica de cada app (p. ej. `quicktask`) vive en el
> repo [`gitops-app-values`](https://github.com/slashispy/gitops-app-values), y las
> `Application`/`ApplicationSet` de Argo CD en
> [`gitops-argocd-apps`](https://github.com/slashispy/gitops-argocd-apps).

## Qué despliega

| Recurso | Cuándo | Descripción |
|---|---|---|
| `Deployment` | siempre | App stateless; env desde ConfigMap/Secret vía `envFrom`; probes configurables; rollout automático al cambiar config/secret (checksum). |
| `Service` | siempre | `ClusterIP` por defecto; expone el puerto de la app. |
| `ServiceAccount` | `serviceAccount.create=true` | SA dedicado (soporta anotaciones IRSA en EKS). |
| `ConfigMap` | si hay `env.config` | Variables de entorno no sensibles. |
| `Secret` | si hay `env.secret` | Variables sensibles (DEMO; en prod usar External Secrets/SOPS). |
| `HorizontalPodAutoscaler` | `autoscaling.enabled=true` | Escalado por CPU/memoria. |
| `Ingress` | `ingress.enabled=true` | Enrutamiento HTTP opcional. |
| `StatefulSet` + `Service` headless (+ `PVC`) de MongoDB | `mongodb.enabled=true` | Dependencia MongoDB para demo en KIND. |

## Contrato de values (resumen)

```yaml
replicaCount: 1
image:
  repository: my-app        # requerido
  tag: "dev"                # requerido (en KIND, tag fijo)
  pullPolicy: IfNotPresent
service:
  type: ClusterIP           # ClusterIP | NodePort | LoadBalancer
  port: 8080
  targetPort: 8080
env:
  config: {}                # -> ConfigMap (envFrom)
  secret: {}                # -> Secret (envFrom)
probes:
  liveness:  { enabled: true, httpGet: { path: /health, port: 8080 } }
  readiness: { enabled: true, httpGet: { path: /ready,  port: 8080 } }
resources: {}
autoscaling: { enabled: false, minReplicas: 1, maxReplicas: 5, targetCPUUtilizationPercentage: 80 }
ingress: { enabled: false }
mongodb: { enabled: false } # StatefulSet + Service headless + PVC cuando true
```

El contrato completo está documentado clave por clave en
[`values.yaml`](./values.yaml), y validado por
[`values.schema.json`](./values.schema.json).

## Uso

### Lint y render (sin cluster)

```bash
# Validar el chart
helm lint .

# Render con los defaults
helm template demo .

# Render con el ejemplo de quicktask (app + MongoDB)
helm template quicktask . -f examples/quicktask-values.yaml
```

### Instalar en un cluster

```bash
helm install quicktask . \
  --namespace quicktask --create-namespace \
  -f examples/quicktask-values.yaml
```

> En el circuito real **no se instala a mano**: Argo CD renderiza este chart con los
> values de `gitops-app-values`. Ver el repo
> [`kind-gitops-utility-belt`](https://github.com/slashispy/kind-gitops-utility-belt)
> para levantar todo el circuito.

## Decisiones de diseño

- **Inyección de env vía `envFrom`**: `config` → ConfigMap, `secret` → Secret. El
  Deployment incluye `checksum/config` y `checksum/secret` como anotaciones para que
  un cambio en esos recursos dispare un rollout automático.
- **`targetPort: http`**: el Service apunta al puerto con nombre `http` del contenedor,
  evitando desajustes si cambia el número de puerto.
- **Probes desacoplados**: liveness en `/health` (siempre 200), readiness en `/ready`
  (verifica dependencias). Cada uno se puede desactivar con `enabled: false`.
- **Secretos en DEMO**: `env.secret` genera un `Secret` con los valores en claro, solo
  para portfolio/KIND. En producción se documenta el uso de External Secrets / SOPS /
  Sealed Secrets.
- **MongoDB opcional**: `StatefulSet` de 1 réplica + `Service` headless + `PVC`,
  pensado para la demo. En producción se usaría un chart dedicado o un servicio
  gestionado.

## Estructura

```
helm-chart-generic-app/
├── Chart.yaml
├── values.yaml              # defaults + documentación del contrato
├── values.schema.json       # validación del contrato
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml       # toggle: env.config
│   ├── secret.yaml          # toggle: env.secret
│   ├── serviceaccount.yaml  # toggle: serviceAccount.create
│   ├── hpa.yaml             # toggle: autoscaling.enabled
│   ├── ingress.yaml         # toggle: ingress.enabled
│   ├── mongodb.yaml         # toggle: mongodb.enabled
│   └── NOTES.txt
└── examples/
    └── quicktask-values.yaml  # ejemplo de referencia (no productivo)
```

## Parte del circuito QuickTask GitOps

1. [`quicktask`](https://github.com/slashispy/quicktask) — la aplicación (API Go + MongoDB).
2. **`helm-chart-generic-app`** — este chart genérico. ← estás aquí
3. [`gitops-app-values`](https://github.com/slashispy/gitops-app-values) — values por app.
4. [`gitops-argocd-apps`](https://github.com/slashispy/gitops-argocd-apps) — App of Apps + ApplicationSet.
5. [`kind-gitops-utility-belt`](https://github.com/slashispy/kind-gitops-utility-belt) — bootstrap del circuito en KIND.
