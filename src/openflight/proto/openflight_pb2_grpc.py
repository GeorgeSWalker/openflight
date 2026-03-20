"""
gRPC service handler for openflight.proto LaunchMonitor service.

Provides:
  - LaunchMonitorServicer  — abstract base class for implementors
  - add_LaunchMonitorServicer_to_server()  — registers the handler with a grpc.Server
"""

import grpc

from .openflight_pb2 import (
    ConfigResponse,
    Empty,
    PingResponse,
    ShotData,  # noqa: F401 – re-exported for convenience
    UserConfig,
)


class LaunchMonitorServicer:
    """
    Abstract base class for the LaunchMonitor gRPC service.

    Subclass this and implement the three RPC methods, then register with
    add_LaunchMonitorServicer_to_server().
    """

    def StreamShots(self, request: Empty, context: grpc.ServicerContext):
        """
        Server-streaming RPC: pushes ShotData messages to the client.
        Must be a generator that yields ShotData objects.
        """
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details("StreamShots not implemented")
        return
        yield  # pragma: no cover  – make Python treat this as a generator

    def UpdateConfig(
        self, request: UserConfig, context: grpc.ServicerContext
    ) -> ConfigResponse:
        """Unary RPC: accepts a UserConfig and returns a ConfigResponse."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details("UpdateConfig not implemented")
        return ConfigResponse()

    def Ping(self, request: Empty, context: grpc.ServicerContext) -> PingResponse:
        """Unary RPC: health-check, returns current server time in ms."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details("Ping not implemented")
        return PingResponse()


class _LaunchMonitorHandler(grpc.GenericRpcHandler):
    """Routes incoming gRPC calls to a LaunchMonitorServicer instance."""

    def __init__(self, servicer: LaunchMonitorServicer):
        self._handlers = {
            "/openflight.LaunchMonitor/StreamShots": (
                grpc.unary_stream_rpc_method_handler(
                    servicer.StreamShots,
                    request_deserializer=Empty.FromString,
                    response_serializer=lambda msg: msg.SerializeToString(),
                )
            ),
            "/openflight.LaunchMonitor/UpdateConfig": (
                grpc.unary_unary_rpc_method_handler(
                    servicer.UpdateConfig,
                    request_deserializer=UserConfig.FromString,
                    response_serializer=lambda msg: msg.SerializeToString(),
                )
            ),
            "/openflight.LaunchMonitor/Ping": (
                grpc.unary_unary_rpc_method_handler(
                    servicer.Ping,
                    request_deserializer=Empty.FromString,
                    response_serializer=lambda msg: msg.SerializeToString(),
                )
            ),
        }

    def service(self, handler_call_details):
        return self._handlers.get(handler_call_details.method)


def add_LaunchMonitorServicer_to_server(
    servicer: LaunchMonitorServicer, server: grpc.Server
):
    """Register a LaunchMonitorServicer implementation with a grpc.Server."""
    server.add_generic_rpc_handlers((_LaunchMonitorHandler(servicer),))
