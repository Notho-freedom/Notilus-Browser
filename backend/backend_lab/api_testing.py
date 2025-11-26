"""
Module API Testing Engine - Tests complets des APIs
Moteur d'exécution de tests avec assertions, variables et scénarios
"""

import asyncio
import re
import json
import time
import uuid
from datetime import datetime
from typing import List, Dict, Optional, Any, Callable
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx
import jsonpath_ng
from jsonschema import validate, ValidationError

from .models.test import (
    TestRequest,
    TestResponse,
    TestResult,
    TestAssertion,
    AssertionOperator,
    AssertionTarget,
    TestResultStatus,
    FunctionalTest,
    TestCollection,
    TestEnvironment,
    TestVariable,
    TestScenario,
    ScenarioStep,
    ScenarioStepType,
    VariableExtraction,
    CollectionRunResult,
    AuthConfig,
    AuthType,
    BodyType,
)

router = APIRouter()

# Stores globaux
_tests: Dict[str, FunctionalTest] = {}
_collections: Dict[str, TestCollection] = {}
_environments: Dict[str, TestEnvironment] = {}
_results: Dict[str, TestResult] = {}
_collection_results: Dict[str, CollectionRunResult] = {}


# ============================================================================
# Variables Dynamiques
# ============================================================================

class DynamicVariables:
    """Générateurs de variables dynamiques"""
    
    @staticmethod
    def generate(var_name: str) -> str:
        """Génère une valeur pour une variable dynamique"""
        generators = {
            '$uuid': lambda: str(uuid.uuid4()),
            '$guid': lambda: str(uuid.uuid4()),
            '$timestamp': lambda: str(int(time.time())),
            '$isoTimestamp': lambda: datetime.now().isoformat(),
            '$randomInt': lambda: str(__import__('random').randint(0, 10000)),
            '$randomString': lambda: ''.join(__import__('random').choices(
                __import__('string').ascii_letters, k=10
            )),
            '$randomEmail': lambda: f"test_{uuid.uuid4().hex[:8]}@example.com",
            '$randomName': lambda: __import__('random').choice([
                'John Doe', 'Jane Smith', 'Bob Wilson', 'Alice Brown',
                'Charlie Davis', 'Diana Miller', 'Frank Moore', 'Grace Taylor'
            ]),
            '$randomPhone': lambda: f"+1-555-{__import__('random').randint(100,999)}-{__import__('random').randint(1000,9999)}",
            '$randomBoolean': lambda: str(__import__('random').choice([True, False])).lower(),
        }
        
        if var_name in generators:
            return generators[var_name]()
        return f"{{{{{var_name}}}}}"  # Retourner tel quel si non reconnu


# ============================================================================
# Moteur d'Assertions
# ============================================================================

class AssertionEngine:
    """Moteur d'évaluation des assertions"""
    
    OPERATORS: Dict[AssertionOperator, Callable[[Any, Any], bool]] = {
        AssertionOperator.EQUALS: lambda a, e: a == e,
        AssertionOperator.NOT_EQUALS: lambda a, e: a != e,
        AssertionOperator.CONTAINS: lambda a, e: e in str(a) if a else False,
        AssertionOperator.NOT_CONTAINS: lambda a, e: e not in str(a) if a else True,
        AssertionOperator.STARTS_WITH: lambda a, e: str(a).startswith(str(e)) if a else False,
        AssertionOperator.ENDS_WITH: lambda a, e: str(a).endswith(str(e)) if a else False,
        AssertionOperator.MATCHES: lambda a, e: bool(re.match(e, str(a))) if a else False,
        AssertionOperator.EXISTS: lambda a, e: a is not None,
        AssertionOperator.NOT_EXISTS: lambda a, e: a is None,
        AssertionOperator.IS_EMPTY: lambda a, e: len(a) == 0 if a is not None else True,
        AssertionOperator.IS_NOT_EMPTY: lambda a, e: len(a) > 0 if a is not None else False,
        AssertionOperator.GREATER_THAN: lambda a, e: float(a) > float(e),
        AssertionOperator.GREATER_THAN_OR_EQUAL: lambda a, e: float(a) >= float(e),
        AssertionOperator.LESS_THAN: lambda a, e: float(a) < float(e),
        AssertionOperator.LESS_THAN_OR_EQUAL: lambda a, e: float(a) <= float(e),
        AssertionOperator.IS_TYPE: lambda a, e: type(a).__name__.lower() == e.lower(),
        AssertionOperator.IS_ARRAY: lambda a, e: isinstance(a, list),
        AssertionOperator.IS_OBJECT: lambda a, e: isinstance(a, dict),
        AssertionOperator.ARRAY_LENGTH: lambda a, e: len(a) == int(e) if isinstance(a, list) else False,
        AssertionOperator.ARRAY_CONTAINS: lambda a, e: e in a if isinstance(a, list) else False,
        AssertionOperator.IS_NULL: lambda a, e: a is None,
        AssertionOperator.IS_NOT_NULL: lambda a, e: a is not None,
        AssertionOperator.IS_TRUE: lambda a, e: a is True or a == "true",
        AssertionOperator.IS_FALSE: lambda a, e: a is False or a == "false",
    }
    
    @classmethod
    def evaluate(cls, assertion: TestAssertion, response: TestResponse) -> TestAssertion:
        """Évalue une assertion contre une réponse"""
        try:
            # Extraire la valeur à tester
            actual_value = cls._extract_value(assertion.target, assertion.target_path, response)
            assertion.actual_value = actual_value
            
            # Cas spécial: JSON Schema validation
            if assertion.operator == AssertionOperator.JSON_SCHEMA:
                try:
                    validate(instance=actual_value, schema=assertion.expected)
                    assertion.passed = True
                except ValidationError as e:
                    assertion.passed = False
                    assertion.error_message = str(e.message)
                return assertion
            
            # Évaluer avec l'opérateur
            operator_func = cls.OPERATORS.get(assertion.operator)
            if not operator_func:
                assertion.passed = False
                assertion.error_message = f"Unknown operator: {assertion.operator}"
                return assertion
            
            try:
                assertion.passed = operator_func(actual_value, assertion.expected)
                if not assertion.passed:
                    assertion.error_message = f"Expected {assertion.expected}, got {actual_value}"
            except Exception as e:
                assertion.passed = False
                assertion.error_message = f"Evaluation error: {str(e)}"
        
        except Exception as e:
            assertion.passed = False
            assertion.error_message = str(e)
        
        return assertion
    
    @classmethod
    def _extract_value(cls, target: AssertionTarget, path: Optional[str], response: TestResponse) -> Any:
        """Extrait une valeur de la réponse"""
        if target == AssertionTarget.STATUS:
            return response.status_code
        
        elif target == AssertionTarget.STATUS_TEXT:
            return response.status_text
        
        elif target == AssertionTarget.RESPONSE_TIME:
            return response.response_time_ms
        
        elif target == AssertionTarget.CONTENT_TYPE:
            return response.content_type
        
        elif target == AssertionTarget.HEADER:
            if not path:
                return response.headers
            return response.headers.get(path) or response.headers.get(path.lower())
        
        elif target == AssertionTarget.BODY:
            return response.body_text
        
        elif target == AssertionTarget.BODY_JSON:
            if not path:
                return response.body_json
            
            # Utiliser JSONPath
            try:
                # Convertir le path simple (body.user.name) en JSONPath ($.user.name)
                if not path.startswith('$'):
                    path = '$.' + path.replace('body.', '').replace('body_json.', '')
                
                jsonpath_expr = jsonpath_ng.parse(path)
                matches = jsonpath_expr.find(response.body_json or {})
                
                if matches:
                    return matches[0].value
                return None
            except Exception as e:
                return None
        
        return None


# ============================================================================
# Moteur de Variables
# ============================================================================

class VariableEngine:
    """Gestion et substitution des variables"""
    
    @staticmethod
    def substitute(template: str, variables: Dict[str, Any]) -> str:
        """Substitue les variables dans un template"""
        if not template:
            return template
        
        result = template
        
        # Substituer les variables dynamiques d'abord
        dynamic_pattern = r'\{\{\s*(\$\w+)\s*\}\}'
        for match in re.finditer(dynamic_pattern, result):
            var_name = match.group(1)
            value = DynamicVariables.generate(var_name)
            result = result.replace(match.group(0), value)
        
        # Substituer les variables normales
        normal_pattern = r'\{\{\s*(\w+(?:\.\w+)*)\s*\}\}'
        for match in re.finditer(normal_pattern, result):
            var_path = match.group(1)
            value = VariableEngine._get_nested_value(variables, var_path)
            if value is not None:
                result = result.replace(match.group(0), str(value))
        
        return result
    
    @staticmethod
    def _get_nested_value(data: Dict, path: str) -> Any:
        """Récupère une valeur imbriquée"""
        keys = path.split('.')
        current = data
        
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                return None
        
        return current
    
    @staticmethod
    def substitute_dict(data: Dict[str, Any], variables: Dict[str, Any]) -> Dict[str, Any]:
        """Substitue récursivement les variables dans un dict"""
        result = {}
        
        for key, value in data.items():
            if isinstance(value, str):
                result[key] = VariableEngine.substitute(value, variables)
            elif isinstance(value, dict):
                result[key] = VariableEngine.substitute_dict(value, variables)
            elif isinstance(value, list):
                result[key] = [
                    VariableEngine.substitute(v, variables) if isinstance(v, str)
                    else VariableEngine.substitute_dict(v, variables) if isinstance(v, dict)
                    else v
                    for v in value
                ]
            else:
                result[key] = value
        
        return result
    
    @staticmethod
    def extract_variables(
        extractions: List[VariableExtraction], 
        response: TestResponse
    ) -> Dict[str, Any]:
        """Extrait des variables d'une réponse"""
        extracted = {}
        
        for extraction in extractions:
            value = None
            
            if extraction.source == 'body' or extraction.source == 'body_json':
                if extraction.path:
                    try:
                        path = extraction.path
                        if not path.startswith('$'):
                            path = '$.' + path
                        
                        jsonpath_expr = jsonpath_ng.parse(path)
                        matches = jsonpath_expr.find(response.body_json or {})
                        
                        if matches:
                            value = matches[0].value
                    except:
                        pass
                else:
                    value = response.body_json
            
            elif extraction.source == 'header':
                value = response.headers.get(extraction.path or '')
            
            elif extraction.source == 'status':
                value = response.status_code
            
            # Regex extraction
            if extraction.regex and value:
                match = re.search(extraction.regex, str(value))
                if match:
                    value = match.group(1) if match.groups() else match.group(0)
            
            # Valeur par défaut
            if value is None and extraction.default_value is not None:
                value = extraction.default_value
            
            if value is not None:
                extracted[extraction.name] = value
        
        return extracted


# ============================================================================
# Exécuteur de Requêtes
# ============================================================================

class RequestExecutor:
    """Exécute les requêtes HTTP"""
    
    @staticmethod
    async def execute(request: TestRequest, variables: Dict[str, Any] = None) -> TestResponse:
        """Exécute une requête et retourne la réponse"""
        variables = variables or {}
        
        # Substituer les variables
        url = VariableEngine.substitute(request.url, variables)
        headers = VariableEngine.substitute_dict(request.headers, variables)
        query_params = VariableEngine.substitute_dict(request.query_params, variables)
        
        # Appliquer l'authentification
        headers = RequestExecutor._apply_auth(headers, request.auth, variables)
        
        # Préparer le body
        body = None
        if request.body_type == BodyType.JSON and request.body:
            if isinstance(request.body, dict):
                body = json.dumps(VariableEngine.substitute_dict(request.body, variables))
            else:
                body = VariableEngine.substitute(str(request.body), variables)
            headers.setdefault('Content-Type', 'application/json')
        
        elif request.body_type == BodyType.RAW and request.body_raw:
            body = VariableEngine.substitute(request.body_raw, variables)
        
        elif request.body_type == BodyType.FORM and request.body:
            body = VariableEngine.substitute_dict(request.body, variables)
        
        # Construire l'URL avec query params
        if query_params:
            separator = '&' if '?' in url else '?'
            params_str = '&'.join(f"{k}={v}" for k, v in query_params.items())
            url = f"{url}{separator}{params_str}"
        
        # Exécuter la requête
        start_time = time.time()
        ttfb = 0.0
        
        async with httpx.AsyncClient(
            timeout=request.timeout_ms / 1000,
            verify=request.verify_ssl,
            follow_redirects=request.follow_redirects
        ) as client:
            try:
                if request.body_type == BodyType.FORM:
                    response = await client.request(
                        method=request.method,
                        url=url,
                        headers=headers,
                        data=body
                    )
                else:
                    response = await client.request(
                        method=request.method,
                        url=url,
                        headers=headers,
                        content=body
                    )
                
                ttfb = time.time() - start_time
                
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Request failed: {str(e)}")
        
        end_time = time.time()
        response_time = (end_time - start_time) * 1000
        
        # Construire la réponse
        test_response = TestResponse(
            status_code=response.status_code,
            status_text=response.reason_phrase,
            headers=dict(response.headers),
            body=response.content,
            body_text=response.text,
            response_time_ms=response_time,
            ttfb_ms=ttfb * 1000,
            content_length=len(response.content),
            content_type=response.headers.get('content-type'),
        )
        
        # Parser JSON si possible
        try:
            test_response.body_json = response.json()
        except:
            pass
        
        return test_response
    
    @staticmethod
    def _apply_auth(headers: Dict[str, str], auth: AuthConfig, variables: Dict[str, Any]) -> Dict[str, str]:
        """Applique l'authentification aux headers"""
        if auth.type == AuthType.NONE:
            return headers
        
        elif auth.type == AuthType.BEARER:
            token = VariableEngine.substitute(auth.token or '', variables)
            headers['Authorization'] = f"{auth.token_prefix} {token}"
        
        elif auth.type == AuthType.BASIC:
            import base64
            username = VariableEngine.substitute(auth.username or '', variables)
            password = VariableEngine.substitute(auth.password or '', variables)
            credentials = base64.b64encode(f"{username}:{password}".encode()).decode()
            headers['Authorization'] = f"Basic {credentials}"
        
        elif auth.type == AuthType.API_KEY:
            key_value = VariableEngine.substitute(auth.key_value or '', variables)
            if auth.key_location == 'header':
                headers[auth.key_name or 'X-API-Key'] = key_value
        
        elif auth.type == AuthType.CUSTOM:
            for key, value in auth.custom_headers.items():
                headers[key] = VariableEngine.substitute(value, variables)
        
        return headers


# ============================================================================
# Test Runner
# ============================================================================

class TestRunner:
    """Exécuteur de tests"""
    
    @staticmethod
    async def run_test(
        test: FunctionalTest, 
        environment: Optional[TestEnvironment] = None,
        extra_variables: Dict[str, Any] = None
    ) -> TestResult:
        """Exécute un test fonctionnel"""
        start_time = datetime.now()
        
        # Préparer les variables
        variables = {}
        
        # Variables d'environnement
        if environment:
            for key, var in environment.variables.items():
                variables[key] = var.value
            if environment.base_url and not test.request.url.startswith('http'):
                test.request.url = f"{environment.base_url}{test.request.url}"
        
        # Variables supplémentaires
        if extra_variables:
            variables.update(extra_variables)
        
        result = TestResult(
            id=str(uuid.uuid4()),
            test_id=test.id,
            status=TestResultStatus.PASSED,
            request=test.request,
            started_at=start_time,
        )
        
        try:
            # Exécuter la requête
            response = await RequestExecutor.execute(test.request, variables)
            result.response = response
            
            # Évaluer les assertions
            for assertion in test.assertions:
                evaluated = AssertionEngine.evaluate(assertion.model_copy(), response)
                result.assertions.append(evaluated)
                
                if evaluated.passed:
                    result.assertions_passed += 1
                else:
                    result.assertions_failed += 1
            
            # Extraire les variables
            if test.extract_variables:
                result.extracted_variables = VariableEngine.extract_variables(
                    test.extract_variables, response
                )
            
            # Déterminer le statut final
            if result.assertions_failed > 0:
                result.status = TestResultStatus.FAILED
            
        except Exception as e:
            result.status = TestResultStatus.ERROR
            result.error_message = str(e)
            result.error_stack = __import__('traceback').format_exc()
        
        result.completed_at = datetime.now()
        result.duration_ms = (result.completed_at - start_time).total_seconds() * 1000
        
        # Stocker le résultat
        _results[result.id] = result
        
        return result
    
    @staticmethod
    async def run_collection(
        collection: TestCollection,
        environment: Optional[TestEnvironment] = None
    ) -> CollectionRunResult:
        """Exécute une collection de tests"""
        start_time = datetime.now()
        
        run_result = CollectionRunResult(
            id=str(uuid.uuid4()),
            collection_id=collection.id,
            environment_id=environment.id if environment else None,
            started_at=start_time,
        )
        
        # Variables accumulées
        variables = {}
        
        # Variables de la collection
        for key, var in collection.variables.items():
            variables[key] = var.value
        
        # Déterminer l'ordre d'exécution
        test_order = collection.test_order if collection.test_order else [t.id for t in collection.tests]
        tests_by_id = {t.id: t for t in collection.tests}
        
        for test_id in test_order:
            if test_id not in tests_by_id:
                continue
            
            test = tests_by_id[test_id]
            
            # Vérifier les dépendances
            if test.depends_on and test.skip_if_fail_dependency:
                deps_failed = any(
                    r.status != TestResultStatus.PASSED 
                    for r in run_result.test_results 
                    if r.test_id in test.depends_on
                )
                if deps_failed:
                    result = TestResult(
                        id=str(uuid.uuid4()),
                        test_id=test.id,
                        status=TestResultStatus.SKIPPED,
                        request=test.request,
                        started_at=datetime.now(),
                        completed_at=datetime.now(),
                    )
                    run_result.test_results.append(result)
                    run_result.skipped_tests += 1
                    continue
            
            # Exécuter le test
            result = await TestRunner.run_test(test, environment, variables)
            run_result.test_results.append(result)
            
            # Accumuler les variables extraites
            variables.update(result.extracted_variables)
            
            # Compter
            if result.status == TestResultStatus.PASSED:
                run_result.passed_tests += 1
            elif result.status == TestResultStatus.FAILED:
                run_result.failed_tests += 1
                if collection.stop_on_failure:
                    break
            elif result.status == TestResultStatus.ERROR:
                run_result.error_tests += 1
                if collection.stop_on_failure:
                    break
        
        run_result.total_tests = len(run_result.test_results)
        run_result.completed_at = datetime.now()
        run_result.duration_ms = (run_result.completed_at - start_time).total_seconds() * 1000
        
        # Statut global
        if run_result.failed_tests > 0 or run_result.error_tests > 0:
            run_result.status = TestResultStatus.FAILED
        
        # Stocker
        _collection_results[run_result.id] = run_result
        
        return run_result


# ============================================================================
# Service Principal
# ============================================================================

class APITestingService:
    """Service principal de tests d'API"""
    
    def __init__(self):
        self.tests = _tests
        self.collections = _collections
        self.environments = _environments
        self.results = _results
    
    async def run_quick_test(self, request: TestRequest) -> TestResult:
        """Exécute un test rapide sans créer de test persistant"""
        test = FunctionalTest(
            id=str(uuid.uuid4()),
            name="Quick Test",
            request=request,
        )
        return await TestRunner.run_test(test)
    
    def create_test(self, test: FunctionalTest) -> FunctionalTest:
        """Crée un nouveau test"""
        self.tests[test.id] = test
        return test
    
    def create_collection(self, collection: TestCollection) -> TestCollection:
        """Crée une nouvelle collection"""
        self.collections[collection.id] = collection
        return collection
    
    def create_environment(self, environment: TestEnvironment) -> TestEnvironment:
        """Crée un nouvel environnement"""
        self.environments[environment.id] = environment
        return environment


# Instance singleton
_service = APITestingService()


# ============================================================================
# Endpoints API
# ============================================================================

class QuickTestRequest(BaseModel):
    """Requête de test rapide"""
    method: str = "GET"
    url: str
    headers: Dict[str, str] = {}
    body: Optional[Any] = None
    body_type: str = "none"


class RunTestRequest(BaseModel):
    """Requête d'exécution de test"""
    test_id: str
    environment_id: Optional[str] = None
    variables: Dict[str, Any] = {}


class RunCollectionRequest(BaseModel):
    """Requête d'exécution de collection"""
    collection_id: str
    environment_id: Optional[str] = None


@router.post("/run", response_model=TestResult)
async def run_quick_test(request: QuickTestRequest):
    """
    Exécute un test rapide.
    Utile pour tester rapidement un endpoint sans créer de test persistant.
    """
    test_request = TestRequest(
        method=request.method,
        url=request.url,
        headers=request.headers,
        body=request.body,
        body_type=BodyType(request.body_type) if request.body_type != "none" else BodyType.NONE,
    )
    return await _service.run_quick_test(test_request)


@router.post("/tests", response_model=FunctionalTest)
async def create_test(test: FunctionalTest):
    """
    Crée un nouveau test fonctionnel.
    """
    return _service.create_test(test)


@router.get("/tests", response_model=List[FunctionalTest])
async def list_tests():
    """
    Liste tous les tests.
    """
    return list(_tests.values())


@router.get("/tests/{test_id}", response_model=FunctionalTest)
async def get_test(test_id: str):
    """
    Récupère un test par ID.
    """
    if test_id not in _tests:
        raise HTTPException(status_code=404, detail="Test not found")
    return _tests[test_id]


@router.post("/tests/{test_id}/run", response_model=TestResult)
async def run_test(test_id: str, request: Optional[RunTestRequest] = None):
    """
    Exécute un test existant.
    """
    if test_id not in _tests:
        raise HTTPException(status_code=404, detail="Test not found")
    
    environment = None
    if request and request.environment_id:
        if request.environment_id not in _environments:
            raise HTTPException(status_code=404, detail="Environment not found")
        environment = _environments[request.environment_id]
    
    return await TestRunner.run_test(
        _tests[test_id], 
        environment,
        request.variables if request else None
    )


@router.post("/collections", response_model=TestCollection)
async def create_collection(collection: TestCollection):
    """
    Crée une nouvelle collection de tests.
    """
    return _service.create_collection(collection)


@router.get("/collections", response_model=List[TestCollection])
async def list_collections():
    """
    Liste toutes les collections.
    """
    return list(_collections.values())


@router.post("/collections/{collection_id}/run", response_model=CollectionRunResult)
async def run_collection(collection_id: str, request: Optional[RunCollectionRequest] = None):
    """
    Exécute une collection de tests.
    """
    if collection_id not in _collections:
        raise HTTPException(status_code=404, detail="Collection not found")
    
    environment = None
    if request and request.environment_id:
        if request.environment_id not in _environments:
            raise HTTPException(status_code=404, detail="Environment not found")
        environment = _environments[request.environment_id]
    
    return await TestRunner.run_collection(_collections[collection_id], environment)


@router.post("/environments", response_model=TestEnvironment)
async def create_environment(environment: TestEnvironment):
    """
    Crée un nouvel environnement de test.
    """
    return _service.create_environment(environment)


@router.get("/environments", response_model=List[TestEnvironment])
async def list_environments():
    """
    Liste tous les environnements.
    """
    return list(_environments.values())


@router.get("/results", response_model=List[TestResult])
async def list_results(limit: int = 100):
    """
    Liste les derniers résultats de tests.
    """
    results = sorted(_results.values(), key=lambda r: r.started_at, reverse=True)
    return results[:limit]


@router.get("/results/{result_id}", response_model=TestResult)
async def get_result(result_id: str):
    """
    Récupère un résultat de test par ID.
    """
    if result_id not in _results:
        raise HTTPException(status_code=404, detail="Result not found")
    return _results[result_id]
