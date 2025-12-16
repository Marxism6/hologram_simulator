%% 系统检查和配置验证脚本
% 运行此脚本以验证MATLAB环境和依赖

function check_environment()
    
    fprintf('\n');
    fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
    fprintf('║      三维物体数字全息模拟 - 系统环境检查                       ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════════╝\n\n');
    
    %% 1. MATLAB版本检查
    fprintf('【检查1】MATLAB版本\n');
    v = ver('MATLAB');
    fprintf('  版本: %s\n', v.Version);
    fprintf('  发布版本: %s\n', version('-release'));
    
    % 检查版本号
    version_num = str2double(v.Version(1:4));
    if version_num < 9.9  % R2020b 是 9.9
        fprintf('  ⚠ 警告: 建议使用 MATLAB R2020b 或更高版本\n');
    else
        fprintf('  ✓ 版本兼容\n');
    end
    fprintf('\n');
    
    %% 2. 工具箱检查
    fprintf('【检查2】可用工具箱\n');
    
    required_features = {'Signal_Toolbox', 'Image_Toolbox', 'Parallel_Toolbox'};
    optional_features = {'Statistics_Toolbox', 'Optimization_Toolbox'};
    
    fprintf('  必需 (基础功能):\n');
    % 基本功能不需要工具箱
    fprintf('    ✓ 基础函数库 - 已有\n');
    
    fprintf('  可选 (增强功能):\n');
    
    v_all = ver;
    toolbox_names = {v_all.Name};
    
    if any(strcmp(toolbox_names, 'Image Processing Toolbox'))
        fprintf('    ✓ Image Processing Toolbox - 已安装\n');
        has_image_toolbox = true;
    else
        fprintf('    ○ Image Processing Toolbox - 未安装 (可选)\n');
        has_image_toolbox = false;
    end
    
    if any(strcmp(toolbox_names, 'Parallel Computing Toolbox'))
        fprintf('    ✓ Parallel Computing Toolbox - 已安装\n');
        has_parallel_toolbox = true;
    else
        fprintf('    ○ Parallel Computing Toolbox - 未安装 (可选)\n');
        has_parallel_toolbox = false;
    end
    
    if any(strcmp(toolbox_names, 'Statistics and Machine Learning Toolbox'))
        fprintf('    ✓ Statistics Toolbox - 已安装\n');
    else
        fprintf('    ○ Statistics Toolbox - 未安装 (可选)\n');
    end
    
    fprintf('\n');
    
    %% 3. 必需函数检查
    fprintf('【检查3】必需函数可用性\n');
    
    required_functions = {
        'fft2', 'ifft2', 'fftshift', 'ifftshift', ...
        'gradient', 'meshgrid', 'ndgrid', ...
        'abs', 'angle', 'exp', 'sqrt', ...
        'figure', 'imagesc', 'colormap', ...
        'save', 'load', 'dir'
    };
    
    all_available = true;
    for i = 1:length(required_functions)
        func = required_functions{i};
        if exist(func, 'builtin') || exist(func, 'file')
            fprintf('    ✓ %s\n', func);
        else
            fprintf('    ✗ %s - 缺失!\n', func);
            all_available = false;
        end
    end
    
    fprintf('\n');
    
    %% 4. 项目文件检查
    fprintf('【检查4】项目文件\n');
    
    required_files = {
        'main.m', ...
        'create_object.m', ...
        'angular_spectrum_diffraction.m', ...
        'generate_hologram.m', ...
        'reconstruct_hologram.m', ...
        'visualize_results.m'
    };
    
    all_files_exist = true;
    for i = 1:length(required_files)
        file = required_files{i};
        if isfile(file)
            fprintf('    ✓ %s\n', file);
        else
            fprintf('    ✗ %s - 缺失!\n', file);
            all_files_exist = false;
        end
    end
    
    fprintf('\n');
    
    %% 5. 内存检查
    fprintf('【检查5】系统内存\n');
    
    % 获取系统信息
    if ispc
        [~, memstr] = memory;
        available_mem = memstr.PhysicalMemory.Available / (1024^3);
        total_mem = memstr.PhysicalMemory.Total / (1024^3);
        fprintf('  可用内存: %.2f GB\n', available_mem);
        fprintf('  总内存: %.2f GB\n', total_mem);
    else
        fprintf('  (无法在此系统上检测内存)\n');
    end
    
    if available_mem < 1
        fprintf('  ⚠ 警告: 内存可能不足，建议使用 pixel_num=256\n');
    end
    fprintf('\n');
    
    %% 6. GPU检查（可选）
    fprintf('【检查6】GPU支持（可选）\n');
    try
        gpuDevice;
        fprintf('  ✓ GPU 可用（可用于加速）\n');
    catch
        fprintf('  ○ GPU 不可用（不影响功能）\n');
    end
    fprintf('\n');
    
    %% 7. 路径检查
    fprintf('【检查7】MATLAB路径\n');
    current_dir = pwd;
    fprintf('  当前目录: %s\n', current_dir);
    
    % 检查项目文件在当前目录
    if all_files_exist
        fprintf('  ✓ 所有项目文件在当前目录\n');
    end
    fprintf('\n');
    
    %% 8. 测试简单衍射计算
    fprintf('【检查8】功能测试\n');
    fprintf('  执行简单的衍射计算...\n');
    
    try
        % 简单测试
        lambda = 632.8e-9;
        z = 100e-3;
        x = linspace(-25e-3, 25e-3, 256);
        y = linspace(-25e-3, 25e-3, 256);
        [X, Y] = ndgrid(x, y);
        
        % 简单的点源衍射
        r = sqrt(X.^2 + Y.^2 + z^2);
        U = exp(1i*2*pi*r/lambda) ./ r;
        
        intensity = abs(U).^2;
        
        fprintf('    ✓ Fresnel衍射计算 - OK\n');
        fprintf('    ✓ 矩阵运算 - OK\n');
        fprintf('    ✓ 复数运算 - OK\n');
    catch err
        fprintf('    ✗ 功能测试失败: %s\n', err.message);
    end
    fprintf('\n');
    
    %% 9. 综合评分
    fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
    fprintf('【系统检查结果】\n');
    fprintf('╚═══════════════════════════════════════════════════════════════╝\n\n');
    
    score = 100;
    
    if version_num >= 9.9
        score = score - 0;
        fprintf('  ✓ MATLAB版本兼容\n');
    else
        score = score - 10;
        fprintf('  ⚠ MATLAB版本可能过旧\n');
    end
    
    if all_files_exist
        score = score - 0;
        fprintf('  ✓ 所有项目文件完整\n');
    else
        score = score - 20;
        fprintf('  ✗ 缺少项目文件\n');
    end
    
    if all_available
        score = score - 0;
        fprintf('  ✓ 必需函数可用\n');
    else
        score = score - 15;
        fprintf('  ✗ 缺少必需函数\n');
    end
    
    if available_mem > 2
        score = score - 0;
        fprintf('  ✓ 内存充足\n');
    elseif available_mem > 1
        score = score - 5;
        fprintf('  ⚠ 内存适中\n');
    else
        score = score - 20;
        fprintf('  ✗ 内存不足\n');
    end
    
    fprintf('\n');
    fprintf('  总体得分: %d/100\n', score);
    fprintf('\n');
    
    %% 10. 推荐和建议
    fprintf('【推荐和建议】\n\n');
    
    if score >= 80
        fprintf('  ✓ 环境配置良好，可以运行所有功能\n');
        fprintf('  推荐执行: quickstart 或 main\n');
    elseif score >= 60
        fprintf('  ○ 环境基本可用，可以运行基础功能\n');
        fprintf('  推荐使用较低分辨率: pixel_num=256\n');
    else
        fprintf('  ✗ 环境可能存在问题\n');
        fprintf('  建议:\n');
        fprintf('    1. 升级MATLAB到R2020b或更高\n');
        fprintf('    2. 检查缺失的项目文件\n');
        fprintf('    3. 增加系统内存\n');
    end
    
    fprintf('\n');
    fprintf('════════════════════════════════════════════════════════════════\n\n');
    
end

%% 如果直接运行此文件
if nargin == 0
    check_environment();
    
    fprintf('【后续步骤】\n');
    fprintf('1. 如果检查通过，运行以下命令:\n');
    fprintf('   >> quickstart      (快速演示)\n');
    fprintf('   >> main            (完整模拟)\n');
    fprintf('\n2. 查看文档:\n');
    fprintf('   查阅 README.md 或 QUICK_REFERENCE.md\n');
    fprintf('\n');
end
