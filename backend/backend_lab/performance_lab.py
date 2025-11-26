"""
Module Performance Lab - Tests de charge et performance
Tests de charge, stress, spike et endurance
"""

import asyncio
import time
import uuid
import statistics
from datetime import datetime
from typing import List, Dict, Optional, Any
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx

from .models.performance import (
    LoadTestConfig,
    LoadTestResult,
    LoadTestStatus,
    LoadTestType,
    LoadTestThresholds,
    PerformanceMetrics,
    ResponseTimeStats,
    TimelinePoint,
    ThresholdViolation,
    ErrorDetail,
)

router = APIRouter()

# Stores
_test_configs: Dict[str, LoadTestConfig] = {}
_test_results: Dict[str, LoadTestResult] = {}
_running_tests: Dict[str, asyncio.Task] = {}


# ============================================================================
# Virtual User Simulator
# ============================================================================

class VirtualUser:
    """Simule un utilisateur virtuel effectuant des requêtes"""
    
    def __init__(self, user_id: int, target_url: str, method: str = "GET", headers: Dict = None, body: Any = None):
        self.user_id = user_id
        self.target_url = target_url
        self.method = method
        self.headers = headers or {}
        self.body = body
        self.response_times: List[float] = []
        self.errors: List[Dict] = []
        self.requests_count = 0
    
    async def make_request(self) -> Dict[str, Any]:
        """Effectue une requête et retourne les métriques"""
        start_time = time.time()
        result = {
            "success": False,
            "status_code": 0,
            "response_time_ms": 0,
            "error": None,
            "size": 0,
        }
        
        try:
            async with httpx.AsyncClient(timeout=30.0, verify=False) as client:
                response = await client.request(
                    self.method,
                    self.target_url,
                    headers=self.headers,
                    content=self.body if self.body else None
                )
                
                result["success"] = response.status_code < 400
                result["status_code"] = response.status_code
                result["size"] = len(response.content)
                
        except httpx.TimeoutException:
            result["error"] = "timeout"
        except httpx.ConnectError:
            result["error"] = "connection"
        except Exception as e:
            result["error"] = str(e)
        
        result["response_time_ms"] = (time.time() - start_time) * 1000
        self.response_times.append(result["response_time_ms"])
        self.requests_count += 1
        
        if result["error"]:
            self.errors.append({
                "timestamp": datetime.now(),
                "error": result["error"]
            })
        
        return result


# ============================================================================
# Load Test Engine
# ============================================================================

class LoadTestEngine:
    """Moteur d'exécution des tests de charge"""
    
    def __init__(self, config: LoadTestConfig, result: LoadTestResult):
        self.config = config
        self.result = result
        self.running = False
        self.users: List[VirtualUser] = []
        self.all_response_times: List[float] = []
        self.all_errors: List[ErrorDetail] = []
        self.status_codes: Dict[int, int] = {}
        self.bytes_received = 0
        self.bytes_sent = 0
        self.timeline: List[TimelinePoint] = []
    
    async def run(self):
        """Exécute le test de charge"""
        self.running = True
        self.result.status = LoadTestStatus.RUNNING
        self.result.started_at = datetime.now()
        
        try:
            if self.config.type == LoadTestType.LOAD:
                await self._run_load_test()
            elif self.config.type == LoadTestType.STRESS:
                await self._run_stress_test()
            elif self.config.type == LoadTestType.SPIKE:
                await self._run_spike_test()
            else:
                await self._run_load_test()
            
            self.result.status = LoadTestStatus.COMPLETED
            
        except asyncio.CancelledError:
            self.result.status = LoadTestStatus.CANCELLED
        except Exception as e:
            self.result.status = LoadTestStatus.FAILED
            self.result.system_errors.append(str(e))
        
        self.running = False
        self.result.completed_at = datetime.now()
        self.result.duration_sec = (self.result.completed_at - self.result.started_at).total_seconds()
        
        # Calculer les métriques finales
        self._calculate_final_metrics()
        
        # Vérifier les seuils
        self._check_thresholds()
    
    async def _run_load_test(self):
        """Test de charge standard"""
        target_url = self.config.target_url or ""
        total_duration = self.config.duration_sec
        ramp_up = self.config.ramp_up_time_sec
        max_users = self.config.virtual_users
        
        start_time = time.time()
        interval_start = start_time
        interval_requests = 0
        interval_errors = 0
        interval_response_times = []
        
        while time.time() - start_time < total_duration and self.running:
            elapsed = time.time() - start_time
            
            # Calculer le nombre d'utilisateurs actuels (ramp-up)
            if elapsed < ramp_up:
                current_users = int((elapsed / ramp_up) * max_users) + 1
            else:
                current_users = max_users
            
            # Créer les tâches pour chaque utilisateur
            tasks = []
            for i in range(current_users):
                user = VirtualUser(i, target_url, "GET", self.config.default_headers)
                tasks.append(user.make_request())
            
            # Exécuter les requêtes
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            for result in results:
                if isinstance(result, dict):
                    self.all_response_times.append(result["response_time_ms"])
                    interval_response_times.append(result["response_time_ms"])
                    interval_requests += 1
                    
                    self.bytes_received += result.get("size", 0)
                    
                    if result["success"]:
                        status = result["status_code"]
                        self.status_codes[status] = self.status_codes.get(status, 0) + 1
                    else:
                        interval_errors += 1
            
            # Collecter les métriques toutes les secondes
            if time.time() - interval_start >= 1:
                self.timeline.append(TimelinePoint(
                    timestamp=datetime.now(),
                    active_users=current_users,
                    requests=interval_requests,
                    requests_per_second=interval_requests / (time.time() - interval_start),
                    errors=interval_errors,
                    error_rate=interval_errors / max(interval_requests, 1) * 100,
                    avg_response_time_ms=statistics.mean(interval_response_times) if interval_response_times else 0,
                    p95_response_time_ms=self._percentile(interval_response_times, 95) if interval_response_times else 0,
                ))
                
                interval_start = time.time()
                interval_requests = 0
                interval_errors = 0
                interval_response_times = []
            
            # Petite pause pour ne pas saturer
            await asyncio.sleep(0.1)
    
    async def _run_stress_test(self):
        """Test de stress - augmentation progressive jusqu'au point de rupture"""
        target_url = self.config.target_url or ""
        initial_users = self.config.initial_users
        max_users = self.config.max_users
        step_users = self.config.step_users
        step_duration = self.config.step_duration_sec
        
        current_users = initial_users
        
        while current_users <= max_users and self.running:
            step_start = time.time()
            step_errors = 0
            step_requests = 0
            step_response_times = []
            
            while time.time() - step_start < step_duration and self.running:
                tasks = []
                for i in range(current_users):
                    user = VirtualUser(i, target_url, "GET", self.config.default_headers)
                    tasks.append(user.make_request())
                
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                for result in results:
                    if isinstance(result, dict):
                        self.all_response_times.append(result["response_time_ms"])
                        step_response_times.append(result["response_time_ms"])
                        step_requests += 1
                        
                        if not result["success"]:
                            step_errors += 1
                
                await asyncio.sleep(0.1)
            
            # Vérifier si on a atteint le point de rupture
            error_rate = step_errors / max(step_requests, 1) * 100
            avg_response_time = statistics.mean(step_response_times) if step_response_times else 0
            
            self.timeline.append(TimelinePoint(
                timestamp=datetime.now(),
                active_users=current_users,
                requests=step_requests,
                requests_per_second=step_requests / step_duration,
                errors=step_errors,
                error_rate=error_rate,
                avg_response_time_ms=avg_response_time,
            ))
            
            # Point de rupture?
            if error_rate > 50 or avg_response_time > 10000:
                self.result.breakpoint_users = current_users
                self.result.breakpoint_rps = step_requests / step_duration
                break
            
            current_users += step_users
    
    async def _run_spike_test(self):
        """Test de spike - pics soudains de charge"""
        target_url = self.config.target_url or ""
        baseline = self.config.baseline_users
        spike = self.config.spike_users
        spike_duration = self.config.spike_duration_sec
        interval = self.config.spike_interval_sec
        spike_count = self.config.spike_count
        
        for spike_num in range(spike_count):
            if not self.running:
                break
            
            # Phase baseline
            await self._run_phase(target_url, baseline, interval)
            
            # Phase spike
            await self._run_phase(target_url, spike, spike_duration)
        
        # Phase de récupération
        await self._run_phase(target_url, baseline, interval)
    
    async def _run_phase(self, target_url: str, users: int, duration: int):
        """Exécute une phase du test"""
        start_time = time.time()
        
        while time.time() - start_time < duration and self.running:
            tasks = []
            for i in range(users):
                user = VirtualUser(i, target_url, "GET", self.config.default_headers)
                tasks.append(user.make_request())
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            for result in results:
                if isinstance(result, dict):
                    self.all_response_times.append(result["response_time_ms"])
            
            await asyncio.sleep(0.1)
    
    def _calculate_final_metrics(self):
        """Calcule les métriques finales"""
        if not self.all_response_times:
            return
        
        sorted_times = sorted(self.all_response_times)
        total_requests = len(sorted_times)
        
        self.result.metrics = PerformanceMetrics(
            total_duration_ms=self.result.duration_sec * 1000 if self.result.duration_sec else 0,
            total_requests=total_requests,
            successful_requests=sum(self.status_codes.get(code, 0) for code in range(200, 400)),
            failed_requests=sum(self.status_codes.get(code, 0) for code in range(400, 600)),
            requests_per_second=total_requests / max(self.result.duration_sec, 1) if self.result.duration_sec else 0,
            total_bytes_received=self.bytes_received,
            response_times=ResponseTimeStats(
                count=total_requests,
                min_ms=min(sorted_times),
                max_ms=max(sorted_times),
                avg_ms=statistics.mean(sorted_times),
                median_ms=statistics.median(sorted_times),
                std_dev_ms=statistics.stdev(sorted_times) if len(sorted_times) > 1 else 0,
                p50_ms=self._percentile(sorted_times, 50),
                p90_ms=self._percentile(sorted_times, 90),
                p95_ms=self._percentile(sorted_times, 95),
                p99_ms=self._percentile(sorted_times, 99),
            ),
            errors_by_status=self.status_codes,
        )
        
        self.result.timeline = self.timeline
    
    def _check_thresholds(self):
        """Vérifie les seuils"""
        thresholds = self.config.thresholds
        metrics = self.result.metrics
        
        if not metrics:
            return
        
        if thresholds.max_response_time_p95_ms:
            if metrics.response_times.p95_ms > thresholds.max_response_time_p95_ms:
                self.result.thresholds_passed = False
                self.result.threshold_violations.append(ThresholdViolation(
                    threshold_name="p95_response_time",
                    expected=f"<= {thresholds.max_response_time_p95_ms}ms",
                    actual=f"{metrics.response_times.p95_ms:.0f}ms",
                    message="P95 response time exceeded threshold"
                ))
        
        if thresholds.max_error_rate_percent:
            error_rate = (metrics.failed_requests / max(metrics.total_requests, 1)) * 100
            if error_rate > thresholds.max_error_rate_percent:
                self.result.thresholds_passed = False
                self.result.threshold_violations.append(ThresholdViolation(
                    threshold_name="error_rate",
                    expected=f"<= {thresholds.max_error_rate_percent}%",
                    actual=f"{error_rate:.2f}%",
                    message="Error rate exceeded threshold"
                ))
        
        if thresholds.min_requests_per_second:
            if metrics.requests_per_second < thresholds.min_requests_per_second:
                self.result.thresholds_passed = False
                self.result.threshold_violations.append(ThresholdViolation(
                    threshold_name="throughput",
                    expected=f">= {thresholds.min_requests_per_second} rps",
                    actual=f"{metrics.requests_per_second:.2f} rps",
                    message="Throughput below threshold"
                ))
    
    @staticmethod
    def _percentile(data: List[float], percentile: int) -> float:
        """Calcule un percentile"""
        if not data:
            return 0
        
        sorted_data = sorted(data)
        index = (len(sorted_data) - 1) * percentile / 100
        lower = int(index)
        upper = lower + 1
        
        if upper >= len(sorted_data):
            return sorted_data[-1]
        
        return sorted_data[lower] + (sorted_data[upper] - sorted_data[lower]) * (index - lower)
    
    def stop(self):
        """Arrête le test"""
        self.running = False


# ============================================================================
# Service Principal
# ============================================================================

class PerformanceLabService:
    """Service principal du Performance Lab"""
    
    def __init__(self):
        self.configs = _test_configs
        self.results = _test_results
        self.running_tests = _running_tests
    
    async def start_test(self, config: LoadTestConfig) -> LoadTestResult:
        """Démarre un test de performance"""
        result = LoadTestResult(
            id=str(uuid.uuid4()),
            config_id=config.id,
            status=LoadTestStatus.PENDING,
        )
        
        self.configs[config.id] = config
        self.results[result.id] = result
        
        # Créer et lancer le moteur
        engine = LoadTestEngine(config, result)
        task = asyncio.create_task(engine.run())
        self.running_tests[result.id] = task
        
        return result
    
    def stop_test(self, result_id: str):
        """Arrête un test en cours"""
        if result_id in self.running_tests:
            self.running_tests[result_id].cancel()
            if result_id in self.results:
                self.results[result_id].status = LoadTestStatus.CANCELLED


# Instance singleton
_service = PerformanceLabService()


# ============================================================================
# Endpoints API
# ============================================================================

class LoadTestRequest(BaseModel):
    """Requête de test de charge"""
    name: str
    target_url: str
    type: LoadTestType = LoadTestType.LOAD
    virtual_users: int = 10
    duration_sec: int = 60
    ramp_up_time_sec: int = 10
    thresholds: Optional[Dict[str, Any]] = None


class StressTestRequest(BaseModel):
    """Requête de test de stress"""
    name: str
    target_url: str
    initial_users: int = 1
    max_users: int = 100
    step_users: int = 10
    step_duration_sec: int = 30


@router.post("/load", response_model=LoadTestResult)
async def start_load_test(request: LoadTestRequest):
    """
    Lance un test de charge.
    """
    config = LoadTestConfig(
        name=request.name,
        target_url=request.target_url,
        type=request.type,
        virtual_users=request.virtual_users,
        duration_sec=request.duration_sec,
        ramp_up_time_sec=request.ramp_up_time_sec,
    )
    
    if request.thresholds:
        config.thresholds = LoadTestThresholds(**request.thresholds)
    
    return await _service.start_test(config)


@router.post("/stress", response_model=LoadTestResult)
async def start_stress_test(request: StressTestRequest):
    """
    Lance un test de stress.
    """
    config = LoadTestConfig(
        name=request.name,
        target_url=request.target_url,
        type=LoadTestType.STRESS,
        initial_users=request.initial_users,
        max_users=request.max_users,
        step_users=request.step_users,
        step_duration_sec=request.step_duration_sec,
    )
    
    return await _service.start_test(config)


@router.get("/runs", response_model=List[LoadTestResult])
async def list_runs():
    """
    Liste tous les tests de performance.
    """
    return sorted(_test_results.values(), key=lambda r: r.started_at or datetime.min, reverse=True)


@router.get("/runs/{run_id}", response_model=LoadTestResult)
async def get_run(run_id: str):
    """
    Récupère un résultat de test.
    """
    if run_id not in _test_results:
        raise HTTPException(status_code=404, detail="Run not found")
    return _test_results[run_id]


@router.post("/runs/{run_id}/stop")
async def stop_run(run_id: str):
    """
    Arrête un test en cours.
    """
    _service.stop_test(run_id)
    return {"status": "ok", "message": "Test stopped"}
