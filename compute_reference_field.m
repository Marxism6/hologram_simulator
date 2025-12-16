function ref_field = compute_reference_field(theta_ref, phi_ref, lambda, x_holo, y_holo)
% 参考光为离轴平面波
% theta_ref: 方位角 (rad)
% phi_ref: 仰角 (rad)

k = 2*pi/lambda;

% 参考光传播方向的波矢
kx_ref = k * sin(phi_ref) * cos(theta_ref);
ky_ref = k * sin(phi_ref) * sin(theta_ref);

% 二维矩阵化
[X, Y] = ndgrid(x_holo, y_holo);

% 参考光复振幅（单位振幅）
ref_field = exp(1i * (kx_ref * X + ky_ref * Y));
end