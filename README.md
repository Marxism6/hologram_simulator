# 三维物体数字全息模拟程序

## 概述

这是一个严格遵循光的衍射、干涉物理规律的**MATLAB数字全息模拟系统**，支持：

- ✅ **任意三维物体建模** (立方体、球体、自定义点云)
- ✅ **角谱衍射法** 计算物光场传播
- ✅ **干涉图生成** 和相位型全息图
- ✅ **多视角全息再现** 和三维重建
- ✅ **噪声模型** (高斯白噪声，可调SNR)
- ✅ **完整可视化** 和输出管理

## 系统要求

- **MATLAB版本**: R2020b 或更高
- **必需工具箱**: 无（使用MATLAB基础函数）
- **可选工具箱**: Image Processing Toolbox（用于增强功能）
- **操作系统**: Windows/macOS/Linux

## 文件结构

```
hologram_simulator/
├── main.m                           # 主程序入口 【运行此文件】
├── create_object.m                  # 物体建模函数
├── angular_spectrum_diffraction.m   # 角谱衍射计算
├── angular_spectrum_utils.m         # 角谱衍射工具函数集
├── generate_hologram.m              # 全息图生成
├── reconstruct_hologram.m           # 全息再现
├── visualize_results.m              # 结果可视化和输出
├── get_custom_config.m              # 自定义配置
└── README.md                        # 本文件
```

## 快速开始

### 1. 基础运行（默认参数）

```matlab
cd hologram_simulator
main
```

程序会自动完成以下流程：
1. 物体建模（立方体+球体）
2. 全息图生成
3. 多视角再现
4. 输出结果到 `hologram_output/` 目录

### 2. 自定义参数

编辑 `main.m` 中的参数部分：

```matlab
%% 【第1部分】全局参数设置
lambda = 632.8e-9;              % 改为所需波长（如405nm紫外激光）
pixel_num = 512;                % 改为512或1024（更高分辨率）
add_noise = true;               % false：关闭噪声
SNR_dB = 30;                    % 改为更高值（如50dB）减少噪声
```

### 3. 自定义物体

编辑 `create_object.m` 函数：

```matlab
% 增加更多物体或修改参数
[cube_x, cube_y, cube_z, ...] = generate_cube(...
    center_x, center_y, center_z, 
    10e-3,  % 改为10mm立方体
    0.9,    % 改为0.9振幅透射率
    pi/6,   % 改为π/6相位延迟
    density);
```

## 物理模型详解

### 1. 光学参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 波长λ | 632.8 nm | 氦氖激光，可改为其他单色光 |
| 参考光角度 | θ=15°, φ=0° | 离轴平面波，避免零级衍射重叠 |
| 全息面 | z=150mm | 物体前方150mm处 |
| 采样率 | 512×512 | 可改为1024×1024或256×256 |
| 像素大小 | 97.7 μm | 50mm / 512 |

### 2. 物体参数

| 对象 | 参数 | 值 |
|------|------|-----|
| 立方体 | 边长 | 5 mm |
| | 振幅透射率 | 0.8 |
| | 相位延迟 | π/4 rad |
| 球体 | 半径 | 2 mm |
| | 振幅透射率 | 0.8 |
| | 相位延迟 | π/4 rad |
| 中心 | 坐标 | (0, 0, 100mm) |

### 3. 数学基础

#### 角谱衍射 (Angular Spectrum Method)

```
物光场在全息面的复振幅：
U(x,y,z0) = ∬ U(x',y',z) * H(x-x',y-y',z0-z) dx'dy'

其中 H 是Fresnel衍射核：
H = exp(i*k*ρ²/(2*Δz)) / (i*λ*Δz)
ρ² = (x-x')² + (y-y')²
```

#### 干涉图生成

```
干涉强度: I = |U_object + U_ref|²
        = |U_object|² + |U_ref|² + 2Re(U_object * U_ref*)

相位型全息图: Φ = arg(U_object + U_ref)
```

#### 全息再现（逆过程）

```
再现光: U_recon = U_hologram * U_reconstruction
逆向传播: 使用-Δz，重构物体平面
去除零级衍射: 数字滤波或空间滤波
```

## 输出文件说明

运行完成后，`hologram_output/` 目录包含：

### 可视化结果

| 文件名 | 内容 | 格式 |
|--------|------|------|
| `hologram_generation.fig` | 干涉图、相位图、物光强度 | .fig/.png |
| `object_3d_model.fig` | 原始物体三维模型 | .fig/.png |
| `reconstruction_theta_*.fig` | 各视角再现像 | .fig/.png |
| `multi_view_comparison.fig` | 4个视角对比 | .fig/.png |
| `parameter_summary.fig` | 参数统计信息 | .fig/.png |

### 数据文件

| 文件名 | 内容 |
|--------|------|
| `hologram_parameters.log` | 完整参数列表 |
| `hologram_statistics.txt` | 统计信息（强度范围、对比度等） |

## 高级功能

### 1. 修改参考光类型

在 `angular_spectrum_utils.m` 中：

```matlab
% 平面波参考光（默认）
theta_ref = 15*pi/180;
phi_ref = 0;

% 球面波参考光
[ref_field, ~] = generate_reference_wave('spherical', theta_ref, phi_ref, ...
    lambda, x_holo, y_holo);
```

### 2. 零级衍射和共轭像滤波

在 `reconstruct_hologram.m` 中启用：

```matlab
% 去除零级衍射和共轭像
hologram_complex = remove_DC_and_conjugate(hologram_complex, lambda, ...
    x_holo, y_holo, theta_ref, phi_ref);
```

### 3. 相位恢复

使用Gerchberg-Saxton算法从强度图恢复相位：

```matlab
num_iterations = 10;
complex_field = phase_recovery_gerchberg_saxton(...
    hologram_intensity, num_iterations, holo_z, lambda);
```

### 4. FFT基础的角谱衍射（高效）

替换 `angular_spectrum_diffraction.m` 中的Fresnel方法：

```matlab
field_at_holo = angular_spectrum_fft(...
    object_field_2d, holo_z, lambda, pixel_size);
```

```

### 切换衍射实现（可选）

`angular_spectrum_diffraction` 支持两种实现：默认的 Fresnel 近似（快速）和更精确但更耗时的角谱精确方法。可以通过在 `get_custom_config.m` 中添加字段 `diffraction_method` 来切换：

```matlab
% 在 get_custom_config.m 中加入以下行以使用角谱精确方法：
config.diffraction_method = 'angular_spectrum';
```

`main.m` 会检测并将该字段传递给 `angular_spectrum_diffraction`，无需修改源码。

## 参数调优指南

### 获得更清晰的再现像

```matlab
% 增加物体采样密度
cube_density = 50;      % 从30增加到50
sphere_density = 60;    % 从40增加到60

% 增加全息面分辨率
pixel_num = 1024;       % 从512增加到1024

% 减少噪声
SNR_dB = 50;            % 从30增加到50
add_noise = false;      % 或关闭噪声
```

### 模拟不同激光波长

```matlab
lambda = 405e-9;        % 紫外激光
lambda = 532e-9;        % 绿色激光
lambda = 780e-9;        % 近红外激光
```

### 调整再现视角分布

```matlab
theta_range = -60:10:60;  % 更宽的方位角范围
phi_range = 0:5:45;       % 更多的仰角步数
```

## 物理验证

程序遵循以下物理原理：

✅ **Helmholtz方程**: 衍射场满足波动方程  
✅ **Huygens-Fresnel原理**: 每个点作为次级波源  
✅ **角谱分解**: 平面波叠加表示  
✅ **能量守恒**: 衍射场总能量与入射能量关系  
✅ **干涉条纹对比**: 干涉项的可见度  

## 计算性能

| 参数 | 计算时间 | 内存占用 |
|------|---------|---------|
| 512×512, 200物体点 | ~10-30秒 | ~200MB |
| 512×512, 500物体点 | ~20-50秒 | ~300MB |
| 1024×1024, 200物体点 | ~40-90秒 | ~800MB |

> **注**: 时间取决于计算机CPU性能

## 常见问题 (FAQ)

### Q1: 再现像模糊怎么办？

**A**: 尝试以下方案：
- 增加 `pixel_num` 到1024
- 减少 `SNR_dB` 值（增加噪声容限）
- 增加物体采样密度

### Q2: 输出全黑或全白？

**A**: 检查：
- 物体是否在全息面前方（`object_center(3) < holo_z`）
- 物体振幅是否太小（`object_amplitude < 0.5`可能过小）
- 参考光强度是否足够

### Q3: 能否支持彩色全息？

**A**: 目前支持单波长。扩展到彩色需要：
- 为RGB三个波长分别计算
- 叠加三个全息图
- 在 `main.m` 中循环处理

### Q4: 如何导入外部STL模型？

**A**: 在 `create_object.m` 中修改：
```matlab
% 读取STL文件（需要额外处理）
[vertices, faces] = stlread('model.stl');
% 从顶点/面生成点云和振幅...
```

### Q5: 如何提高速度？

**A**:
- 减少 `pixel_num` 到256
- 减少物体采样密度
- 使用FFT基础的角谱方法（`angular_spectrum_fft.m`）
- 在 `parfor` 循环中并行化视角再现

## 扩展功能建议

1. **体积全息** - 三维记录介质
2. **反射全息** - 支持反射型全息
3. **彩色全息** - 多波长支持
4. **动态全息** - 时间变化物体
5. **全息视频** - 序列处理

## 参考文献

1. Goodman, J. W. (2005). *Introduction to Fourier Optics*. Roberts and Company.
2. Schnars, U., & Jueptner, W. (2005). *Digital Holography*. Springer.
3. Nayar, S. K., & Nakamura, Y. (1994). "Shape from focus". IEEE Transactions on Pattern Analysis.

## 许可证

此代码用于教学和研究目的。

## 技术支持

如遇问题，请检查：

1. MATLAB版本 ≥ R2020b
2. 所有 `.m` 文件在同一目录
3. `hologram_output/` 目录有写权限
4. 物体中心在全息面前方

---

**最后更新**: 2025年12月  
**开发环境**: MATLAB R2020b 及以上

