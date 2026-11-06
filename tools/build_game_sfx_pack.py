from __future__ import annotations

import json
import math
import wave
from pathlib import Path

import numpy as np


RATE = 44100
ROOT = Path(r"C:\Users\jiahe\Desktop\游戏作业")
MASTER = ROOT / "Audio" / "SFX"
GODOT = ROOT / "Godot_遗迹光路" / "assets" / "audio" / "sfx"
RNG = np.random.default_rng(20261021)


def env(n: int, attack=0.01, release=0.2):
    a = max(1, int(n * attack))
    r = max(1, int(n * release))
    result = np.ones(n)
    result[:a] = np.linspace(0, 1, a)
    result[-r:] *= np.linspace(1, 0, r)
    return result


def tone(duration, freq, volume=0.6, kind="sine", sweep=0.0):
    n = int(RATE * duration)
    t = np.arange(n) / RATE
    phase = 2 * np.pi * (freq * t + 0.5 * sweep * t * t / max(duration, 1e-6))
    if kind == "square":
        data = np.sign(np.sin(phase))
    elif kind == "saw":
        data = 2 * ((freq * t) % 1.0) - 1
    else:
        data = np.sin(phase)
    return data * env(n) * volume


def noise(duration, volume=0.35, smooth=1):
    n = int(RATE * duration)
    data = RNG.normal(0, 1, n)
    if smooth > 1:
        kernel = np.ones(smooth) / smooth
        data = np.convolve(data, kernel, mode="same")
    return data * env(n, 0.01, 0.25) * volume


def clicks(duration, count, body_freq=180, metallic=0.4):
    n = int(RATE * duration)
    out = np.zeros(n)
    for position in np.linspace(0.08, duration - 0.08, count):
        start = int(position * RATE)
        clip = tone(min(0.16, duration), body_freq * RNG.uniform(0.85, 1.2), 0.55, sweep=-80)
        clip += noise(len(clip) / RATE, 0.35 * metallic, 2)
        end = min(n, start + len(clip))
        out[start:end] += clip[: end - start]
    return out


def loop_noise(duration, volume=0.18, smooth=30, hum=0.0):
    n = int(RATE * duration)
    raw = RNG.normal(0, 1, n + RATE)
    kernel = np.ones(smooth) / smooth
    filtered = np.convolve(raw, kernel, mode="same")[:n]
    blend = int(RATE * 0.75)
    filtered[-blend:] = filtered[-blend:] * np.linspace(1, 0, blend) + filtered[:blend] * np.linspace(0, 1, blend)
    if hum:
        t = np.arange(n) / RATE
        filtered += 0.3 * np.sin(2 * np.pi * hum * t)
    return filtered * volume


def normalize(data):
    peak = np.max(np.abs(data)) or 1.0
    return np.clip(data / peak * 0.88, -1, 1)


def write(relpath: str, data, description: str, loop=False):
    data = normalize(np.asarray(data, dtype=np.float64))
    for base in (MASTER, GODOT):
        path = base / relpath
        path.parent.mkdir(parents=True, exist_ok=True)
        pcm = (data * 32767).astype("<i2")
        with wave.open(str(path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(pcm.tobytes())
    manifest.append({"file": relpath.replace("\\", "/"), "description": description, "loop": loop})


manifest = []

# Interface and progression.
write("ui/ui_hover.wav", tone(0.09, 980, 0.35, sweep=120), "按钮悬停")
write("ui/ui_click.wav", tone(0.12, 520, 0.55, sweep=-180) + noise(0.12, 0.15, 3), "按钮点击")
write("ui/ui_confirm.wav", np.concatenate([tone(0.11, 660), tone(0.16, 990)]), "确认")
write("ui/ui_cancel.wav", tone(0.22, 420, 0.55, sweep=-260), "取消")
write("ui/ui_error.wav", np.concatenate([tone(0.13, 190, kind="square"), tone(0.2, 145, kind="square")]), "错误提示")
write("ui/manual_page.wav", noise(0.34, 0.34, 18) + tone(0.34, 120, 0.08), "维修手册翻页")
write("ui/task_reveal.wav", np.concatenate([tone(0.12, 520), tone(0.12, 690), tone(0.24, 920)]), "新任务出现")
write("ui/medal_unlock.wav", np.concatenate([tone(0.22, 523), tone(0.22, 659), tone(0.5, 1047)]), "奖章解锁")

# Character and shared ambience.
write("player/footstep_stone_01.wav", clicks(0.24, 1, 130, 0.5), "石地脚步一")
write("player/footstep_stone_02.wav", clicks(0.24, 1, 155, 0.45), "石地脚步二")
write("player/footstep_wet_01.wav", clicks(0.28, 1, 105, 0.75) + noise(0.28, 0.24, 7), "湿石脚步一")
write("player/footstep_wet_02.wav", clicks(0.28, 1, 118, 0.7) + noise(0.28, 0.2, 9), "湿石脚步二")
write("player/toolbag_rustle.wav", noise(0.4, 0.3, 24) + clicks(0.4, 2, 220, 0.2), "工具包摩擦")
write("ambience/coastal_wind_loop.wav", loop_noise(8.0, 0.2, 90) + tone(8.0, 58, 0.035), "海塔风声循环", True)
write("ambience/rain_room_loop.wav", loop_noise(8.0, 0.24, 7), "室内雨水与滴水循环", True)
write("ambience/machinery_hum_loop.wav", loop_noise(8.0, 0.08, 35, 52) + tone(8.0, 104, 0.06), "机械低鸣循环", True)

# Floor 1: foundation.
write("floor_01/salt_scrape.wav", noise(0.75, 0.42, 5) + clicks(0.75, 5, 260, 0.35), "刮除盐霜")
write("floor_01/stone_tap.wav", clicks(0.65, 3, 190, 0.7), "敲击检查石基")
write("floor_01/mortar_spread.wav", noise(0.9, 0.38, 13) + tone(0.9, 95, 0.12), "抹涂修补砂浆")
write("floor_01/pressure_test.wav", tone(1.1, 75, 0.45, sweep=90) + noise(1.1, 0.12, 10), "承压测试")

# Floor 2: pipes and drainage.
write("floor_02/pipe_clank.wav", clicks(0.72, 3, 290, 0.85), "金属管拼接")
write("floor_02/water_leak.wav", noise(1.25, 0.4, 5) + tone(1.25, 340, 0.08), "漏水")
write("floor_02/valve_turn.wav", clicks(1.0, 7, 145, 0.7) + noise(1.0, 0.18, 18), "阀门转动")
write("floor_02/pump_start.wav", tone(1.4, 46, 0.48, kind="saw", sweep=42) + noise(1.4, 0.15, 20), "水泵启动")

# Floor 3: electrical assembly.
write("floor_03/electric_crackle.wav", noise(0.8, 0.5, 2) + tone(0.8, 2500, 0.13, sweep=-1700), "电弧与短路")
write("floor_03/fuse_insert.wav", clicks(0.42, 2, 420, 0.8), "保险丝插入")
write("floor_03/switch_throw.wav", clicks(0.38, 2, 180, 0.85), "电闸合闸")
write("floor_03/power_restore.wav", tone(1.5, 55, 0.35, sweep=80) + tone(1.5, 440, 0.13, sweep=220), "供电恢复")

# Floor 4: gear calibration.
write("floor_04/gear_jam.wav", clicks(1.0, 6, 110, 0.9) + tone(1.0, 64, 0.32, kind="saw"), "齿轮卡滞")
write("floor_04/gear_fit.wav", clicks(0.62, 3, 230, 0.75), "齿轮啮合")
write("floor_04/oil_squeeze.wav", noise(0.7, 0.32, 28) + tone(0.7, 90, 0.12, sweep=-25), "注油")
write("floor_04/gear_running.wav", tone(1.8, 72, 0.28, kind="saw") + clicks(1.8, 12, 170, 0.2), "齿轮稳定运转")

# Floor 5: lens assembly.
write("floor_05/glass_wipe.wav", noise(0.9, 0.3, 35) + tone(0.9, 690, 0.06), "擦拭镜片")
write("floor_05/glass_tap.wav", np.concatenate([tone(0.18, 1350), np.zeros(int(RATE * 0.08)), tone(0.22, 1720)]), "镜片检查")
write("floor_05/lens_place.wav", clicks(0.6, 2, 360, 0.35) + tone(0.6, 820, 0.22), "镜片安装")
write("floor_05/test_beam.wav", tone(1.2, 420, 0.22, sweep=1180) + tone(1.2, 840, 0.14, sweep=620), "光路测试")

# Floor 6: focus calibration.
write("floor_06/mirror_swivel.wav", tone(0.9, 110, 0.28, sweep=-20) + clicks(0.9, 5, 190, 0.25), "反射镜转动")
write("floor_06/focus_adjust.wav", clicks(1.15, 9, 220, 0.45) + tone(1.15, 330, 0.15, sweep=160), "焦距微调")
write("floor_06/thermal_warning.wav", np.tile(np.concatenate([tone(0.11, 880), np.zeros(int(RATE * 0.09))]), 4), "温度警告")
write("floor_06/focus_lock.wav", np.concatenate([tone(0.2, 620), tone(0.2, 930), tone(0.45, 1240)]), "焦点锁定")

# Floor 7: main lamp and finale.
write("floor_07/control_beep.wav", np.concatenate([tone(0.1, 720), tone(0.16, 960)]), "控制台确认")
write("floor_07/compass_rotate.wav", clicks(1.0, 8, 150, 0.42) + tone(1.0, 205, 0.11), "方位盘旋转")
write("floor_07/main_breaker.wav", clicks(0.75, 3, 105, 0.95), "主断路器合闸")
write("floor_07/lighthouse_start.wav", tone(2.4, 38, 0.45, kind="saw", sweep=62) + tone(2.4, 280, 0.16, sweep=540), "主灯启动")
write("floor_07/full_success.wav", np.concatenate([tone(0.3, 392), tone(0.3, 523), tone(0.3, 659), tone(1.0, 1047)]), "灯塔完全复明")

payload = {"format": "WAV PCM 16-bit mono 44.1kHz", "count": len(manifest), "sounds": manifest}
for destination in (MASTER / "SFX_MANIFEST.json", GODOT / "SFX_MANIFEST.json"):
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"Generated {len(manifest)} original sound effects")
print(MASTER)
print(GODOT)
