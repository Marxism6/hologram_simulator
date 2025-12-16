%% 物体建模函数
% 输入：物体中心坐标、立方体尺寸、球体半径、振幅透射率、相位延迟、波长等
% 输出：物光场复振幅、物体坐标点云
% 功能：通过离散点集表示三维物体表面，计算每个点的复振幅

function [object_field, object_coords] = create_object(...
    object_center, cube_size, sphere_radius, ...
    object_amplitude, object_phase, ...
    lambda, pixel_num, holo_size)

    % 参数解包
    center_x = object_center(1);
    center_y = object_center(2);
    center_z = object_center(3);
    
    % 物体坐标系范围（相对于中心）
    coord_range = holo_size / 2;
    
    % 生成立方体表面点
    cube_density = 30;  % 每个面的采样点数
    [cube_x, cube_y, cube_z, cube_amp, cube_phase] = generate_cube(...
        center_x, center_y, center_z, cube_size, ...
        object_amplitude, object_phase, cube_density);
    
    % 生成球体表面点
    sphere_density = 40;  % 球面采样点数
    [sphere_x, sphere_y, sphere_z, sphere_amp, sphere_phase] = generate_sphere(...
        center_x, center_y, center_z, sphere_radius, ...
        object_amplitude, object_phase, sphere_density);
    
    % 合并所有点
    object_coords.x = [cube_x; sphere_x];
    object_coords.y = [cube_y; sphere_y];
    object_coords.z = [cube_z; sphere_z];
    object_coords.amplitude = [cube_amp; sphere_amp];
    object_coords.phase = [cube_phase; sphere_phase];
    
    % 计算复振幅
    k = 2*pi/lambda;
    object_field = zeros(size(object_coords.x));
    for i = 1:length(object_coords.x)
        object_field(i) = object_coords.amplitude(i) * exp(1i * object_coords.phase(i));
    end
    
end

%% 生成立方体表面点
function [cube_x, cube_y, cube_z, cube_amp, cube_phase] = generate_cube(...
    center_x, center_y, center_z, cube_size, amplitude, phase, density)
    
    % 立方体6个面的点生成
    half_size = cube_size / 2;
    
    % 创建单个面上的网格
    face_coords = linspace(-half_size, half_size, density);
    [f_u, f_v] = meshgrid(face_coords, face_coords);
    f_u = f_u(:);
    f_v = f_v(:);
    
    % 初始化点阵列
    cube_x = [];
    cube_y = [];
    cube_z = [];
    
    % 6个面
    % 面1: z = +half_size (顶部)
    cube_x = [cube_x; center_x + f_u];
    cube_y = [cube_y; center_y + f_v];
    cube_z = [cube_z; center_z + half_size * ones(size(f_u))];
    
    % 面2: z = -half_size (底部)
    cube_x = [cube_x; center_x + f_u];
    cube_y = [cube_y; center_y + f_v];
    cube_z = [cube_z; center_z - half_size * ones(size(f_u))];
    
    % 面3: x = +half_size (右面)
    cube_x = [cube_x; center_x + half_size * ones(size(f_u))];
    cube_y = [cube_y; center_y + f_u];
    cube_z = [cube_z; center_z + f_v];
    
    % 面4: x = -half_size (左面)
    cube_x = [cube_x; center_x - half_size * ones(size(f_u))];
    cube_y = [cube_y; center_y + f_u];
    cube_z = [cube_z; center_z + f_v];
    
    % 面5: y = +half_size (前面)
    cube_x = [cube_x; center_x + f_u];
    cube_y = [cube_y; center_y + half_size * ones(size(f_u))];
    cube_z = [cube_z; center_z + f_v];
    
    % 面6: y = -half_size (后面)
    cube_x = [cube_x; center_x + f_u];
    cube_y = [cube_y; center_y - half_size * ones(size(f_u))];
    cube_z = [cube_z; center_z + f_v];
    
    % 分配振幅和相位
    num_points = length(cube_x);
    cube_amp = amplitude * ones(num_points, 1);
    cube_phase = phase * ones(num_points, 1);
    
end

%% 生成球体表面点
function [sphere_x, sphere_y, sphere_z, sphere_amp, sphere_phase] = generate_sphere(...
    center_x, center_y, center_z, radius, amplitude, phase, density)
    
    % 球面参数化：theta (0到2π), phi (0到π)
    theta = linspace(0, 2*pi, density);
    phi = linspace(0, pi, density/2);
    
    [THETA, PHI] = meshgrid(theta, phi);
    
    % 笛卡尔坐标
    x = radius * sin(PHI) .* cos(THETA) + center_x;
    y = radius * sin(PHI) .* sin(THETA) + center_y;
    z = radius * cos(PHI) + center_z;
    
    % 展平为列向量
    sphere_x = x(:);
    sphere_y = y(:);
    sphere_z = z(:);
    
    % 分配振幅和相位
    num_points = length(sphere_x);
    sphere_amp = amplitude * ones(num_points, 1);
    sphere_phase = phase * ones(num_points, 1);
    
end
