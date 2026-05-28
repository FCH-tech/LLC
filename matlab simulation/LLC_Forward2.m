%% LLC Resonant Tank Gain Sweep (复刻指定参考图 + 文本可拖拽功能)
clear; clc; close all;

%% 1) 设定谐振腔参数 (保持原有参数，其 Ln 恰好为 3.5)
Lr = 70e-6;      % 谐振电感 Lr (H)
Cr = 36e-9;      % 谐振电容 Cr (F)
Lm = 245e-6;     % 磁化电感 Lm (H)

k  = Lm/Lr;                      % 电感比 Ln (即 3.5)
fr = 1/(2*pi*sqrt(Lr*Cr));       % 串联谐振频率 fo=fr
Zr = sqrt(Lr/Cr);                % 特征阻抗

%% 2) 扫频范围（为了匹配原图，设置 fn 从 0.1 到 1.8）
fn = linspace(0.1, 1.8, 5000);   
fs = fn * fr;
w  = 2*pi*fs;

%% 3) 选择要对比的 Qe (匹配原图的 0, 0.47, 0.52)
Qe_list = [0, 0.443, 0.487]; 
M = zeros(numel(Qe_list), numel(fn));

%% 4) FHA 频域计算：阻抗法
Zs = 1j*w*Lr + 1./(1j*w*Cr); 
Zm = 1j*w*Lm; 

for ii = 1:numel(Qe_list)
    Qe = Qe_list(ii);
    if Qe == 0
        Zp = Zm; % Qe=0 相当于空载，Rac 无穷大
    else
        Rac = Zr / Qe; 
        Zp = 1 ./ (1./Zm + 1./Rac); 
    end
    G = Zp ./ (Zs + Zp); 
    M(ii,:) = abs(G);
end

%% 5) 计算峰值增益轨迹 (黑色虚线)
Qe_sweep = linspace(0.15, 1.5, 200);
peak_fn = zeros(size(Qe_sweep));
peak_M = zeros(size(Qe_sweep));

for i = 1:numel(Qe_sweep)
    Rac_sweep = Zr / Qe_sweep(i);
    Zp_sweep = 1 ./ (1./Zm + 1./Rac_sweep);
    G_sweep = Zp_sweep ./ (Zs + Zp_sweep);
    [max_val, max_idx] = max(abs(G_sweep));
    peak_M(i) = max_val;
    peak_fn(i) = fn(max_idx);
end

%% 6) 画图与高精度美化对齐
figure('Color', 'w', 'Position', [100, 100, 750, 600]); 
hold on; grid on;

% 定义匹配原图的曲线颜色
color_Qe0  = [0.80, 0.40, 0.10];  % 橙褐色
color_Qe47 = [0.40, 0.65, 0.65];  % 灰绿色
color_Qe52 = [0.20, 0.30, 0.65];  % 深蓝色

% 绘制三条主增益曲线
plot(fn, M(1,:), 'Color', color_Qe0,  'LineWidth', 2);
plot(fn, M(2,:), 'Color', color_Qe47, 'LineWidth', 2);
plot(fn, M(3,:), 'Color', color_Qe52, 'LineWidth', 2);

% 绘制峰值轨迹黑色虚线
plot(peak_fn, peak_M, 'k--', 'LineWidth', 1.5);

%% 7) 绘制参考线与工作点边界
Mg_max = 1.3;
Mg_min = 0.99;
fn_min = 0.65;
fn_max = 1.02;

% 水平红色点划线 (增益边界)
plot([0, 1.8], [Mg_max, Mg_max], '-.', 'Color', 'r', 'LineWidth', 1.2);
plot([0, 1.8], [Mg_min, Mg_min], '-.', 'Color', 'r', 'LineWidth', 1.2);

% 垂直红色点划线 (频率边界，局部绘制使其不贯穿到底)
plot([fn_min, fn_min], [0, Mg_max], '-.', 'Color', 'r', 'LineWidth', 1.2);
plot([fn_max, fn_max], [0, Mg_min], '-.', 'Color', 'r', 'LineWidth', 1.2);

% f_n = 1 的黑色虚线
plot([1, 1], [0, 1], 'k--', 'LineWidth', 1.5);

%% 8) 坐标轴格式化
set(gca, 'FontSize', 12, 'FontWeight', 'bold', 'LineWidth', 1.2, ...
         'GridAlpha', 0.5, 'MinorGridAlpha', 0.2);
set(gca, 'XTick', 0:0.5:1.5);
set(gca, 'YTick', 0.5:0.2:1.9);
xlim([0, 1.8]);
ylim([0.5, 2.0]);
xlabel('Normalized Frequency, \bf{f_n}', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Gain, \bf{M_g}', 'FontSize', 14, 'FontWeight', 'bold');

%% 9) 添加原生文本与箭头标注，并捕获句柄
% 将所有的 text 对象句柄保存到数组中
h_txt(1) = text(0.40, 1.45, 'Q_e = 0.443 \rightarrow ', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
h_txt(2) = text(0.44, 0.90, 'Q_e = 0.487 \rightarrow ', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
h_txt(3) = text(0.72, 1.80, ' \leftarrow Q_e = 0', 'FontSize', 12, 'FontWeight', 'bold');

h_txt(4) = text(1.25, 1.35, 'M_{g\_max} = 1.3', 'FontSize', 12, 'FontWeight', 'bold');
h_txt(5) = text(1.25, 1.04, 'M_{g\_min} = 0.99', 'FontSize', 12, 'FontWeight', 'bold');
h_txt(6) = text(0.67, 1.50, ' \leftarrow f_{n\_min} = 0.65', 'FontSize', 12, 'FontWeight', 'bold');
h_txt(7) = text(1.05, 0.60, ' \leftarrow f_{n\_max} = 1.02', 'FontSize', 12, 'FontWeight', 'bold');

h_txt(8) = text(1.35, 1.90, sprintf('L_n = %.1f', k), 'FontSize', 14, 'FontWeight', 'bold');

hold off;

%% 10) 为文本添加拖拽功能 (绑定回调事件)
for i = 1:length(h_txt)
    % 开启鼠标指针交互，并绑定按下事件
    set(h_txt(i), 'ButtonDownFcn', @startDrag, 'Margin', 1);
end

% =========================================================================
% 下方为处理鼠标拖拽事件的局部函数 (Local Functions)
% =========================================================================

function startDrag(src, ~)
    % 鼠标点击文本时触发
    fig = ancestor(src, 'figure');
    % 将鼠标移动事件和松开事件绑定到当前 Figure
    fig.WindowButtonMotionFcn = @(f, e) dragging(f, e, src);
    fig.WindowButtonUpFcn = @stopDrag;
end

function dragging(~, ~, src)
    % 鼠标拖动过程中，实时更新文本坐标
    ax = ancestor(src, 'axes');
    cp = ax.CurrentPoint;
    % 将文本的 X 和 Y 坐标更新为鼠标当前位置
    src.Position(1) = cp(1, 1);
    src.Position(2) = cp(1, 2);
end

function stopDrag(fig, ~)
    % 鼠标松开，解除事件绑定，停止拖动
    fig.WindowButtonMotionFcn = '';
    fig.WindowButtonUpFcn = '';
end