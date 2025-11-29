# 🐙 Notilus Backend Lab - Architecture Système

> **Le système de tests backend le plus avancé jamais conçu pour un navigateur de développement**

---

## 📋 Table des Matières

1. [Vision & Philosophie](#vision--philosophie)
2. [Architecture Globale](#architecture-globale)
3. [Module 1: Server Discovery](#module-1-server-discovery)
4. [Module 2: Route Discovery](#module-2-route-discovery)
5. [Module 3: API Testing Engine](#module-3-api-testing-engine)
6. [Module 4: Injection & Interception](#module-4-injection--interception)
7. [Module 5: Security Scanner](#module-5-security-scanner)
8. [Module 6: Performance Lab](#module-6-performance-lab)
9. [Module 7: Mock & Simulation](#module-7-mock--simulation)
10. [Module 8: Analytics & Reporting](#module-8-analytics--reporting)
11. [Interface Utilisateur Flutter](#interface-utilisateur-flutter)
12. [Intégrations & API](#intégrations--api)

---

## Vision & Philosophie

### 🎯 Objectif Principal

Créer un **écosystème de tests backend complet et autonome** qui permet aux développeurs de:
- Découvrir automatiquement tous les serveurs locaux en cours d'exécution
- Mapper intelligemment toutes les routes et endpoints
- Tester exhaustivement les API (fonctionnel, performance, sécurité)
- Intercepter, modifier et rejouer les requêtes en temps réel
- Détecter les vulnérabilités avant la mise en production
- Générer des rapports professionnels

### 💡 Principes Fondamentaux

1. **Zero Configuration** - Fonctionne immédiatement, sans configuration
2. **Intelligence Artificielle** - Apprentissage et suggestions automatiques
3. **Temps Réel** - Tout est live et instantané
4. **Sécurité First** - Tests de sécurité intégrés nativement
5. **Developer Experience** - Interface intuitive et puissante

---

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NOTILUS BACKEND LAB                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   SERVER     │  │    ROUTE     │  │     API      │  │  INJECTION   │    │
│  │  DISCOVERY   │  │  DISCOVERY   │  │   TESTING    │  │ INTERCEPTION │    │
│  │              │  │              │  │   ENGINE     │  │              │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │             │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐    │
│  │   SECURITY   │  │ PERFORMANCE  │  │    MOCK      │  │  ANALYTICS   │    │
│  │   SCANNER    │  │     LAB      │  │  SIMULATION  │  │  REPORTING   │    │
│  │              │  │              │  │              │  │              │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                         🔗 UNIFIED DATA LAYER                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Session Manager │ Request Store │ Test Results │ Security Findings │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                         📡 COMMUNICATION LAYER                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │     WebSocket     │     REST API     │    Event Stream    │  IPC    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

                                    ⬇️

┌─────────────────────────────────────────────────────────────────────────────┐
│                         💻 FLUTTER INTERFACE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐ │
│  │  Servers   │ │   Routes   │ │   Tests    │ │  Security  │ │ Reports  │ │
│  │   Panel    │ │   Panel    │ │   Panel    │ │   Panel    │ │  Panel   │ │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘ └──────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Module 1: Server Discovery

### 🔍 Vue d'Ensemble

Le module Server Discovery est le **cœur de l'intelligence** du système. Il détecte automatiquement tous les serveurs en cours d'exécution sur la machine locale et extrait leurs métadonnées.

### Fonctionnalités Détaillées

#### 1.1 Scan des Ports Actifs

```python
# Plages de ports à scanner
PORT_RANGES = {
    'web_common': [80, 443, 8080, 8443, 8000, 8888],
    'node_react': [3000, 3001, 3002, 3003, 5000, 5173, 5174],
    'python': [5000, 5001, 8000, 8001, 8080],
    'java': [8080, 8081, 9000, 9090],
    'database': [5432, 3306, 27017, 6379, 9200],
    'full_range': range(1024, 65535)  # Scan complet optionnel
}
```

#### 1.2 Fingerprinting des Technologies

| Framework | Détection | Confiance |
|-----------|-----------|-----------|
| Express.js | Headers `X-Powered-By`, patterns de routes | 95% |
| FastAPI | `/docs`, `/openapi.json`, headers | 98% |
| Django | `/admin`, cookies CSRF | 92% |
| Flask | Headers, patterns | 88% |
| Spring Boot | `/actuator`, headers | 96% |
| Rails | Headers, cookies | 90% |
| Laravel | Headers, cookies XSRF | 93% |
| NestJS | Swagger, patterns | 91% |
| Gin (Go) | Headers, performance | 85% |
| ASP.NET | Headers | 97% |

#### 1.3 Health Check & Monitoring

```python
class HealthCheckResult:
    status: HealthStatus  # healthy, degraded, unhealthy, unknown
    response_time_ms: float
    last_check: datetime
    uptime_percentage: float
    error_count: int
    consecutive_failures: int
    ssl_valid: bool
    ssl_expires: Optional[datetime]
    memory_usage: Optional[float]  # Si accessible via endpoints
    cpu_usage: Optional[float]
```

#### 1.4 Process Intelligence

- Détection du processus parent (node, python, java, etc.)
- Arguments de lancement
- Variables d'environnement (si accessibles)
- Fichiers de configuration associés

### Schéma de Données

```python
@dataclass
class DiscoveredServer:
    id: str                          # UUID unique
    host: str                        # localhost, 127.0.0.1, 0.0.0.0
    port: int                        # Port d'écoute
    protocol: str                    # http, https, ws, wss
    
    # Identification
    name: Optional[str]              # Nom auto-détecté
    framework: Optional[str]         # Express, FastAPI, Django...
    framework_version: Optional[str] # Version du framework
    language: Optional[str]          # Node.js, Python, Java...
    
    # État
    status: ServerStatus             # running, stopped, error
    health: HealthCheckResult        # Résultat du health check
    
    # Métadonnées
    process_id: Optional[int]        # PID du processus
    process_name: Optional[str]      # Nom du processus
    working_directory: Optional[str] # Répertoire de travail
    
    # Découverte
    discovered_at: datetime          # Date de découverte
    last_seen: datetime              # Dernière activité
    discovery_method: str            # port_scan, process, manual
    
    # Routes (remplies par Route Discovery)
    routes: List[DiscoveredRoute]
    
    # Métriques
    request_count: int               # Requêtes interceptées
    error_rate: float               # Taux d'erreur
    avg_response_time: float        # Temps de réponse moyen
```

### API Endpoints

```
POST   /api/backend-lab/servers/scan              # Lancer un scan
GET    /api/backend-lab/servers                   # Liste des serveurs
GET    /api/backend-lab/servers/{id}              # Détails d'un serveur
POST   /api/backend-lab/servers/{id}/health       # Health check manuel
DELETE /api/backend-lab/servers/{id}              # Supprimer de la liste
POST   /api/backend-lab/servers/add               # Ajouter manuellement
GET    /api/backend-lab/servers/{id}/processes    # Infos processus
```

---

## Module 2: Route Discovery

### 🗺️ Vue d'Ensemble

Le module Route Discovery **cartographie automatiquement** tous les endpoints d'une API en utilisant plusieurs techniques avancées.

### Méthodes de Découverte

#### 2.1 OpenAPI/Swagger Detection

```python
OPENAPI_ENDPOINTS = [
    '/openapi.json',
    '/swagger.json', 
    '/api-docs',
    '/docs',
    '/swagger',
    '/swagger-ui',
    '/swagger-ui.html',
    '/v2/api-docs',
    '/v3/api-docs',
    '/api/openapi.json',
    '/api/swagger.json'
]
```

#### 2.2 GraphQL Introspection

```graphql
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}
```

#### 2.3 Smart Fuzzing

```python
# Patterns de routes courants à tester
ROUTE_PATTERNS = [
    # CRUD basique
    '/api/{resource}',
    '/api/{resource}/{id}',
    '/api/v1/{resource}',
    '/api/v2/{resource}',
    
    # Auth
    '/auth/login',
    '/auth/register',
    '/auth/logout',
    '/auth/refresh',
    '/auth/forgot-password',
    '/api/auth/*',
    
    # Users
    '/users',
    '/users/me',
    '/users/{id}',
    '/api/users/*',
    
    # Common resources
    '/products', '/items', '/orders', '/posts', '/comments',
    '/categories', '/tags', '/files', '/uploads', '/images',
    
    # Admin
    '/admin',
    '/admin/*',
    '/dashboard',
    '/settings',
    
    # Health & Status
    '/health',
    '/status',
    '/ping',
    '/ready',
    '/live',
    '/metrics',
    '/info',
    
    # GraphQL
    '/graphql',
    '/gql',
    
    # WebSocket
    '/ws',
    '/socket',
    '/socket.io',
]

# Ressources communes à découvrir
RESOURCE_NAMES = [
    'users', 'products', 'orders', 'items', 'posts', 'comments',
    'categories', 'tags', 'files', 'images', 'documents', 'messages',
    'notifications', 'settings', 'profiles', 'accounts', 'payments',
    'transactions', 'reports', 'analytics', 'logs', 'events'
]
```

#### 2.4 Response Analysis

```python
class ResponseAnalyzer:
    """Analyse les réponses pour découvrir plus de routes"""
    
    def analyze_links(self, response: Response) -> List[str]:
        """Extrait les liens des headers Link et du body"""
        pass
    
    def analyze_hateoas(self, response: Response) -> List[str]:
        """Analyse les réponses HATEOAS pour trouver les liens"""
        pass
    
    def analyze_html(self, response: Response) -> List[str]:
        """Parse le HTML pour trouver les endpoints dans les forms/scripts"""
        pass
    
    def analyze_javascript(self, content: str) -> List[str]:
        """Analyse le JavaScript pour extraire les URLs d'API"""
        patterns = [
            r'fetch\(["\']([^"\']+)["\']',
            r'axios\.[a-z]+\(["\']([^"\']+)["\']',
            r'\.get\(["\']([^"\']+)["\']',
            r'\.post\(["\']([^"\']+)["\']',
            r'api[Uu]rl\s*[:=]\s*["\']([^"\']+)["\']',
            r'endpoint\s*[:=]\s*["\']([^"\']+)["\']',
        ]
        pass
```

### Schéma de Données

```python
@dataclass
class DiscoveredRoute:
    id: str                           # UUID unique
    server_id: str                    # Référence au serveur
    
    # Identité
    path: str                         # /api/users/{id}
    method: HttpMethod                # GET, POST, PUT, DELETE, PATCH...
    
    # Paramètres
    path_params: List[RouteParameter]  # Paramètres dans le path
    query_params: List[RouteParameter] # Paramètres query string
    headers: List[RouteParameter]      # Headers requis
    body_schema: Optional[Dict]        # Schéma du body (JSON Schema)
    
    # Réponse
    response_schema: Optional[Dict]    # Schéma de réponse
    response_codes: List[int]          # Codes de réponse observés
    content_types: List[str]           # Types de contenu
    
    # Métadonnées
    discovery_method: str              # openapi, fuzzing, intercept, manual
    discovered_at: datetime
    last_tested: Optional[datetime]
    
    # Documentation
    summary: Optional[str]             # Description courte
    description: Optional[str]         # Description longue
    tags: List[str]                    # Tags/catégories
    deprecated: bool = False
    
    # Sécurité
    auth_required: bool               # Authentification requise?
    auth_type: Optional[str]          # bearer, basic, api_key, oauth2
    permissions: List[str]            # Permissions requises
    
    # Tests
    test_results: List[TestResult]    # Historique des tests
    vulnerability_scan: Optional[ScanResult]  # Résultats sécu
    
    # Statistiques
    call_count: int                   # Nombre d'appels interceptés
    avg_response_time: float          # Temps de réponse moyen
    error_rate: float                 # Taux d'erreur
    
@dataclass
class RouteParameter:
    name: str
    location: str                     # path, query, header, body
    type: str                         # string, integer, boolean, array, object
    required: bool
    default_value: Optional[Any]
    description: Optional[str]
    enum_values: Optional[List[Any]]  # Valeurs possibles
    pattern: Optional[str]            # Regex de validation
    example: Optional[Any]            # Exemple de valeur
```

### API Endpoints

```
POST   /api/backend-lab/routes/discover/{server_id}  # Découverte auto
GET    /api/backend-lab/routes/{server_id}           # Liste des routes
GET    /api/backend-lab/routes/{server_id}/{route_id} # Détails route
POST   /api/backend-lab/routes/{server_id}/import    # Import OpenAPI
PUT    /api/backend-lab/routes/{route_id}            # Modifier route
DELETE /api/backend-lab/routes/{route_id}            # Supprimer route
POST   /api/backend-lab/routes/{route_id}/test       # Tester route
```

---

## Module 3: API Testing Engine

### 🧪 Vue d'Ensemble

Le cœur du système de tests. Un moteur complet permettant de créer, exécuter et analyser des tests d'API de manière visuelle ou programmatique.

### Types de Tests

#### 3.1 Tests Fonctionnels

```python
class FunctionalTest:
    """Test fonctionnel d'un endpoint"""
    
    # Configuration
    name: str
    description: str
    route_id: str
    
    # Requête
    request: TestRequest
    
    # Assertions
    assertions: List[Assertion]
    
    # Chaînage
    extract_variables: List[VariableExtraction]  # Extraire des valeurs
    depends_on: List[str]  # Dépendances sur d'autres tests
    
class Assertion:
    """Types d'assertions disponibles"""
    type: AssertionType  # status, header, body, time, schema
    target: str          # Ce qu'on vérifie
    operator: str        # equals, contains, matches, exists, gt, lt...
    expected: Any        # Valeur attendue
    
# Opérateurs d'assertion
ASSERTION_OPERATORS = {
    'equals': lambda a, b: a == b,
    'not_equals': lambda a, b: a != b,
    'contains': lambda a, b: b in a,
    'not_contains': lambda a, b: b not in a,
    'starts_with': lambda a, b: a.startswith(b),
    'ends_with': lambda a, b: a.endswith(b),
    'matches': lambda a, b: re.match(b, a),
    'exists': lambda a, _: a is not None,
    'not_exists': lambda a, _: a is None,
    'is_empty': lambda a, _: len(a) == 0,
    'is_not_empty': lambda a, _: len(a) > 0,
    'gt': lambda a, b: float(a) > float(b),
    'gte': lambda a, b: float(a) >= float(b),
    'lt': lambda a, b: float(a) < float(b),
    'lte': lambda a, b: float(a) <= float(b),
    'is_type': lambda a, b: type(a).__name__ == b,
    'is_array': lambda a, _: isinstance(a, list),
    'is_object': lambda a, _: isinstance(a, dict),
    'array_length': lambda a, b: len(a) == b,
    'array_contains': lambda a, b: b in a,
    'json_schema': lambda a, b: validate_schema(a, b),
}
```

#### 3.2 Tests de Collection

```python
class TestCollection:
    """Collection de tests liés"""
    id: str
    name: str
    description: str
    
    # Variables d'environnement
    variables: Dict[str, Any]
    
    # Tests
    tests: List[FunctionalTest]
    
    # Hooks
    pre_request_script: Optional[str]   # Script avant chaque requête
    post_response_script: Optional[str] # Script après chaque réponse
    setup_script: Optional[str]         # Script avant la collection
    teardown_script: Optional[str]      # Script après la collection
    
    # Configuration
    stop_on_failure: bool
    parallel_execution: bool
    retry_count: int
    retry_delay_ms: int
```

#### 3.3 Tests de Scénarios (Workflows)

```python
class TestScenario:
    """Scénario de test complexe avec flux"""
    name: str
    steps: List[ScenarioStep]
    
class ScenarioStep:
    """Une étape du scénario"""
    id: str
    name: str
    type: StepType  # request, condition, loop, delay, script
    
    # Pour type=request
    request: Optional[TestRequest]
    assertions: List[Assertion]
    extract: List[VariableExtraction]
    
    # Pour type=condition
    condition: Optional[str]  # Expression à évaluer
    if_true: Optional[str]    # ID du step si vrai
    if_false: Optional[str]   # ID du step si faux
    
    # Pour type=loop
    loop_count: Optional[int]
    loop_variable: Optional[str]
    loop_over: Optional[str]  # Variable contenant une liste
    
    # Pour type=delay
    delay_ms: Optional[int]
    
    # Pour type=script
    script: Optional[str]
```

#### 3.4 Tests de Validation de Schéma

```python
class SchemaValidationTest:
    """Validation automatique des schémas"""
    route_id: str
    
    # Schéma attendu (JSON Schema)
    request_schema: Optional[Dict]
    response_schema: Optional[Dict]
    
    # Configuration
    validate_request: bool
    validate_response: bool
    strict_mode: bool  # Pas de propriétés additionnelles
    
    # Résultats
    validation_errors: List[SchemaValidationError]
```

#### 3.5 Tests de Contrat

```python
class ContractTest:
    """Test de contrat API (consumer-driven)"""
    consumer_name: str
    provider_name: str
    
    # Interactions attendues
    interactions: List[ContractInteraction]
    
class ContractInteraction:
    description: str
    request: ContractRequest
    response: ContractResponse
    
    # Le provider DOIT respecter ce contrat
```

### Variables & Environnements

```python
class Environment:
    """Environnement de test"""
    id: str
    name: str  # Development, Staging, Production
    
    variables: Dict[str, EnvironmentVariable]
    
class EnvironmentVariable:
    key: str
    value: str
    type: str  # string, secret, dynamic
    
    # Pour les secrets
    is_secret: bool
    
    # Pour les valeurs dynamiques
    generator: Optional[str]  # uuid, timestamp, random_string, etc.
    
# Variables dynamiques built-in
DYNAMIC_VARIABLES = {
    '{{$uuid}}': lambda: str(uuid.uuid4()),
    '{{$timestamp}}': lambda: str(int(time.time())),
    '{{$isoTimestamp}}': lambda: datetime.now().isoformat(),
    '{{$randomInt}}': lambda: str(random.randint(0, 1000)),
    '{{$randomString}}': lambda: ''.join(random.choices(string.ascii_letters, k=10)),
    '{{$randomEmail}}': lambda: f"test_{uuid.uuid4().hex[:8]}@example.com",
    '{{$randomName}}': lambda: random.choice(FAKE_NAMES),
    '{{$guid}}': lambda: str(uuid.uuid4()),
}
```

### Moteur d'Exécution

```python
class TestRunner:
    """Moteur d'exécution des tests"""
    
    async def run_test(self, test: FunctionalTest, env: Environment) -> TestResult:
        """Exécute un test unique"""
        pass
    
    async def run_collection(self, collection: TestCollection, env: Environment) -> CollectionResult:
        """Exécute une collection de tests"""
        pass
    
    async def run_scenario(self, scenario: TestScenario, env: Environment) -> ScenarioResult:
        """Exécute un scénario complet"""
        pass
    
    def substitute_variables(self, template: str, variables: Dict) -> str:
        """Remplace les variables dans un template"""
        pass
    
    async def execute_script(self, script: str, context: Dict) -> Any:
        """Exécute un script de test (JavaScript sandbox)"""
        pass
```

### API Endpoints

```
# Tests
POST   /api/backend-lab/tests/run                   # Exécuter un test
POST   /api/backend-lab/tests/collection/run        # Exécuter collection
POST   /api/backend-lab/tests/scenario/run          # Exécuter scénario

# Collections
GET    /api/backend-lab/collections                 # Liste collections
POST   /api/backend-lab/collections                 # Créer collection
GET    /api/backend-lab/collections/{id}            # Détails
PUT    /api/backend-lab/collections/{id}            # Modifier
DELETE /api/backend-lab/collections/{id}            # Supprimer
POST   /api/backend-lab/collections/{id}/run        # Exécuter

# Environnements
GET    /api/backend-lab/environments                # Liste
POST   /api/backend-lab/environments                # Créer
PUT    /api/backend-lab/environments/{id}           # Modifier
DELETE /api/backend-lab/environments/{id}           # Supprimer

# Résultats
GET    /api/backend-lab/results                     # Historique
GET    /api/backend-lab/results/{id}                # Détails résultat
DELETE /api/backend-lab/results/{id}                # Supprimer
```

---

## Module 4: Injection & Interception

### 💉 Vue d'Ensemble

Le module le plus puissant pour le debugging. Permet d'intercepter, modifier et rejouer toutes les requêtes HTTP/WebSocket en temps réel.

### Fonctionnalités

#### 4.1 Proxy MITM (Man-in-the-Middle)

```python
class MitmProxy:
    """Proxy d'interception transparent"""
    
    # Configuration
    listen_port: int = 8888
    ssl_enabled: bool = True
    ssl_cert: str  # Certificat auto-généré
    
    # Règles d'interception
    intercept_rules: List[InterceptRule]
    
    # Handlers
    on_request: Callable
    on_response: Callable
    on_websocket_message: Callable
    
class InterceptRule:
    """Règle d'interception"""
    id: str
    name: str
    enabled: bool
    
    # Matching
    url_pattern: str           # Regex ou glob
    methods: List[str]         # GET, POST, etc.
    content_types: List[str]   # application/json, etc.
    
    # Actions
    action: InterceptAction    # capture, modify, block, delay, forward
    
    # Pour modify
    request_modifications: List[Modification]
    response_modifications: List[Modification]
    
    # Pour delay
    delay_ms: int
    
    # Pour forward
    forward_to: str  # URL de redirection
    
class Modification:
    """Modification à appliquer"""
    target: str       # header.X-Custom, body.user.name, status
    operation: str    # set, delete, append, replace
    value: Any
    regex: Optional[str]  # Pour replace
```

#### 4.2 Request Capture

```python
class CapturedRequest:
    """Requête capturée"""
    id: str
    timestamp: datetime
    
    # Requête
    method: str
    url: str
    headers: Dict[str, str]
    body: Optional[bytes]
    body_text: Optional[str]
    body_json: Optional[Dict]
    
    # Réponse
    status_code: int
    response_headers: Dict[str, str]
    response_body: Optional[bytes]
    response_body_text: Optional[str]
    response_body_json: Optional[Dict]
    
    # Timing
    duration_ms: float
    ttfb_ms: float  # Time to first byte
    
    # Métadonnées
    server_id: Optional[str]
    route_id: Optional[str]
    
    # État
    was_modified: bool
    modifications_applied: List[str]
    
    # Replay
    can_replay: bool
    replay_count: int
```

#### 4.3 Request Builder

```python
class RequestBuilder:
    """Constructeur de requêtes personnalisées"""
    
    # Méthode et URL
    method: HttpMethod
    url: str
    
    # Paramètres
    path_params: Dict[str, str]
    query_params: Dict[str, str]
    
    # Headers
    headers: Dict[str, str]
    auth: Optional[AuthConfig]
    
    # Body
    body_type: BodyType  # none, json, form, raw, binary, graphql
    body_content: Any
    
    # Options
    follow_redirects: bool
    timeout_ms: int
    verify_ssl: bool
    
    # Hooks
    pre_send_script: Optional[str]
    post_receive_script: Optional[str]
    
class AuthConfig:
    type: AuthType  # none, bearer, basic, api_key, oauth2, aws_sig
    
    # Bearer
    token: Optional[str]
    
    # Basic
    username: Optional[str]
    password: Optional[str]
    
    # API Key
    key_name: Optional[str]
    key_value: Optional[str]
    key_location: Optional[str]  # header, query
    
    # OAuth2
    oauth_flow: Optional[str]
    client_id: Optional[str]
    client_secret: Optional[str]
    # ... plus de champs OAuth2
```

#### 4.4 Replay Engine

```python
class ReplayEngine:
    """Moteur de replay des requêtes"""
    
    async def replay_single(self, request_id: str, modifications: List[Modification] = None) -> CapturedRequest:
        """Rejoue une requête unique"""
        pass
    
    async def replay_sequence(self, request_ids: List[str]) -> List[CapturedRequest]:
        """Rejoue une séquence de requêtes"""
        pass
    
    async def replay_with_variations(self, request_id: str, variations: List[Dict]) -> List[CapturedRequest]:
        """Rejoue avec plusieurs variations (fuzzing)"""
        pass
    
    async def replay_stress(self, request_id: str, count: int, concurrency: int) -> StressTestResult:
        """Stress test par replay"""
        pass
```

#### 4.5 WebSocket Interception

```python
class WebSocketInterceptor:
    """Interception des connexions WebSocket"""
    
    connections: Dict[str, WebSocketConnection]
    
    async def intercept_message(self, conn_id: str, direction: str, message: Any):
        """Intercepte un message WS"""
        pass
    
    async def inject_message(self, conn_id: str, message: Any):
        """Injecte un message dans une connexion"""
        pass
    
    async def close_connection(self, conn_id: str, code: int, reason: str):
        """Ferme une connexion"""
        pass
```

### API Endpoints

```
# Proxy
POST   /api/backend-lab/proxy/start                 # Démarrer le proxy
POST   /api/backend-lab/proxy/stop                  # Arrêter le proxy
GET    /api/backend-lab/proxy/status                # État du proxy
GET    /api/backend-lab/proxy/certificate           # Télécharger le cert

# Interception Rules
GET    /api/backend-lab/intercept/rules             # Liste des règles
POST   /api/backend-lab/intercept/rules             # Créer règle
PUT    /api/backend-lab/intercept/rules/{id}        # Modifier règle
DELETE /api/backend-lab/intercept/rules/{id}        # Supprimer règle

# Captured Requests
GET    /api/backend-lab/captures                    # Liste captures
GET    /api/backend-lab/captures/{id}               # Détails capture
DELETE /api/backend-lab/captures                    # Vider captures
POST   /api/backend-lab/captures/{id}/replay        # Rejouer requête

# Request Builder
POST   /api/backend-lab/request/send                # Envoyer requête custom

# WebSocket
GET    /api/backend-lab/websocket/connections       # Connexions actives
POST   /api/backend-lab/websocket/{id}/inject       # Injecter message
```

---

## Module 5: Security Scanner

### 🛡️ Vue d'Ensemble

Le module Security Scanner effectue des **tests de sécurité automatisés** sur les APIs découvertes. C'est un véritable scanner de vulnérabilités intégré.

### Categories de Tests

#### 5.1 Injection Tests

```python
class InjectionScanner:
    """Détection des vulnérabilités d'injection"""
    
    # SQL Injection
    SQL_PAYLOADS = [
        "' OR '1'='1",
        "' OR '1'='1' --",
        "' OR '1'='1' /*",
        "1; DROP TABLE users--",
        "1' AND '1'='1",
        "' UNION SELECT NULL--",
        "' UNION SELECT username, password FROM users--",
        "1 AND 1=1",
        "1 AND 1=2",
        "1' AND SLEEP(5)--",
        "1' AND BENCHMARK(10000000,SHA1('test'))--",
    ]
    
    # NoSQL Injection
    NOSQL_PAYLOADS = [
        '{"$gt": ""}',
        '{"$ne": null}',
        '{"$where": "sleep(5000)"}',
        '{"$regex": ".*"}',
    ]
    
    # Command Injection
    COMMAND_PAYLOADS = [
        "; ls -la",
        "| cat /etc/passwd",
        "$(whoami)",
        "`id`",
        "& ping -c 10 127.0.0.1 &",
        "| sleep 5",
    ]
    
    # LDAP Injection
    LDAP_PAYLOADS = [
        "*",
        "*)(&",
        "*)(uid=*))(|(uid=*",
    ]
    
    # XPath Injection
    XPATH_PAYLOADS = [
        "' or '1'='1",
        "' or ''='",
    ]
    
    async def scan_sql_injection(self, route: DiscoveredRoute) -> List[Vulnerability]:
        pass
    
    async def scan_nosql_injection(self, route: DiscoveredRoute) -> List[Vulnerability]:
        pass
    
    async def scan_command_injection(self, route: DiscoveredRoute) -> List[Vulnerability]:
        pass
```

#### 5.2 XSS (Cross-Site Scripting)

```python
class XSSScanner:
    """Détection des vulnérabilités XSS"""
    
    XSS_PAYLOADS = [
        '<script>alert("XSS")</script>',
        '<img src=x onerror=alert("XSS")>',
        '<svg onload=alert("XSS")>',
        '"><script>alert("XSS")</script>',
        "'-alert('XSS')-'",
        '<body onload=alert("XSS")>',
        '<iframe src="javascript:alert(\'XSS\')">',
        '<input onfocus=alert("XSS") autofocus>',
        '{{constructor.constructor("alert(1)")()}}',  # Angular
        '${alert("XSS")}',  # Template literal
    ]
    
    async def scan_reflected_xss(self, route: DiscoveredRoute) -> List[Vulnerability]:
        """Détecte les XSS réfléchies"""
        pass
    
    async def scan_stored_xss(self, route: DiscoveredRoute) -> List[Vulnerability]:
        """Détecte les XSS stockées"""
        pass
    
    async def scan_dom_xss(self, route: DiscoveredRoute) -> List[Vulnerability]:
        """Détecte les XSS DOM-based"""
        pass
```

#### 5.3 Authentication & Authorization

```python
class AuthScanner:
    """Tests d'authentification et autorisation"""
    
    async def scan_broken_authentication(self, server: DiscoveredServer) -> List[Vulnerability]:
        """
        Teste:
        - Brute force possible
        - Weak passwords acceptés
        - Session fixation
        - Credential stuffing
        """
        pass
    
    async def scan_broken_authorization(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """
        Teste:
        - IDOR (Insecure Direct Object Reference)
        - Privilege escalation vertical
        - Privilege escalation horizontal
        - Missing function level access control
        """
        pass
    
    async def scan_jwt_vulnerabilities(self, route: DiscoveredRoute) -> List[Vulnerability]:
        """
        Teste:
        - Algorithm confusion (none, HS256 vs RS256)
        - Weak secret
        - Token expiration
        - Sensitive data in payload
        """
        pass
    
    async def scan_session_management(self, server: DiscoveredServer) -> List[Vulnerability]:
        """
        Teste:
        - Session ID entropy
        - Session timeout
        - Cookie flags (HttpOnly, Secure, SameSite)
        - Session regeneration after login
        """
        pass
```

#### 5.4 Data Exposure

```python
class DataExposureScanner:
    """Détection des fuites de données"""
    
    SENSITIVE_PATTERNS = {
        'credit_card': r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b',
        'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
        'email': r'[\w\.-]+@[\w\.-]+\.\w+',
        'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
        'password_field': r'"password"\s*:\s*"[^"]+"|password=\w+',
        'api_key': r'(api[_-]?key|apikey)\s*[:=]\s*[\w-]+',
        'secret': r'(secret|private[_-]?key)\s*[:=]\s*[\w-]+',
        'jwt': r'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*',
        'aws_key': r'AKIA[0-9A-Z]{16}',
        'private_key': r'-----BEGIN (RSA |EC )?PRIVATE KEY-----',
    }
    
    async def scan_sensitive_data_exposure(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """Détecte les données sensibles dans les réponses"""
        pass
    
    async def scan_verbose_errors(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """Détecte les messages d'erreur trop verbeux"""
        pass
    
    async def scan_debug_endpoints(self, server: DiscoveredServer) -> List[Vulnerability]:
        """Détecte les endpoints de debug exposés"""
        pass
```

#### 5.5 Rate Limiting & DoS

```python
class RateLimitScanner:
    """Tests de rate limiting et DoS"""
    
    async def scan_rate_limiting(self, route: DiscoveredRoute) -> RateLimitResult:
        """
        Teste:
        - Présence de rate limiting
        - Seuil du rate limiting
        - Contournement possible (header manipulation, etc.)
        """
        pass
    
    async def scan_resource_exhaustion(self, route: DiscoveredRoute) -> List[Vulnerability]:
        """
        Teste:
        - Large payload acceptance
        - Recursive structures (billion laughs)
        - Slow loris
        """
        pass
```

#### 5.6 CORS & Security Headers

```python
class HeadersScanner:
    """Analyse des headers de sécurité"""
    
    SECURITY_HEADERS = {
        'Strict-Transport-Security': {
            'required': True,
            'recommended': 'max-age=31536000; includeSubDomains'
        },
        'X-Content-Type-Options': {
            'required': True,
            'recommended': 'nosniff'
        },
        'X-Frame-Options': {
            'required': True,
            'recommended': 'DENY'
        },
        'Content-Security-Policy': {
            'required': True,
            'recommended': "default-src 'self'"
        },
        'X-XSS-Protection': {
            'required': False,  # Deprecated
            'recommended': '1; mode=block'
        },
        'Referrer-Policy': {
            'required': True,
            'recommended': 'strict-origin-when-cross-origin'
        },
        'Permissions-Policy': {
            'required': False,
            'recommended': 'geolocation=(), camera=(), microphone=()'
        }
    }
    
    async def scan_cors(self, server: DiscoveredServer) -> CorsAnalysis:
        """
        Analyse:
        - Access-Control-Allow-Origin wildcards
        - Access-Control-Allow-Credentials avec wildcard
        - Origin reflection
        - Null origin acceptance
        """
        pass
    
    async def scan_security_headers(self, server: DiscoveredServer) -> SecurityHeadersReport:
        """Analyse tous les headers de sécurité"""
        pass
```

#### 5.7 Business Logic

```python
class BusinessLogicScanner:
    """Tests de logique métier"""
    
    async def scan_mass_assignment(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """Détecte les vulnérabilités de mass assignment"""
        pass
    
    async def scan_parameter_tampering(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """Teste la manipulation des paramètres"""
        pass
    
    async def scan_race_conditions(self, routes: List[DiscoveredRoute]) -> List[Vulnerability]:
        """Détecte les race conditions potentielles"""
        pass
```

### Schéma de Vulnérabilité

```python
@dataclass
class Vulnerability:
    id: str
    
    # Classification
    type: VulnerabilityType
    category: str  # OWASP category
    cwe_id: Optional[str]  # CWE ID
    cvss_score: Optional[float]  # Score CVSS 3.1
    
    # Sévérité
    severity: Severity  # critical, high, medium, low, info
    
    # Localisation
    server_id: str
    route_id: Optional[str]
    parameter: Optional[str]
    location: str  # header, body, query, path
    
    # Détails
    title: str
    description: str
    evidence: str  # Preuve de la vulnérabilité
    
    # Payload
    payload_used: Optional[str]
    request: Optional[str]  # Requête qui a déclenché
    response: Optional[str]  # Réponse observée
    
    # Remédiation
    recommendation: str
    references: List[str]  # Liens vers documentation
    
    # Métadonnées
    discovered_at: datetime
    confidence: float  # 0.0 à 1.0
    false_positive: bool = False
    verified: bool = False
    
    # État
    status: VulnStatus  # open, confirmed, false_positive, fixed
```

### API Endpoints

```
# Scans
POST   /api/backend-lab/security/scan/{server_id}   # Scan complet
POST   /api/backend-lab/security/scan/quick         # Scan rapide
POST   /api/backend-lab/security/scan/custom        # Scan personnalisé
GET    /api/backend-lab/security/scans              # Liste des scans
GET    /api/backend-lab/security/scans/{id}         # Détails scan

# Vulnérabilités
GET    /api/backend-lab/security/vulnerabilities    # Liste vulns
GET    /api/backend-lab/security/vulnerabilities/{id} # Détails vuln
PUT    /api/backend-lab/security/vulnerabilities/{id} # Mettre à jour statut
POST   /api/backend-lab/security/vulnerabilities/{id}/verify # Vérifier

# Rapports
GET    /api/backend-lab/security/report/{scan_id}   # Rapport PDF/HTML
GET    /api/backend-lab/security/summary            # Résumé global
```

---

## Module 6: Performance Lab

### ⚡ Vue d'Ensemble

Le Performance Lab permet de mesurer et analyser les performances des APIs avec des tests de charge, stress, et endurance.

### Types de Tests

#### 6.1 Load Testing

```python
class LoadTest:
    """Test de charge"""
    name: str
    target: str  # URL ou route_id
    
    # Configuration
    virtual_users: int           # Nombre d'utilisateurs virtuels
    ramp_up_time_sec: int       # Temps de montée en charge
    duration_sec: int           # Durée du test
    
    # Scénario
    scenario: LoadTestScenario  # Scénario à exécuter
    
    # Seuils
    thresholds: LoadTestThresholds
    
class LoadTestScenario:
    """Scénario de test de charge"""
    steps: List[LoadTestStep]
    think_time_ms: int  # Pause entre les étapes
    
class LoadTestThresholds:
    """Seuils de succès"""
    max_response_time_p95_ms: int    # 95e percentile
    max_response_time_p99_ms: int    # 99e percentile
    max_error_rate_percent: float   # Taux d'erreur max
    min_throughput_rps: int         # Requêtes par seconde min
```

#### 6.2 Stress Testing

```python
class StressTest:
    """Test de stress (trouver le point de rupture)"""
    target: str
    
    # Configuration
    initial_users: int
    max_users: int
    step_users: int          # Augmentation par palier
    step_duration_sec: int   # Durée de chaque palier
    
    # Critère d'arrêt
    stop_on_error_rate: float  # Arrêter si taux d'erreur > x%
    stop_on_response_time: int # Arrêter si temps > x ms
```

#### 6.3 Spike Testing

```python
class SpikeTest:
    """Test de pics soudains"""
    target: str
    
    baseline_users: int
    spike_users: int
    spike_duration_sec: int
    recovery_time_sec: int
    
    # Répétitions
    spike_count: int
    interval_sec: int
```

#### 6.4 Endurance Testing

```python
class EnduranceTest:
    """Test d'endurance (fuites mémoire, etc.)"""
    target: str
    
    users: int
    duration_hours: int
    
    # Métriques à surveiller
    monitor_memory: bool
    monitor_connections: bool
    monitor_response_times: bool
```

### Métriques Collectées

```python
@dataclass
class PerformanceMetrics:
    # Timing
    response_times: List[float]
    avg_response_time: float
    min_response_time: float
    max_response_time: float
    p50_response_time: float
    p90_response_time: float
    p95_response_time: float
    p99_response_time: float
    std_dev_response_time: float
    
    # Throughput
    total_requests: int
    successful_requests: int
    failed_requests: int
    requests_per_second: float
    
    # Errors
    error_rate: float
    error_breakdown: Dict[int, int]  # status_code: count
    
    # Data
    total_bytes_sent: int
    total_bytes_received: int
    avg_request_size: int
    avg_response_size: int
    
    # Concurrent
    max_concurrent_connections: int
    avg_concurrent_connections: float
    
    # Timeline
    timeline: List[TimelinePoint]  # Métriques par intervalle
    
@dataclass
class TimelinePoint:
    timestamp: datetime
    requests: int
    errors: int
    avg_response_time: float
    p95_response_time: float
    active_users: int
```

### API Endpoints

```
# Tests
POST   /api/backend-lab/performance/load            # Test de charge
POST   /api/backend-lab/performance/stress          # Test de stress
POST   /api/backend-lab/performance/spike           # Test de spike
POST   /api/backend-lab/performance/endurance       # Test d'endurance

# Exécution
GET    /api/backend-lab/performance/runs            # Liste des runs
GET    /api/backend-lab/performance/runs/{id}       # Détails run
POST   /api/backend-lab/performance/runs/{id}/stop  # Arrêter un run
GET    /api/backend-lab/performance/runs/{id}/live  # Métriques live (SSE)

# Rapports
GET    /api/backend-lab/performance/report/{id}     # Rapport complet
GET    /api/backend-lab/performance/compare         # Comparer des runs
```

---

## Module 7: Mock & Simulation

### 🎭 Vue d'Ensemble

Permet de créer des serveurs mock et de simuler des comportements d'API pour les tests.

### Fonctionnalités

#### 7.1 Mock Server

```python
class MockServer:
    """Serveur mock dynamique"""
    id: str
    name: str
    port: int
    
    # Routes mockées
    routes: List[MockRoute]
    
    # Comportement global
    default_delay_ms: int
    default_response: MockResponse
    
    # Logging
    log_requests: bool
    store_requests: bool
    
class MockRoute:
    """Route mockée"""
    path: str
    method: str
    
    # Réponse
    response: MockResponse
    
    # Conditions
    conditions: List[MockCondition]  # Réponses conditionnelles
    
    # Comportement
    delay_ms: int
    fail_rate: float  # Pourcentage d'échec simulé
    
class MockResponse:
    """Réponse mockée"""
    status_code: int
    headers: Dict[str, str]
    body: Any
    body_template: Optional[str]  # Template avec variables
    
class MockCondition:
    """Condition pour réponse différente"""
    match: MockMatch
    response: MockResponse
    
class MockMatch:
    """Critère de matching"""
    type: str  # header, query, body, path
    key: str
    operator: str  # equals, contains, matches
    value: str
```

#### 7.2 Response Templates

```python
# Templates dynamiques avec Faker
TEMPLATE_FUNCTIONS = {
    '{{faker.name}}': lambda: fake.name(),
    '{{faker.email}}': lambda: fake.email(),
    '{{faker.address}}': lambda: fake.address(),
    '{{faker.company}}': lambda: fake.company(),
    '{{faker.text}}': lambda: fake.text(),
    '{{faker.uuid}}': lambda: str(fake.uuid4()),
    '{{faker.date}}': lambda: fake.date(),
    '{{faker.number(1, 100)}}': lambda: fake.random_int(1, 100),
    '{{request.body.id}}': lambda ctx: ctx['body'].get('id'),
    '{{request.headers.Authorization}}': lambda ctx: ctx['headers'].get('Authorization'),
    '{{timestamp}}': lambda: int(time.time()),
}
```

#### 7.3 Scenario Recording

```python
class ScenarioRecorder:
    """Enregistrement de scénarios pour replay"""
    
    async def start_recording(self, server_id: str) -> str:
        """Commence l'enregistrement"""
        pass
    
    async def stop_recording(self, recording_id: str) -> RecordedScenario:
        """Arrête et retourne le scénario"""
        pass
    
    async def generate_mock(self, scenario: RecordedScenario) -> MockServer:
        """Génère un mock à partir d'un scénario"""
        pass
```

### API Endpoints

```
# Mock Servers
GET    /api/backend-lab/mocks                       # Liste des mocks
POST   /api/backend-lab/mocks                       # Créer mock
GET    /api/backend-lab/mocks/{id}                  # Détails
PUT    /api/backend-lab/mocks/{id}                  # Modifier
DELETE /api/backend-lab/mocks/{id}                  # Supprimer
POST   /api/backend-lab/mocks/{id}/start            # Démarrer
POST   /api/backend-lab/mocks/{id}/stop             # Arrêter

# Recording
POST   /api/backend-lab/mocks/record/start          # Démarrer recording
POST   /api/backend-lab/mocks/record/stop           # Arrêter recording
POST   /api/backend-lab/mocks/generate              # Générer depuis recording
```

---

## Module 8: Analytics & Reporting

### 📊 Vue d'Ensemble

Le module Analytics centralise toutes les données et génère des rapports professionnels.

### Dashboards

#### 8.1 Overview Dashboard

```python
class OverviewDashboard:
    """Dashboard principal"""
    
    # Serveurs
    total_servers: int
    healthy_servers: int
    unhealthy_servers: int
    
    # Routes
    total_routes: int
    tested_routes: int
    untested_routes: int
    
    # Tests
    total_tests_run: int
    passed_tests: int
    failed_tests: int
    test_success_rate: float
    
    # Sécurité
    total_vulnerabilities: int
    critical_vulnerabilities: int
    high_vulnerabilities: int
    medium_vulnerabilities: int
    
    # Performance
    avg_response_time: float
    slowest_routes: List[RoutePerformance]
    
    # Tendances
    tests_timeline: List[DayStats]
    vulnerabilities_timeline: List[DayStats]
```

#### 8.2 Server Dashboard

```python
class ServerDashboard:
    """Dashboard par serveur"""
    server: DiscoveredServer
    
    # Santé
    uptime: float
    health_history: List[HealthCheck]
    
    # Routes
    routes_count: int
    routes_by_method: Dict[str, int]
    
    # Trafic
    total_requests: int
    requests_timeline: List[TimePoint]
    
    # Erreurs
    error_rate: float
    errors_by_status: Dict[int, int]
    
    # Performance
    avg_response_time: float
    p95_response_time: float
```

### Rapports

#### 8.3 Security Report

```python
class SecurityReport:
    """Rapport de sécurité complet"""
    
    # En-tête
    generated_at: datetime
    scan_duration: float
    
    # Score global
    security_score: int  # 0-100
    grade: str  # A, B, C, D, F
    
    # Résumé exécutif
    executive_summary: str
    
    # Vulnérabilités
    vulnerabilities: List[Vulnerability]
    vulnerabilities_by_severity: Dict[Severity, int]
    vulnerabilities_by_category: Dict[str, int]
    
    # Recommandations
    top_recommendations: List[Recommendation]
    
    # Compliance
    owasp_top_10_coverage: Dict[str, ComplianceStatus]
    
    # Export
    formats: ['pdf', 'html', 'json', 'csv']
```

#### 8.4 Test Report

```python
class TestReport:
    """Rapport de tests"""
    
    # Résumé
    total_tests: int
    passed: int
    failed: int
    skipped: int
    duration: float
    
    # Par collection
    collections_results: List[CollectionResult]
    
    # Échecs
    failures: List[TestFailure]
    
    # Couverture
    route_coverage: float
    method_coverage: Dict[str, float]
```

#### 8.5 Performance Report

```python
class PerformanceReport:
    """Rapport de performance"""
    
    # Configuration
    test_type: str
    duration: float
    virtual_users: int
    
    # Résultats
    total_requests: int
    requests_per_second: float
    
    # Latence
    response_times: ResponseTimeStats
    
    # Erreurs
    error_rate: float
    errors: List[ErrorDetail]
    
    # Seuils
    thresholds_passed: bool
    threshold_violations: List[ThresholdViolation]
    
    # Graphiques
    charts: PerformanceCharts
```

### Export & Intégrations

```python
class ReportExporter:
    """Export des rapports"""
    
    async def export_pdf(self, report: Any) -> bytes:
        pass
    
    async def export_html(self, report: Any) -> str:
        pass
    
    async def export_json(self, report: Any) -> Dict:
        pass
    
    async def export_csv(self, report: Any) -> str:
        pass
    
    async def export_junit_xml(self, test_report: TestReport) -> str:
        """Pour intégration CI/CD"""
        pass
    
    async def send_to_slack(self, report: Any, webhook_url: str):
        pass
    
    async def send_to_email(self, report: Any, recipients: List[str]):
        pass
```

### API Endpoints

```
# Dashboards
GET    /api/backend-lab/analytics/overview          # Dashboard principal
GET    /api/backend-lab/analytics/server/{id}       # Dashboard serveur
GET    /api/backend-lab/analytics/trends            # Tendances

# Rapports
GET    /api/backend-lab/reports/security/{scan_id}  # Rapport sécu
GET    /api/backend-lab/reports/test/{run_id}       # Rapport test
GET    /api/backend-lab/reports/performance/{run_id} # Rapport perf

# Export
POST   /api/backend-lab/reports/export              # Exporter rapport
POST   /api/backend-lab/reports/schedule            # Planifier rapport
```

---

## Interface Utilisateur Flutter

### 🎨 Architecture UI

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BACKEND LAB PANEL                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│ │ Servers │ │ Routes  │ │  Tests  │ │ Capture │ │Security │ │Analytics│   │
│ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘   │
│      │          │          │          │          │          │             │
│ ┌────┴──────────┴──────────┴──────────┴──────────┴──────────┴──────────┐ │
│ │                                                                        │ │
│ │                           CONTENT AREA                                 │ │
│ │                                                                        │ │
│ │  ┌────────────────────────────────┐  ┌─────────────────────────────┐  │ │
│ │  │                                │  │                              │  │ │
│ │  │        LEFT PANEL              │  │       RIGHT PANEL            │  │ │
│ │  │        (List/Tree)             │  │       (Details/Actions)      │  │ │
│ │  │                                │  │                              │  │ │
│ │  └────────────────────────────────┘  └─────────────────────────────┘  │ │
│ │                                                                        │ │
│ └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ ┌────────────────────────────────────────────────────────────────────────┐ │
│ │ STATUS BAR: Proxy: ● Running | Servers: 5 | Tests: 42 | Vulns: 3      │ │
│ └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Composants Principaux

#### Servers Panel

```dart
class BackendLabServersPanel extends StatefulWidget {
  // Liste des serveurs avec:
  // - Status en temps réel (icône colorée)
  // - Framework détecté (badge)
  // - Port d'écoute
  // - Nombre de routes découvertes
  // - Actions: Refresh, Scan Routes, Test All
}
```

#### Routes Panel

```dart
class BackendLabRoutesPanel extends StatefulWidget {
  // Arbre des routes groupées par:
  // - Server
  // - Path prefix
  // - Method
  // 
  // Chaque route affiche:
  // - Method badge coloré
  // - Path
  // - Status du dernier test
  // - Actions: Test, Edit, Mock
}
```

#### Tests Panel

```dart
class BackendLabTestsPanel extends StatefulWidget {
  // Interface complète de test:
  // - Request builder (méthode, URL, headers, body)
  // - Variables/Environnements
  // - Assertions builder visuel
  // - Résultats avec diff
  // - Historique des tests
}
```

#### Capture Panel

```dart
class BackendLabCapturePanel extends StatefulWidget {
  // Liste des requêtes capturées:
  // - Timeline en temps réel
  // - Filtres (method, status, URL)
  // - Détails de chaque requête
  // - Actions: Replay, Edit & Replay, Save
}
```

#### Security Panel

```dart
class BackendLabSecurityPanel extends StatefulWidget {
  // Dashboard sécurité:
  // - Score global
  // - Liste des vulnérabilités
  // - Détails par vulnérabilité
  // - Actions de scan
  // - Rapport exportable
}
```

#### Analytics Panel

```dart
class BackendLabAnalyticsPanel extends StatefulWidget {
  // Graphiques et métriques:
  // - Charts de performance
  // - Tendances temporelles
  // - Comparaisons
  // - Export de rapports
}
```

---

## Intégrations & API

### 🔗 WebSocket Events

```python
# Events temps réel
EVENTS = {
    'server.discovered': ServerDiscoveredEvent,
    'server.status_changed': ServerStatusChangedEvent,
    'route.discovered': RouteDiscoveredEvent,
    'request.captured': RequestCapturedEvent,
    'test.started': TestStartedEvent,
    'test.completed': TestCompletedEvent,
    'vulnerability.found': VulnerabilityFoundEvent,
    'performance.metrics': PerformanceMetricsEvent,
}
```

### REST API Complète

```
BASE URL: /api/backend-lab

# Core
GET    /status                    # État du Backend Lab
POST   /start                     # Démarrer tous les services
POST   /stop                      # Arrêter tous les services

# [Voir les sections précédentes pour tous les endpoints]
```

### CI/CD Integration

```yaml
# Exemple GitHub Actions
- name: Run API Tests
  uses: notilus/backend-lab-action@v1
  with:
    server-url: http://localhost:3000
    test-collection: ./tests/api-tests.json
    security-scan: true
    fail-on-vulnerabilities: high
    
- name: Upload Report
  uses: actions/upload-artifact@v3
  with:
    name: api-test-report
    path: ./backend-lab-report.html
```

---

## Roadmap d'Implémentation

### Phase 1: Foundation (2-3 semaines)
- [ ] Structure de base du module Backend Lab
- [ ] Server Discovery basique
- [ ] Route Discovery via OpenAPI
- [ ] Interface Flutter de base

### Phase 2: Core Features (3-4 semaines)
- [ ] API Testing Engine complet
- [ ] Request Builder avancé
- [ ] Proxy MITM basique
- [ ] UI des panneaux principaux

### Phase 3: Security (2-3 semaines)
- [ ] Security Scanner de base
- [ ] Tests d'injection
- [ ] Analyse des headers
- [ ] Rapport de sécurité

### Phase 4: Performance (2 semaines)
- [ ] Load Testing
- [ ] Stress Testing
- [ ] Métriques et graphiques

### Phase 5: Advanced (2-3 semaines)
- [ ] Mock Server
- [ ] Analytics avancés
- [ ] Export et intégrations
- [ ] Documentation

---

## Conclusion

Le **Notilus Backend Lab** sera le système de tests backend le plus complet jamais intégré dans un navigateur de développement. Il combine:

- 🔍 **Découverte intelligente** des serveurs et routes
- 🧪 **Tests exhaustifs** (fonctionnels, performance, sécurité)
- 💉 **Interception avancée** avec modification en temps réel
- 🛡️ **Scanner de sécurité** de niveau professionnel
- 📊 **Analytics puissants** avec rapports exportables
- 🎨 **Interface intuitive** intégrée parfaitement à Notilus

Ce système positionnera Notilus comme **l'outil incontournable** pour tout développeur backend.
