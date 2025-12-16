% 自定义配置函数（可选）
% 用户可以自定义物体参数、光学参数等

function config = get_custom_config()
    % 返回自定义配置参数
    % 用户可以修改这个函数来改变模拟参数
    
    config.lambda = 632.8e-9;              % 波长 (m)
    config.object_center = [0, 0, 100e-3]; % 物体中心
    config.cube_size = 5e-3;               % 立方体边长，设为0可禁用立方体
    config.sphere_radius = 2e-3;           % 球体半径，设为0可禁用球体
    config.object_amplitude = 0.8;         % 振幅透射率
    config.object_phase = pi/4;            % 相位延迟
    config.cube_density = 30;              % 立方体采样密度（每个面）
    config.sphere_density = 40;            % 球体采样密度
    
    config.holo_z = 150e-3;                % 全息面距离
    config.holo_size = 50e-3;              % 全息面大小
    config.pixel_num = 512;                % 像素数
    
    config.theta_ref = 15 * pi/180;        % 参考光方位角
    config.phi_ref = 0;                    % 参考光仰角
    
    config.theta_range = -45:15:45;        % 再现方位角
    config.phi_range = 0:10:30;            % 再现仰角
    
    config.add_noise = false;               % 是否加噪声
    config.SNR_dB = 30;                    % 信噪比
    
    % ----- 运行与保存控制（可选） -----
    % 衍射实现：'fresnel'（默认） 或 'angular_spectrum'（更精确）
    config.diffraction_method = 'fresnel';

    % 是否并行化视角再现（需要 Parallel Computing Toolbox）
    config.enable_parfor = true;
    % parpool 大小：0 = 自动（默认），>0 指定 worker 数
    config.parpool_size = 0;

    % 每多少个视角保存一次再现像（1 = 每个都保存）
    config.save_every_n_views = 1;

    % 是否使用 imwrite 保存矩阵图像（更快）
    config.enable_imwrite = true;

end
