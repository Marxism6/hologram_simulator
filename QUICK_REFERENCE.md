# MATLAB 三维物体数字全息模拟程序 - 快速参考卡

## 🚀 快速启动

```matlab
% 方案 1: 快速演示（推荐首次使用）
quickstart

% 方案 2: 完整功能
main

% 方案 3: 高级示例
advanced_examples
```

## 📊 核心参数配置

编辑 `main.m` 文件的第一部分：

| 参数 | 含义 | 默认值 | 可调范围 |
|------|------|--------|---------|
| `lambda` | 激光波长 | 632.8 nm | 405~780 nm |
| `pixel_num` | 采样分辨率 | 512 | 256/512/1024 |
| `cube_size` | 立方体边长 | 5 mm | 1~10 mm |
| `sphere_radius` | 球体半径 | 2 mm | 0.5~5 mm |
| `holo_z` | 全息面距离 | 150 mm | 50~300 mm |
| `theta_ref` | 参考光方位角 | 15° | 0~30° |
| `add_noise` | 是否加噪声 | true | true/false |
| `SNR_dB` | 信噪比 | 30 dB | 20~50 dB |
| `diffraction_method` | 衍射实现 | (默认:fresnel) | 'fresnel' or 'angular_spectrum' |

## 📁 文件功能速查

| 文件 | 主要功能 | 何时调用 |
|------|--------|--------|
| `main.m` | 主程序 | 完整模拟 |
| `quickstart.m` | 快速开始 | 初学者入门 |
| `create_object.m` | 物体建模 | 自动调用 |
| `angular_spectrum_diffraction.m` | 衍射计算 | 自动调用 |
| `generate_hologram.m` | 全息生成 | 自动调用 |
| `reconstruct_hologram.m` | 全息再现 | 自动调用 |
| `visualize_results.m` | 可视化输出 | 自动调用 |
| `advanced_examples.m` | 示例代码 | 学习参考 |
| `hologram_data_analysis.m` | 数据分析 | 自定义分析 |

## 💾 输出文件位置

```
hologram_output/
├── hologram_generation.png       ← 干涉图
├── object_3d_model.png          ← 物体模型
├── reconstruction_theta_*_phi_*.png  ← 再现像
├── multi_view_comparison.png    ← 视角对比
├── hologram_parameters.log      ← 参数日志
└── hologram_statistics.txt      ← 统计信息
```

## 🔧 常见问题速解

### 问题 1: 运行时间太长
```matlab
% 解决方案：降低分辨率
pixel_num = 256;  % 从512改为256
```

### 问题 2: 输出图像太暗或太亮
```matlab
% 解决方案：调整物体参数
object_amplitude = 0.8;   % 改大此值
```

### 问题 3: 干涉条纹不清晰
```matlab
% 解决方案：增加采样或降低噪声
pixel_num = 1024;         % 更高分辨率
SNR_dB = 50;              % 更小的噪声
```

### 问题 4: 如何改变波长
```matlab
% 紫外激光
lambda = 405e-9;   % 单位：米

% 绿色激光
lambda = 532e-9;

% 近红外
lambda = 780e-9;
```

## 📈 性能表现

| 配置 | 计算时间 | 内存 | 推荐场景 |
|------|--------|------|--------|
| 256×256 | ~10 秒 | 50 MB | 快速测试 |
| 512×512 | ~30 秒 | 150 MB | **常规使用** |
| 1024×1024 | ~120 秒 | 600 MB | 高精度 |

## 🎯 典型使用流程

### 流程 1: 快速测试（2分钟）
```matlab
quickstart
```
→ 输出基本的干涉图和再现像

### 流程 2: 完整分析（1-2分钟）
```matlab
main
```
→ 输出全部结果、日志和分析

### 流程 3: 自定义实验
```matlab
% 1. 编辑 main.m 中的参数
lambda = 405e-9;           % 改变波长
pixel_num = 1024;          % 改变分辨率
theta_range = -60:10:60;   % 改变视角

% 2. 运行
main

% 3. 查看输出
open hologram_output
```

### 流程 4: 数据分析
```matlab
% 1. 运行模拟获得数据
main

% 2. 加载和分析
hologram_data_analysis.m
```

## 🔬 物理原理简述

### 1️⃣ 物体建模
- 离散点云表示三维物体
- 每个点有复振幅 = 振幅×exp(i×相位)

### 2️⃣ 衍射计算 (角谱法)
```
U(x,y,z) = ∬ U(x',y',z-Δz) × H(Δx,Δy,Δz) dx'dy'
其中 H 是 Fresnel 衍射核
```

### 3️⃣ 干涉图生成
```
I = |U_object + U_ref|²
```

### 4️⃣ 全息再现
```
U_recon = U_hologram × U_reconstruction
```

## ✅ 功能清单

- ✅ 单色相干光源 (632.8nm 氦氖激光)
- ✅ 三维物体建模 (立方体+球体)
- ✅ 角谱衍射法计算
- ✅ 干涉图和相位型全息图
- ✅ 高斯白噪声模型 (SNR可调)
- ✅ 多视角全息再现 (21个视角)
- ✅ 三维点云提取
- ✅ 完整可视化
- ✅ 数据统计和分析
- ✅ 自动报告生成
- ✅ 参数日志保存

## 📚 推荐阅读顺序

1. **5分钟入门**: 本文件 (你正在看！)
2. **15分钟快速开始**: README.md 中的"快速开始"章节
3. **30分钟深入理解**: README.md 中的"物理模型"章节
4. **1小时实战操作**: 运行 advanced_examples.m 中的各个示例
5. **进阶开发**: 参考 hologram_data_analysis.m 中的API

## 🎓 学习路径

### 初级 (适合快速了解)
1. 运行 `quickstart`
2. 查看输出的几张图
3. 阅读生成的日志文件

### 中级 (适合一般使用)
1. 运行 `main`
2. 修改参数重新运行
3. 观察参数对结果的影响
4. 查看 README.md 了解细节

### 高级 (适合深入研究)
1. 研究各个 .m 文件的源代码
2. 使用 advanced_examples.m 进行特定分析
3. 使用 hologram_data_analysis.m 进行数据处理
4. 根据需要扩展功能

## 🔗 快速命令参考

```matlab
% 运行快速演示
quickstart

% 运行完整模拟
main

% 查看高级示例
advanced_examples

% 打开输出目录
open hologram_output

% 显示文件夹内容
ls hologram_output

% 清空之前的输出
delete hologram_output/*

% 进入程序目录
cd hologram_simulator
```

## 💡 技巧和窍门

### 提示 1: 快速测试参数
```matlab
% 在Command Window中直接运行
pixel_num = 256; main
```

### 提示 2: 监控进度
使用 `fprintf` 输出会自动打印到 Command Window

### 提示 3: 调整可视化大小
编辑 visualize_results.m 中的 figure('Position', [...])

### 提示 4: 并行计算多个视角
修改 main.m 中的循环为 parfor (需要 Parallel Computing Toolbox)

### 提示 5: 导出高分辨率图像
```matlab
saveas(fig, 'output.png')
print(fig, '-dpng', '-r300', 'output.png')  % 300 dpi
```

## ⚠️ 常见错误及排查

| 错误信息 | 原因 | 解决方案 |
|---------|------|--------|
| "Undefined function" | 函数不在路径中 | 确保所有 .m 文件在同一目录 |
| "Out of memory" | 内存不足 | 降低 pixel_num |
| "Matrix dimensions incompatible" | 矩阵大小不匹配 | 检查参数一致性 |
| 输出全黑 | 物体超出范围或参数错误 | 检查 object_center 和 holo_z |

## 📞 获取帮助

1. **查看文档**: README.md 中的 FAQ 部分
2. **查看示例**: advanced_examples.m
3. **检查日志**: hologram_output/ 中的 .log 文件
4. **代码注释**: 每个函数都有详细注释

---

**版本**: v1.0  
**最后更新**: 2025年12月  
**MATLAB 版本**: R2020b 及以上

祝您使用愉快！如有问题，请参考 README.md 或项目代码中的注释。
