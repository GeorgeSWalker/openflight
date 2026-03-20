"""
Hand-crafted protobuf message classes for openflight.proto.

Implements binary wire-format encoding/decoding using Python's struct module.
Generated output is wire-compatible with the standard protoc output.

Wire types:
  0 = varint  (int32, int64, bool, enum)
  1 = 64-bit  (double, fixed64, sfixed64)
  2 = length-delimited (string, bytes, embedded messages)
  5 = 32-bit  (float, fixed32, sfixed32)
"""

import struct
import time


# ---------------------------------------------------------------------------
# Low-level varint helpers
# ---------------------------------------------------------------------------

def _encode_varint(value: int) -> bytes:
    """Encode a non-negative integer as a protobuf varint."""
    result = []
    while True:
        bits = value & 0x7F
        value >>= 7
        if value:
            result.append(bits | 0x80)
        else:
            result.append(bits)
            break
    return bytes(result)


def _decode_varint(buf: bytes, pos: int):
    """Decode a varint from buf at pos. Returns (value, new_pos)."""
    result = 0
    shift = 0
    while True:
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            break
        shift += 7
    return result, pos


def _encode_field(field_number: int, wire_type: int, payload: bytes) -> bytes:
    tag = _encode_varint((field_number << 3) | wire_type)
    return tag + payload


def _encode_float_field(field_number: int, value: float) -> bytes:
    return _encode_field(field_number, 5, struct.pack("<f", value))


def _encode_varint_field(field_number: int, value: int) -> bytes:
    return _encode_field(field_number, 0, _encode_varint(value))


def _encode_string_field(field_number: int, value: str) -> bytes:
    encoded = value.encode("utf-8")
    return _encode_field(field_number, 2, _encode_varint(len(encoded)) + encoded)


def _encode_bool_field(field_number: int, value: bool) -> bytes:
    return _encode_varint_field(field_number, 1 if value else 0)


def _encode_int64_field(field_number: int, value: int) -> bytes:
    # int64 as varint (wire type 0)
    # Handle negative values as 64-bit unsigned two's complement
    if value < 0:
        value = value & 0xFFFFFFFFFFFFFFFF
    return _encode_field(field_number, 0, _encode_varint(value))


# ---------------------------------------------------------------------------
# Message classes
# ---------------------------------------------------------------------------

class Empty:
    """Empty message — no fields."""

    def SerializeToString(self) -> bytes:
        return b""

    @classmethod
    def FromString(cls, data: bytes) -> "Empty":
        return cls()


class ShotData:
    """
    Shot data pushed from Pi to mobile app.

    Fields match openflight.proto ShotData:
      1: ball_speed_mph  (float)
      2: club_speed_mph  (float)
      3: launch_angle_v  (float)
      4: launch_angle_h  (float)
      5: spin_rpm        (int32)
      6: carry_yards     (float)
      7: club_id         (string)
      8: timestamp       (int64, unix ms)
    """

    def __init__(
        self,
        ball_speed_mph: float = 0.0,
        club_speed_mph: float = 0.0,
        launch_angle_v: float = 0.0,
        launch_angle_h: float = 0.0,
        spin_rpm: int = 0,
        carry_yards: float = 0.0,
        club_id: str = "",
        timestamp: int = 0,
    ):
        self.ball_speed_mph = ball_speed_mph
        self.club_speed_mph = club_speed_mph
        self.launch_angle_v = launch_angle_v
        self.launch_angle_h = launch_angle_h
        self.spin_rpm = spin_rpm
        self.carry_yards = carry_yards
        self.club_id = club_id
        self.timestamp = timestamp

    def SerializeToString(self) -> bytes:
        out = b""
        if self.ball_speed_mph:
            out += _encode_float_field(1, self.ball_speed_mph)
        if self.club_speed_mph:
            out += _encode_float_field(2, self.club_speed_mph)
        if self.launch_angle_v:
            out += _encode_float_field(3, self.launch_angle_v)
        if self.launch_angle_h:
            out += _encode_float_field(4, self.launch_angle_h)
        if self.spin_rpm:
            out += _encode_varint_field(5, self.spin_rpm)
        if self.carry_yards:
            out += _encode_float_field(6, self.carry_yards)
        if self.club_id:
            out += _encode_string_field(7, self.club_id)
        if self.timestamp:
            out += _encode_int64_field(8, self.timestamp)
        return out

    @classmethod
    def FromString(cls, data: bytes) -> "ShotData":
        msg = cls()
        pos = 0
        while pos < len(data):
            tag, pos = _decode_varint(data, pos)
            field_number = tag >> 3
            wire_type = tag & 0x07

            if wire_type == 5:  # 32-bit (float)
                value = struct.unpack_from("<f", data, pos)[0]
                pos += 4
                if field_number == 1:
                    msg.ball_speed_mph = value
                elif field_number == 2:
                    msg.club_speed_mph = value
                elif field_number == 3:
                    msg.launch_angle_v = value
                elif field_number == 4:
                    msg.launch_angle_h = value
                elif field_number == 6:
                    msg.carry_yards = value

            elif wire_type == 0:  # varint
                value, pos = _decode_varint(data, pos)
                if field_number == 5:
                    msg.spin_rpm = value
                elif field_number == 8:
                    msg.timestamp = value

            elif wire_type == 2:  # length-delimited
                length, pos = _decode_varint(data, pos)
                raw = data[pos:pos + length]
                pos += length
                if field_number == 7:
                    msg.club_id = raw.decode("utf-8")

            else:  # skip unknown wire types
                if wire_type == 1:
                    pos += 8
                elif wire_type == 5:
                    pos += 4
        return msg


class UserConfig:
    """
    Configuration update from app to Pi.

    Fields:
      1: current_club         (string)
      2: target_distance_yards (float)
    """

    def __init__(self, current_club: str = "", target_distance_yards: float = 0.0):
        self.current_club = current_club
        self.target_distance_yards = target_distance_yards

    def SerializeToString(self) -> bytes:
        out = b""
        if self.current_club:
            out += _encode_string_field(1, self.current_club)
        if self.target_distance_yards:
            out += _encode_float_field(2, self.target_distance_yards)
        return out

    @classmethod
    def FromString(cls, data: bytes) -> "UserConfig":
        msg = cls()
        pos = 0
        while pos < len(data):
            tag, pos = _decode_varint(data, pos)
            field_number = tag >> 3
            wire_type = tag & 0x07

            if wire_type == 2:  # length-delimited
                length, pos = _decode_varint(data, pos)
                raw = data[pos:pos + length]
                pos += length
                if field_number == 1:
                    msg.current_club = raw.decode("utf-8")

            elif wire_type == 5:  # 32-bit float
                value = struct.unpack_from("<f", data, pos)[0]
                pos += 4
                if field_number == 2:
                    msg.target_distance_yards = value

            elif wire_type == 0:
                _, pos = _decode_varint(data, pos)

            elif wire_type == 1:
                pos += 8

        return msg


class ConfigResponse:
    """
    Response to UpdateConfig.

    Fields:
      1: success (bool)
    """

    def __init__(self, success: bool = False):
        self.success = success

    def SerializeToString(self) -> bytes:
        if self.success:
            return _encode_bool_field(1, True)
        return b""

    @classmethod
    def FromString(cls, data: bytes) -> "ConfigResponse":
        msg = cls()
        pos = 0
        while pos < len(data):
            tag, pos = _decode_varint(data, pos)
            field_number = tag >> 3
            wire_type = tag & 0x07
            if wire_type == 0:
                value, pos = _decode_varint(data, pos)
                if field_number == 1:
                    msg.success = bool(value)
            elif wire_type == 2:
                length, pos = _decode_varint(data, pos)
                pos += length
            elif wire_type == 5:
                pos += 4
            elif wire_type == 1:
                pos += 8
        return msg


class PingResponse:
    """
    Response to Ping.

    Fields:
      1: server_time (int64, unix ms)
    """

    def __init__(self, server_time: int = 0):
        self.server_time = server_time

    def SerializeToString(self) -> bytes:
        if self.server_time:
            return _encode_int64_field(1, self.server_time)
        return b""

    @classmethod
    def FromString(cls, data: bytes) -> "PingResponse":
        msg = cls()
        pos = 0
        while pos < len(data):
            tag, pos = _decode_varint(data, pos)
            field_number = tag >> 3
            wire_type = tag & 0x07
            if wire_type == 0:
                value, pos = _decode_varint(data, pos)
                if field_number == 1:
                    msg.server_time = value
            elif wire_type == 2:
                length, pos = _decode_varint(data, pos)
                pos += length
            elif wire_type == 5:
                pos += 4
            elif wire_type == 1:
                pos += 8
        return msg
