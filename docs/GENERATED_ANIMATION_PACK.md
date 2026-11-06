# 主角补充动画包

## 新增动画

- `Idle`：Front / Side / Back，各 4 帧，建议 4 fps 循环播放。
- `Interact`：Front / Side / Back，各 6 帧，建议 8 fps 单次播放。
- `Success`：Front，6 帧，建议 8 fps 单次播放。
- `Failure`：Front，6 帧，建议 8 fps 单次播放。

每一帧均已统一到 448 × 704 透明 PNG。`Sprites` 保存独立帧，`SpriteSheets` 保存可供 Godot AtlasTexture 使用的水平序列帧。

## Godot 动画设置建议

| 动画名 | 循环 | FPS | 结束后 |
|---|---:|---:|---|
| idle_front / idle_side / idle_back | 是 | 4 | 保持循环 |
| interact_front / interact_side / interact_back | 否 | 8 | 返回对应 idle |
| success_front | 否 | 8 | 返回 idle_front |
| failure_front | 否 | 8 | 返回 idle_front |

Side 素材默认朝左；向右时在 Godot 的 `AnimatedSprite2D` 上设置 `flip_h = true`，无需再生成一套右向图片。

## 生成说明

补充动画使用内置 ImageGen，以原有 Walk 三方向 SpriteSheet 为角色、服装、比例和画风参考。原始生成图保存在每个动画目录的 `SourceSheets`，随后通过 `Tools/process_generated_animation_sheets.py` 等分、对齐脚底并标准化为游戏规格。

