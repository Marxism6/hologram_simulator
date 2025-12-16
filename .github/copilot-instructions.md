# Copilot 使用说明（针对 hologram_simulator）

简短目标：帮助 AI 编码代理快速上手本 MATLAB 数字全息项目，说明项目架构、常用开发流程、关键修改点与可复用代码模式。

1) 项目概览
- 主入口：[main.m](main.m)；快速演示：`quickstart`（在 [QUICK_REFERENCE.md](QUICK_REFERENCE.md) 中也有说明）。
- 核心流水：物体建模 → 角谱衍射（FFT优先）→ 干涉图生成 → 数字再现 → 可视化/保存。
- 主要实现文件：[create_object.m](create_object.m), [angular_spectrum_diffraction.m](angular_spectrum_diffraction.m), [angular_spectrum_utils.m](angular_spectrum_utils.m), [generate_hologram.m](generate_hologram.m), [reconstruct_hologram.m](reconstruct_hologram.m), [visualize_results.m](visualize_results.m)。

2) 快速开发/调试流程（最常用命令）
- 在项目目录下运行：
  - `check_environment`：先运行以验证 MATLAB 环境（参见 [USAGE_GUIDE.txt](USAGE_GUIDE.txt)）。
  - `quickstart`：快速演示（小分辨率）。
  - `main`：完整模拟。
- 若改参数：主要在 [main.m](main.m) 的“第1部分”修改 `lambda`, `pixel_num`, `add_noise`, `SNR_dB`, `holo_z` 等。

3) 项目约定与实现细节（可直接用作自动修改规则）
- 物体表示：点云 + 复振幅（振幅×exp(i×相位）），生成在 `create_object.m`。
- 衍射实现：优先使用 FFT 版本（若存在 `angular_spectrum_fft` 或在 [angular_spectrum_diffraction.m](angular_spectrum_diffraction.m) 中切换到 FFT 实现），比直接卷积更高效。
- 参考光：在 [angular_spectrum_utils.m](angular_spectrum_utils.m) 中定义（平面波默认，项目也支持球面波参数）。
- 再现处理：在 [reconstruct_hologram.m](reconstruct_hologram.m) 中有去除零级与共轭像的数字滤波函数，编辑时注意保留这些步骤以免产生伪像。

4) 常见参数和值域（代码编辑示例）
- 分辨率：`pixel_num` 常用 256 / 512 / 1024（512 为默认、平衡精度/速度）。
- 波长示例：`lambda = 632.8e-9`（默认），或 `405e-9`, `532e-9`, `780e-9`。
- 噪声：`add_noise = true/false`, `SNR_dB` 典型 20–50。示例：在 [main.m](main.m) 修改第一段即可应用全局参数。

5) 性能与并行化
- 多视角循环可安全切换为 `parfor`（需要 Parallel Computing Toolbox），相关循环在 [main.m](main.m) 中管理视角分发。
- 若内存或时间瓶颈，优先降低 `pixel_num` 或物体采样密度（参见 [QUICK_REFERENCE.md](QUICK_REFERENCE.md) 的性能表）。

6) 可复用代码片段与修改要点（示例性 patch 行动）
- 修改参考光类型：在 [angular_spectrum_utils.m](angular_spectrum_utils.m) 中替换 `generate_reference_wave('plane',...)` 为 `'spherical'` 并保留角度参数。
- 关闭噪声快速测试：在 [main.m](main.m) 设置 `add_noise = false; SNR_dB = 50;`。
- 导入外部模型：在 [create_object.m](create_object.m) 中添加 `stlread` 路径并把顶点转换为点云。

7) 输出与验证
- 输出目录：`hologram_output/`（含 `hologram_parameters.log`, 各视角 `reconstruction_*.png` 等），自动保存参数日志以便回溯。
- 验证点：检查 `object_center(3)` 相对于 `holo_z`（物体应在全息面前方），以及参考光强度与物体振幅是否合理。

8) 依赖与限制
- 必需：MATLAB R2020b+（所有代码为纯 .m 脚本）。
- 可选：Image Processing Toolbox（可视化增强）、Parallel Computing Toolbox（`parfor` 并行）。

9) 编辑与 PR 指南（AI 代理具体行为）
- 修改参数或实验脚本：只改 [main.m](main.m) 或示例脚本，并在 `hologram_output/` 生成新的日志文件以验证行为。
- 新增功能：保持接口与现有函数签名一致，更新 README 或 QUICK_REFERENCE 中的“快速命令参考”。
- 提交说明应包含：变化原因、影响的参数默认值、以及简短的“如何复现”步骤（例如: `cd hologram_simulator; main`）。

10) 需要人工确认的修改点
- 引入外部依赖（Toolbox）前需确认目标用户环境。
- 改动会显著增加内存/时间（如默认改为 1024）应在 PR 描述中说明并提供替代低成本配置。

如需我把某段具体流程自动化（例如把 `main.m` 的参数抽成 `config.m`，或添加 `angular_spectrum_fft.m` 备选实现），回复说明要自动修改的范围与审批策略。谢谢！
