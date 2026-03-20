"""
gRPC server for the OpenFlight LaunchMonitor service.

Exposes three RPCs to the Flutter mobile app:
  StreamShots  — server-streaming; pushes ShotData as shots are detected
  UpdateConfig — unary; accepts club/target config changes from the app
  Ping         — unary; health-check / latency measurement

Usage (called from server.py):
    servicer, grpc_server = start_grpc_server(monitor, host="0.0.0.0", port=50051)
    ...
    stop_grpc_server(grpc_server)
"""

import logging
import queue
import time
from concurrent import futures
from typing import Optional

import grpc

from .launch_monitor import ClubType, Shot
from .proto.openflight_pb2 import (
    ConfigResponse,
    Empty,
    PingResponse,
    ShotData,
    UserConfig,
)
from .proto.openflight_pb2_grpc import (
    LaunchMonitorServicer,
    add_LaunchMonitorServicer_to_server,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Club-ID → ClubType mapping
# (Mobile app sends short IDs like "DR", "7I", "PW"; backend uses ClubType enum)
# ---------------------------------------------------------------------------

_CLUB_MAP: dict[str, ClubType] = {
    "DR": ClubType.DRIVER,
    "3W": ClubType.WOOD_3,
    "5W": ClubType.WOOD_5,
    "7W": ClubType.WOOD_7,
    "3H": ClubType.HYBRID_3,
    "4H": ClubType.HYBRID_5,   # mobile has 4H → nearest backend enum is HYBRID_5
    "5H": ClubType.HYBRID_5,
    "6H": ClubType.HYBRID_7,
    "7H": ClubType.HYBRID_7,
    "9H": ClubType.HYBRID_9,
    "2I": ClubType.IRON_2,
    "3I": ClubType.IRON_3,
    "4I": ClubType.IRON_4,
    "5I": ClubType.IRON_5,
    "6I": ClubType.IRON_6,
    "7I": ClubType.IRON_7,
    "8I": ClubType.IRON_8,
    "9I": ClubType.IRON_9,
    "PW": ClubType.PW,
    "GW": ClubType.GW,
    "SW": ClubType.SW,
    "LW": ClubType.LW,
}


def _shot_to_proto(shot: Shot) -> ShotData:
    """Convert a backend Shot dataclass to a ShotData protobuf message."""
    return ShotData(
        ball_speed_mph=float(shot.ball_speed_mph),
        club_speed_mph=float(shot.club_speed_mph) if shot.club_speed_mph else 0.0,
        launch_angle_v=float(shot.launch_angle_vertical) if shot.launch_angle_vertical else 0.0,
        launch_angle_h=float(shot.launch_angle_horizontal) if shot.launch_angle_horizontal else 0.0,
        spin_rpm=int(shot.spin_rpm) if shot.spin_rpm else 0,
        carry_yards=float(
            shot.carry_spin_adjusted if shot.carry_spin_adjusted else shot.estimated_carry_yards
        ),
        club_id=shot.club.value,
        timestamp=int(shot.timestamp.timestamp() * 1000),
    )


# ---------------------------------------------------------------------------
# Concrete servicer
# ---------------------------------------------------------------------------

class _OpenFlightServicer(LaunchMonitorServicer):
    """
    Concrete implementation of the LaunchMonitor gRPC service.

    Shot delivery uses a per-client queue: when notify_shot() is called from the
    shot-detection thread, it enqueues the ShotData onto every active subscriber
    queue.  Each StreamShots generator dequeues from its own queue and yields to
    its client.
    """

    # Sentinel pushed to subscriber queues to signal stream termination.
    _STOP = object()

    # Max number of undelivered shots per subscriber before older ones are dropped.
    _QUEUE_MAX = 20

    def __init__(self, monitor=None):
        """
        Args:
            monitor: A LaunchMonitor / MockLaunchMonitor / RollingBufferMonitor
                     instance.  Used by UpdateConfig to call set_club().
                     May be None if the monitor hasn't started yet.
        """
        self._monitor = monitor
        self._subscribers: list[queue.Queue] = []
        self._lock = __import__("threading").Lock()

    def set_monitor(self, monitor):
        """Late-bind the monitor after it has been created."""
        self._monitor = monitor

    # ------------------------------------------------------------------
    # gRPC RPCs
    # ------------------------------------------------------------------

    def StreamShots(self, request: Empty, context: grpc.ServicerContext):
        """
        Server-streaming RPC.  Stays open and yields ShotData until the client
        disconnects or the server stops.
        """
        peer = context.peer()
        logger.info("[gRPC] StreamShots: client connected (%s)", peer)

        q: queue.Queue = queue.Queue(maxsize=self._QUEUE_MAX)

        with self._lock:
            self._subscribers.append(q)

        try:
            while context.is_active():
                try:
                    item = q.get(timeout=1.0)
                except queue.Empty:
                    continue

                if item is self._STOP:
                    break

                yield item

        finally:
            with self._lock:
                self._subscribers.remove(q)
            logger.info("[gRPC] StreamShots: client disconnected (%s)", peer)

    def UpdateConfig(
        self, request: UserConfig, context: grpc.ServicerContext
    ) -> ConfigResponse:
        """Unary RPC — update club selection and target distance."""
        club_id = (request.current_club or "").strip().upper()
        club_type = _CLUB_MAP.get(club_id)

        if club_type is None:
            logger.warning("[gRPC] UpdateConfig: unknown club id %r", club_id)
            return ConfigResponse(success=False)

        if self._monitor is not None:
            try:
                self._monitor.set_club(club_type)
                logger.info(
                    "[gRPC] UpdateConfig: club=%s target=%.0f yds",
                    club_id,
                    request.target_distance_yards,
                )
            except Exception as exc:  # pylint: disable=broad-except
                logger.error("[gRPC] UpdateConfig error: %s", exc)
                return ConfigResponse(success=False)

        return ConfigResponse(success=True)

    def Ping(self, request: Empty, context: grpc.ServicerContext) -> PingResponse:
        """Unary RPC — returns server epoch time in milliseconds."""
        return PingResponse(server_time=int(time.time() * 1000))

    # ------------------------------------------------------------------
    # Internal: called from the shot-detection thread
    # ------------------------------------------------------------------

    def notify_shot(self, shot: Shot):
        """
        Push a newly detected shot to all active StreamShots subscribers.

        Called from server.py's on_shot_detected() callback (not on the gRPC
        thread), so we acquire the lock briefly to copy the subscriber list.
        """
        proto = _shot_to_proto(shot)

        with self._lock:
            subscribers = list(self._subscribers)

        for q in subscribers:
            try:
                q.put_nowait(proto)
            except queue.Full:
                # Drop the oldest item to make room, then re-enqueue.
                try:
                    q.get_nowait()
                except queue.Empty:
                    pass
                try:
                    q.put_nowait(proto)
                except queue.Full:
                    logger.warning("[gRPC] subscriber queue still full — shot dropped")

    def stop_all_streams(self):
        """Signal all active StreamShots generators to terminate cleanly."""
        with self._lock:
            subscribers = list(self._subscribers)
        for q in subscribers:
            try:
                q.put_nowait(self._STOP)
            except queue.Full:
                pass


# ---------------------------------------------------------------------------
# Public helpers used by server.py
# ---------------------------------------------------------------------------

def start_grpc_server(
    monitor=None,
    host: str = "0.0.0.0",
    port: int = 50051,
    max_workers: int = 4,
) -> tuple[_OpenFlightServicer, grpc.Server]:
    """
    Create and start the gRPC server.

    Args:
        monitor: LaunchMonitor instance (may be None; call servicer.set_monitor()
                 later if the monitor isn't ready yet).
        host:    Bind address.
        port:    gRPC port.
        max_workers: Thread pool size for the gRPC server.

    Returns:
        (servicer, server) tuple so the caller can:
          - call servicer.notify_shot(shot) from the shot callback
          - call server.stop(grace) during shutdown
    """
    servicer = _OpenFlightServicer(monitor=monitor)
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=max_workers))
    add_LaunchMonitorServicer_to_server(servicer, server)
    server.add_insecure_port(f"{host}:{port}")
    server.start()
    logger.info("[gRPC] Server listening on %s:%d", host, port)
    return servicer, server


def stop_grpc_server(server: grpc.Server, grace: Optional[float] = 2.0):
    """Stop the gRPC server, waiting up to *grace* seconds for RPCs to finish."""
    logger.info("[gRPC] Stopping server…")
    server.stop(grace)
